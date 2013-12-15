library ieee;
	use ieee.std_logic_1164.ALL;
	use ieee.numeric_std.ALL;

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
-- Yamaha YM3012 - 2-Channel Serial Input Floating DAC
--
--	The YM3012 DAC-MS (hereinafter referred to as DAC) is a floating D/A converter
-- with serial input for two channels. It can generate analog output (dynamic
-- range 16 bits) of 10-bit mantissa section and 3-bit exponent section on the
-- basis of input digital signal.
--
--			+---------+
--	VDD   | 1  U 16 | AGND
--	PHI0  | 2    15 | RA
--	DGND  | 3    14 | BC
--	SDATA | 4    13 | MP
--	SAM2  | 5    12 | BUFF
--	SAM1  | 6    11 | COM
--	/ICL  | 7    10 | CH2
--	AGND  | 8     9 | CH1
--			+---------+
--------------------------------------------------------------------------------
-- Vout = 1/2Vdd + 1/4Vdd(-1 + D9/1 + D8/2 + D7/4 + D6/8 + D5/16 + D4/32 + D3/64 + D2/128 + D1/256 + D0/512 + 1/1024) / 2**N
-- N = /S2*4 + /S1*2 + /S0 where S2=S1=S0=0 is not allowed

--       _                                                                         _______________________
-- SAM1   |_______________________________________________________________________|                       |__
--                                 _______________________                                                                                 _
-- SAM2  _________________________|                       |__________________________________________________
--       _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   
-- PHI0   |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_|
--         <---------------    channel 1   ---------------><---------------    channel 2   --------------->
-- SDATA   X  X  X  D0 D1 D2 D3 D4 D5 D6 D7 D8 D9 S0 S1 S2 X  X  X  D0 D1 D2 D3 D4 D5 D6 D7 D8 D9 S0 S1 S2

entity YM3012 is
port (
	PHI0    : in  std_logic; -- clock
	ICL     : in  std_logic; -- reset
	SDATA   : in  std_logic; -- serial data
	SAM1    : in  std_logic; -- ch1 sample select
	SAM2    : in  std_logic; -- ch2 sample select

	CH1     : out std_logic_vector(15 downto 0);
	CH2     : out std_logic_vector(15 downto 0)
);
end entity;

architecture RTL of YM3012 is
begin
	-- this chip not implemented yet! Output zero level
	CH1 <= (others=>'0');
	CH2 <= (others=>'0');
end architecture;
