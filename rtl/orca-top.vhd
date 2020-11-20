library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;
use work.orca_defaults.all;

entity orca_top is
  port (
    clk   : in std_logic;
    rst_n : in std_logic;
    
    -- LOCAL PORT INTERFACE
    -- AXI-Stream slave interface 
    --clock_rx_local:  in  std_logic;
    --rx_local:        in  std_logic;
    --data_in_local:   in  std_logic_vector(TAM_FLIT-1 downto 0);
    --credit_o_local:  out std_logic;
    validS_i:        in  std_logic;
    -- the last port is not required for slave interfaces
    --lastS_i:         in  std_logic;
    dataS_i:         in  std_logic_vector(TAM_FLIT-1 downto 0);
    readyS_o:        out std_logic;
    -- AXI-Stream master interface 
    --clock_tx_local:  out std_logic;
    --tx_local:        out std_logic;
    --data_out_local:  out std_logic_vector(TAM_FLIT-1 downto 0);
    --credit_i_local:  in  std_logic
    lastM_o:         out std_logic;
    validM_o:        out std_logic;
    dataM_o:         out std_logic_vector(TAM_FLIT-1 downto 0);
    readyM_i:        in  std_logic
  );

end orca_top;

architecture orca_top of orca_top is

  ATTRIBUTE X_INTERFACE_INFO : STRING;
  
  ATTRIBUTE X_INTERFACE_INFO OF clk: SIGNAL IS "xilinx.com:signal:clock:1.0 M CLK";
  ATTRIBUTE X_INTERFACE_INFO OF rst_n: SIGNAL IS "xilinx.com:signal:reset:1.0 AXI_RESETN RST";  
  
  -- ATTRIBUTE X_INTERFACE_INFO of <port-name>: SIGNAL is "xilinx.com:interface:axis:1.0 <interface_name> <AXIS-port-type>";
  ATTRIBUTE X_INTERFACE_INFO of dataS_i: SIGNAL is "xilinx.com:interface:axis:1.0 S TDATA";
  --ATTRIBUTE X_INTERFACE_INFO of <s_tlast>: SIGNAL is "xilinx.com:interface:axis:1.0 S TLAST";
  ATTRIBUTE X_INTERFACE_INFO of validS_i: SIGNAL is "xilinx.com:interface:axis:1.0 S TVALID";
  ATTRIBUTE X_INTERFACE_INFO of readyS_o: SIGNAL is "xilinx.com:interface:axis:1.0 S TREADY";

  ATTRIBUTE X_INTERFACE_INFO of dataM_o: SIGNAL is "xilinx.com:interface:axis:1.0 M TDATA";
  ATTRIBUTE X_INTERFACE_INFO of lastM_o: SIGNAL is "xilinx.com:interface:axis:1.0 M TLAST";
  ATTRIBUTE X_INTERFACE_INFO of validM_o: SIGNAL is "xilinx.com:interface:axis:1.0 M TVALID";
  ATTRIBUTE X_INTERFACE_INFO of readyM_i: SIGNAL is "xilinx.com:interface:axis:1.0 M TREADY";

  -- Uncomment the following to set interface specific parameter on the bus interface.
  --  ATTRIBUTE X_INTERFACE_PARAMETER : STRING;
  --  ATTRIBUTE X_INTERFACE_PARAMETER of <port_name>: SIGNAL is "CLK_DOMAIN <value>,PHASE <value>,FREQ_HZ <value>,LAYERED_METADATA <value>,HAS_TLAST <value>,HAS_TKEEP <value>,HAS_TSTRB <value>,HAS_TREADY <value>,TUSER_WIDTH <value>,TID_WIDTH <value>,TDEST_WIDTH <value>,TDATA_NUM_BYTES <value>";

  ATTRIBUTE X_INTERFACE_PARAMETER : STRING;
  ATTRIBUTE X_INTERFACE_PARAMETER OF clk: SIGNAL IS "XIL_INTERFACENAME aclk_CLOCK, FREQ_HZ 50000000, ASSOCIATED_BUSIF M:S";
  ATTRIBUTE X_INTERFACE_PARAMETER OF rst_n: SIGNAL IS "XIL_INTERFACENAME AXIS_CONTROL_RESET, POLARITY ACTIVE_LOW";

  -- Interconnection signals 
  type txNport is array (NUMBER_PROCESSORS - 1 downto 0) of std_logic_vector(3 downto 0);
  signal tx : txNPORT;
  type rxNport is array (NUMBER_PROCESSORS - 1 downto 0) of std_logic_vector(3 downto 0);
  signal rx : rxNPORT;
  type clock_rxNport is array (NUMBER_PROCESSORS - 1 downto 0) of std_logic_vector(3 downto 0);
  signal clock_rx : clock_rxNPORT;
  type clock_txNport is array (NUMBER_PROCESSORS - 1 downto 0) of std_logic_vector(3 downto 0);
  signal clock_tx : clock_txNPORT;
  type credit_iNport is array (NUMBER_PROCESSORS - 1 downto 0) of std_logic_vector(3 downto 0);
  signal credit_i : credit_iNPORT;
  type credit_oNport is array (NUMBER_PROCESSORS - 1 downto 0) of std_logic_vector(3 downto 0);
  signal credit_o : credit_oNPORT;
  type data_inNport is array (NUMBER_PROCESSORS - 1 downto 0) of arrayNport_regflitLONE;
  signal data_in : data_inNPORT;
  type data_outNport is array (NUMBER_PROCESSORS - 1 downto 0) of arrayNport_regflitLONE;
  signal data_out       : data_outNPORT;
  signal address_router : regmetadeflit;
  type router_position is array (NUMBER_PROCESSORS - 1 downto 0) of integer range 0 to TR;
  signal position : router_position;


  -- Specific to Node 00 (local port)
  signal clock_rx_00 : regNport;
  signal rx_00 : regNport;
  signal data_in_00 : arrayNport_regflit;
  signal credit_o_00 : regNport;    
  signal clock_tx_00 : regNport;
  signal tx_00 : regNport;
  signal data_out_00 : arrayNport_regflit;
  signal credit_i_00 : regNport;

  -- reset synchornizer
  --signal rff1,rst_sync : std_logic;
  signal rst : std_logic;


--attribute KEEP : string;
--attribute MARK_DEBUG : string;
--
--attribute KEEP of  EA : signal is "TRUE";
--attribute MARK_DEBUG of EA  : signal is "TRUE";

begin

  -- ARM uses active low reset
  rst <= not rst_n;

  -- process (clk, rst)
  -- begin
  --   if (rst = '1') then
  --     rff1 <= '1';
  --     rst_sync <= '1';
  --   elsif (clk'event and clk = '1') then
  --     rff1 <= '0';
  --     rst_sync <= rff1;
  --   end if;
  -- end process;

  router_binding : entity work.RouterCC
    generic map(
      address => RouterAddress(0)
    )
    port map(
      clock => clk,
      --reset => rst_sync,
      reset => rst,

    clock_rx => clock_rx_00,
    rx => rx_00,
    data_in => data_in_00,
    credit_o => credit_o_00,

    clock_tx => clock_tx_00,
    tx => tx_00,
    data_out => data_out_00,
    credit_i => credit_i_00
    );

  --clock_rx_00(LOCAL) <= clock_rx_local;
  clock_rx_00(LOCAL) <= clk;
  --rx_00(LOCAL)       <= rx_local;
  rx_00(LOCAL)       <= validS_i;
  --data_in_00(LOCAL)  <= data_in_local;
  data_in_00(LOCAL)  <= dataS_i;
  --credit_o_local     <= credit_o_00(LOCAL);
  readyS_o           <= credit_o_00(LOCAL);
  --clock_tx_local     <= clock_tx_00(LOCAL);
  --tx_local           <= tx_00(LOCAL);
  --data_out_local     <= data_out_00(LOCAL);
  --credit_i_00(LOCAL) <= credit_i_local;
  -- these 3 signals are replaced by the 'last_gen' module to generate the AXI master tlast port
  --validM_o           <= tx_00(LOCAL);
  --dataM_o            <= data_out_00(LOCAL);
  --credit_i_00(LOCAL) <= readyM_i;

  -- these module stays between the AXI Master port an the external orca-top inteface
  last_Local: Entity work.last_gen
  port map(
          clock   => clk,  
          reset   => rst,
          -- these go the external side of the local port 
          validL_o=> validM_o,
          lastL_o => lastM_o,
          dataL_o => dataM_o,
          readyL_i=> readyM_i,
          -- these go to the internal side of the router 
          valid_i => tx_00(LOCAL),
          data_i  => data_out_00(LOCAL),
          ready_o => credit_i_00(LOCAL)
  );




  clock_rx_00(NORTH) <= clock_rx(0)(NORTH);
  rx_00(NORTH)       <= rx(0)(NORTH);
  data_in_00(NORTH)  <= data_in(0)(NORTH);
  credit_o(0)(NORTH) <= credit_o_00(NORTH);    
  clock_tx(0)(NORTH) <= clock_tx_00(NORTH);
  tx(0)(NORTH)       <= tx_00(NORTH);
  data_out(0)(NORTH) <= data_out_00(NORTH);
  credit_i_00(NORTH) <= credit_i(0)(NORTH);  

  clock_rx_00(SOUTH) <= clock_rx(0)(SOUTH);
  rx_00(SOUTH)       <= rx(0)(SOUTH);
  data_in_00(SOUTH)  <= data_in(0)(SOUTH);
  credit_o(0)(SOUTH) <= credit_o_00(SOUTH);    
  clock_tx(0)(SOUTH) <= clock_tx_00(SOUTH);
  tx(0)(SOUTH)       <= tx_00(SOUTH);
  data_out(0)(SOUTH) <= data_out_00(SOUTH);
  credit_i_00(SOUTH) <= credit_i(0)(SOUTH);  

  clock_rx_00(EAST) <= clock_rx(0)(EAST);
  rx_00(EAST)       <= rx(0)(EAST);
  data_in_00(EAST)  <= data_in(0)(EAST);
  credit_o(0)(EAST) <= credit_o_00(EAST);    
  clock_tx(0)(EAST) <= clock_tx_00(EAST);
  tx(0)(EAST)       <= tx_00(EAST);
  data_out(0)(EAST) <= data_out_00(EAST);
  credit_i_00(EAST) <= credit_i(0)(EAST);  

  clock_rx_00(WEST) <= clock_rx(0)(WEST);
  rx_00(WEST)       <= rx(0)(WEST);
  data_in_00(WEST)  <= data_in(0)(WEST);
  credit_o(0)(WEST) <= credit_o_00(WEST);    
  clock_tx(0)(WEST) <= clock_tx_00(WEST);
  tx(0)(WEST)       <= tx_00(WEST);
  data_out(0)(WEST) <= data_out_00(WEST);
  credit_i_00(WEST) <= credit_i(0)(WEST);  


    north_grounding_00: if RouterPosition(0) = TL or RouterPosition(0) = TC or RouterPosition(0) = TR or NUMBER_PROCESSORS_Y = 1 generate
      rx(0)(NORTH)            <= '0';
      clock_rx(0)(NORTH)      <= '0';
      credit_i(0)(NORTH)      <= '0';
      data_in(0)(NORTH)       <= (others => '0');
    end generate;

    north_connection_00: if (RouterPosition(0) = BL or RouterPosition(0) = BC or RouterPosition(0) = BR or RouterPosition(0) = CL or RouterPosition(0) = CRX or RouterPosition(0) = CC) and NUMBER_PROCESSORS_Y /= 1 generate
      rx(0)(NORTH)            <= tx(0+NUMBER_PROCESSORS_X)(SOUTH);
      clock_rx(0)(NORTH)      <= clock_tx(0+NUMBER_PROCESSORS_X)(SOUTH);
      credit_i(0)(NORTH)      <= credit_o(0+NUMBER_PROCESSORS_X)(SOUTH);
      data_in(0)(NORTH)       <= data_out(0+NUMBER_PROCESSORS_X)(SOUTH);
    end generate;

    east_grounding_00: if RouterPosition(0) = BR or RouterPosition(0) = CRX or RouterPosition(0) = TR or NUMBER_PROCESSORS_X = 1 generate
      rx(0)(EAST)             <= '0';
      clock_rx(0)(EAST)       <= '0';
      credit_i(0)(EAST)       <= '0';
      data_in(0)(EAST)        <= (others => '0');
    end generate;

    east_connection_00: if (RouterPosition(0) = BL or RouterPosition(0) = CL or RouterPosition(0) = TL  or RouterPosition(0) = BC or RouterPosition(0) = TC or RouterPosition(0) = CC) and NUMBER_PROCESSORS_X /= 1 generate
      rx(0)(EAST)             <= tx(0+1)(WEST);
      clock_rx(0)(EAST)       <= clock_tx(0+1)(WEST);
      credit_i(0)(EAST)       <= credit_o(0+1)(WEST);
      data_in(0)(EAST)        <= data_out(0+1)(WEST);
    end generate;


  rx(0)(SOUTH)       <= '0';
  clock_rx(0)(SOUTH) <= '0';
  credit_i(0)(SOUTH) <= '0';
  data_in(0)(SOUTH)  <= (others => '0');
  rx(0)(WEST)        <= '0';
  clock_rx(0)(WEST)  <= '0';
  credit_i(0)(WEST)  <= '0';
  data_in(0)(WEST)   <= (others => '0');

  proc: for i in 1 to NUMBER_PROCESSORS-1 generate
    orca_tile: entity work.orca_processing_tile
    generic map (
      R_ADDRESS => RouterAddress(i)
    )
    port map(
      clk      => clk,
      rst      => rst,
      -- NoC
      clock_tx => clock_tx(i),
      tx       => tx(i),
      data_o => data_out(i),
      credit_i => credit_i(i),
      clock_rx => clock_rx(i),
      rx       => rx(i),
      data_i  => data_in(i),
      credit_o => credit_o(i)                        
    );
                
    ------------------------------------------------------------------------------
    --- EAST PORT CONNECTIONS ----------------------------------------------------
    ------------------------------------------------------------------------------
    east_grounding: if RouterPosition(i) = BR or RouterPosition(i) = CRX or RouterPosition(i) = TR or NUMBER_PROCESSORS_X = 1 generate
      rx(i)(EAST)             <= '0';
      clock_rx(i)(EAST)       <= '0';
      credit_i(i)(EAST)       <= '0';
      data_in(i)(EAST)        <= (others => '0');
    end generate;

    east_connection: if (RouterPosition(i) = BL or RouterPosition(i) = CL or RouterPosition(i) = TL  or RouterPosition(i) = BC or RouterPosition(i) = TC or RouterPosition(i) = CC) and NUMBER_PROCESSORS_X /=1 generate
      rx(i)(EAST)             <= tx(i+1)(WEST);
      clock_rx(i)(EAST)       <= clock_tx(i+1)(WEST);
      credit_i(i)(EAST)       <= credit_o(i+1)(WEST);
      data_in(i)(EAST)        <= data_out(i+1)(WEST);
    end generate;

    ------------------------------------------------------------------------------
    --- WEST PORT CONNECTIONS ----------------------------------------------------
    ------------------------------------------------------------------------------
    west_grounding: if RouterPosition(i) = BL or RouterPosition(i) = CL or RouterPosition(i) = TL or NUMBER_PROCESSORS_X = 1 generate
      rx(i)(WEST)             <= '0';
      clock_rx(i)(WEST)       <= '0';
      credit_i(i)(WEST)       <= '0';
      data_in(i)(WEST)        <= (others => '0');
    end generate;

    west_connection: if (RouterPosition(i) = BR or RouterPosition(i) = CRX or RouterPosition(i) = TR or  RouterPosition(i) = BC or RouterPosition(i) = TC or RouterPosition(i) = CC) and NUMBER_PROCESSORS_X /= 1 generate
      rx(i)(WEST)             <= tx(i-1)(EAST);
      clock_rx(i)(WEST)       <= clock_tx(i-1)(EAST);
      credit_i(i)(WEST)       <= credit_o(i-1)(EAST);
      data_in(i)(WEST)        <= data_out(i-1)(EAST);
    end generate;

    -------------------------------------------------------------------------------
    --- NORTH PORT CONNECTIONS ----------------------------------------------------
    -------------------------------------------------------------------------------
    north_grounding: if RouterPosition(i) = TL or RouterPosition(i) = TC or RouterPosition(i) = TR or NUMBER_PROCESSORS_Y = 1 generate
      rx(i)(NORTH)            <= '0';
      clock_rx(i)(NORTH)      <= '0';
      credit_i(i)(NORTH)      <= '0';
      data_in(i)(NORTH)       <= (others => '0');
    end generate;

    north_connection: if (RouterPosition(i) = BL or RouterPosition(i) = BC or RouterPosition(i) = BR or RouterPosition(i) = CL or RouterPosition(i) = CRX or RouterPosition(i) = CC) and NUMBER_PROCESSORS_Y /= 1 generate
      rx(i)(NORTH)            <= tx(i+NUMBER_PROCESSORS_X)(SOUTH);
      clock_rx(i)(NORTH)      <= clock_tx(i+NUMBER_PROCESSORS_X)(SOUTH);
      credit_i(i)(NORTH)      <= credit_o(i+NUMBER_PROCESSORS_X)(SOUTH);
      data_in(i)(NORTH)       <= data_out(i+NUMBER_PROCESSORS_X)(SOUTH);
    end generate;

    --------------------------------------------------------------------------------
    --- SOUTH PORT CONNECTIONS -----------------------------------------------------
    ---------------------------------------------------------------------------
    south_grounding: if RouterPosition(i) = BL or RouterPosition(i) = BC or RouterPosition(i) = BR or NUMBER_PROCESSORS_Y = 1 generate
      rx(i)(SOUTH)            <= '0';
      clock_rx(i)(SOUTH)      <= '0';
      credit_i(i)(SOUTH)      <= '0';
      data_in(i)(SOUTH)       <= (others => '0');
    end generate;

    south_connection: if (RouterPosition(i) = TL or RouterPosition(i) = TC or RouterPosition(i) = TR or RouterPosition(i) = CL or RouterPosition(i) = CRX or RouterPosition(i) = CC) and NUMBER_PROCESSORS_Y /= 1 generate
      rx(i)(SOUTH)            <= tx(i-NUMBER_PROCESSORS_X)(NORTH);
      clock_rx(i)(SOUTH)      <= clock_tx(i-NUMBER_PROCESSORS_X)(NORTH);
      credit_i(i)(SOUTH)      <= credit_o(i-NUMBER_PROCESSORS_X)(NORTH);
      data_in(i)(SOUTH)       <= data_out(i-NUMBER_PROCESSORS_X)(NORTH);
    end generate;
  end generate proc;
end orca_top;
