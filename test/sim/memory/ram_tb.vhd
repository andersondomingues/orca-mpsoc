-- Single port RAM testbench. 

-- This file is part of project ORCA. More information on the project
-- can be found at ORCA's repository at GitHub >>
-- http://https://github.com/andersondomingues/orca-mpsoc
 
-- Copyright (C) 2020 Guilherme Heck, <heckgui@gmail.com>

-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; either version 2 of the License, or
-- (at your option) any later version.

-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
-- GNU General Public License for more details.

-- You should have received a copy of the GNU General Public License along
-- with this program; if not, write to the Free Software Foundation, Inc.,
-- 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity ram_tb is 
	generic(
		address_width: integer := 8;
		memory_file : string := "code.txt"
	);
end ram_tb;


architecture ram_tb of ram_tb is
    signal clock   : std_logic := '0';
    signal reset   : std_logic := '0';
    signal counter : std_logic_vector(31 downto 0);
    signal read_ram: std_logic_vector(31 downto 0);
    signal we      : std_logic_vector(3 downto 0);
begin

	process						--25Mhz system clock
	begin
		clock <= not clock;
		wait for 20 ns;
		clock <= not clock;
		wait for 20 ns;
	end process;

	reset <= '0', '1' after 5 ns, '0' after 500 ns;


	process(clock, reset)
	begin
		if reset = '1' then
			counter <= (others => '0');
			we <= "1111";
		elsif clock'event and clock = '1' then
			if we = "0000" then
				counter <= counter + 1;
				we <= "1111";
			else
			we <= '0' & we(3 downto 1);
			end if;
		end if;
	end process;

	memory0lb: entity work.bram
	generic map (	memory_file => memory_file,
					data_width => 8,
					address_width => address_width,
					bank => 0)
	port map(
		clk 	=> clock,
		addr 	=> counter(address_width -1 downto 2),
		cs_n 	=> '0',
		we_n	=> we(0),
		data_i	=> counter(7 downto 0),
		data_o	=> read_ram(7 downto 0)
	);

	memory0ub: entity work.bram
	generic map (	memory_file => memory_file,
					data_width => 8,
					address_width => address_width,
					bank => 1)
	port map(
		clk 	=> clock,
		addr 	=> counter(address_width -1 downto 2),
		cs_n 	=> '0',
		we_n	=> we(1),
		data_i	=> counter(15 downto 8),
		data_o	=> read_ram(15 downto 8)
	);

	memory1lb: entity work.bram
	generic map (	memory_file => memory_file,
					data_width => 8,
					address_width => address_width,
					bank => 2)
	port map(
		clk 	=> clock,
		addr 	=> counter(address_width -1 downto 2),
		cs_n 	=> '0',
		we_n	=> we(2),
		data_i	=> counter(23 downto 16),
		data_o	=> read_ram(23 downto 16)
	);

	memory1ub: entity work.bram
	generic map (	memory_file => memory_file,
					data_width => 8,
					address_width => address_width,
					bank => 3)
	port map(
		clk 	=> clock,
		addr 	=> counter(address_width -1 downto 2),
		cs_n 	=> '0',
		we_n	=> we(3),
		data_i	=> counter(31 downto 24),
		data_o	=> read_ram(31 downto 24)
	);


end ram_tb;


