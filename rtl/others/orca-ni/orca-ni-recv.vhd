library ieee;

use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity orca_ni_recv is

  --parameters come from the top level rtl (naming consistency
  --is preserved for all rtl files).
  generic (
    RAM_WIDTH  : natural; --width of main memory word
    FLIT_WIDTH : natural;  --width of router word
    PRELOAD_ADDR : natural --base addres for memory preload
  );

  port(
    clk : in std_logic;
    rst : in std_logic;
    stall : out std_logic; -- holds the cpu and takes control on memory i/f
    -- load: in std_logic;    -- load next packet into main memory

    -- interface to the memory mux
    m_addr_o : out std_logic_vector((RAM_WIDTH - 1) downto 0);
    m_data_o : out std_logic_vector((RAM_WIDTH - 1) downto 0);
    m_wb_o   : out std_logic_vector(3 downto 0);

    -- interface with the receiving buffer (no fifo required)
    b_addr_o : out std_logic_vector((RAM_WIDTH - 1) downto 0);
    b_data_i :  in std_logic_vector((RAM_WIDTH - 1) downto 0);
    b_data_o : out std_logic_vector((RAM_WIDTH - 1) downto 0);
    b_wb_o   : out std_logic_vector(3 downto 0);

    -- router interface (receiving)
    r_clock_rx : in std_logic;
    r_rx       : in std_logic;
    r_data_i   : in std_logic_vector(FLIT_WIDTH downto 0);
    r_credit_o : out std_logic;

    -- dma programming (must be mapped into memory space)
    recv_start : in std_logic;
    recv_status : out std_logic_vector(31 downto 0);
    prog_address : in std_logic_vector(31 downto 0);
    prog_size    : in std_logic_vector(31 downto 0)
  );

end orca_ni_recv;

architecture orca_ni_recv of orca_ni_recv is

  -- typeing defs. 
  type recv_state_type is (

    -- preload means "put everything from the input into memory" 
    R_PRELOAD_WAIT, -- initial state, happens once as long as "load" stays low
    R_PRELOAD_SIZE, -- receive the second flit and stores burst lenght
    R_PRELOAD_COPY, -- copy raw data from input to the memory

    -- these states relate to usual ni functioning (recv-irq-release)
    R_WAIT_FLIT_ADDR, --wait for the leading flit (should have the address flit)
    R_WAIT_FLIT_SIZE, --wait for the second flit (should have burst size)
    R_WAIT_PAYLOAD,   --stays here until receiving data
    R_WAIT_CONFIG_STALL, --request a valid addres to copy data to (performed by software)
    R_COPY_RELEASE,   --stalls the cpu and copies data into memory, then releases the cpu
    R_FLUSH -- wait for the acknowledgement and goes back to WAIT_FLIT_ADDR
  );

  --storage for both machine states
  signal recv_state : recv_state_type;

  --temporary data
  signal recv_copy_addr : std_logic_vector(31 downto 0);
  signal recv_copy_size : std_logic_vector(31 downto 0);

begin

  -- recv proc, state control
  recv_state_control_proc: process(clk, rst) 
  begin 
  
    if rst = '1' then
      recv_state <= R_PRELOAD_WAIT;
    elsif rising_edge(clk) then

      case recv_state is 
      
        -- preload mode state machine 
        when R_PRELOAD_WAIT => --wait for a flit to appear at the input
          if r_rx = '1' then
            --recv_copy_addr <= PRELOAD_ADDR;
            recv_state <= R_PRELOAD_SIZE;
          end if;
        when R_PRELOAD_SIZE =>
          --recv_copy_size <= r_data_i; --second flit carries the size of the burst
          recv_state <= R_PRELOAD_COPY;
        when R_PRELOAD_COPY =>
          if recv_copy_size = recv_copy_size'low then
            recv_state <= R_WAIT_FLIT_ADDR;
          end if;
          
        -- driver mode state machine 
        when R_WAIT_FLIT_ADDR =>
          if r_rx = '1' then
            recv_state <= R_WAIT_FLIT_SIZE;
          end if;
        when R_WAIT_FLIT_SIZE => 
          if r_rx = '1' then
            recv_state <= R_WAIT_PAYLOAD;
          end if;
        when R_WAIT_PAYLOAD =>
          if recv_copy_size = x"0" then
            recv_state <= R_WAIT_CONFIG_STALL;
          end if;
        when R_WAIT_CONFIG_STALL =>
          if recv_start = '1' then
            recv_state <= R_COPY_RELEASE;
          end if;
        when R_COPY_RELEASE =>
          if recv_copy_size = x"0" then
            recv_state <= R_FLUSH;
          end if;
        when R_FLUSH =>
          if recv_start = '0' then
            recv_state <= R_WAIT_FLIT_ADDR;
          end if;

      end case;

    end if;
  end process;
  
  
  

end orca_ni_recv;
