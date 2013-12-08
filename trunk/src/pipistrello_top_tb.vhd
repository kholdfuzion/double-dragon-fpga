--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   2013-12-09 10:08:42
-- Design Name:   
-- Module Name:   pipistrello_top_tb.vhd
-- Project Name:  pipistrello_top
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: PIPISTRELLO_TOP
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: This testbench has been automatically generated
--------------------------------------------------------------------------------
library std;
	use std.textio.all;

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_arith.all;
	use ieee.std_logic_unsigned.all;
	--	use ieee.numeric_std.all;
	use ieee.std_logic_textio.all;

entity pipistrello_top_tb is
end pipistrello_top_tb;

architecture behavior of pipistrello_top_tb is 

	--Inputs
	signal I_RESET : std_logic := '0';
	signal CLK_IN : std_logic := '0';

	--BiDirs
	signal PS2CLK1 : std_logic;
	signal PS2DAT1 : std_logic;

	--Outputs
	signal TMDS_P : std_logic_vector(3 downto 0);
	signal TMDS_N : std_logic_vector(3 downto 0);
	signal O_AUDIO_L : std_logic;
	signal O_AUDIO_R : std_logic;

	-- 50MHz clock timings
	constant CLK_IN_frequency : integer := 50000000; -- Hertz
	constant CLK_IN_period : TIME := 1000 ms / CLK_IN_frequency;

	-- PS2 keyboard timings
	constant PS2CLK1_frequency : integer := 250000; -- Hertz
	constant PS2CLK1_period : time := 1000 ms / PS2CLK1_frequency;

begin

	-- Instantiate the Unit Under Test (UUT)
	uut: entity work.PIPISTRELLO_TOP port map (
		I_RESET   => I_RESET,
		TMDS_P    => TMDS_P,
		TMDS_N    => TMDS_N,
		O_AUDIO_L => O_AUDIO_L,
		O_AUDIO_R => O_AUDIO_R,
		PS2CLK1   => PS2CLK1,
		PS2DAT1   => PS2DAT1,
		CLK_50    => CLK_IN
	);


	-- Clock process definitions
	CLK_IN_process :process
	begin
		CLK_IN <= '0';
		wait for CLK_IN_period/2;
		CLK_IN <= '1';
		wait for CLK_IN_period/2;
	end process;
 
	-- Stimulus process
	stim_proc: process
	begin
		I_RESET <= '1';
		wait for CLK_IN_period*8;
		I_RESET <= '0';
		wait;
	end process;

	tb_keyboard : process
		file file_in 		: text open read_mode is "..\src\keypress.txt";
		variable line_in	: line;
		variable cmd		: character;
		variable delay		: time;
		variable parity	: std_logic;
		variable char		: std_logic_vector( 7 downto 0);
		variable ps2tx		: std_logic_vector(10 downto 0);
	begin

		loop                                   
			readline(file_in, line_in);           
			read(line_in, cmd);

			case cmd is

				-- Wait
				when 'W' =>
					read(line_in, delay);
					PS2CLK1 <= '1';
					PS2DAT1 <= '1';
					wait for delay;

				-- Key
				when 'K' =>
					hread(line_in, char);
					parity := not (char(7) xor char(6) xor char(5) xor char(4) xor char(3) xor char(2) xor char(1) xor char(0));
					ps2tx := "1" & parity & char & "0"; -- stop_bit + parity + byte + start_bit

					for i in 0 to 10 loop
						PS2DAT1 <= ps2tx(i);	-- LSB to MSB
						wait for PS2CLK1_period/2;
						PS2CLK1 <= '0';
						wait for PS2CLK1_period;
						PS2CLK1 <= '1';
						wait for PS2CLK1_period/2;
					end loop;

				-- End
				when 'E' =>
					PS2CLK1 <= '1';
					PS2DAT1 <= 'Z';
					wait;

				when others => null;

			end case;
		end loop;

	end process;
end;
