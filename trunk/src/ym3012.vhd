library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_unsigned.all;

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
-- N = /S2*4 + /S1*2 + /S0*1 where S2=S1=S0=0 is not allowed. Note the negation of S2,S1,S0 !!!

-- Here are some calculated sample values
-- D9......D0 where N can be 0 to 6 (7 not allowed)
-- 0000000000 = -0.9990234375 / 2**N
-- 0011111111 = -0.5009765625 / 2**N
-- 0111111111 = -0.0009765625 / 2**N
-- 1000000000 =  0.0009765625 / 2**N
-- 1011111111 =  0.4990234375 / 2**N
-- 1111111111 =  0.9990234375 / 2**N
-- It is apparent that the sign bit D9 has the opposite effect from the expected traditional interpretation

--       _                                                                         _______________________
-- SAM1   |_______________________________________________________________________|                       |__
--                                 _______________________                                                                                 _
-- SAM2  _________________________|                       |__________________________________________________
--       _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   
-- PHI0   |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_|
--         <---------------    channel 1   ---------------><---------------    channel 2   --------------->
-- SDATA   X  X  X  D0 D1 D2 D3 D4 D5 D6 D7 D8 D9 S0 S1 S2 X  X  X  D0 D1 D2 D3 D4 D5 D6 D7 D8 D9 S0 S1 S2

entity YM3012 is
	generic (signed_data : boolean := true);			-- true  : outputs   signed data in range -32768/32767
																	-- false : outputs unsigned data in range 0..65535
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
	signal CH1_out      : std_logic_vector(15 downto 0) := (others=>'0');
	signal CH2_out      : std_logic_vector(15 downto 0) := (others=>'0');
	signal data_l       : std_logic_vector(15 downto 0) := (others=>'0');
	signal data_r       : std_logic_vector(15 downto 0) := (others=>'0');
	signal exp_l        : std_logic_vector( 2 downto 0) := (others=>'0');
	signal exp_r        : std_logic_vector( 2 downto 0) := (others=>'0');
	signal sreg         : std_logic_vector(12 downto 0) := (others=>'0');
	signal SAM1_last    : std_logic := '0';
	signal SAM2_last    : std_logic := '0';

begin
	-- allow user to select signed or unsigned output
	CH1 <= CH1_out when signed_data else CH1_out + x"8000";
	CH2 <= CH2_out when signed_data else CH2_out + x"8000";

	-- shift in data on rising clock edge
	shift_p : process
	begin
		wait until rising_edge(PHI0);
		sreg <= SDATA & sreg(12 downto 1);
	end process;

	-- right channel
	right_p : process
	begin
		wait until rising_edge(PHI0);
		SAM1_last <= SAM1;

		-- latch data on falling edge of SAM1
		if (SAM1_last and (not SAM1)) = '1' then 
			CH2_out <= data_r;
			exp_r   <= sreg(12 downto 10); -- exponent
			data_r  <= not sreg(9) & sreg(8 downto 0) & "100000"; -- mantissa
		-- else adjust according to (inverted!) exponent
		elsif (exp_r < 7) then
			exp_r <= exp_r + 1;
			-- shift right maintaining sign bit
			data_r(14 downto 0) <= data_r(15 downto 1);
		end if;
	end process;

	-- left channel
	left_p : process
	begin
		wait until rising_edge(PHI0);
		SAM2_last <= SAM2;

		-- latch data on falling edge of SAM2
		if (SAM2_last and (not SAM2)) = '1' then
			CH1_out <= data_l;
			exp_l   <= sreg(12 downto 10); -- exponent
			data_l  <= not sreg(9) & sreg(8 downto 0) & "100000"; -- mantissa
		-- else adjust according to (inverted!) exponent
		elsif (exp_l < 7) then
			exp_l <= exp_l + 1;
			-- shift right maintaining sign bit
			data_l(14 downto 0) <= data_l(15 downto 1);
		end if;
	end process;
end architecture;
