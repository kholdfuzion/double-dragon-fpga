--	(c) 2012 d18c7db(a)hotmail
--
--	This program is free software; you can redistribute it and/or modify it under
--	the terms of the GNU General Public License version 3 or, at your option,
--	any later version as published by the Free Software Foundation.
--
--	This program is distributed in the hope that it will be useful,
--	but WITHOUT ANY WARRANTY; without even the implied warranty of
--	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
--
-- For full details, see the GNU General Public License at www.gnu.org/licenses

--------------------------------------------------------------------------------
--	Top level targeted for Pipistrello board, basic h/w specs:
--		Spartan 6 LX45
--		50Mhz xtal oscillator
--		32Mx16 LPDDR 200MHz
--		128Mbit serial Flash
--
--	adpcm samples stored in internal FPGA memory
--	0x00000, 64KB, file "21j-6"
--	0x10000, 64KB, file "21j-7"

library ieee;
	use ieee.std_logic_1164.all;
--	use ieee.std_logic_arith.all;
	use ieee.std_logic_unsigned.all;
--	use ieee.numeric_std.all;

library unisim;
	use unisim.vcomponents.all;

-- Chip connections to wing
-- AH15..9  = YM_CLK, GND, YM_IRQ, YM_IC, YM_A0, YM_WR, YM_RD, YM_CS
-- AL7...4  = CLK, SD, S1, S2
-- BL7...0  = DB7..0

entity PIPISTRELLO_TOP is
	port(
		I_RESET		: in		std_logic;								-- active high reset

		-- HDMI VGA Video
		TMDS_P    : out std_logic_vector( 3 downto 0);
		TMDS_N    : out std_logic_vector( 3 downto 0);

		-- Sound out
		O_AUDIO_L	: out		std_logic;
		O_AUDIO_R	: out		std_logic;

		-- Active high external buttons
		PS2CLK1		: inout	std_logic;
		PS2DAT1		: inout	std_logic;

		-- YM2151 chip connections
		YM_CLK      : out   std_logic; -- clock
		YM_GND      : out   std_logic; -- isolation
		YM_IC       : out   std_logic; -- reset active low
		YM_A0       : out   std_logic; -- address line 0
		YM_WR       : out   std_logic; -- write active low
		YM_RD       : out   std_logic; -- read active low
		YM_CS       : out   std_logic; -- chip select active low
		YM_IRQ      : in    std_logic; -- interrupt active low
		YM_DB       : inout std_logic_vector( 7 downto 0);

		I_CLK       : in    std_logic;
		I_SD        : in    std_logic;
		I_S1        : in    std_logic;
		I_S2        : in    std_logic;

		-- 32MHz clock
		CLK_50      : in    std_logic := '0' -- System clock 32Mhz

	);
end PIPISTRELLO_TOP;

architecture RTL of PIPISTRELLO_TOP is
	signal ps2_codeready		: std_logic := '1';
	signal ps2_scancode		: std_logic_vector( 9 downto 0) := (others => '0');
	signal key_val				: std_logic_vector( 7 downto 0) := (others => '0');
	signal key_strobe			: std_logic := '1';

	signal read_state			: std_logic_vector( 1 downto 0) := (others => '0');

	signal vga_r				: std_logic_vector( 3 downto 0) := (others => '0');
	signal vga_g				: std_logic_vector( 3 downto 0) := (others => '0');
	signal vga_b				: std_logic_vector( 3 downto 0) := (others => '0');
	signal vga_hs				: std_logic := '1';
	signal vga_vs				: std_logic := '1';

   signal red_s				: std_logic := '0';
   signal grn_s				: std_logic := '0';
   signal blu_s				: std_logic := '0';
   signal clk_s				: std_logic := '0';

	signal pwm_l				: std_logic := '1';
	signal pwm_r				: std_logic := '1';

	signal reset				: std_logic := '1';
	signal rst_ctr				: std_logic_vector( 7 downto 0) := (others => '0');
	signal hCount				: std_logic_vector(11 downto 0) := (others => '0');
	signal vCount				: std_logic_vector(11 downto 0) := (others => '0');
	signal video				: std_logic := '0';
	signal venable				: std_logic := '0';

   signal clk120M_p			: std_logic := '0';
   signal clk120M_n			: std_logic := '0';
   signal clk24M				: std_logic := '0';
	signal clk12M				: std_logic := '0';
	signal clk6M				: std_logic := '0';
	signal clk7M1				: std_logic := '0';
	signal clk3M57				: std_logic := '0';
	signal clk1M5				: std_logic := '0';

	signal clkout0				: std_logic := '0';
	signal clkout1				: std_logic := '0';
	signal clkout2				: std_logic := '0';
	signal clkout3				: std_logic := '0';
	signal clkout4				: std_logic := '0';
	signal clkout5				: std_logic := '0';
	signal clkfb				: std_logic := '0';
	signal pll_locked			: std_logic := '0';
	signal clkdiv				: std_logic_vector( 1 downto 0) := (others => '0');
	signal clkdiv2				: std_logic_vector( 1 downto 0) := (others => '0');

	signal pcm0					: std_logic_vector(11 downto 0) := (others => '0');
	signal pcm1					: std_logic_vector(11 downto 0) := (others => '0');
	signal ym0					: std_logic_vector(15 downto 0) := (others => '0');
	signal ym1					: std_logic_vector(15 downto 0) := (others => '0');
	signal sum0					: std_logic_vector(15 downto 0) := (others => '0');
	signal sum1					: std_logic_vector(15 downto 0) := (others => '0');

	-- internal YM2151 signals
	signal ym_ic_int			: std_logic := '0';
	signal ym_a0_int			: std_logic := '0';
	signal ym_wr_int			: std_logic := '0';
	signal ym_rd_int			: std_logic := '0';
	signal ym_cs_int			: std_logic := '0';
	signal ym_irq_int			: std_logic := '0';
	signal ym_dbi_int			: std_logic_vector( 7 downto 0) := (others => '0');
	signal ym_dbo_int			: std_logic_vector( 7 downto 0) := (others => '0');
	signal ym3012_clk			: std_logic := '0';

begin
--	IO pin assignments
	OBUFDS_clk : OBUFDS port map ( O => TMDS_P(3), OB => TMDS_N(3), I => clk_s );
	OBUFDS_red : OBUFDS port map ( O => TMDS_P(2), OB => TMDS_N(2), I => red_s );
	OBUFDS_grn : OBUFDS port map ( O => TMDS_P(1), OB => TMDS_N(1), I => grn_s );
	OBUFDS_blu : OBUFDS port map ( O => TMDS_P(0), OB => TMDS_N(0), I => blu_s );

	O_AUDIO_L  <= pwm_l;
	O_AUDIO_R  <= pwm_r;

	-- negate some signals to convert internal positive logic to external negative logic
	YM_CLK     <= clk3M57;
	YM_GND     <= '0';
	YM_IC      <= not ym_ic_int;
	YM_A0      <= ym_a0_int;
	YM_WR      <= not ym_wr_int;
	YM_RD      <= not ym_rd_int;
	YM_CS      <= not ym_cs_int;
	ym_irq_int <= not YM_IRQ;
	ym_dbi_int <= YM_DB;
	YM_DB      <= ym_dbo_int when ym_wr_int = '1' and ym_cs_int = '1' else (others=>'Z');

	inst_dvid: entity work.dvid
	port map(
      clk_p     => clk120M_p,
      clk_n     => clk120M_n, 
      clk_pixel => clk24M,
      red_p(  7) => video,
      red_p(  6 downto 0) => (others => '0'),
      green_p(7) => video,
      green_p(6 downto 0) => (others => '0'),
      blue_p( 7) => video,
      blue_p( 6 downto 0) => (others => '0'),
      blank     => not venable,
      hsync     => vga_hs,
      vsync     => vga_vs,
      -- outputs to TMDS drivers
      red_s     => red_s,
      green_s   => grn_s,
      blue_s    => blu_s,
      clock_s   => clk_s
   );

	-----------------------------------------------
	-- generate all the system clocks required
	-----------------------------------------------
	inst_pll_base : PLL_BASE
	generic map (
		BANDWIDTH          => "OPTIMIZED", -- "HIGH", "LOW" or "OPTIMIZED"
		COMPENSATION       => "SYSTEM_SYNCHRONOUS", -- "SYSTEM_SYNCHRNOUS", "SOURCE_SYNCHRNOUS", "INTERNAL", "EXTERNAL", "DCM2PLL", "PLL2DCM"
		CLKIN_PERIOD       => 20.00, -- Clock period (ns) of input clock on CLKIN
		DIVCLK_DIVIDE      => 1,     -- Division factor for all clocks (1 to 52)
		CLKFBOUT_MULT      => 12,    -- Multiplication factor for all output clocks (1 to 64)
		CLKFBOUT_PHASE     => 0.0,   -- Phase shift (degrees) of all output clocks
		REF_JITTER         => 0.100, -- Input reference jitter (0.000 to 0.999 UI%)
		-- 120Mhz positive
		CLKOUT0_DIVIDE     => 5,     -- Division factor for CLKOUT2 (1 to 128)
		CLKOUT0_DUTY_CYCLE => 0.5,   -- Duty cycle for CLKOUT2 (0.01 to 0.99)
		CLKOUT0_PHASE      => 0.0,   -- Phase shift (degrees) for CLKOUT2 (0.0 to 360.0)
		-- 120Mhz negative
		CLKOUT1_DIVIDE     => 5,     -- Division factor for CLKOUT3 (1 to 128)
		CLKOUT1_DUTY_CYCLE => 0.5,   -- Duty cycle for CLKOUT3 (0.01 to 0.99)
		CLKOUT1_PHASE      => 180.0, -- Phase shift (degrees) for CLKOUT3 (0.0 to 360.0)
		-- 24Mhz VGA clock
		CLKOUT2_DIVIDE     => 25,    -- Division factor for CLKOUT1 (1 to 128)
		CLKOUT2_DUTY_CYCLE => 0.5,   -- Duty cycle for CLKOUT1 (0.01 to 0.99)
		CLKOUT2_PHASE      => 0.0,   -- Phase shift (degrees) for CLKOUT1 (0.0 to 360.0)
		-- 12Mhz
		CLKOUT3_DIVIDE     => 50,    -- Division factor for CLKOUT0 (1 to 128)
		CLKOUT3_DUTY_CYCLE => 0.5,   -- Duty cycle for CLKOUT0 (0.01 to 0.99)
		CLKOUT3_PHASE      => 0.0,   -- Phase shift (degrees) for CLKOUT0 (0.0 to 360.0)
		-- 7.14MHz (double the YM2151 clock)
		CLKOUT4_DIVIDE     => 84,    -- Division factor for CLKOUT4 (1 to 128)
		CLKOUT4_DUTY_CYCLE => 0.5,   -- Duty cycle for CLKOUT4 (0.01 to 0.99)
		CLKOUT4_PHASE      => 0.0,   -- Phase shift (degrees) for CLKOUT4 (0.0 to 360.0)
		-- 6M
		CLKOUT5_DIVIDE     => 100,   -- Division factor for CLKOUT5 (1 to 128)
		CLKOUT5_DUTY_CYCLE => 0.5,   -- Duty cycle for CLKOUT5 (0.01 to 0.99)
		CLKOUT5_PHASE      => 0.0    -- Phase shift (degrees) for CLKOUT5 (0.0 to 360.0)
	)
	port map (
		CLKFBOUT => clkfb,      -- General output feedback signal
		CLKOUT0  => clkout0,
		CLKOUT1  => clkout1,
		CLKOUT2  => clkout2,
		CLKOUT3  => clkout3,
		CLKOUT4  => clkout4,
		CLKOUT5  => clkout5,
		LOCKED   => pll_locked, -- Active high PLL lock signal
		CLKFBIN  => clkfb,      -- Clock feedback input
		CLKIN    => CLK_50,     -- Clock input
		RST      => I_RESET     -- Asynchronous PLL reset
	);

	bufg_i0 : bufg port map (I => clkout0,   O =>clk120M_p);
	bufg_i1 : bufg port map (I => clkout1,   O =>clk120M_n);
	bufg_i2 : bufg port map (I => clkout2,   O =>clk24M);
	bufg_i3 : bufg port map (I => clkout3,   O =>clk12M);
	bufg_i4 : bufg port map (I => clkdiv(1), O =>clk1M5);
	bufg_i5 : bufg port map (I => I_CLK,     O =>ym3012_clk);

	clk7M1 <= clkout4;
	clk6M  <= clkout5;

	----------------------------------------------
	-- generate delayed reset once DCM is stable
	----------------------------------------------
	p_rst_delay : process(clk24M, pll_locked)
	begin
		if pll_locked = '0' then
			rst_ctr <= (others=>'0');
		elsif rising_edge(clk24M) then
			if rst_ctr < x"80" then
				rst_ctr <= rst_ctr + 1;
			end if;
		end if;
	end process;
	reset <= not rst_ctr(7);

	----------------------------------------------
	-- generate CPU clock
	-- allow clock to run ahead of reset deasserting
	----------------------------------------------
	p_clk : process(clk6M, pll_locked)
	begin
		if (pll_locked = '0') then
			clkdiv <= (others=>'0');
		elsif rising_edge(clk6M) then
			clkdiv <= clkdiv + 1;
		end if;
	end process;

	--------------------------------------------------------------------
	-- this needs to be 3.579545MHz - we get 7.1428M/2=3.5714M
	--------------------------------------------------------------------
	clk3M57  <= clkdiv2(0);
	p_clk3M58 : process(clk7M1, reset)
	begin
		if rising_edge(clk7M1) then
			clkdiv2 <= clkdiv2 + 1;
		end if;
	end process;

	----------------------------------------------
	-- left D/A converter
	----------------------------------------------
	dacl : entity work.dac
	generic map (msbi_g => 9)
	port map (
		clk_i  => clk12M,
		res_i  => reset,
		dac_i  => sum0(15 downto 6),
		dac_o  => pwm_l
	);

	----------------------------------------------
	-- right D/A converter
	----------------------------------------------
	dacr : entity work.dac
	generic map (msbi_g => 9)
	port map (
		clk_i  => clk12M,
		res_i  => reset,
		dac_i  => sum1(15 downto 6),
		dac_o  => pwm_r
	);

	-- bring up the samples pcm level to match the FM
	sum0 <= ym0 + (pcm0 & "000");
	sum1 <= ym1 + (pcm1 & "000");

	----------------------------------------------
	-- sound module
	----------------------------------------------
	dd_snd : entity work.dd_snd
	port map (
		-- two PCM channel outputs
		pcm0    => pcm0,
		pcm1    => pcm1,
		-- two FM channel outputs
		ym0     => ym0,
		ym1     => ym1,

		-- YM2151 chip connections
		ym_ic   => ym_ic_int,
		ym_a0   => ym_a0_int,
		ym_wr   => ym_wr_int,
		ym_rd   => ym_rd_int,
		ym_cs   => ym_cs_int,
		ym_irq  => ym_irq_int,
		ym_dbi  => ym_dbi_int,
		ym_dbo  => ym_dbo_int,
		ym_sclk => ym3012_clk,
		ym_sd   => I_SD,
		ym_sam1 => I_S1,
		ym_sam2 => I_S2,

		reset  => reset,		-- active high reset
		hclk   => clk1M5,		-- CPU clock 1.5MHz
		yclk  => clk3M57,		-- FM synth clock (3.579545MHz)
		db    => key_val,		-- sound to play
		wr_n  => key_strobe	-- latch sound value on rising edge
	);

	----------------------------------------------
	-- video for debugging
	----------------------------------------------
	u_hexy : entity work.hexy
	generic map (
		yOffset => 320,
		xOffset => 240
	)
	port map (
		clk			=> clk24M,
		vSync			=> vga_vs,
		hSync			=> vga_hs,
		vPos			=> vCount,
		hPos			=> hCount,
		video			=> video,
		dim			=> open,
		val         => key_val
	);

	u_vga : entity work.vga_sync
	generic map (
		hA =>  16,
		hB =>  96,
		hC =>  48,
		hD => 640,
		hS => '0',
		vA =>  11,
		vB =>   2,
		vC =>  31,
		vD => 480,
		vS => '0'
	)
	port map (
		i_pixelClock	=> clk24M,
		o_hCount			=> hCount,
		o_vCount			=> vCount,
		o_hSync			=> vga_hs,
		o_vSync			=> vga_vs,
		o_enable			=> venable
	);

	-----------------------------------------------------------------------------
	-- Keyboard - active low buttons
	-----------------------------------------------------------------------------
	kbd_inst : entity work.Keyboard
	port map (
		Reset     => reset,
		Clock     => clk12M,
		PS2Clock  => PS2CLK1,
		PS2Data   => PS2DAT1,
		CodeReady => ps2_codeready,
		ScanCode  => ps2_scancode
	);

-- ScanCode(9)          : 1 = Extended  0 = Regular
-- ScanCode(8)          : 1 = Break     0 = Make
-- ScanCode(7 downto 0) : Key Code

	process
	begin
		wait until rising_edge(clk12M);
		if reset = '1' then
			key_val <= (others=>'0');
		elsif (ps2_codeready = '1') then
			case (ps2_scancode(7 downto 0)) is
				when x"45" => if (ps2_scancode(8) = '0') then key_val <= key_val(3 downto 0) & x"0"; end if; -- 0
				when x"16" => if (ps2_scancode(8) = '0') then key_val <= key_val(3 downto 0) & x"1"; end if; -- 1
				when x"1E" => if (ps2_scancode(8) = '0') then key_val <= key_val(3 downto 0) & x"2"; end if; -- 2
				when x"26" => if (ps2_scancode(8) = '0') then key_val <= key_val(3 downto 0) & x"3"; end if; -- 3
				when x"25" => if (ps2_scancode(8) = '0') then key_val <= key_val(3 downto 0) & x"4"; end if; -- 4
				when x"2E" => if (ps2_scancode(8) = '0') then key_val <= key_val(3 downto 0) & x"5"; end if; -- 5
				when x"36" => if (ps2_scancode(8) = '0') then key_val <= key_val(3 downto 0) & x"6"; end if; -- 6
				when x"3D" => if (ps2_scancode(8) = '0') then key_val <= key_val(3 downto 0) & x"7"; end if; -- 7
				when x"3E" => if (ps2_scancode(8) = '0') then key_val <= key_val(3 downto 0) & x"8"; end if; -- 8
				when x"46" => if (ps2_scancode(8) = '0') then key_val <= key_val(3 downto 0) & x"9"; end if; -- 9
				when x"1C" => if (ps2_scancode(8) = '0') then key_val <= key_val(3 downto 0) & x"A"; end if; -- A
				when x"32" => if (ps2_scancode(8) = '0') then key_val <= key_val(3 downto 0) & x"B"; end if; -- B
				when x"21" => if (ps2_scancode(8) = '0') then key_val <= key_val(3 downto 0) & x"C"; end if; -- C
				when x"23" => if (ps2_scancode(8) = '0') then key_val <= key_val(3 downto 0) & x"D"; end if; -- D
				when x"24" => if (ps2_scancode(8) = '0') then key_val <= key_val(3 downto 0) & x"E"; end if; -- E
				when x"2B" => if (ps2_scancode(8) = '0') then key_val <= key_val(3 downto 0) & x"F"; end if; -- F
				when x"75" => if (ps2_scancode(8) = '0') then key_val <= key_val + 1;                end if; -- up
				when x"72" => if (ps2_scancode(8) = '0') then key_val <= key_val - 1;                end if; -- down
				when x"76" => if (ps2_scancode(8) = '0') then key_val <= x"FF";                      end if; -- ESC
				when x"5A" => key_strobe <= ps2_scancode(8);     -- RET
				when others => null;
			end case;
		end if;
	end process;
end RTL;
