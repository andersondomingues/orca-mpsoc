-- NI (sender) testbench. 

-- This file is part of project ORCA. More information on the project
-- can be found at ORCA's repository at GitHub >>
-- http://https://github.com/andersondomingues/orca-mpsoc
 
-- Copyright (C) 2020 Anderson Domingues, <ti.andersondomingues@gmail.com>

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

entity ni_tb is 
  generic (
    RAM_WIDTH  : natural := 32; --width of main memory word
    FLIT_WIDTH : natural := 32;  --width of router word
    
    -- 1073741824_10 corresponds to 40000000_16
    PRELOAD_ADDR : natural := 1073741824 --preload at memory base addr
  );
end ni_tb;

architecture ni_tb of ni_tb is
    
  procedure clk_gen(signal clk : out std_logic; constant f: real) is
    constant PERIOD    : time := 1 sec / f;  
    constant HIGH_TIME : time := PERIOD / 2; 
    constant LOW_TIME  : time := PERIOD - HIGH_TIME;
  begin
    assert (HIGH_TIME /= 0 fs) 
    	report "clk_plain: High time is zero; time resolution to large for frequency" 
    	severity FAILURE;
    loop
      clk <= '1';
      wait for HIGH_TIME;
      clk <= '0';
      wait for LOW_TIME;
    end loop;
  end procedure;
    
  signal clock : std_logic := '1';
  signal reset : std_logic := '0';
    
  signal stall : std_logic := '0';

  signal m_addr_o : std_logic_vector((RAM_WIDTH - 1) downto 0);
  signal m_data_o : std_logic_vector((RAM_WIDTH - 1) downto 0);
  signal m_wb_o   : std_logic_vector(3 downto 0);

  signal b_addr_o : std_logic_vector((RAM_WIDTH - 1) downto 0);
  signal b_data_i : std_logic_vector((RAM_WIDTH - 1) downto 0) := (others => '0');
  signal b_data_o : std_logic_vector((RAM_WIDTH - 1) downto 0);
  signal b_wb_o   : std_logic_vector(3 downto 0);

  signal r_clock_rx : std_logic := '0';
  signal r_rx       : std_logic;
  signal r_data_i   : std_logic_vector((FLIT_WIDTH -1) downto 0) := (others => '0');
  signal r_credit_o : std_logic;
 
  signal recv_start   : std_logic;
  signal recv_status  : std_logic_vector(31 downto 0);
  signal prog_address : std_logic_vector(31 downto 0);
  signal prog_size    : std_logic_vector(31 downto 0);

begin
	--sender mod binding
	ni_recv_mod: entity work.orca_ni_recv
		generic map (	
			RAM_WIDTH => RAM_WIDTH,
			FLIT_WIDTH => FLIT_WIDTH,
			PRELOAD_ADDR => PRELOAD_ADDR
		)
		port map(
			clk  => clock,
			rst  => reset,
			stall => stall,
			
			m_data_o => m_data_o, --main mem. i/f
			m_addr_o => m_addr_o,
			m_wb_o => m_wb_o,
			
			b_addr_o => b_addr_o, --buf i/f
			b_data_i => b_data_i,
			b_data_o => b_data_o,
			b_wb_o   => b_wb_o,
			
			r_credit_o => r_credit_o, --router i/f
			r_rx => r_rx,
			r_data_i => r_data_i,
			r_clock_rx => r_clock_rx,
			
			recv_start  => recv_start, --programming
			recv_status => recv_status,
			prog_address => prog_address,
			prog_size => prog_size
		);

	--initial reset
	reset <= '0', '1' after 10 ns, '0' after 20 ns;

	-- clock generation
	clk_gen(clock, 166.667E6);  -- 166.667 MHz clock
	clk_gen(r_clock_rx, 100.000E6);  -- 166.667 MHz clock
	
	--perform some tests
	recv_start <= '0', '1' after 250 ns, '0' after 400 ns;

	-- fix values for memory access
	prog_address <= x"40001000";
	prog_size <= x"0000000A"; -- 10 dec
	
	-- generate arbitrary values at router output
	router_seq_proc : process(r_clock_rx)
	begin
		r_rx <= '1';
		r_data_i <= r_data_i + 1;
	end process;
	
	mem_output_proc : process(clock)
	begin
		b_data_i <= b_data_i + 1;
	end process;


end ni_tb;


