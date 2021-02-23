library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;
use ieee.math_real.log2;
use ieee.math_real.ceil;
use work.orca_defaults.all;

-- ORCA Processing Tile
-- A processing consists of  
--  (a) a Processor Core (hfriscv)
--  (b) 2x Single Port Memories, one main, one buffer
--  (c) a DMA/NI module
entity orca_processing_tile is

  generic (
    R_ADDRESS : regmetadeflit := "0000000000000000" --address
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
    credit_i: in regNportLONE  );

end orca_processing_tile;

architecture orca_processing_tile of orca_processing_tile is

  -- reset sinchronizers
  signal rst_cpu    : std_logic;
  signal rst_local  : std_logic;
  signal rst_reload : std_logic;
  signal rst_i      : std_logic;
  signal rcff1      : std_logic;
  signal rlff1      : std_logic;

  -- interruptions
  signal ni_intr  : std_logic;
  signal stall : std_logic;

  -- mem delay
  signal periph_dly : std_logic;

  -- interface to the memory mux
  signal shift_m_addr_i : std_logic_vector((RAM_WIDTH - 1) downto 0);
  signal m_addr_i : std_logic_vector((RAM_WIDTH - 1) downto 0);
  signal m_data_o : std_logic_vector((RAM_WIDTH - 1) downto 0);
  signal m_data_i : std_logic_vector((RAM_WIDTH - 1) downto 0);
  signal m_cs_n_i   : std_logic_vector(3 downto 0);
  signal m_wb_n_i   : std_logic_vector(3 downto 0);

  -- dma programming (must be mapped into memory space)
  signal recv_reload : std_logic;
  signal send_start :   std_logic;
  signal recv_start :   std_logic;
  signal send_status :  std_logic;
  signal recv_status :  std_logic_vector(((RAM_WIDTH/2) - 1) downto 0);
  signal prog_address : std_logic_vector((RAM_WIDTH - 1) downto 0);
  signal prog_size    : std_logic_vector((RAM_WIDTH - 1) downto 0);
  signal prog_dest    : std_logic_vector((RAM_WIDTH - 1) downto 0);
  
  signal n_addr_o : std_logic_vector((RAM_WIDTH - 1) downto 0);
  signal n_data_o : std_logic_vector((RAM_WIDTH - 1) downto 0);
  signal n_m_data_o : std_logic_vector((RAM_WIDTH - 1) downto 0);
  signal n_wb_o   : std_logic_vector(3 downto 0);
  signal n_wb_n_o   : std_logic_vector(3 downto 0);


  -- proc i/f
  signal p_addr_o: std_logic_vector((RAM_WIDTH - 1) downto 0);
  signal p_data_o: std_logic_vector((RAM_WIDTH - 1) downto 0);
  signal p_data_i: std_logic_vector((RAM_WIDTH - 1) downto 0);
  signal p_wb_o:   std_logic_vector(3 downto 0);
  signal p_wb_n_o:   std_logic_vector(3 downto 0);


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
  signal data_write_periph: std_logic_vector((RAM_WIDTH - 1) downto 0);
  signal data_read_periph_s: std_logic_vector((RAM_WIDTH - 1) downto 0);
  signal data_read_periph: std_logic_vector((RAM_WIDTH - 1) downto 0);

  signal periph: std_logic;
  signal periph_wr:  std_logic;
  signal periph_irq: std_logic;

  signal dummy_gpioa_in:  std_logic_vector(7 downto 0);
  signal dummy_gpioa_out: std_logic_vector(7 downto 0);
  signal dummy_gpioa_ddr: std_logic_vector(7 downto 0);
  
  -- FPGA debug signals and definitions
  -- these signals are used only to easy the FPGA debug
  signal r_debug_rx: std_logic;
  signal r_debug_data_i: std_logic_vector((RAM_WIDTH - 1) downto 0);
  signal r_debug_credit_o: std_logic;
  
  signal r_debug_tx: std_logic;
  signal r_debug_data_o: std_logic_vector((RAM_WIDTH - 1) downto 0);
  signal r_debug_credit_i: std_logic;

--#################################################
--Uncomment these lines to enable FPGA debuging.
--It monitors the router-ni interface of every PE
--#################################################
--attribute KEEP : string;
--attribute MARK_DEBUG : string;
--
--attribute KEEP of  r_debug_rx : signal is "TRUE";
--attribute MARK_DEBUG of r_debug_rx  : signal is "TRUE";
--attribute KEEP of  r_debug_data_i : signal is "TRUE";
--attribute MARK_DEBUG of r_debug_data_i  : signal is "TRUE";
--attribute KEEP of  r_debug_credit_o : signal is "TRUE";
--attribute MARK_DEBUG of r_debug_credit_o  : signal is "TRUE";
--
--attribute KEEP of  r_debug_tx : signal is "TRUE";
--attribute MARK_DEBUG of r_debug_tx  : signal is "TRUE";
--attribute KEEP of  r_debug_data_o : signal is "TRUE";
--attribute MARK_DEBUG of r_debug_data_o  : signal is "TRUE";
--attribute KEEP of  r_debug_credit_i : signal is "TRUE";
--attribute MARK_DEBUG of r_debug_credit_i  : signal is "TRUE";

begin

	rst_i <= rst or rst_reload;
 
	-- cpu reset synchronizer
	process (clk, rst_i)
	begin
		if (rst_i = '1') then
			rcff1 <= '1';
			rst_cpu <= '1';
		elsif (clk'event and clk = '1') then
			rcff1 <= '0';
			rst_cpu <= rcff1;
		end if;
	end process;

	-- tile reset synchronizer
	process (clk, rst)
	begin
		if (rst = '1') then
			rlff1 <= '1';
			rst_local <= '1';
		elsif (clk'event and clk = '1') then
			rlff1 <= '0';
			rst_local <= rlff1;
		end if;
	end process;


	process (rst_local, clk)
	begin
		if rst_local = '1' then
			periph_dly <= '0';
		elsif clk'event and clk = '1' then
			periph_dly <= periph;
		end if;
	end process;

	p_data_i <= data_read_periph when periph = '1' or periph_dly = '1' else m_data_o;
--	data_w_n_ram <= not data_we;
	p_extio_in <= "0000000" & periph_irq;

  --cpu core binding
  prov_cpu_binding : entity work.processor
    port map(
      clk_i => clk,
      rst_i => rst_cpu,
      stall_i => stall,

      addr_o => p_addr_o,
      data_o => p_data_o,
      data_w_o => p_wb_o,

      data_i => p_data_i,

      data_mode_o => p_data_mode_o,
      extio_in => p_extio_in,
      extio_out => p_extio_out
    );


	data_read_periph <= data_read_periph_s(7 downto 0) & data_read_periph_s(15 downto 8) & data_read_periph_s(23 downto 16) & data_read_periph_s(31 downto 24);
	data_write_periph <= p_data_o(7 downto 0) & p_data_o(15 downto 8) & p_data_o(23 downto 16) & p_data_o(31 downto 24);
	periph_wr <= '1' when p_wb_o /= "0000" else '0';
	periph <= '1' when p_addr_o(31 downto 28) = x"e" else '0';

    -- assign to remove the 'undriven pin' warning in synthesis
    dummy_gpioa_in <= (others => '0');
    
  peripherals_binding : entity work.peripherals
    port map(
      clk_i => clk,
      rst_i => rst_local,
      
      addr_i => p_addr_o,
      data_i => data_write_periph,
      data_o => data_read_periph_s,

      sel_i => periph,
      wr_i  => periph_wr,
      irq_o => periph_irq,

      
      gpioa_in  => dummy_gpioa_in,
      gpioa_out => dummy_gpioa_out,
      gpioa_ddr => dummy_gpioa_ddr,

      ni_address => R_ADDRESS,
      ni_reload => recv_reload,
      ni_send_start => send_start,
      ni_recv_start => recv_start,
      ni_send_status => send_status,
      ni_intr => ni_intr,
      ni_recv_size => recv_status,
      ni_mem_addr => prog_address,
      ni_pct_size => prog_size,
      ni_pct_dest => prog_dest
      
    );

  router_binding : entity work.RouterCC
    generic map(
      address => R_ADDRESS
    )
    port map(
      clock => clk,
      reset => rst_local,

      clock_rx => r_clock_rx,
      rx => r_rx,
      data_in => r_data_i,
      credit_o => r_credit_o,

      clock_tx => r_clock_tx,
      tx => r_tx,
      data_out => r_data_o,
      credit_i => r_credit_i
    );


  m_cs_n_i <= "1111" when periph = '1' else "0000";
  p_wb_n_o <= "1111" when periph = '1' else not p_wb_o;
  shift_m_addr_i <= "00" & m_addr_i(31 downto 2);
  --main memory binding
  proc_tile_mem_binding: entity work.single_port_ram_32bits
    generic map(
        RAM_DEPTH_I => RAM_DEPTH
    )
    port map(
        clk => clk,
        --rst => rst_local,

        addr_i => shift_m_addr_i((INTEGER(CEIL(LOG2(REAL(RAM_DEPTH)))))-1 downto 0),
        data_o => m_data_o,
        data_i => m_data_i,
        cs_n_i => m_cs_n_i,
        wb_n_i => m_wb_n_i
    );
    
  n_wb_n_o <= not n_wb_o;
  n_m_data_o <= m_data_o(7 downto 0) & m_data_o(15 downto 8) & m_data_o(23 downto 16) & m_data_o(31 downto 24);
  -- ni binding
  proc_tile_ni_binding: entity work.orca_ni_top
    port map(
      clk => clk,
      rst => rst_local, 
      rst_reload => rst_reload,
      intr => ni_intr,
      stall => stall,

      m_addr_o => n_addr_o, -- interface to the memory mux
      m_data_o => n_data_o, -- output is driven to both modules
      m_wb_o   => n_wb_o,
      m_data_i => n_m_data_o,

      r_clock_tx => r_clock_rx(LOCAL), -- router i/f
      r_tx => r_debug_rx,
      r_data_o => r_debug_data_i,
      r_credit_i => r_debug_credit_o,
      
      r_clock_rx => r_clock_tx(LOCAL),
      r_rx  => r_debug_tx,
      r_data_i => r_debug_data_o,
      r_credit_o => r_debug_credit_i,

      recv_reload => recv_reload, -- dma programming
      send_start => send_start, 
      recv_start => recv_start,
      send_status => send_status,
      recv_status => recv_status,
      prog_address => prog_address,
      prog_dest => prog_dest,
      prog_size => prog_size
    );
    
    -- these 6 signal are only used for FPGA debug
    r_rx(LOCAL) <= r_debug_rx;
    r_data_i(LOCAL) <= r_debug_data_i;
    r_debug_credit_o <= r_credit_o(LOCAL);
    
    r_debug_tx <= r_tx(LOCAL);
    r_debug_data_o <= r_data_o(LOCAL);
    r_credit_i(LOCAL) <= r_debug_credit_i;

    -- memory mux (m_data_o done via port mapping)
    m_addr_i <= n_addr_o when stall = '1' else p_addr_o;
    m_data_i <= n_data_o(7 downto 0) & n_data_o(15 downto 8) & n_data_o(23 downto 16) & n_data_o(31 downto 24) when stall = '1' else p_data_o;
    m_wb_n_i <= n_wb_n_o when stall = '1' else p_wb_n_o;

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
