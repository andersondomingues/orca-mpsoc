-- ni

library ieee;

use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity orca_dma is

	port(
		-- memory interface (main memory)
		memM_addr   : out std_logic_vector(31 downto 0);
		memM_data_w : out std_logic_vector(31 downto 0);
		memM_data_r : in  std_logic_vector(31 downto 0);

		-- memory interface (send memory)
		memS_addr   : out std_logic_vector(31 downto 0);
		memS_data_w : out std_logic_vector(31 downto 0);
		memS_data_r : in  std_logic_vector(31 downto 0);

		-- memory interface (recv memory)
		memR_addr   : out std_logic_vector(31 downto 0);
		memR_data_w : out std_logic_vector(31 downto 0);
		memS_data_r : out std_logic_vector(31 downto 0);

		-- cpu interface (recv)
	    recv_intr  : out std_logic;                     -- raise intr when pkt is recv'd
		recv_addr  : in  std_logic_vector(31 downto 0); -- wait for a valid addr and start=1
		recv_start : in  std_logic
		recv_status: out std_logic;                     -- report status to free the cpu

		-- cpu interface (send)
		send_intr  : in std_logic;                      -- wait for intr and valid addr    
		send_addr  : in std_logic_vector(31 downto 0);
        send_status: out std_logic;                     -- report send succefully


		-- router interface 
		tx         : out std_logic;
		data_out   : out flit_t;
		credit_in  : out std_logic;

		rx         : in std_logic;
		data_in    : in flit_t;
		credit_out : in std_logic;
