---------------------------------------------------------------------
-- TITLE: Test Bench
-- AUTHOR: Steve Rhoads (rhoadss@yahoo.com)
-- DATE CREATED: 4/21/01
-- FILENAME: tbench.vhd
-- PROJECT: Plasma CPU core
-- COPYRIGHT: Software placed into the public domain by the author.
--    Software 'as is' without warranty.  Author liable for nothing.
-- DESCRIPTION:
--    This entity provides a test bench for testing the Plasma CPU core.
---------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_textio.all;
use ieee.std_logic_unsigned.all;
use std.textio.all;
use work.HeMPS_PKG.all;
use work.HeMPS_defaults.all;
use work.mlite_pack.all;


entity tbench is
end;  

architecture logic of tbench is
 
component processing_element

	port (
		address_ip: in std_logic_vector(7 downto 0);
		clock: in std_logic;
		reset: in std_logic;
		clock_rx: in std_logic_vector(3 downto 0);
		rx: in std_logic_vector(3 downto 0);
		\data_in[0]\: in std_logic_vector(15 downto 0);
		\data_in[1]\: in std_logic_vector(15 downto 0);
		\data_in[2]\: in std_logic_vector(15 downto 0);
		\data_in[3]\: in std_logic_vector(15 downto 0);
		credit_o: out std_logic_vector(3 downto 0);
		clock_tx: out std_logic_vector(3 downto 0);
		tx: out std_logic_vector(3 downto 0);
		\data_out[0]\: out std_logic_vector(15 downto 0);
		\data_out[1]\: out std_logic_vector(15 downto 0);
		\data_out[2]\: out std_logic_vector(15 downto 0);
		\data_out[3]\: out std_logic_vector(15 downto 0);
		credit_i: in std_logic_vector(3 downto 0);
		address: out std_logic_vector(31 downto 2);
		read_req: out std_logic;
		data_write: out std_logic_vector(31 downto 0);
		data_read: in std_logic_vector(31 downto 0);
		write_byte_enable: out std_logic_vector(3 downto 0);
		data_valid: in std_logic;
		write_enable_debug: out std_logic;
		data_out_debug: out std_logic_vector(31 downto 0);
		busy_debug: in std_logic;
		ack_task: out std_logic;
		req_task: in std_logic_vector(31 downto 0)
	);
end component;


   signal clk         : std_logic := '1';
   signal reset       : std_logic := '1';

	signal address_ip	: regmetadeflit;
	signal clock_rx	: std_logic_vector(3 downto 0);
	signal rx		: std_logic_vector(3 downto 0);
	signal data_in		: arrayNPORT_1_regflit;
	signal credit_o	: std_logic_vector(3 downto 0);
	signal clock_tx	: std_logic_vector(3 downto 0);
	signal tx		: std_logic_vector(3 downto 0);
	signal data_out	: arrayNPORT_1_regflit;
	signal credit_i	: std_logic_vector(3 downto 0);
	signal ack_task	: std_logic;
	signal req_task	: std_logic_vector(31 downto 0);


begin  
   clk <= not clk after 10 ns;
   reset <= '1', '0' after 100 ns;
   address_ip <= x"00";
   
--   uart_av  <= '1' when mem_address = UART and mem_write = '1' else '0';
 
---
--- Processing Element
---

	u1_pe: processing_element
		port map(
	                address_ip	=> address_ip,
	
	                -- Noc Ports
	                clock		=> clk,
	                reset		=> reset,
	
	                clock_rx	=> clock_rx,
	                rx		=> rx,
	                \data_in[0]\	=> data_in(0),
	                \data_in[1]\	=> data_in(1),
	                \data_in[2]\	=> data_in(2),
	                \data_in[3]\	=> data_in(3),
		
        	        credit_o	=> credit_o,
	                clock_tx	=> clock_tx,
	                tx		=> tx,
	                \data_out[0]\	=> data_out(0),
	                \data_out[1]\	=> data_out(1),
	                \data_out[2]\	=> data_out(2),
	                \data_out[3]\	=> data_out(3),
	                credit_i	=> credit_i,
 
                        address                         => open,
                        data_write                      => open,
                        data_read                       => (others => '0'),
                        write_byte_enable   => open,
                        data_valid                      => '0',
                
                -- Debug MC
                        write_enable_debug      => open,
                        data_out_debug          => open,
                        busy_debug                      => '0',
                               
                        ack_task        => open,
                        req_task        => (others=>'0')
 		);


	sc_input: entity work.inputmodule
		port map(
			clock	=> clk,
			reset	=> reset,
			address_ip => address_ip,
			outTx	=> rx(0),
			outData	=> data_in(0),
			inCredit=> credit_o(0)
		);
	rx(1) <= '0';
	rx(2) <= '0';
	rx(3) <= '0';
--	credit_o(0) <= '1';
	clock_rx(0) <= clk;
	clock_rx(1) <= clk;
	clock_rx(2) <= clk;
	clock_rx(3) <= clk;
	data_in(1) <= (others => '0');
	data_in(2) <= (others => '0');
	data_in(3) <= (others => '0');
	credit_i(0) <= '1';
	credit_i(1) <= '1';
	credit_i(2) <= '1';
	credit_i(3) <= '1';

    -- acesso de escrita
 



end;  
