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
	use ieee.std_logic_1164.ALL;
	use ieee.std_logic_unsigned.all;
	use ieee.numeric_std.ALL;

library unisim;
	use unisim.vcomponents.all;

entity adpdctr is
	port (
		clk	    : in  std_logic;                     -- 1.5M clock for use in synchronous logic
		vck	    : in  std_logic;                     -- 375K clock from MSM5205 IC80
		swd       : in  std_logic;                     -- write enable
		sdb       : in  std_logic_vector( 7 downto 0); -- data bus
		addr      : out std_logic_vector(16 downto 0); -- 17 bit address bus to external ROM
		clrctr    : in  std_logic;                     -- clear counters
		setctr    : in  std_logic;                     -- preset counters
		setcmp    : in  std_logic;                     -- set comparators
		cmpout    : out std_logic                      -- comparator output
	);
end adpdctr;

architecture RTL of adpdctr is
	signal counter     : std_logic_vector(17 downto 0) := (others=>'0');
	signal comp        : std_logic_vector( 7 downto 0) := (others=>'0');
	signal setctr_last : std_logic := '0';
	signal setcmp_last : std_logic := '0';
	signal vck_last    : std_logic := '0';

begin
	addr   <= counter(16 downto 0);
	cmpout <= '1' when comp = counter(17 downto 10) else '0';

	-- for edge detection
	process
	begin
		wait until rising_edge(clk);
		setcmp_last <= setcmp;
		setctr_last <= setctr;
		vck_last    <= vck;
	end process;

	process
	begin
		wait until rising_edge(clk);
		-- latch value on rising edge
		if setcmp_last = '0' and setcmp = '1' then
			comp <= sdb;
		end if;
	end process;

	process
	begin
		wait until rising_edge(clk);
		-- latch value on rising edge
		if (setctr_last = '0' and setctr = '1' and swd = '1') then
			counter(17 downto 10) <= sdb;
		-- not edge sensitive
		elsif clrctr = '1' then
			counter( 9 downto  0) <= (others=>'0');
		-- on falling edge
		elsif vck_last = '1' and vck = '0' then
			counter <= counter + 1;
		end if;
	end process;
end RTL;
