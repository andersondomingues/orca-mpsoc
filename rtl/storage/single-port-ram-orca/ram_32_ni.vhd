-- RAM with single port. 
-- Original design based on the one available in >> 
--  Recommended way to describe Byte Write Enable RAMs
--  source: UG901, Section RAM HDL Coding Guidelines

-- This file is part of project ORCA. More information on the project
-- can be found at ORCA's repository at GitHub >>
-- http://https://github.com/andersondomingues/orca-mpsoc
 
-- Copyright (C) 2018-2020 Alexandre Amory, <amamory@gmail.com>

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
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.Numeric_Std.all;
use ieee.math_real.log2;
use ieee.math_real.ceil;


entity ram_32_ni is 
    generic (
        RAM_DEPTH_I : natural
    );
    
    port(
        clk    : in  std_logic;
        addr_i : in  std_logic_vector(((INTEGER(CEIL(LOG2(REAL(RAM_DEPTH_I))))) - 1) downto 0);
        data_o : out std_logic_vector(31 downto 0);
        data_i : in  std_logic_vector(31 downto 0);
        cs_n_i : in  std_logic;
        wb_n_i : in  std_logic
    );
end ram_32_ni;

architecture ram_32_ni of ram_32_ni is
    type ram_type is array (0 to RAM_DEPTH_I -1) of std_logic_vector(data_i'range);
    signal ram : ram_type;
    signal c_read : std_logic_vector(addr_i'range);
begin

process(clk)
begin
    if rising_edge(clk) then
        if cs_n_i = '0' then
            data_o <= RAM(conv_integer(addr_i));
            if wb_n_i = '0' then
                RAM(conv_integer(addr_i)) <= data_i;
            end if;
        end if;
    end if;
end process;

end ram_32_ni;


