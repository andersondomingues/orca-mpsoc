library ieee;

use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

use work.standards.all;

entity orca_dma is

	port(
	   clock : in std_logic;
	   reset : in std_logic;
	
	   -- mem0 if
       mem0_address_i : in std_logic_vector(31 downto 0);
       mem0_enable_i  : in std_logic;
       mem0_wbe_i     : in std_logic_vector(3 downto 0);
       mem0_data_write: in std_logic_vector(31 downto 0);
       mem0_data_read : out std_logic_vector(31 downto 0);    
          
      -- mem1 if
      mem1_address_i : in std_logic_vector(31 downto 0);
      mem1_enable_i  : in std_logic;
      mem1_wbe_i     : in std_logic_vector(3 downto 0);
      mem1_data_write: in std_logic_vector(31 downto 0);
      mem1_data_read : out std_logic_vector(31 downto 0);    
   
    -- mem2 if
    mem2_address_i : in std_logic_vector(31 downto 0);
    mem2_enable_i  : in std_logic;
    mem2_wbe_i     : in std_logic_vector(3 downto 0);
    mem2_data_write: in std_logic_vector(31 downto 0);
    mem2_data_read : out std_logic_vector(31 downto 0);    
         
		-- router interface
		clock_tx   : in std_logic; 
		tx         : out std_logic;
		data_out   : out std_logic_vector(TAM_FLIT downto 0);
		credit_in  : out std_logic;

        clock_rx   : out std_logic;
		rx         : in std_logic;
		data_in    : in std_logic_vector(TAM_FLIT downto 0);
		credit_out : in std_logic
);
		
end orca_dma;

architecture ni of orca_dma is
   signal a, b : std_logic;
begin
   a <= b;
end ni;
