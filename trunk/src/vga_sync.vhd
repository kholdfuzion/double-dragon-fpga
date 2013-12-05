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
--
-- General purpose VGA signal generator
--
--	Horizonal Timing
-- _____________              ______________________              ______________________
-- ENABLE       |____________|         ENABLE       |____________|         ENABLE
-- _____________              ______________________              _____________________
-- VIDEO (last) |____________|         VIDEO        |____________|         VIDEO (next)
-- -hD----------|-hA-|  |-hC-|----------hD----------|-hA-|  |-hC-|----------hD---------
-- __________________|  |________________________________|  |__________________________
-- SYNC              |__|              SYNC              |__|              SYNC
--                   |hB|                                |hB|
-- -hE---------------|------------------hE---------------|------------------hE---------
--
-- Vertical Timing
-- _____________              ______________________              ______________________
-- ENABLE||||||||____________||||||||||ENABLE||||||||____________||||||||||ENABLE|||||||
-- _____________              ______________________              _____________________
-- VIDEO (last)||____________||||||||||VIDEO|||||||||____________||||||||||VIDEO (next)
-- -vD----------|-vA-|  |-vC-|----------vD----------|-vA-|  |-vC-|----------vD---------
-- __________________|  |________________________________|  |__________________________
-- SYNC              |__|              SYNC              |__|              SYNC
--                   |vB|                                |vB|
-- -vE---------------|------------------vE---------------|------------------vE---------

-- Timing parameters for some popular resolutions

--	Resolution - Frame | Pixel      | Front     | Sync       | Back       | Active      | H Sync   | Front    | Sync     | Back     | Active    | V Sync
--            - Rate  | Clock      | Porch hA  | Pulse hB   | Porch hC   | Video hD    | Polarity | Porch vA | Pulse vB | Porch vC | Video vD  | Polarity
---------------------------------------------------------------------------------------------------------------------------------------------------------
--  640x480   - 60Hz  | 25.175 MHz | 16 pixels |  96 pixels |  48 pixels |  640 pixels | negative | 11 lines | 2 lines  | 31 lines | 480 lines | negative
--  640x480   - 72Hz  | 31.500 MHz | 24 pixels |  40 pixels | 128 pixels |  640 pixels | negative |  9 lines | 3 lines  | 28 lines | 480 lines | negative
--  640x480   - 75Hz  | 31.500 MHz | 16 pixels |  96 pixels |  48 pixels |  640 pixels | negative | 11 lines | 2 lines  | 32 lines | 480 lines | negative
--  640x480   - 85Hz  | 36.000 MHz | 32 pixels |  48 pixels | 112 pixels |  640 pixels | negative |  1 lines | 3 lines  | 25 lines | 480 lines | negative
---------------------------------------------------------------------------------------------------------------------------------------------------------
--  800x600   - 56Hz  | 38.100 MHz | 32 pixels | 128 pixels | 128 pixels |  800 pixels | positive |  1 lines | 4 lines  | 14 lines | 600 lines | positive
--  800x600   - 60Hz  | 40.000 MHz | 40 pixels | 128 pixels |  88 pixels |  800 pixels | positive |  1 lines | 4 lines  | 23 lines | 600 lines | positive
--  800x600   - 72Hz  | 50.000 MHz | 56 pixels | 120 pixels |  64 pixels |  800 pixels | positive | 37 lines | 6 lines  | 23 lines | 600 lines | positive
--  800x600   - 75Hz  | 49.500 MHz | 16 pixels |  80 pixels | 160 pixels |  800 pixels | positive |  1 lines | 2 lines  | 21 lines | 600 lines | positive
--  800x600   - 85Hz  | 56.250 MHz | 32 pixels |  64 pixels | 152 pixels |  800 pixels | positive |  1 lines | 3 lines  | 27 lines | 600 lines | positive
---------------------------------------------------------------------------------------------------------------------------------------------------------
-- 1024x768   - 60Hz  | 65.000 MHz | 24 pixels | 136 pixels | 160 pixels | 1024 pixels | negative |  3 lines | 6 lines  | 29 lines | 768 lines | negative
-- 1024x768   - 70Hz  | 75.000 MHz | 24 pixels | 136 pixels | 144 pixels | 1024 pixels | negative |  3 lines | 6 lines  | 29 lines | 768 lines | negative
-- 1024x768   - 75Hz  | 78.750 MHz | 16 pixels |  96 pixels | 176 pixels | 1024 pixels | positive |  1 lines | 3 lines  | 28 lines | 768 lines | positive
-- 1024x768   - 85Hz  | 94.500 MHz | 48 pixels |  96 pixels | 208 pixels | 1024 pixels | positive |  1 lines | 3 lines  | 36 lines | 768 lines | positive
---------------------------------------------------------------------------------------------------------------------------------------------------------
library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_unsigned.all;

entity vga_sync is
	generic (
		hA  : natural   :=  16;	-- horizontal front porch
		hB  : natural   :=  96;	-- horizontal sync pulse
		hC  : natural   :=  48;	-- horizontal back porch
		hD  : natural   := 640;	-- horizontal resolution
		hS  : std_logic := '0';	-- horizontal sync active, 0=negative, 1=positive

		vA  : natural   :=  11;	-- vertical front porch
		vB  : natural   :=   2;	-- vertical sync pulse
		vC  : natural   :=  31;	-- vertical back porch
		vD  : natural   := 480;	-- vertical resolution
		vS  : std_logic := '0'	-- vertical sync active, 0=negative, 1=positive
	);

	port (
		i_pixelClock : in  std_logic;
		o_hCount     : out std_logic_vector (11 downto 0);
		o_vCount     : out std_logic_vector (11 downto 0);
		o_hSync      : out std_logic;
		o_vSync      : out std_logic;
		o_enable     : out std_logic
	);
end vga_sync;

architecture rtl of vga_sync is
	signal hCount : std_logic_vector(11 downto 0) := (others=>'0');
	signal vCount : std_logic_vector(11 downto 0) := (others=>'0');
begin
	o_hCount <= hCount;
	o_vCount <= vCount;

	process
	begin
		wait until rising_edge(i_pixelClock);
		-- set default inactive states
		o_hSync  <= not hS;
		o_vSync  <= not vS;
		o_enable <= '0';

		-- counter control
		if hCount = (hA+hB)+(hC+hD) then
			hCount <= (others => '0');
			if vCount = (vA+vB)+(vC+vD) then
				vCount <= (others => '0');
			else
				vCount <= vCount+1;
			end if;
		else
			hCount <= hCount+1;
		end if;

		-- enable indicates when active video is being displayed
		if (hCount >= (hB+hC) and hCount <= (hB+hC)+hD) and (vCount >= (vB+vC) and vCount <= (vB+vC)+vD ) then
			o_enable <= '1';
		end if;

		-- horizontal sync pulse
		if hCount < hB then
			o_hSync <= hS;
		end if;

		-- vertical sync pulse
		if vCount < vB then
			o_vSync <= vS;
		end if;
	end process;
end rtl;
