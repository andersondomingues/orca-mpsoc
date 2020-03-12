library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;
use work.HeMPS_defaults.all;

-- ORCA Processing Tile
-- A processing consists of  
--  (a) a Processor Core (hfriscv)
--  (b) 2x Single Port Memories, one main, one buffer
--  (c) a DMA/NI module
entity orca_processing_tile is

  generic (
    RAM_WIDTH    : natural := 32;        --width of main memory word
    RAM_SIZE     : natural := 320000000; -- 4MB
    
    FLIT_WIDTH   : natural := 32;  --width of router word
    BUFFER_DEPTH : natural := 128; --size of internal buffer of recv proc
    PRELOAD_ADDR : natural := 32;   --address to preload first burst at
    
    R_ADDRESS : regmetadeflit := "0000000000010001"; --address
    LOCAL_PORT_NUM : natural := LOCAL
  );

  port (
    clk : in std_logic;
    rst : in std_logic;
    
    clock_rx: in  regNportLONE;
    rx      : in  regNportLONE;
    data_i  : in  arrayNport_regflitLONE;
    credit_o: out regNportLONE;

    clock_tx: out regNportLONE;
    tx      : out regNportLONE;
    data_o  : out arrayNport_regflitLONE;
    credit_i: in regNportLONE
  );

end orca_processing_tile;

architecture orca_processing_tile of orca_processing_tile is

  signal intr  : std_logic;
  signal stall : std_logic;

  -- interface to the memory mux
  signal m_addr_i : std_logic_vector((RAM_WIDTH - 1) downto 0);
  signal m_data_o : std_logic_vector((RAM_WIDTH - 1) downto 0);
  signal m_data_i : std_logic_vector((RAM_WIDTH - 1) downto 0);
  signal m_wb_i   : std_logic_vector(3 downto 0);

  -- dma programming (must be mapped into memory space)
  signal send_start :   std_logic;
  signal recv_start :   std_logic;
  signal send_status :  std_logic_vector(31 downto 0);
  signal recv_status :  std_logic_vector(31 downto 0);
  signal prog_address : std_logic_vector(31 downto 0);
  signal prog_size    : std_logic_vector(31 downto 0);
  
  signal n_addr_o : std_logic_vector((RAM_WIDTH - 1) downto 0);
  signal n_data_o : std_logic_vector((RAM_WIDTH - 1) downto 0);
  signal n_wb_o   : std_logic_vector(3 downto 0);

  -- proc i/f
  signal p_addr_o: std_logic_vector((RAM_WIDTH - 1) downto 0);
  signal p_data_o: std_logic_vector((RAM_WIDTH - 1) downto 0);
  signal p_wb_o:   std_logic_vector(3 downto 0);

  signal p_data_mode_o: std_logic_vector(2 downto 0);
  signal p_extio_in: std_logic_vector(7 downto 0);
  signal p_extio_out: std_logic_vector(7 downto 0);

  -- router i/f
  signal r_clock_rx : regNport;
  signal r_rx       : regNport;
  signal r_data_i   : arrayNport_regflit;
  signal r_credit_o : regNport;

  signal r_clock_tx : regNport;
  signal r_tx       : regNport;
  signal r_data_o   : arrayNport_regflit;
  signal r_credit_i : regNport;

  -- peripherals
  signal dummy_addr_i: std_logic_vector(31 downto 0);
  signal dummy_data_i: std_logic_vector(31 downto 0);
  signal dummy_data_o: std_logic_vector(31 downto 0);

  signal dummy_sel_i: std_logic;
  signal dummy_wr_i:  std_logic;
  signal dummy_irq_o: std_logic;

  signal dummy_gpioa_in:  std_logic_vector(7 downto 0);
  signal dummy_gpioa_out: std_logic_vector(7 downto 0);
  signal dummy_gpioa_ddr: std_logic_vector(7 downto 0);

begin

  peripherals_binding : entity work.peripherals
    port map(
      clk_i => clk,
      rst_i => rst,
      
      addr_i => dummy_addr_i,
      data_i => dummy_data_i,
      data_o => dummy_data_o,

      sel_i => dummy_sel_i,
      wr_i  => dummy_wr_i,
      irq_o => dummy_irq_o,
      
      gpioa_in  => dummy_gpioa_in,
      gpioa_out => dummy_gpioa_out,
      gpioa_ddr => dummy_gpioa_ddr
    );

  router_binding : entity work.RouterCC
    generic map(
      address => R_ADDRESS
    )
    port map(
      clock => clk,
      reset => rst,

      clock_rx => r_clock_rx,
      rx => r_rx,
      data_in => r_data_i,
      credit_o => r_credit_o,

      clock_tx => r_clock_tx,
      tx => r_tx,
      data_out => r_data_o,
      credit_i => r_credit_i
    );

  --cpu core binding
  prov_cpu_binding : entity work.processor
    port map(
      clk_i => clk,
      rst_i => rst,
      stall_i => stall,

      addr_o => p_addr_o,
      data_o => p_data_o,
      data_w_o => p_wb_o,

      data_i => m_data_o,

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

        addr_i => m_addr_i,
        data_o => m_data_o,
        data_i => m_data_i,
        wb_i => m_wb_i
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
      m_data_o => n_data_o, -- output is driven to both modules
      m_wb_o   => n_wb_o,
      m_data_i => m_data_o,

      r_clock_tx => r_clock_rx(LOCAL_PORT_NUM), -- router i/f
      r_tx => r_rx(LOCAL_PORT_NUM),
      r_data_o => r_data_i(LOCAL_PORT_NUM),
      r_credit_i => r_credit_o(LOCAL_PORT_NUM),
      
      r_clock_rx => r_clock_tx(LOCAL_PORT_NUM),
      r_rx  => r_tx(LOCAL_PORT_NUM),
      r_data_i => r_data_o(LOCAL_PORT_NUM),
      r_credit_o => r_credit_i(LOCAL_PORT_NUM),

      send_start => send_start, -- dma programming
      recv_start => recv_start,
      send_status => send_status,
      recv_status => recv_status,
      prog_address => prog_address,
      prog_size => prog_size
    );
    
    -- memory mux (m_data_o done via port mapping)
    m_addr_i <= n_addr_o when stall = '1' else p_addr_o;
    m_data_i <= n_data_o when stall = '1' else p_data_o;
    m_wb_i <= n_wb_o when stall = '1' else p_wb_o;

    -- external routers (pass-through)
    r_clock_rx(3 downto 0) <= clock_rx;
    r_rx(3 downto 0) <= rx;
    r_credit_i(3 downto 0) <= credit_i;
    
    credit_o <= r_credit_o(3 downto 0);
    clock_tx <= r_clock_tx(3 downto 0);
    tx <= r_tx(3 downto 0);

    --NOTE: could directly assign as the compiler could not convert types properly
    data_o(0) <= r_data_o(0);
    data_o(1) <= r_data_o(1);
    data_o(2) <= r_data_o(2);
    data_o(3) <= r_data_o(3);

    r_data_i(0) <= data_i(0);
    r_data_i(1) <= data_i(1);
    r_data_i(2) <= data_i(2);
    r_data_i(3) <= data_i(3);

end orca_processing_tile;
