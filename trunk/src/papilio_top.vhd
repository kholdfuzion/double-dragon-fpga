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
--	Top level targeted for Papilio Plus board, basic h/w specs:
--		Spartan 6 LX9
--		32Mhz xtal oscillator
--		512Kx16 SRAM 10ns access
--		4Mbit serial Flash
--

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_arith.all;
	use ieee.std_logic_unsigned.all;
	use ieee.numeric_std.all;

library unisim;
	use unisim.vcomponents.all;

entity PAPILIO_TOP is
	port(
		I_RESET		: in		std_logic;								-- active high reset

		-- debugging
		O_LED			: out		std_logic_vector(3 downto 0);

		-- VGA monitor output
		O_VIDEO_R	: out		std_logic_vector(3 downto 0);
		O_VIDEO_G	: out		std_logic_vector(3 downto 0);
		O_VIDEO_B	: out		std_logic_vector(3 downto 0);
		O_HSYNC		: out		std_logic;
		O_VSYNC		: out		std_logic;

		-- Sound out
		O_AUDIO_L	: out		std_logic;
		O_AUDIO_R	: out		std_logic;

		-- Active high external buttons
		PS2CLK1		: inout	std_logic;
		PS2DAT1		: inout	std_logic;

		-- 32MHz clock
		CLK_IN		: in		std_logic := '0'						-- System clock 32Mhz

	);
end PAPILIO_TOP;

architecture RTL of PAPILIO_TOP is
	signal ps2_codeready		: std_logic := '1';
	signal ps2_scancode		: std_logic_vector( 9 downto 0) := (others => '0');
	signal key_val				: std_logic_vector( 7 downto 0) := (others => '0');
	signal key_strobe			: std_logic := '1';

	signal vga_r				: std_logic_vector( 3 downto 0) := (others => '0');
	signal vga_g				: std_logic_vector( 3 downto 0) := (others => '0');
	signal vga_b				: std_logic_vector( 3 downto 0) := (others => '0');
	signal vga_hs				: std_logic := '1';
	signal vga_vs				: std_logic := '1';

	signal reset				: std_logic := '1';
	signal dcm_reset			: std_logic := '1';
	signal dcm_locked			: std_logic := '1';
	signal rst_ctr				: std_logic_vector( 7 downto 0) := (others => '0');
	signal hCount				: std_logic_vector(11 downto 0) := (others => '0');
	signal vCount				: std_logic_vector(11 downto 0) := (others => '0');
	signal video				: std_logic := '0';
	signal venable				: std_logic := '0';

	signal clkfb				: std_logic := '0';
	signal clkdiv				: std_logic_vector( 4 downto 0) := (others => '0');

	signal clk48M				: std_logic := '0';
	signal clk12M				: std_logic := '0';
	signal clk1M5				: std_logic := '0';

begin
--	IO pin assignments
	O_VIDEO_R	<= vga_r;
	O_VIDEO_G	<= vga_g;
	O_VIDEO_B	<= vga_b;
	O_HSYNC		<= vga_hs;
	O_VSYNC		<= vga_vs;

	-- just default assignments for now - maybe we'll use these later?
	O_LED			<= (others=>'0');
	O_AUDIO_L	<= '0';
	O_AUDIO_R	<= '0';

	dcm_reset		<= I_RESET;

	vga_g <= video & "100" when venable='1' else (others=>'0');
	vga_r <= video & "100" when venable='1' else (others=>'0');
	vga_b <= video & "100" when venable='1' else (others=>'0');

	----------------------------------------------
	-- clock generator, 48MHz from 32MHz
	----------------------------------------------
	dcm_sp_inst: DCM_SP
	generic map(
		CLKFX_DIVIDE   => 2,
		CLKFX_MULTIPLY => 3,
		CLKIN_PERIOD   => 31.25

	)
	port map (
		CLKIN			=> CLK_IN,
		CLKFB			=> clkfb,
		CLK0			=> clkfb,
		CLKFX			=> clk48M,
		LOCKED		=> dcm_locked,
		RST			=> dcm_reset
	);

	----------------------------------------------
	-- generate delayed reset once DCM is stable
	----------------------------------------------
	p_rst_delay : process(clk48M, dcm_locked)
	begin
		if dcm_locked = '0' then
			rst_ctr <= (others=>'0');
		elsif rising_edge(clk48M) then
			if rst_ctr < x"80" then
				rst_ctr <= rst_ctr + 1;
			end if;
		end if;
	end process;
	reset <= not rst_ctr(7);

	----------------------------------------------
	-- generate misc clocks from 48MHz
	-- allow clock to run ahead of reset deasserting
	----------------------------------------------
	clk12M  <= clkdiv(1);
	clk1M5  <= clkdiv(4);

	p_clk48 : process(clk48M, dcm_locked)
	begin
		if (dcm_locked = '0') then
			clkdiv <= (others=>'0');
		elsif rising_edge(clk48M) then
			clkdiv <= clkdiv + 1;
		end if;
	end process;

	----------------------------------------------
	-- sound module
	----------------------------------------------
	dd_snd : entity work.dd_snd
	port map (
		-- two PCM channel outputs
		pcm0  => open,			-- not implemented
		pcm1  => open,			-- not implemented
		-- two FM channel outputs
		ym0   => open,			-- not implemented
		ym1   => open,			-- not implemented

		-- inputs
		reset => reset,		-- active high reset
		hclk  => clk1M5,		-- CPU clock 1.5MHz
		yclk  => '0',			-- FM synth clock (3.579545MHz)
		db    => key_val,		-- sound to play
		wr_n  => key_strobe	-- latch sound value on rising edge
	);

	----------------------------------------------
	-- video for debugging
	----------------------------------------------
	u_hexy : entity work.hexy
	generic map (
		yOffset => 296,
		xOffset => 376
	)
	port map (
		clk			=> clk48M,
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
		hB =>  80,
		hC => 160,
		hD => 800,
		hS => '1',
		vA =>   1,
		vB =>   2,
		vC =>  21,
		vD => 600,
		vS => '1'
	)
	port map (
		i_pixelClock	=> clk48M,
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
