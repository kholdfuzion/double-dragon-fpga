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


library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_unsigned.all;

entity dd_snd is
	port(
		pcm0		: out	std_logic_vector(11 downto 0);	-- samples output 1 from IC80
		pcm1		: out	std_logic_vector(11 downto 0);	-- samples output 2 from IC81
		ym0		: out	std_logic_vector( 9 downto 0);	-- left  channel from IC82
		ym1		: out	std_logic_vector( 9 downto 0);	-- right channel from IC82

		db			: in	std_logic_vector( 7 downto 0);	-- data bus
		reset		: in	std_logic;								-- active high reset
		hclk		: in	std_logic;								-- cpu clock 1.5MHz
		yclk		: in	std_logic;								-- YM clock 3.579545MHz
		wr_n		: in	std_logic								-- active low write
	);
end dd_snd;

architecture RTL of dd_snd is

	signal last_wr_n			: std_logic := '0';

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
	signal ym_do				: std_logic_vector( 7 downto 0) := (others => '0');

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
	-- dummy assignments for now
	ym0  <= (others => '0');
	ym1  <= (others => '0');
	pcm0 <= (others => '0');
	pcm1 <= (others => '0');

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
		ym_do   when ic79_dec5 = '1' and mpu_rd = '1' else
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

	ROM0 : entity work.ROM_21J00
	port map (
		CLK  => hclk_n,
		ENA  => rom0_ena,
		ADDR => mpu_addr(13 downto 0),
		DATA => rom0_do
	);

	ROM1 : entity work.ROM_21J01
	port map (
		CLK  => hclk_n,
		ENA  => rom1_ena,
		ADDR => mpu_addr(13 downto 0),
		DATA => rom1_do
	);

	RAM : entity work.ram_2048_8
	port map (
		clk  => hclk_n,
		we   => mpu_wr,
		cs   => ic79_dec0,
		addr => mpu_addr(10 downto 0),
		di   => mpu_do,
		do   => ram_do
	);
end RTL;
