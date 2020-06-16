library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;
use work.orca_defaults.all;

entity orca_top_v2 is
  port (
    clk : in std_logic;
    rst : in std_logic;
    
    -- LOCAL PORT INTERFACE
    clock_rx_local:  in  std_logic;
    rx_local:        in  std_logic;
    data_in_local:   in  std_logic_vector(TAM_FLIT-1 downto 0);
    credit_o_local:  out std_logic;    
    clock_tx_local:  out std_logic;
    tx_local:        out std_logic;
    data_out_local:  out std_logic_vector(TAM_FLIT-1 downto 0);
    credit_i_local:  in  std_logic
  );

end orca_top_v2;

architecture orca_top_v2 of orca_top_v2 is

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

		
  type repo_address_t is array (NUMBER_PROCESSORS - 1 downto 0) of std_logic_vector(29 downto 0);
  signal repo_address_sig 	: repo_address_t;
  signal repo_data_sig     	: arrayNPe_reg32;
  signal ack_app_sig        	: regNPe;
  signal req_app_sig     		: arrayNPe_reg32;

begin

  router_binding : entity work.RouterCC
    generic map(
      address => x"0000"
    )
    port map(
      clock => clk,
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

  clock_rx_00(LOCAL) <= clock_rx_local;
  rx_00(LOCAL)       <= rx_local;
  data_in_00(LOCAL)  <= data_in_local;
  credit_o_local     <= credit_o_00(LOCAL);    
  clock_tx_local     <= clock_tx_00(LOCAL);
  tx_local           <= tx_00(LOCAL);
  data_out_local     <= data_out_00(LOCAL);
  credit_i_00(LOCAL) <= credit_i_local;  

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
end orca_top_v2;
