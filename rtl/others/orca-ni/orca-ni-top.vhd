library ieee;

use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity orca_ni_top is

  --parameters come from the top level rtl (naming consistency
  --is preserved for all rtl files).
  generic (
    RAM_WIDTH  : natural; --width of main memory word
    FLIT_WIDTH : natural; --width of router word
    BUFFER_DEPTH : natural --depth of internal buffer (recv only)
  );

  port(
    clk : in std_logic;
    rst : in std_logic;
    load: in std_logic;    -- load next packet into main memory
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
    data_out   : out std_logic_vector(FLIT_WIDTH downto 0);
    credit_in  : out std_logic;

    -- router interface (receiving)
    clock_rx   : out std_logic;
    rx         : in std_logic;
    data_in    : in std_logic_vector(FLIT_WIDTH downto 0);
    credit_out : in std_logic;

    -- dma programming (must be mapped into memory space)
    send_start : in std_logic;
    recv_start : in std_logic;
    send_status : out std_logic_vector(31 downto 0);
    recv_status : out std_logic_vector(31 downto 0);
    prog_address : in std_logic_vector(31 downto 0);
    prog_size    : in std_logic_vector(31 downto 0)

  );

end orca_ni_top;

architecture orca_ni_top of orca_ni_top is

  component orca_ni_sender_comp
    --generic (...);
    port (
      clk_s : in std_logic;
      rst_s : in std_logic;
      stall_s : out std_logic; -- holds the cpu and takes control on memory i/f

      -- interface to the memory mux
      m_data_i_s :  in std_logic_vector((RAM_WIDTH - 1) downto 0);
      m_addr_o_s : out std_logic_vector((RAM_WIDTH - 1) downto 0);
      m_wb_o_s   : out std_logic_vector(3 downto 0);

      -- router interface (transmiting)
      r_clock_tx_s  : out std_logic; 
      r_tx_s        : out std_logic;
      r_data_o_s    : out std_logic_vector(FLIT_WIDTH downto 0);
      r_credit_i_s  : in std_logic;

      -- dma programming (must be mapped into memory space)
      send_start_s : in std_logic;
      prog_address_s : in std_logic_vector(31 downto 0);
      prog_size_s    : in std_logic_vector(31 downto 0);
      send_status_s : out std_logic_vector(31 downto 0)
    );
  end component;
  
begin
  binding_sender: orca_ni_sender_comp
  --  --generic map(...)
    port map(
      -- forward clk, rst, and stall signals
      clk => clk_s,
      rst => rst_s,
      stall_s => stall,
      -- bind memory acconding to the active process 
      
    );

end orca_ni_top;
