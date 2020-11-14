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
    BUFFER_DEPTH : natural := 32;
  );
end ni_tb;

architecture ni_tb of ni_tb is
    
  procedure clk_gen(signal clk : out std_logic; constant f: real) is
    constant PERIOD    : time := 1 sec / f;  
    constant HIGH_TIME : time := PERIOD / 2; 
    constant LOW_TIME  : time := PERIOD - HIGH_TIME;
  begin
    assert (HIGH_TIME /= 0 fs) report "clk_plain: High time is zero; time resolution to large for frequency" severity FAILURE;
    loop
      clk <= '1';
      wait for HIGH_TIME;
      clk <= '0';
      wait for LOW_TIME;
    end loop;
  end procedure;
    
  signal clock : std_logic := '1';
  signal reset : std_logic := '0';
  signal intr  : std_logic := '0';
  signal stall : std_logic := '0';
    
  --mem
  signal m_data_i : std_logic_vector((RAM_WIDTH - 1) downto 0) := (others => '0');
  signal m_addr_o : std_logic_vector((RAM_WIDTH - 1) downto 0);
  signal m_wb_o   : std_logic_vector(3 downto 0);
  signal m_data_o : std_logic_vector((RAM_WIDTH - 1) downto 0) := (others => '0');
    
  --router
  signal r_clock_tx  : std_logic; 
  signal r_tx        : std_logic;
  signal r_data_o    : std_logic_vector(FLIT_WIDTH-1 downto 0);
  signal r_credit_i  : std_logic;
  
  signal r_clock_rx  : std_logic; 
  signal r_rx        : std_logic;
  signal r_data_i    : std_logic_vector(FLIT_WIDTH-1 downto 0);
  signal r_credit_o  : std_logic;

  --programming
  signal send_start  : std_logic;
  signal recv_start  : std_logic;
  signal send_status : std_logic_vector(31 downto 0);
  signal recv_status : std_logic_vector(31 downto 0);
  signal prog_address: std_logic_vector(31 downto 0);
  signal prog_size   : std_logic_vector(31 downto 0)

begin
  --sender mod binding
  ni_top_mod: entity work.orca_ni_top
    generic map (
      RAM_WIDTH => RAM_WIDTH,
      FLIT_WIDTH => FLIT_WIDTH,
      BUFFER_SIZE => BUFFER_SIZE
    )
    port map(
      clk : in std_logic;
      rst : in std_logic;
      intr  : out std_logic;    -- load next packet into main memory
      stall : out std_logic; -- holds the cpu and takes control on memory i/f

      -- interface to the memory mux
      m_addr_o : out std_logic_vector((RAM_WIDTH - 1) downto 0);
      m_data_i :  in std_logic_vector((RAM_WIDTH - 1) downto 0);
      m_data_o : out std_logic_vector((RAM_WIDTH - 1) downto 0);
      m_wb_o   : out std_logic_vector(3 downto 0);

      -- interface with the receiving buffer (no fifo required)
      b_addr_o : out std_logic_vector((RAM_WIDTH - 1) downto 0);
      b_data_i :  in std_logic_vector((RAM_WIDTH - 1) downto 0);
      b_data_o : out std_logic_vector((RAM_WIDTH - 1) downto 0);
      b_wb_o   : out std_logic_vector(3 downto 0);

      -- router interface (transmiting)
      clock_tx   : in std_logic; 
      tx         : out std_logic;
      data_out   : out std_logic_vector((FLIT_WIDTH -1) downto 0);
      credit_in  : out std_logic;

      -- router interface (receiving)
      clock_rx   : out std_logic;
      rx         : in std_logic;
      data_in    : in std_logic_vector((FLIT_WIDTH -1) downto 0);
      credit_out : in std_logic;

      -- dma programming (must be mapped into memory space)
      send_start : in std_logic;
      recv_start : in std_logic;
      send_status : out std_logic_vector(31 downto 0);
      recv_status : out std_logic_vector(31 downto 0);
      prog_address : in std_logic_vector(31 downto 0);
      prog_size    : in std_logic_vector(31 downto 0)
    );

	--initial reset
	reset <= '0', '1' after 10 ns, '0' after 20 ns;

	-- clock generation
	clk_gen(clock, 166.667E6);  -- 166.667 MHz clock
	r_clock_tx <= clock;
	r_credit_i <= '1';

	--perform some tests
	send_start <= '0', '1' after 50 ns, '0' after 100 ns;

	-- fix values for memory access
	prog_address <= x"40001000";
	prog_size <= x"0000000A"; -- 10 dec
	
	-- generate arbitrary values at memory output
	mem_seq_proc : process(clock, reset)
	begin
		if reset = '1' then
			m_data_i <= (others => '0');
		elsif rising_edge(clock) then
			m_data_i <= m_data_i + 1;
		end if;
	end process;

end ni_tb;


