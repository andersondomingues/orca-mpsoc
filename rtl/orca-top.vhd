library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;
use work.HeMPS_defaults.all;

entity orca_top is

  generic (
    RAM_WIDTH    : natural := 32;        --width of main memory word
    RAM_SIZE     : natural := 8388608; -- 4MB
    
    FLIT_WIDTH   : natural := 32;  --width of router word
    BUFFER_DEPTH : natural := 128; --size of internal buffer of recv proc
    PRELOAD_ADDR : natural := 0;   --address to preload first burst at

    S_INIT_MEM_ADDR : natural := 0; --base addres for memory
    R_INIT_MEM_ADDR : natural := 0; --base addres for memory

    S_MEM_DEPTH : natural := 2048; -- size of send comm buffer
    R_MEM_DEPTH : natural := 2048; -- size of recv comm buffer
  );

  port (
    clk : in std_logic;
    rst : in std_logic;
    
    -- ARM INTERFACE
    send_addr_i : in std_logic_vector(31 downto 0);
    send_data_o : out std_logic_vector(31 downto 0);
    send_data_i : in std_logic_vector(31 downto 0);
    send_wb_i : in std_logic_vector(3 downto 0);
    send : in std_logic;
    sent : out std_logic;

    recv_addr_i : in std_logic_vector(31 downto 0);
    recv_data_o : out std_logic_vector(31 downto 0);
    recv_data_i : in std_logic_vector(31 downto 0);
    recv_wb_i : in std_logic_vector(3 downto 0);
    intr : out std_logic;
    read : in std_logic
  );

end orca_top;

architecture orca_top of orca_top is

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
  type data_inNport is array (NUMBER_PROCESSORS - 1 downto 0) of arrayNPORT_1_regflit;
  signal data_in : data_inNPORT;
  type data_outNport is array (NUMBER_PROCESSORS - 1 downto 0) of arrayNPORT_1_regflit;
  signal data_out       : data_outNPORT;
  signal address_router : std_logic_vector(7 downto 0);
  type router_position is array (NUMBER_PROCESSORS - 1 downto 0) of integer range 0 to TR;
  signal position : router_position;
		
  type repo_address_t is array (NUMBER_PROCESSORS - 1 downto 0) of std_logic_vector(29 downto 0);
  signal repo_address_sig 	: repo_address_t;
  signal repo_data_sig     	: arrayNPe_reg32;
  signal ack_app_sig        	: regNPe;
  signal req_app_sig     		: arrayNPe_reg32;

begin

  comm_tile : entity work.orca_communication_tile
  generic map(
      RAM_WIDTH => RAM_WIDTH, --width of main memory word
      FLIT_WIDTH => FLIT_WIDTH,  --width of router word
      S_INIT_MEM_ADDR => S_INIT_MEM_ADDR, --base addres for memory
      R_INIT_MEM_ADDR => R_INIT_MEM_ADDR, --base addres for memory

      S_MEM_DEPTH => S_MEM_DEPTH, -- size of internal buffer
      R_MEM_DEPTH => R_MEM_DEPTH, -- size of internal buffer

      R_ADDRESS => x"0000" --address
    )
  port map(
    clk => clk,
    rst => rst,

    send_addr_i => send_addr_i,
    send_data_o => send_data_o,
    send_data_i => send_data_i,
    send_wb_i => send_wb_i,
    send => send,
    sent => sent,

    recv_addr_i => recv_addr_i,
    recv_data_o => recv_data_o,
    recv_data_i => recv_data_i,
    recv_wb_i => recv_wb_i,
    intr => intr,
    read => read,

    clock_rx => clock_rx(0),
    rx => rx(0),
    data_i => data_i(0),
    credit_o => credit_o(0),

    clock_tx => clock_tx(0),
    tx => tx(0),
    data_o => data_o(0),
    credit_i => credit_i(0)
  );

  rx(0)(NORTH)       <= tx(0+NUMBER_PROCESSORS_X)(SOUTH);
  clock_rx(0)(NORTH) <= clock_tx(0+NUMBER_PROCESSORS_X)(SOUTH);
  credit_i(0)(NORTH) <= credit_o(0+NUMBER_PROCESSORS_X)(SOUTH);
  data_in(0)(NORTH)  <= data_out(0+NUMBER_PROCESSORS_X)(SOUTH);
  rx(0)(SOUTH)       <= '0';
  clock_rx(0)(SOUTH) <= '0';
  credit_i(0)(SOUTH) <= '0';
  data_in(0)(SOUTH)  <= (others => '0');
  rx(0)(EAST)        <= tx(0+1)(WEST);
  clock_rx(0)(EAST)  <= clock_tx(0+1)(WEST);
  credit_i(0)(EAST)  <= credit_o(0+1)(WEST);
  data_in(0)(EAST)   <= data_out(0+1)(WEST);
  rx(0)(WEST)        <= '0';
  clock_rx(0)(WEST)  <= '0';
  credit_i(0)(WEST)  <= '0';
  data_in(0)(WEST)   <= (others => '0');

  proc: for i in 1 to NUMBER_PROCESSORS-1 generate
    orca_tile: entity work.orca_processing_tile
    generic map (
      RAM_WIDTH => RAM_WIDTH,
      RAM_SIZE => RAM_SIZE,
    
      FLIT_WIDTH => FLIT_WIDTH,
      BUFFER_DEPTH => BUFFER_DEPTH,
      PRELOAD_ADDR => PRELOAD_ADDR,
    
      R_ADDRESS => RouterAddress(i),
    )
    port map(
      clk      => clk,
      rst      => rst,
      -- NoC
      clock_tx => clock_tx(i),
      tx       => tx(i),
      data_out => data_out(i),
      credit_i => credit_i(i),
      clock_rx => clock_rx(i),
      rx       => rx(i),
      data_in  => data_in(i),
      credit_o => credit_o(i)                        
    );
                
    ------------------------------------------------------------------------------
    --- EAST PORT CONNECTIONS ----------------------------------------------------
    ------------------------------------------------------------------------------
    east_grounding: if RouterPosition(i) = BR or RouterPosition(i) = CRX or RouterPosition(i) = TR generate
      rx(i)(EAST)             <= '0';
      clock_rx(i)(EAST)       <= '0';
      credit_i(i)(EAST)       <= '0';
      data_in(i)(EAST)        <= (others => '0');
    end generate;

    east_connection: if RouterPosition(i) = BL or RouterPosition(i) = CL or RouterPosition(i) = TL  or RouterPosition(i) = BC or RouterPosition(i) = TC or RouterPosition(i) = CC generate
      rx(i)(EAST)             <= tx(i+1)(WEST);
      clock_rx(i)(EAST)       <= clock_tx(i+1)(WEST);
      credit_i(i)(EAST)       <= credit_o(i+1)(WEST);
      data_in(i)(EAST)        <= data_out(i+1)(WEST);
    end generate;

    ------------------------------------------------------------------------------
    --- WEST PORT CONNECTIONS ----------------------------------------------------
    ------------------------------------------------------------------------------
    west_grounding: if RouterPosition(i) = BL or RouterPosition(i) = CL or RouterPosition(i) = TL generate
      rx(i)(WEST)             <= '0';
      clock_rx(i)(WEST)       <= '0';
      credit_i(i)(WEST)       <= '0';
      data_in(i)(WEST)        <= (others => '0');
    end generate;

    west_connection: if (RouterPosition(i) = BR or RouterPosition(i) = CRX or RouterPosition(i) = TR or  RouterPosition(i) = BC or RouterPosition(i) = TC or RouterPosition(i) = CC) generate
      rx(i)(WEST)             <= tx(i-1)(EAST);
      clock_rx(i)(WEST)       <= clock_tx(i-1)(EAST);
      credit_i(i)(WEST)       <= credit_o(i-1)(EAST);
      data_in(i)(WEST)        <= data_out(i-1)(EAST);
    end generate;

    -------------------------------------------------------------------------------
    --- NORTH PORT CONNECTIONS ----------------------------------------------------
    -------------------------------------------------------------------------------
    north_grounding: if RouterPosition(i) = TL or RouterPosition(i) = TC or RouterPosition(i) = TR generate
      rx(i)(NORTH)            <= '0';
      clock_rx(i)(NORTH)      <= '0';
      credit_i(i)(NORTH)      <= '0';
      data_in(i)(NORTH)       <= (others => '0');
    end generate;

    north_connection: if RouterPosition(i) = BL or RouterPosition(i) = BC or RouterPosition(i) = BR or RouterPosition(i) = CL or RouterPosition(i) = CRX or RouterPosition(i) = CC generate
      rx(i)(NORTH)            <= tx(i+NUMBER_PROCESSORS_X)(SOUTH);
      clock_rx(i)(NORTH)      <= clock_tx(i+NUMBER_PROCESSORS_X)(SOUTH);
      credit_i(i)(NORTH)      <= credit_o(i+NUMBER_PROCESSORS_X)(SOUTH);
      data_in(i)(NORTH)       <= data_out(i+NUMBER_PROCESSORS_X)(SOUTH);
    end generate;

    --------------------------------------------------------------------------------
    --- SOUTH PORT CONNECTIONS -----------------------------------------------------
    ---------------------------------------------------------------------------
    south_grounding: if RouterPosition(i) = BL or RouterPosition(i) = BC or RouterPosition(i) = BR generate
      rx(i)(SOUTH)            <= '0';
      clock_rx(i)(SOUTH)      <= '0';
      credit_i(i)(SOUTH)      <= '0';
      data_in(i)(SOUTH)       <= (others => '0');
    end generate;

    south_connection: if RouterPosition(i) = TL or RouterPosition(i) = TC or RouterPosition(i) = TR or RouterPosition(i) = CL or RouterPosition(i) = CRX or RouterPosition(i) = CC generate
      rx(i)(SOUTH)            <= tx(i-NUMBER_PROCESSORS_X)(NORTH);
      clock_rx(i)(SOUTH)      <= clock_tx(i-NUMBER_PROCESSORS_X)(NORTH);
      credit_i(i)(SOUTH)      <= credit_o(i-NUMBER_PROCESSORS_X)(NORTH);
      data_in(i)(SOUTH)       <= data_out(i-NUMBER_PROCESSORS_X)(NORTH);
    end generate;
  end generate proc;
end orca_top;
