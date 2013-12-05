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

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_unsigned.all;
	use ieee.numeric_std.all;

library UNISIM;
	use UNISIM.Vcomponents.all;

entity ram_2048_8 is
	port (
		clk  : in  std_logic;
		we   : in  std_logic;
		cs   : in  std_logic;
		addr : in  std_logic_vector(10 downto 0);
		di   : in  std_logic_vector( 7 downto 0);
		do   : out std_logic_vector( 7 downto 0)
	);
end;

architecture RTL of ram_2048_8 is
begin

	ram2k : component RAMB16_S9
	port map (
		clk  => clk,
		en   => cs,
		ssr  => '0',
		we   => we,
		addr => addr,
		do   => do,
		dop  => open,
		di   => di,
		dip  => "0"
	);
end architecture RTL;
