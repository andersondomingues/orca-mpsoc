-- Single por RAM design. 
-- Original design based on the one available in >> 
-- https://www.doulos.com/knowhow/vhdl_designers_guide/models/simple_ram_model/

-- This file is part of project ORCA. More information on the project
-- can be found at ORCA's repository at GitHub >>
-- http://https://github.com/andersondomingues/orca-mpsoc
 
-- Copyright (C) 2018-2020 Anderson Domingues, <ti.andersondomingues@gmail.com>

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
-- 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA. **/

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.Numeric_Std.all;

entity ram is
	port(
	    clk :       in std_logic;
	    addr_i:		in std_logic_vector(31 downto 0);
        data_o:     out std_logic_vector(31 downto 0);
        data_i:     in std_logic_vector(31 downto 0);
        data_w_i:   in std_logic_vector(3 downto 0)
    );
end ram; --entity ram     

architecture generic_ram of ram is
   --type ram_type is array (0 to (2 ** addr_i'length) -1) of std_logic_vector(data_i'range);
	type ram_type is array (0 to (2 ** 8) -1) of std_logic_vector(data_i'range);
   signal ram : ram_type;
   signal c_read: std_logic_vector(addr_i'range);
begin

    ram_process: process(clk) is
    
    begin
      if rising_edge(clk) then
        if data_w_i = "1" then
          ram(to_integer(unsigned(addr_i))) <= data_i;
        end if;
        c_read <= addr_i;
      end if;
    end process ram_process;

    data_o <= ram(to_integer(unsigned(c_read)));
    
end generic_ram;