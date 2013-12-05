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

begin
	-- dummy assignments for now
	ym0  <= (others => '0');
	ym1  <= (others => '0');
	pcm0 <= (others => '0');
	pcm1 <= (others => '0');
end RTL;
