---------------------------------------------------------------------
-- TITLE: Test Bench
-- AUTHOR: Guilherme Heck (heckgui@gmail.com)
-- Based on Steve Rhoads design (rhoadss@yahoo.com)
-- DATE CREATED: 6/19/2020
-- FILENAME: tbench.vhd
-- PROJECT: ORCA MPSoC
-- COPYRIGHT: Software placed into the public domain by the author.
--    Software 'as is' without warranty.  Author liable for nothing.
-- DESCRIPTION:
--    This entity provides a test bench for testing the ORCA MPSoC.
---------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_textio.all;
use ieee.std_logic_unsigned.all;
use std.textio.all;
use work.orca_defaults.all;


entity tbench is
end;  

architecture logic of tbench is
 
   signal clock         : std_logic := '1';
   signal reset       : std_logic := '1';

	signal address_ip 	: regmetadeflit;
	signal clock_rx		: std_logic;
	signal rx		: std_logic;
	signal data_in		: std_logic_vector(TAM_FLIT - 1 downto 0);
	signal credit_o		: std_logic;
	signal clock_tx		: std_logic;
	signal tx		: std_logic;
	signal data_out		: std_logic_vector(TAM_FLIT - 1 downto 0);
	signal credit_i		: std_logic;
	signal ack_task		: std_logic;
	signal req_task		: std_logic_vector(31 downto 0);


begin  
   clock <= not clock after 4 ns;
   reset <= '1', '0' after 50 ns;
   address_ip <= x"10";
   credit_i <= '1';
   
	u1_orca: entity work.orca_top
		port map(
	                clk		=> clock,
	                rst		=> reset,
	
	                clock_rx_local	=> clock,
	                rx_local	=> rx,
	                data_in_local	=> data_in,
        	        credit_o_local	=> credit_o,
	                clock_tx_local	=> clock_tx,
	                tx_local	=> tx,
	                data_out_local	=> data_out,
	                credit_i_local	=> credit_i
  		);


	sc_input: entity work.inputmodule
		port map(
			clock	=> clock,
			reset	=> reset,
			address_ip => address_ip,
			outTx	=> rx,
			outData	=> data_in,
			inCredit=> credit_o
		);

end;  
