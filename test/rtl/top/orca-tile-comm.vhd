library ieee;

use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;
use work.orca_defaults.all;

entity orca_communication_tile is

  --parameters come from the top level rtl (naming consistency
  --is preserved for all rtl files).
  generic (
    R_ADDRESS : regmetadeflit := x"0000" --address
  );

  port(
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
    read : in std_logic;

    -- NOC INTERFACE

    clock_rx: in  regNportLONE;
    rx      : in  regNportLONE;
    data_i  : in  arrayNport_regflitLONE;
    credit_o: out regNportLONE;

    clock_tx: out regNportLONE;
    tx      : out regNportLONE;
    data_o  : out arrayNport_regflitLONE;
    credit_i: in regNportLONE

  );

end orca_communication_tile;

architecture orca_communication_tile of orca_communication_tile is

  -- Memory interfaces
  signal sm_addr_i : std_logic_vector((RAM_WIDTH - 1) downto 0);
  signal sm_data_o : std_logic_vector((RAM_WIDTH - 1) downto 0);
  signal sm_data_i : std_logic_vector((RAM_WIDTH - 1) downto 0);
  signal sm_wb_i   : std_logic_vector(3 downto 0);
  signal sc_addr_i : std_logic_vector((RAM_WIDTH - 1) downto 0);
  signal sc_addr_o : std_logic_vector((RAM_WIDTH - 1) downto 0);
  signal sc_data_o : std_logic_vector((RAM_WIDTH - 1) downto 0);
  signal sc_data_i : std_logic_vector((RAM_WIDTH - 1) downto 0);
  signal sc_wb_i   : std_logic_vector(3 downto 0);
  signal sc_wb_o   : std_logic_vector(3 downto 0);
  signal rm_addr_i : std_logic_vector((RAM_WIDTH - 1) downto 0);
  signal rm_data_o : std_logic_vector((RAM_WIDTH - 1) downto 0);
  signal rm_data_i : std_logic_vector((RAM_WIDTH - 1) downto 0);
  signal rm_wb_i   : std_logic_vector(3 downto 0);
  signal rc_addr_i : std_logic_vector((RAM_WIDTH - 1) downto 0);
  signal rc_addr_o : std_logic_vector((RAM_WIDTH - 1) downto 0);
  signal rc_data_o : std_logic_vector((RAM_WIDTH - 1) downto 0);
  signal rc_data_i : std_logic_vector((RAM_WIDTH - 1) downto 0);
  signal rc_wb_i   : std_logic_vector(3 downto 0);
  signal rc_wb_o   : std_logic_vector(3 downto 0);

  signal rlff1, rst_local : std_logic;
  
  signal s_intr : std_logic;

  -- router i/f
  signal r_clock_rx : regNport;
  signal r_rx       : regNport;
  signal r_data_i   : arrayNport_regflit;
  signal r_credit_o : regNport;

  signal r_clock_tx : regNport;
  signal r_tx       : regNport;
  signal r_data_o   : arrayNport_regflit;
  signal r_credit_i : regNport;

begin

  intr <= s_intr;

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


 -- send memory binding
  send_tile_mem_binding: entity work.single_port_ram
    generic map(
      RAM_WIDTH_I => RAM_WIDTH,
      RAM_DEPTH_I => SEND_NODE_RAM_DEPTH
    )
    port map(
        clk => clk,
        rst => rst_local,

        addr_i => sm_addr_i,
        data_o => sm_data_o,
        data_i => sm_data_i,
        wb_i => sm_wb_i
    );

    -- send memory mux
    sm_addr_i <= sc_addr_o when send = '1' else send_addr_i;
    sm_data_i <= send_data_i;
    sm_wb_i <= sc_wb_o when send = '1' else send_wb_i;
    sc_data_i <= sm_data_o;
    send_data_o <= sm_data_o;
    

  --sender mod binding
  comm_sender_mod: entity work.orca_comm_send
    port map(
      clk  => clk,
      rst  => rst_local,
      send => send,
      sent => sent,

      m_data_i => sc_data_i,
      m_addr_o => sc_addr_o,
      m_wb_o => sc_wb_o,

      r_credit_i => r_credit_i(LOCAL),
      r_tx => r_tx(LOCAL),
      r_data_o => r_data_o(LOCAL),
      r_clock_tx => r_clock_tx(LOCAL)
    );

 -- recv memory binding
  recv_tile_mem_binding: entity work.single_port_ram
    generic map(
      RAM_WIDTH_I => RAM_WIDTH,
      RAM_DEPTH_I => RECV_NODE_RAM_DEPTH
    )
    port map(
        clk => clk,
        rst => rst_local,

        addr_i => rm_addr_i,
        data_o => rm_data_o,
        data_i => rm_data_i,
        wb_i => rm_wb_i
    );

    -- recv memory mux
    rm_addr_i <= rc_addr_o when s_intr = '0' else recv_addr_i;
    rm_data_i <= rc_data_o when s_intr = '0' else recv_data_i;
    rm_wb_i <= rc_wb_o when s_intr = '0' else recv_wb_i;
    recv_data_o <= rm_data_o;

    
  --recv mod binding
  comm_recv_mod: entity work.orca_comm_recv
    port map(
      clk  => clk,
      rst  => rst_local,
      intr => s_intr,
      read => read,

      m_data_o => rc_data_o,
      m_addr_o => rc_addr_o,
      m_wb_o => rc_wb_o,

      r_credit_o => r_credit_o(LOCAL),
      r_rx => r_rx(LOCAL),
      r_data_i => r_data_i(LOCAL),
      r_clock_rx => r_clock_rx(LOCAL)
    );

end orca_communication_tile;
