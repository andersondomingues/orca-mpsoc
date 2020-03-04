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

architecture orca_ni of orca_ni_top is
  component orca_n
    generic (...);
    port (Clk, Rst: in std_logic;
          D: in std_logic_vector(3 downto 0);
          Rd : out std_logic;
          Q: out std_logic_vector(3 downto 0));
  end component;
begin
  u1: CompA generic map(...)
            port map(Clock, Reset, DIn, QOut);
  u2: CompA generic map(...)
            port map(Clk => Clock,
                     Rst => Reset,
                     D => DIn,
                     Rd => open,
                     Q(0) => QOut1,
                     Q(3 downto 1) => QOut2);
end Structure;
