--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   2013-12-01 19:22:05
-- Design Name:   
-- Module Name:   papilio_pro_top_tb.vhd
-- Project Name:  papilio_pro_top
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: PAPILIO_TOP
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
--	use ieee.numeric_std.all;
	use ieee.std_logic_textio.all;

entity papilio_pro_top_tb is
end papilio_pro_top_tb;
 
architecture behavior of papilio_pro_top_tb is 

	--Inputs
	signal I_RESET   : std_logic := '1';
	signal CLK_IN    : std_logic := '0';

	--BiDirs
	signal SRAM_D    : std_logic_vector(15 downto 0) := (others=>'0');
	signal PS2CLK1   : std_logic := '1';
	signal PS2DAT1   : std_logic := '1';

	--Outputs
	signal O_LED     : std_logic_vector( 3 downto 0) := (others=>'0');
	signal O_VIDEO_R : std_logic_vector( 3 downto 0) := (others=>'0');
	signal O_VIDEO_G : std_logic_vector( 3 downto 0) := (others=>'0');
	signal O_VIDEO_B : std_logic_vector( 3 downto 0) := (others=>'0');
	signal O_HSYNC   : std_logic := '0';
	signal O_VSYNC   : std_logic := '0';
	signal O_AUDIO_L : std_logic := '0';
	signal O_AUDIO_R : std_logic := '0';

	-- 50MHz clock timings
	constant CLK_IN_frequency : integer := 50000000; -- Hertz
	constant CLK_IN_period : TIME := 1000 ms / CLK_IN_frequency;

	-- PS2 keyboard timings
	constant PS2CLK1_frequency : integer := 250000; -- Hertz
	constant PS2CLK1_period : time := 1000 ms / PS2CLK1_frequency;

begin
 
	-- Instantiate the Unit Under Test (UUT)
	uut: entity work.PAPILIO_TOP
	port map (
		I_RESET   => I_RESET,
		O_LED     => O_LED,
		O_VIDEO_R => O_VIDEO_R,
		O_VIDEO_G => O_VIDEO_G,
		O_VIDEO_B => O_VIDEO_B,
		O_HSYNC   => O_HSYNC,
		O_VSYNC   => O_VSYNC,
		O_AUDIO_L => O_AUDIO_L,
		O_AUDIO_R => O_AUDIO_R,
		PS2CLK1   => PS2CLK1,
		PS2DAT1   => PS2DAT1,
		CLK_IN    => CLK_IN
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
		variable char		: std_logic_vector(7 downto 0);
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
