library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use work.standards.all;
use ieee.numeric_std.all;

-- ORCA Processing Tile
-- A processing consists of  
--  (a) a Processor Core (hfriscv)
--  (b) 3x Single Port Memories, one main, two auxiliary
--  (c) a DMA/NI module
--  (d) a Router
entity orca_processing_tile is

   port (
      clock : in std_logic;
      reset : in std_logic;
    
      -- RX from router is exposed 
      -- @TODO: hide local port from the top module
      clock_rx:  in  regNport;
      rx:        in  regNport;
      data_in:   in  arrayNport_regflit;
      credit_o:  out regNport;    
        
      -- TX form router is exposed
      -- @TODO: hide local port form the top module
      clock_tx:  out regNport;
      tx:        out regNport;
      data_out:  out arrayNport_regflit;
      credit_i:  in  regNport
   );
   
   
   
end orca_processing_tile;

architecture orca_processing_tile of orca_processing_tile is
        
    -- cpu core interface
    signal stall : std_logic;
	signal data_mode_o_dummy : std_logic_vector(2 downto 0);
	signal extio_in_dummy    : std_logic_vector(7 downto 0);
    signal extio_out_dummy   : std_logic_vector(7 downto 0);
    
    -- main memory interface
    signal mem0_addr_s: std_logic_vector(31 downto 0);
    signal mem0_data_i_s: std_logic_vector(31 downto 0);
    signal mem0_data_o_s: std_logic_vector(31 downto 0);
    signal mem0_data_w_s: std_logic_vector(3 downto 0);

    -- mem1 (recv) interface
    signal mem1_addr_o: std_logic_vector(31 downto 0);
    signal mem1_data_i: std_logic_vector(31 downto 0);
    signal mem1_data_o: std_logic_vector(31 downto 0);
    signal mem1_data_w_o: std_logic_vector(3 downto 0);
    signal mem1_enable_dummy: std_logic;
    signal mem1_wbe_dummy: std_logic_vector(3 downto 0);

    -- mem2 (recv) interface
    signal mem2_addr_o: std_logic_vector(31 downto 0);
    signal mem2_data_i: std_logic_vector(31 downto 0);
    signal mem2_data_o: std_logic_vector(31 downto 0);
    signal mem2_data_w_o: std_logic_vector(3 downto 0);
    signal mem2_enable_dummy: std_logic;
    signal mem2_wbe_dummy: std_logic_vector(3 downto 0);

    -- router interface
    signal clock_rx_dummy: regNport;
    signal rx_dummy:       regNport;
    signal data_in_dummy:  arrayNport_regflit;
    signal credit_o_dummy: regNport; 
       
    signal clock_tx_dummy: regNport;
    signal tx_dummy:       regNport;
    signal data_out_dummy: arrayNport_regflit;
    signal credit_i_dummy: regNport;
    
    -- dma interface
    -- ??
        
begin
	-- hf-risc top
	core: entity work.processor(arch_processor)
	port map(
        clk_i => clock,  -- remember: submodule => top-level
        rst_i => reset,
        stall_i => stall,

        addr_o => mem0_addr_s,    --ok TODO: make the core 
        data_i => mem0_data_i_s,  --ok       accessing mem0
        data_o => mem0_data_o_s,  --ok       passing through
        data_w_o => mem0_data_w_s,--ok       the ni
        
        data_mode_o => data_mode_o_dummy,    

        extio_in => extio_in_dummy,
        extio_out => extio_out_dummy
    );
    
    -- main memory 
    -- @TODO: cpu cannot interact direct with mem0, must pass through the ni first
    mem0: entity work.ram(generic_ram)
    port map(
        clk => clock,
        addr_i => mem0_addr,
        data_i => mem0_data_i,
        data_o => mem0_data_o, 
        data_w => mem0_data_w          
    );
    
    mem1: entity work.ram(generic_ram) --recv
    port map(
        clk => clock,
        addr_i => mem0_addr,
        data_i => mem0_data_i,
        data_o => mem0_data_o, 
        data_w => mem0_data_w    
    );

    mem2: entity work.orca_ram(ram) --send
    port map(
        clk => clock,
        address => mem2_addr_o,
        enable => mem2_enable_dummy,
        wbe => mem2_wbe_dummy,
        data_write => mem2_data_i 
    );
    
   dma: entity work.orca_dma(ni)
      port map(
         clock => clock,
         reset => reset,
         
         -- mem0 if
         mem0_address_i => mem0_addr_o,
         mem0_enable_i => mem0_enable_dummy,
         mem0_wbe_i   => mem0_wbe_dummy,
         mem0_data_write => mem0_data_w_o,
         mem0_data_read => mem0_data_o,    
              
         mem1_address_i => mem1_addr_o,
         mem1_enable_i => mem1_enable_dummy,
         mem1_wbe_i   => mem1_wbe_dummy,
         mem1_data_write => mem1_data_w_o,
         mem1_data_read => mem1_data_o,    
          
         mem2_address_i => mem2_addr_o,
         mem2_enable_i => mem2_enable_dummy,
         mem2_wbe_i   => mem2_wbe_dummy,
         mem2_data_write => mem2_data_w_o,
         mem2_data_read => mem2_data_o,    
                  
         -- local port binding
         clock_tx => clock_tx_dummy(LOCAL),
         tx => tx_dummy(LOCAL), 
         data_out => data_out_dummy(LOCAL),
         credit_in => credit_i_dummy(LOCAL),

         clock_rx => clock_rx_dummy(LOCAL),
         rx => rx_dummy(LOCAL),
         data_in => data_in_dummy(LOCAL),
         credit_out => credit_o_dummy(LOCAL)
    );


    router: entity work.hermes_router(hermes_router)
    
    port map(
        clock => clock, 
        reset => reset,
        clock_rx => clock_rx_dummy,
        rx => rx_dummy,
        data_in => data_in_dummy,
        credit_o => credit_o_dummy,    
        clock_tx => clock_tx_dummy,
        tx => tx_dummy,
        data_out => data_out_dummy,
        credit_i => credit_i_dummy
    );

end orca_processing_tile;
