library ieee;

use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity orca_comm_recv is

  --parameters come from the top level rtl (naming consistency
  --is preserved for all rtl files).
  generic (
    RAM_WIDTH  : natural; --width of main memory word
    FLIT_WIDTH : natural;  --width of router word
    INIT_MEM_ADDR : natural --base addres for memory
  );

  port(
    clk : in std_logic;
    rst : in std_logic;
    intr  : out std_logic; -- interruption flag
    read : in std_logic; -- read flag

    -- interface to the memory mux
    m_addr_o : out std_logic_vector((RAM_WIDTH - 1) downto 0);
    m_data_o : out std_logic_vector((RAM_WIDTH - 1) downto 0);
    m_wb_o   : out std_logic_vector(3 downto 0);

    -- router interface (receiving)
    r_clock_rx : in std_logic;
    r_rx       : in std_logic;
    r_data_i   : in std_logic_vector((FLIT_WIDTH - 1) downto 0);
    r_credit_o : out std_logic

  );

end orca_comm_recv;

architecture orca_comm_recv of orca_comm_recv is

  -- typeing defs. 
  type comm_recv_state_type is (

    R_WAIT_HEADER, 
    R_WAIT_SIZE,
    R_WAIT_PAYLOAD,
    R_WAIT_FLUSH,
    R_WAIT_FLUSH_FLAG
  );

  --storage for both machine states
  signal comm_recv_state : comm_recv_state_type;

  --temporary data
  signal recv_copy_addr : std_logic_vector(31 downto 0);
  signal recv_copy_size : std_logic_vector(31 downto 0);
  
begin

  m_addr_o <= recv_copy_addr;
  m_data_o <= r_data_i;

  -- comm recv proc, state control
  comm_recv_state_control_proc: process(clk, rst) 
  begin 
  
    if rst = '1' then
      comm_recv_state <= R_WAIT_HEADER;
    elsif rising_edge(clk) then
      case comm_recv_state is 
	when R_WAIT_HEADER =>
          if r_rx = '1' then
             comm_recv_state <= R_WAIT_SIZE;
          end if;
        when R_WAIT_SIZE =>
          if r_rx = '1' then
             comm_recv_state <= R_WAIT_PAYLOAD;
          end if;
        when R_WAIT_PAYLOAD =>
          if recv_copy_size = recv_copy_size'low then
             comm_recv_state <= R_WAIT_FLUSH;
          end if;
        when R_WAIT_FLUSH =>
          if read = '1' then
             comm_recv_state <= R_WAIT_FLUSH_FLAG;
          end if;
        when R_WAIT_FLUSH_FLAG =>
          if read = '0' then
             comm_recv_state <= R_WAIT_HEADER;
          end if; 
        end case;
    end if;
  end process;
  
  -- functional implementation
  comm_recv_machine_funct: process(clk, rst) 
  begin 
    if rst = '1' then
      recv_copy_addr <= conv_std_logic_vector(INIT_MEM_ADDR, 32);
      recv_copy_size <= (others => '0'); 
      r_credit_o <= '1'; 
      m_wb_o <= (others => '1'); 
      intr <= '0'; 
    elsif rising_edge(clk) then
      case comm_recv_state is 
        when R_WAIT_HEADER => 
          intr <= '0';
          r_credit_o <= '1';
          m_wb_o <= x"1";
          if r_rx = '1' then
             recv_copy_addr <= recv_copy_addr + 4;
          end if;
        when R_WAIT_SIZE =>
          if r_rx = '1' then 
            recv_copy_size <= r_data_i;
            recv_copy_addr <= recv_copy_addr + 4;
          end if;
        when R_WAIT_PAYLOAD =>
          if r_rx = '1' then
            recv_copy_size <= recv_copy_size - 1;
            recv_copy_addr <= recv_copy_addr + 4; -- << care mem. width!
          end if ;
        when R_WAIT_FLUSH =>
          m_wb_o <= x"0";
          intr <= '1';
          r_credit_o <= '0';
	when R_WAIT_FLUSH_FLAG =>
          intr <= '0';
          recv_copy_addr <= conv_std_logic_vector(INIT_MEM_ADDR, 32);
          recv_copy_size <= (others => '0');
          if read = '0' then
            m_wb_o <= x"1";
            r_credit_o <= '1';
          end if;
        end case;
    end if;  
  end process;

end orca_comm_recv;
