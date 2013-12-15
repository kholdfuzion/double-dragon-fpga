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
--	Double Dragon sound board implementation
--
-- 1x 68A09 CPU 1.5MHz
-- 1x  2KB RAM
-- 1x 32KB ROM
-- 2x 64KB ROM for ADPCM samples
-- 2x MSM5205 ADPCM decoder
-- 1x YM2151 FM synth
-- 1x YM3012 stereo DAC

--	adpcm samples stored in external memory
--	0x00000, 64KB, file "21j-6"
--	0x10000, 64KB, file "21j-7"

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_unsigned.all;

entity dd_snd is
	port(
		pcm0    : out	std_logic_vector(11 downto 0);	-- samples output 1 from IC80
		pcm1    : out	std_logic_vector(11 downto 0);	-- samples output 2 from IC81
		ym0     : out	std_logic_vector(15 downto 0);	-- left  channel from IC82
		ym1     : out	std_logic_vector(15 downto 0);	-- right channel from IC82

		ym_ic   : out std_logic;
		ym_a0   : out std_logic;
		ym_wr   : out std_logic;
		ym_rd   : out std_logic;
		ym_cs   : out std_logic;
		ym_irq  : in  std_logic;
		ym_dbi  : in  std_logic_vector( 7 downto 0);
		ym_dbo  : out std_logic_vector( 7 downto 0);
		ym_sclk : in  std_logic;
		ym_sd   : in  std_logic;
		ym_sam1 : in  std_logic;
		ym_sam2 : in  std_logic;

		db      : in	std_logic_vector( 7 downto 0);	-- data bus
		reset   : in	std_logic;								-- active high reset
		hclk    : in	std_logic;								-- cpu clock 1.5MHz
		yclk    : in	std_logic;								-- YM clock 3.579545MHz
		wr_n    : in	std_logic								-- active low write
	);
end dd_snd;

architecture RTL of dd_snd is
	signal clk375k				: std_logic := '0';

	signal vck0					: std_logic := '0';
	signal vck1					: std_logic := '0';

	signal last_wr_n			: std_logic := '0';

	signal clk_ctr				: std_logic_vector( 1 downto 0) := (others => '0');
	signal snd_val				: std_logic_vector( 7 downto 0) := (others => '0');
	signal mpu_di				: std_logic_vector( 7 downto 0) := (others => '0');
	signal mpu_do				: std_logic_vector( 7 downto 0) := (others => '0');
	signal mpu_addr			: std_logic_vector(15 downto 0) := (others => '0');
	signal mpu_wr				: std_logic := '0';
	signal mpu_rd				: std_logic := '0';
	signal mpu_irq				: std_logic := '0';
	signal mpu_firq			: std_logic := '0';
	signal mpu_reset			: std_logic := '0';

	signal rom0_ena			: std_logic := '0';
	signal rom1_ena			: std_logic := '0';

	signal rst_ctr				: std_logic_vector( 3 downto 0) := (others => '0');
	signal hclk_n				: std_logic := '0';

	signal rom0_do				: std_logic_vector( 7 downto 0) := (others => '0');
	signal rom1_do				: std_logic_vector( 7 downto 0) := (others => '0');
	signal ram_do				: std_logic_vector( 7 downto 0) := (others => '0');

	signal adpd0_di			: std_logic_vector( 3 downto 0) := (others => '0');
	signal adpd1_di			: std_logic_vector( 3 downto 0) := (others => '0');
	signal adpd0_addr			: std_logic_vector(16 downto 0) := (others => '0');
	signal adpd1_addr			: std_logic_vector(16 downto 0) := (others => '0');
	signal ad1rst				: std_logic := '0';
	signal ad2rst				: std_logic := '0';
	signal ad1match			: std_logic := '0';
	signal ad2match			: std_logic := '0';

	signal ADPCM0_ena			: std_logic := '0';
	signal ADPCM1_ena			: std_logic := '0';
	signal ADPCM2_ena			: std_logic := '0';
	signal ADPCM3_ena			: std_logic := '0';
	signal ADPCM4_ena			: std_logic := '0';
	signal ADPCM5_ena			: std_logic := '0';
	signal ADPCM6_ena			: std_logic := '0';
	signal ADPCM7_ena			: std_logic := '0';

	signal ADPCM0_do			: std_logic_vector( 7 downto 0) := (others => '0');
	signal ADPCM1_do			: std_logic_vector( 7 downto 0) := (others => '0');
	signal ADPCM2_do			: std_logic_vector( 7 downto 0) := (others => '0');
	signal ADPCM3_do			: std_logic_vector( 7 downto 0) := (others => '0');
	signal ADPCM4_do			: std_logic_vector( 7 downto 0) := (others => '0');
	signal ADPCM5_do			: std_logic_vector( 7 downto 0) := (others => '0');
	signal ADPCM6_do			: std_logic_vector( 7 downto 0) := (others => '0');
	signal ADPCM7_do			: std_logic_vector( 7 downto 0) := (others => '0');

	signal rom0d				: std_logic_vector( 7 downto 0) := (others => '0');	-- ADPCM ROM0 data
	signal rom1d				: std_logic_vector( 7 downto 0) := (others => '0');	-- ADPCM ROM1 data

	signal ic79_dec0			: std_logic := '0';
--	signal ic79_dec1			: std_logic := '0';
	signal ic79_dec2			: std_logic := '0';
	signal ic79_dec3			: std_logic := '0';
--	signal ic79_dec4			: std_logic := '0';
	signal ic79_dec5			: std_logic := '0';
--	signal ic79_dec6			: std_logic := '0';
	signal ic79_dec7			: std_logic := '0';

	signal s3800w				: std_logic := '0';
	signal s3801w				: std_logic := '0';
	signal s3802w				: std_logic := '0';
	signal s3803w				: std_logic := '0';
	signal s3804w				: std_logic := '0';
	signal s3805w				: std_logic := '0';
	signal s3806w				: std_logic := '0';
	signal s3807w				: std_logic := '0';

begin
	ym_a0    <= mpu_addr(0);
	ym_ic    <= reset;
	ym_wr    <= mpu_wr;
	ym_rd    <= mpu_rd;
	ym_cs    <= ic79_dec5;
	ym_dbo   <= mpu_do;
	mpu_firq <= ym_irq;

	p_mpu_rst : process(hclk, reset)
	begin
		if (reset = '1') then
			rst_ctr <= (others=>'0');
		elsif rising_edge(hclk) then
			if rst_ctr /= x"F" then
				rst_ctr <= rst_ctr + 1;
			end if;
		end if;
	end process;

	-- generate ADPCM clock from mainclock
	p_clk_ctr : process(hclk, reset)
	begin
		if (reset = '1') then
			clk_ctr <= (others=>'0');
		elsif rising_edge(hclk) then
			if clk_ctr /= x"F" then
				clk_ctr <= clk_ctr + 1;
			end if;
		end if;
	end process;

	clk375k <= clk_ctr(1);

	IC80 : entity work.MSM5205
	generic map (signed_data => false)
	port map (
		s1s2		=> "10",			-- sampling freq: LL=4Khz, LH=6Khz, HL=8Khz, HH=prohibited
		s4b3b		=> '1',			-- ADPCM data format, H = 4 bit, L = 3 bit
		di			=> adpd0_di,	-- 4 bit input data
		do			=> pcm0,			-- 12 bit output data
		vck		=> vck0,			-- sampling clk out as selected by s1s2
		reset		=> ad1rst,		-- active high reset
		xt			=> clk375k		-- 384khz clock input
	);

	IC81 : entity work.MSM5205
	generic map (signed_data => false)
	port map (
		s1s2		=> "10",			-- sampling freq: LL=4Khz, LH=6Khz, HL=8Khz, HH=prohibited
		s4b3b		=> '1',			-- ADPCM data format, H = 4 bit, L = 3 bit
		di			=> adpd1_di,	-- 4 bit input data
		do			=> pcm1,			-- 12 bit output data
		vck		=> vck1,			-- sampling clk out as selected by s1s2
		reset		=> ad2rst,		-- active high reset
		xt			=> clk375k		-- 384khz clock input
	);

	-- IC82 serial DAC
	IC82 : entity work.ym3012
	port map (
		PHI0     => ym_sclk,
		ICL      => reset,
		SDATA    => ym_sd,
		SAM1     => ym_sam1,
		SAM2     => ym_sam2,
		CH1      => ym0,
		Ch2      => ym1
	);

	adpd0 : entity work.adpdctr
	port map (
		clk		=> hclk_n,
		vck		=> vck0,			-- 375K clock from MSM5205 IC80
		swd		=> mpu_wr,		-- write enable
		sdb		=> mpu_do,		-- data bus
		addr		=> adpd0_addr,	-- 17 bit address bus to external ROM
		clrctr	=> ad1rst,		-- clear counters
		setctr	=> s3804w,		-- preset counters
		setcmp	=> s3802w,		-- set comparators
		cmpout	=> ad1match		-- comparator output
	);

	adpd1 : entity work.adpdctr
	port map (
		clk		=> hclk_n,
		vck		=> vck1,			-- 375K clock from MSM5205 IC81
		swd		=> mpu_wr,		-- write enable
		sdb		=> mpu_do,		-- data bus
		addr		=> adpd1_addr,	-- 17 bit address bus to external ROM
		clrctr	=> ad2rst,		-- clear counters
		setctr	=> s3805w,		-- preset counters
		setcmp	=> s3803w,		-- set comparators
		cmpout	=> ad2match		-- comparator output
	);

	-- demux 8 bit data to 4 bit
	adpd0_di <= rom0d(3 downto 0) when adpd0_addr(0) = '1' else rom0d(7 downto 4);
	adpd1_di <= rom1d(3 downto 0) when adpd1_addr(0) = '1' else rom1d(7 downto 4);

	-- latch
	process
	begin
		wait until rising_edge(hclk_n);
		if s3800w = '1' then
			ad1rst <= '0';	-- clear
		elsif s3806w = '1' or ad1match ='1' then
			ad1rst <= '1'; -- set
		end if;
	end process;

	-- latch
	process
	begin
		wait until rising_edge(hclk_n);
		if s3801w = '1' then
			ad2rst <= '0';	-- clear
		elsif s3807w = '1' or ad2match ='1' then
			ad2rst <= '1'; -- set
		end if;
	end process;

	rom0_ena   <= '1' when mpu_addr(15 downto 14) = "10" else '0';
	rom1_ena   <= '1' when mpu_addr(15 downto 14) = "11" else '0';

	----------------------------
	-- main address decoder IC79
	----------------------------
	ic79_dec0  <= '1' when mpu_addr(15 downto 11) = "00000" else '0'; -- 0000-07ff
--	ic79_dec1  <= '1' when mpu_addr(15 downto 11) = "00001" else '0'; -- 0800-0fff
	ic79_dec2  <= '1' when mpu_addr(15 downto 11) = "00010" else '0'; -- 1000-17ff
	ic79_dec3  <= '1' when mpu_addr(15 downto 11) = "00011" else '0'; -- 1800-1fff
--	ic79_dec4  <= '1' when mpu_addr(15 downto 11) = "00100" else '0'; -- 2000-27ff
	ic79_dec5  <= '1' when mpu_addr(15 downto 11) = "00101" else '0'; -- 2800-2fff
--	ic79_dec6  <= '1' when mpu_addr(15 downto 11) = "00110" else '0'; -- 3000-37ff
	ic79_dec7  <= '1' when mpu_addr(15 downto 11) = "00111" else '0'; -- 3800-3fff

	----------------------------
	-- aux address decoder IC63
	----------------------------
	s3800w <= '1' when mpu_addr(2 downto 0) = "000" and ic79_dec7 = '1' and mpu_wr = '1' else '0';
	s3801w <= '1' when mpu_addr(2 downto 0) = "001" and ic79_dec7 = '1' and mpu_wr = '1' else '0';
	s3802w <= '1' when mpu_addr(2 downto 0) = "010" and ic79_dec7 = '1' and mpu_wr = '1' else '0';
	s3803w <= '1' when mpu_addr(2 downto 0) = "011" and ic79_dec7 = '1' and mpu_wr = '1' else '0';
	s3804w <= '1' when mpu_addr(2 downto 0) = "100" and ic79_dec7 = '1' and mpu_wr = '1' else '0';
	s3805w <= '1' when mpu_addr(2 downto 0) = "101" and ic79_dec7 = '1' and mpu_wr = '1' else '0';
	s3806w <= '1' when mpu_addr(2 downto 0) = "110" and ic79_dec7 = '1' and mpu_wr = '1' else '0';
	s3807w <= '1' when mpu_addr(2 downto 0) = "111" and ic79_dec7 = '1' and mpu_wr = '1' else '0';

	------------------------
	--	mpu data bus mux
	------------------------
	mpu_di <=
		rom0_do when rom0_ena  = '1' and mpu_rd = '1' else
		rom1_do when rom1_ena  = '1' and mpu_rd = '1' else
		ram_do  when ic79_dec0 = '1' and mpu_rd = '1' else
		snd_val when ic79_dec2 = '1' and mpu_rd = '1' else
		"000000" &
		 ad2rst  &
		 ad1rst when ic79_dec3 = '1' and mpu_rd = '1' else
		ym_dbi  when ic79_dec5 = '1' and mpu_rd = '1' else
		(others=>'0');

	mpu_wr <= not mpu_rd;
	hclk_n <= not hclk;
	mpu_reset <= '0' when (rst_ctr = x"f") else '1';

	-- detect rising edge of the write and trigger IRQ
	-- CPU can clear the IRQ state asynchronously
	process(hclk)
	begin
		if rising_edge(hclk) then
			last_wr_n <= wr_n;
			if ic79_dec2 = '1' then
				mpu_irq <= '0';
			elsif wr_n = '1' and last_wr_n = '0' then -- rising edge
				snd_val <= db;
				mpu_irq <= '1';
			end if;
		end if;
	end process;

	------------------------
	--	CPU, ROM, RAM section
	------------------------
	cpu09 : entity work.cpu09
	port map (
		-- ins
		clk	    => hclk,
		rst       => mpu_reset,
		hold      => '0',      -- active low clock enable
		halt      => '0',      -- not used
		nmi       => '0',      -- not used
		irq       => mpu_irq,  -- from game CPU
		firq      => mpu_firq, -- from YM2151
		data_in   => mpu_di,
		-- outs
		data_out  => mpu_do,
		address   => mpu_addr,
		rw	       => mpu_rd,
		-- unused outputs
		ba        => open,
		bs        => open,
		vma       => open,
		pc_out    => open
	);

	-- CPU 2KB RAM
	RAM : entity work.ram_2048_8
	port map (
		clk  => hclk_n,
		we   => mpu_wr,
		cs   => ic79_dec0,
		addr => mpu_addr(10 downto 0),
		di   => mpu_do,
		do   => ram_do
	);

	-- CPU program ROMs
	ROM0   : entity work.ROM_21J00 port map ( CLK => hclk_n, ENA => rom0_ena, ADDR => mpu_addr(13 downto 0), DATA => rom0_do );
	ROM1   : entity work.ROM_21J01 port map ( CLK => hclk_n, ENA => rom1_ena, ADDR => mpu_addr(13 downto 0), DATA => rom1_do );

	-- ADPCM samles ROMs
	ADPCM0 : entity work.ROM_21J60 port map ( CLK => hclk_n, ENA => ADPCM0_ena, ADDR => adpd0_addr(14 downto 1), DATA => ADPCM0_do );
	ADPCM1 : entity work.ROM_21J61 port map ( CLK => hclk_n, ENA => ADPCM1_ena, ADDR => adpd0_addr(14 downto 1), DATA => ADPCM1_do );
	ADPCM2 : entity work.ROM_21J62 port map ( CLK => hclk_n, ENA => ADPCM2_ena, ADDR => adpd0_addr(14 downto 1), DATA => ADPCM2_do );
	ADPCM3 : entity work.ROM_21J63 port map ( CLK => hclk_n, ENA => ADPCM3_ena, ADDR => adpd0_addr(14 downto 1), DATA => ADPCM3_do );
	ADPCM4 : entity work.ROM_21J70 port map ( CLK => hclk_n, ENA => ADPCM4_ena, ADDR => adpd1_addr(14 downto 1), DATA => ADPCM4_do );
	ADPCM5 : entity work.ROM_21J71 port map ( CLK => hclk_n, ENA => ADPCM5_ena, ADDR => adpd1_addr(14 downto 1), DATA => ADPCM5_do );
	ADPCM6 : entity work.ROM_21J72 port map ( CLK => hclk_n, ENA => ADPCM6_ena, ADDR => adpd1_addr(14 downto 1), DATA => ADPCM6_do );
	ADPCM7 : entity work.ROM_21J73 port map ( CLK => hclk_n, ENA => ADPCM7_ena, ADDR => adpd1_addr(14 downto 1), DATA => ADPCM7_do );

	-- 3 to 8 decoder
	ADPCM0_ena <= '1' when adpd0_addr(16 downto 15) = "00" else '0';
	ADPCM1_ena <= '1' when adpd0_addr(16 downto 15) = "01" else '0';
	ADPCM2_ena <= '1' when adpd0_addr(16 downto 15) = "10" else '0';
	ADPCM3_ena <= '1' when adpd0_addr(16 downto 15) = "11" else '0';
	ADPCM4_ena <= '1' when adpd1_addr(16 downto 15) = "00" else '0';
	ADPCM5_ena <= '1' when adpd1_addr(16 downto 15) = "01" else '0';
	ADPCM6_ena <= '1' when adpd1_addr(16 downto 15) = "10" else '0';
	ADPCM7_ena <= '1' when adpd1_addr(16 downto 15) = "11" else '0';

	-- address muxers
	rom0d <=
		ADPCM0_do when ADPCM0_ena = '1' else
		ADPCM1_do when ADPCM1_ena = '1' else
		ADPCM2_do when ADPCM2_ena = '1' else
		ADPCM3_do when ADPCM3_ena = '1' else
		(others=>'0');

	rom1d <=
		ADPCM4_do when ADPCM4_ena = '1' else
		ADPCM5_do when ADPCM5_ena = '1' else
		ADPCM6_do when ADPCM6_ena = '1' else
		ADPCM7_do when ADPCM7_ena = '1' else
		(others=>'0');
end RTL;
