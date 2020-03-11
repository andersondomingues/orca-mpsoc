library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;

-- ORCA Processing Tile
-- A processing consists of  
--  (a) a Processor Core (hfriscv)
--  (b) 2x Single Port Memories, one main, one buffer
--  (c) a DMA/NI module
entity orca_processing_tile is

  generic (
    RAM_WIDTH    : natural := 32; --width of main memory word
    FLIT_WIDTH   : natural := 32; --width of router word
    PRELOAD_ADDR : natural := 32; --address to preload first burst at
    BUFFER_DEPTH : natural := 128 --size of internal buffer of recv proc
  );

  port (
    clk : in std_logic;
    rst : in std_logic;
    
    -- router interface (transmiting)
    r_clock_tx : out std_logic;
    r_tx       : out std_logic;
    r_data_o   : out std_logic_vector((FLIT_WIDTH -1) downto 0);
    r_credit_i : in std_logic;

    -- router interface (receiving)
    r_clock_rx : in std_logic;
    r_rx       : in std_logic;
    r_data_i   : in std_logic_vector((FLIT_WIDTH -1) downto 0);
    r_credit_o : out std_logic
  );

end orca_processing_tile;

architecture orca_processing_tile of orca_processing_tile is

  signal intr  : std_logic;
  signal stall : std_logic;

  -- interface to the memory mux
  signal m_addr_o : std_logic_vector((RAM_WIDTH - 1) downto 0);
  signal m_data_i : std_logic_vector((RAM_WIDTH - 1) downto 0);
  signal m_data_o : std_logic_vector((RAM_WIDTH - 1) downto 0);
  signal m_wb_o   : std_logic_vector(3 downto 0);

  -- dma programming (must be mapped into memory space)
  signal send_start : std_logic;
  signal recv_start : std_logic;
  signal send_status : std_logic_vector(31 downto 0);
  signal recv_status : std_logic_vector(31 downto 0);
  signal prog_address : std_logic_vector(31 downto 0);
  signal prog_size    : std_logic_vector(31 downto 0);
  
  signal n_addr_o : std_logic_vector((RAM_WIDTH - 1) downto 0);
  signal n_data_i : std_logic_vector((RAM_WIDTH - 1) downto 0);
  signal n_data_o : std_logic_vector((RAM_WIDTH - 1) downto 0);
  signal n_wb_o   : std_logic_vector(3 downto 0);

  -- proc i/f
  signal p_addr_o:   std_logic_vector(31 downto 0);
  signal p_data_i:   std_logic_vector(31 downto 0);
  signal p_data_o:   std_logic_vector(31 downto 0);
  signal p_data_w_o: std_logic_vector(3 downto 0);

  signal p_data_mode_o: std_logic_vector(2 downto 0);
  signal p_extio_in: std_logic_vector(7 downto 0);
  signal p_extio_out: std_logic_vector(7 downto 0)

begin

  --cpu core binding
  prov_cpu_binding : entity work.arch_processor
    port map(
      clk_i => clk,
      rst_i => rst,
      stall_i => stall,

      addr_o => p_addr_o,
      data_i => p_data_i,
      data_o => p_data_o,
      data_w_o => p_data_w_o,
      
      data_mode_o => p_data_mode_o,
      extio_in => p_extio_in,
      extio_out => p_extio_out
    );

  --main memory binding
  proc_tile_mem_binding: entity work.single_port_ram
    generic map(
      RAM_WIDTH => RAM_WIDTH,
      RAM_DEPTH => BUFFER_DEPTH
    )
    port map(
        clk => clk,
        rst => rst,

        addr_i => m_addr_o,
        data_o => m_data_i,
        data_i => m_data_o,
        wb_i => m_wb_o
    );
    
  -- ni binding
  proc_tile_ni_binding: entity work.orca_ni_top
    generic map(
      RAM_WIDTH    => RAM_WIDTH,
      FLIT_WIDTH   => FLIT_WIDTH,
      PRELOAD_ADDR => PRELOAD_ADDR,
      BUFFER_DEPTH => BUFFER_DEPTH
    )
    port map(
      clk => clk,
      rst => rst, 
      intr =>intr,
      stall => stall,

      m_addr_o => n_addr_o, -- interface to the memory mux
      m_data_i => n_data_i,
      m_data_o => n_data_o,
      m_wb_o   => n_wb_o,

      r_clock_tx => r_clock_tx, -- router i/f
      r_tx => r_tx,
      r_data_o => r_data_o,
      r_credit_i => r_credit_i,
      r_clock_rx => r_clock_rx,
      r_rx  => r_rx,
      r_data_i => r_data_i,
      r_credit_o => r_credit_o,

      send_start => send_start, -- dma programming
      recv_start => recv_start,
      send_status => send_status,
      recv_status => recv_status,
      prog_address => prog_address,
      prog_size => prog_size
      
    );
    
end orca_processing_tile;
