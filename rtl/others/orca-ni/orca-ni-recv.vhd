library ieee;

use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity orca_ni_recv is

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

end orca_ni_recv;

architecture orca_ni_recv of orca_ni_recv is

  -- typeing defs. 
  type recv_state_type is (

    -- preload means "put everything from the input into memory" 
    R_WAIT_PRELOAD,  -- initial state, happens once as long as "load" stays low
    R_PRELOAD_WRITE, -- copy raw data from input to the memory

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

begin

  -- recv proc, state control
  --recv_state_control_proc: process(clk, rst) 
  --begin 
  
  --  if rising_edge(clk) then 

  --    if rst = rst'high then
  --      recv_state <= R_WAIT_PRELOAD;  -- preload is the default action at the startup
  --    elsif recv_state = R_WAIT_PRELOAD then
      
  --    elsif recv_state = R_PRELOAD_WRITE then
      
  --    elsif 

  --    end if;
      
  --  end if; --clk
  
  --end process;
  
  recv_state <= R_COPY_RELEASE;

end orca_ni_recv;
