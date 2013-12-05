library IEEE;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_unsigned.ALL;
use ieee.numeric_std.ALL;

-----------------------------------------------------------------------

entity hexy is
	generic (
		yOffset : integer := 100;
		xOffset : integer := 100
	);
	port (
		clk	: in  std_logic;
		vSync	: in  std_logic;
		hSync	: in  std_logic;
		video	: out std_logic;
		dim	: out std_logic;

		vPos	: in  std_logic_vector(11 downto 0);
		hPos	: in  std_logic_vector(11 downto 0);

		val	: in  std_logic_vector( 7 downto 0)
	);
end entity;

architecture rtl of hexy is
	signal localX     : unsigned( 8 downto 0) := (others=>'0');
	signal localX2    : unsigned( 8 downto 0) := (others=>'0');
	signal localX3    : unsigned( 8 downto 0) := (others=>'0');
	signal localY     : unsigned( 3 downto 0) := (others=>'0');
	signal runY       : std_logic := '0';
	signal runX       : std_logic := '0';

	signal cChar      : unsigned( 5 downto 0) := (others=>'0');
	signal pixels     : unsigned( 0 to 63) := (others=>'0');

	constant char_0   : unsigned( 5 downto 0) :="000000";
	constant char_1   : unsigned( 5 downto 0) :="000001";
	constant char_2   : unsigned( 5 downto 0) :="000010";
	constant char_3   : unsigned( 5 downto 0) :="000011";
	constant char_4   : unsigned( 5 downto 0) :="000100";
	constant char_5   : unsigned( 5 downto 0) :="000101";
	constant char_6   : unsigned( 5 downto 0) :="000110";
	constant char_7   : unsigned( 5 downto 0) :="000111";
	constant char_8   : unsigned( 5 downto 0) :="001000";
	constant char_9   : unsigned( 5 downto 0) :="001001";
	constant char_A   : unsigned( 5 downto 0) :="001010";
	constant char_B   : unsigned( 5 downto 0) :="001011";
	constant char_C   : unsigned( 5 downto 0) :="001100";
	constant char_D   : unsigned( 5 downto 0) :="001101";
	constant char_E   : unsigned( 5 downto 0) :="001110";
	constant char_F   : unsigned( 5 downto 0) :="001111";
	constant char_G   : unsigned( 5 downto 0) :="010000";
	constant char_H   : unsigned( 5 downto 0) :="010001";
	constant char_I   : unsigned( 5 downto 0) :="010010";
	constant char_J   : unsigned( 5 downto 0) :="010011";
	constant char_K   : unsigned( 5 downto 0) :="010100";
	constant char_L   : unsigned( 5 downto 0) :="010101";
	constant char_M   : unsigned( 5 downto 0) :="010110";
	constant char_N   : unsigned( 5 downto 0) :="010111";
	constant char_O   : unsigned( 5 downto 0) :="011000";
	constant char_P   : unsigned( 5 downto 0) :="011001";
	constant char_Q   : unsigned( 5 downto 0) :="011010";
	constant char_R   : unsigned( 5 downto 0) :="011011";
	constant char_S   : unsigned( 5 downto 0) :="011100";
	constant char_T   : unsigned( 5 downto 0) :="011101";
	constant char_U   : unsigned( 5 downto 0) :="011110";
	constant char_V   : unsigned( 5 downto 0) :="011111";
	constant char_W   : unsigned( 5 downto 0) :="100000";
	constant char_X   : unsigned( 5 downto 0) :="100001";
	constant char_Y   : unsigned( 5 downto 0) :="100010";
	constant char_Z   : unsigned( 5 downto 0) :="100011";
	constant char_col : unsigned( 5 downto 0) :="111110";
	constant char_sp  : unsigned( 5 downto 0) :="111111";
begin
	dim <= runX and runY;

	process(clk)
	begin
		if rising_edge(clk) then
			video <= pixels(to_integer(localY & localX3(2 downto 0)));
		end if;
	end process;

	process(clk)
	begin
		if rising_edge(clk) then
			if hPos = xOffset then
				localX <= (others => '0');
				runX <= '1';
				if vPos = yOffset then
					localY <= (others => '0');
					runY <= '1';
				end if;
			elsif runX = '1'
			and localX = "111111111" then
				runX <= '0';
				if localY = "111" then
					runY <= '0';
				else	
					localY <= localY + 1;
				end if;
			else
				localX <= localX + 1;
			end if;
		end if;
	end process;

	process(clk)
	begin
		if rising_edge(clk) then
			localX2 <= localX;
			localX3 <= localX2;
			if (runY = '0')
			or (runX = '0') then
				pixels <= (others => '0');
			else
				case cChar is
				when char_0   => pixels <= X"3C666E7666663C00"; -- 0
				when char_1   => pixels <= X"1818381818187E00"; -- 1
				when char_2   => pixels <= X"3C66060C30607E00"; -- 2
				when char_3   => pixels <= X"3C66061C06663C00"; -- 3
				when char_4   => pixels <= X"060E1E667F060600"; -- 4
				when char_5   => pixels <= X"7E607C0606663C00"; -- 5
				when char_6   => pixels <= X"3C66607C66663C00"; -- 6
				when char_7   => pixels <= X"7E660C1818181800"; -- 7
				when char_8   => pixels <= X"3C66663C66663C00"; -- 8
				when char_9   => pixels <= X"3C66663E06663C00"; -- 9
				when char_A   => pixels <= X"183C667E66666600"; -- A
				when char_B   => pixels <= X"7C66667C66667C00"; -- B
				when char_C   => pixels <= X"3C66606060663C00"; -- C
				when char_D   => pixels <= X"786C6666666C7800"; -- D
				when char_E   => pixels <= X"7E60607860607E00"; -- E
				when char_F   => pixels <= X"7E60607860606000"; -- F
				when char_G   => pixels <= X"3C66606E66663C00"; -- G
				when char_H   => pixels <= X"6666667E66666600"; -- H
				when char_I   => pixels <= X"3C18181818183C00"; -- I
				when char_J   => pixels <= X"1E0C0C0C0C6C3800"; -- J
				when char_K   => pixels <= X"666C7870786C6600"; -- K
				when char_L   => pixels <= X"6060606060607E00"; -- L
				when char_M   => pixels <= X"63777F6B63636300"; -- M
				when char_N   => pixels <= X"66767E7E6E666600"; -- N
				when char_O   => pixels <= X"3C66666666663C00"; -- O
				when char_P   => pixels <= X"7C66667C60606000"; -- P
				when char_Q   => pixels <= X"3C666666663C0E00"; -- Q
				when char_R   => pixels <= X"7C66667C786C6600"; -- R
				when char_S   => pixels <= X"3C66603C06663C00"; -- S
				when char_T   => pixels <= X"7E18181818181800"; -- T
				when char_U   => pixels <= X"6666666666663C00"; -- U
				when char_V   => pixels <= X"66666666663C1800"; -- V
				when char_W   => pixels <= X"6363636B7F776300"; -- W
				when char_X   => pixels <= X"66663C183C666600"; -- X
				when char_Y   => pixels <= X"6666663C18181800"; -- Y
				when char_Z   => pixels <= X"7E060C1830607E00"; -- Z
				when char_col => pixels <= X"0000180000180000"; -- :
				when others   => pixels <= X"0000000000000000"; -- space
				end case;
			end if;
		end if;
	end process;

	process(clk)
	begin
		if rising_edge(clk) then
			case localX(8 downto 3) is
			when "000000" => cChar <= char_sp;  --
			when "000001" => cChar <= char_sp;  --
			when "000010" => cChar <= char_V;   -- V
			when "000011" => cChar <= char_A;   -- A
			when "000100" => cChar <= char_L;   -- L
			when "000101" => cChar <= char_col; -- :
			when "000110" => cChar <= "00" & unsigned(val( 7 downto  4));
			when "000111" => cChar <= "00" & unsigned(val( 3 downto  0));
--			when "001000" => cChar <= 
--			when "001001" => cChar <= 
--			when "001010" => cChar <= 
--			when "001011" => cChar <= 
--			when "001100" => cChar <= 
--			when "001101" => cChar <= 
--			when "001110" => cChar <= 
--			when "001111" => cChar <= 
--			when "010000" => cChar <= 
--			when "010001" => cChar <= 
--			when "010010" => cChar <= 
--			when "010011" => cChar <= 
--			when "010100" => cChar <= 
--			when "010101" => cChar <= 
--			when "010110" => cChar <= 
--			when "010111" => cChar <= 
--			when "011000" => cChar <= 
--			when "011001" => cChar <= 
--			when "011010" => cChar <= 
--			when "011011" => cChar <= 
--			when "011100" => cChar <= 
--			when "011101" => cChar <= 
--			when "011110" => cChar <= 
--			when "011111" => cChar <= 
--			when "100000" => cChar <= 
--			when "100001" => cChar <= 
--			when "100010" => cChar <= 
--			when "100011" => cChar <= 
--			when "100100" => cChar <= 
--			when "100101" => cChar <= 
--			when "100110" => cChar <= 
--			when "100111" => cChar <= 
--			when "101000" => cChar <= 
--			when "101001" => cChar <= 
--			when "101010" => cChar <= 
--			when "101011" => cChar <= 
--			when "101100" => cChar <= 
--			when "101101" => cChar <= 
--			when "101110" => cChar <= 
--			when "101111" => cChar <= 
--			when "110000" => cChar <= 
--			when "110001" => cChar <= 
--			when "110010" => cChar <= 
--			when "110011" => cChar <= 
--			when "110100" => cChar <= 
--			when "110101" => cChar <= 
--			when "110110" => cChar <= 
--			when "110111" => cChar <= 
--			when "111000" => cChar <= 
--			when "111001" => cChar <= 
--			when "111010" => cChar <= 
--			when "111011" => cChar <= 
--			when "111100" => cChar <= 
--			when "111101" => cChar <= 
--			when "111110" => cChar <= 
--			when "111111" => cChar <= 
			when others => cChar <= (others => '1');
			end case;
		end if;
	end process;

end architecture;
