library ieee;

use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity orca_ni_top is

  --parameters come from the top level rtl (naming consistency
  --is preserved for all rtl files).
  generic (
    RAM_WIDTH    : natural;
    FLIT_WIDTH   : natural;
    PRELOAD_ADDR : natural;
    BUFFER_DEPTH : natural
  );

  port(
    clk : in std_logic;
    rst : in std_logic;
    rst_reload : out std_logic;
    intr  : out std_logic;    -- load next packet into main memory
    stall : out std_logic; -- holds the cpu and takes control on memory i/f

    -- interface to the memory mux
    m_addr_o : out std_logic_vector((RAM_WIDTH - 1) downto 0);
    m_data_i :  in std_logic_vector((RAM_WIDTH - 1) downto 0);
    m_data_o : out std_logic_vector((RAM_WIDTH - 1) downto 0);
    m_wb_o   : out std_logic_vector(3 downto 0);

    -- router interface (transmiting)
    r_clock_tx : out std_logic; 
    r_tx       : out std_logic;
    r_data_o   : out std_logic_vector((FLIT_WIDTH -1) downto 0);
    r_credit_i : in std_logic;

    -- router interface (receiving)
    r_clock_rx : in std_logic;
    r_rx       : in std_logic;
    r_data_i   : in std_logic_vector((FLIT_WIDTH -1) downto 0);
    r_credit_o : out std_logic;

    -- dma programming (must be mapped into memory space)
    recv_reload : in std_logic;
    send_start : in std_logic;
    recv_start : in std_logic;
    send_status : out std_logic;
    recv_status : out std_logic_vector(15 downto 0);
    prog_address : in std_logic_vector(31 downto 0);
    prog_size    : in std_logic_vector(31 downto 0)

  );
end orca_ni_top;

architecture orca_ni_top of orca_ni_top is

  signal recv_status_r : std_logic_vector(15 downto 0);
  signal send_status_s : std_logic;

  signal stall_r : std_logic;
  signal stall_s : std_logic; 

  signal m_addr_o_s : std_logic_vector((RAM_WIDTH - 1) downto 0);
  signal m_wb_o_s   : std_logic_vector(3 downto 0);

  signal m_addr_o_r : std_logic_vector((RAM_WIDTH - 1) downto 0);
  signal m_wb_o_r   : std_logic_vector(3 downto 0);

begin

  --sender mod binding
  ni_sender_mod: entity work.orca_ni_send
    generic map (
      RAM_WIDTH => RAM_WIDTH,
      FLIT_WIDTH => FLIT_WIDTH
    )
    port map(
      clk  => clk,
      rst  => rst,
      stall => stall_s,

      m_data_i => m_data_i,
      m_addr_o => m_addr_o_s,
      m_wb_o => m_wb_o_s,

      r_credit_i => r_credit_i,
      r_tx => r_tx,
      r_data_o => r_data_o,
      r_clock_tx => r_clock_tx,

      send_start => send_start,
      send_status => send_status_s,
      
      prog_address => prog_address,
      prog_size => prog_size
    );

  --recv mod binding
  ni_recv_mod: entity work.orca_ni_recv
    generic map (
      RAM_WIDTH => RAM_WIDTH,
      FLIT_WIDTH => FLIT_WIDTH,
      PRELOAD_ADDR => PRELOAD_ADDR,
      BUFFER_DEPTH => BUFFER_DEPTH
    )
    port map(
      clk  => clk,
      rst  => rst,
      rst_reload => rst_reload,
      stall => stall_r,
      intr => intr,

      m_data_o => m_data_o,
      m_addr_o => m_addr_o_r,
      m_wb_o => m_wb_o_r,

      r_credit_o => r_credit_o,
      r_rx => r_rx,
      r_data_i => r_data_i,
      r_clock_rx => r_clock_rx,

      recv_reload => recv_reload,
      recv_start => recv_start,
      recv_status => recv_status_r,
      
      prog_address => prog_address,
      prog_size => prog_size
    );

    stall <= stall_r or stall_s;
    recv_status <= recv_status_r;
    send_status <= send_status_s;

    m_addr_o <= m_addr_o_r when recv_status_r /= 0 else m_addr_o_s;
    m_wb_o <= m_wb_o_r when recv_status_r /= 0 else m_wb_o_s;
  
end orca_ni_top;
