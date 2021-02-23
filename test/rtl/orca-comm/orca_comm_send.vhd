library ieee;

use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use work.orca_defaults.all;

entity orca_comm_send is

  port(
    clk : in std_logic;
    rst : in std_logic;
    send : in std_logic; -- send flag from ARM
    sent : out std_logic; -- sent flag to ARM

    -- interface to the memory mux (data_o is supressed)
    m_data_i :  in std_logic_vector((RAM_WIDTH - 1) downto 0);
    m_addr_o : out std_logic_vector((RAM_WIDTH - 1) downto 0);
    m_wb_o   : out std_logic_vector(3 downto 0);

    -- router interface (transmiting)
    r_clock_tx  : out std_logic; 
    r_tx        : out std_logic;
    r_data_o    : out std_logic_vector(TAM_FLIT-1 downto 0);
    r_credit_i  : in std_logic

  );

end orca_comm_send;

architecture orca_comm_send of orca_comm_send is

  type comm_send_state_type is (
    S_WAIT_PACKAGE,
    S_SEND_HEADER,
    S_SEND_SIZE,
    S_SEND_PAYLOAD,
    S_WAIT_FLAG
  );

  --storage for both machine states
  signal comm_send_state : comm_send_state_type;

  --temporary data
  signal send_copy_addr : std_logic_vector(31 downto 0);
  signal send_copy_size : std_logic_vector(31 downto 0);

begin

  -- transmitting clock stays the same as for the ni
  r_clock_tx <= clk;

  -- mem interface
  r_data_o <= m_data_i;
  m_wb_o <= (others => '0');

  -- send proc, state control
  comm_send_state_control_proc: process(clk, rst)
  begin
    if rst = '1' then
        comm_send_state <= S_WAIT_PACKAGE;
    elsif rising_edge(clk) then
      case comm_send_state is
        when S_WAIT_PACKAGE => 
          if send = '1' then
            comm_send_state <= S_SEND_HEADER;
          end if;
        when S_SEND_HEADER =>
          if r_credit_i = '1' then
            comm_send_state <= S_SEND_SIZE;
          end if;
        when S_SEND_SIZE =>
          if r_credit_i = '1' then
            comm_send_state <= S_SEND_PAYLOAD;
          end if;
        when S_SEND_PAYLOAD =>
          if send_copy_size = send_copy_size'low and r_credit_i = '1' then
            comm_send_state <= S_WAIT_FLAG;
          end if;
	when S_WAIT_FLAG =>
          if send = '0' then
            comm_send_state <= S_WAIT_PACKAGE;
          end if;
      end case;
    end if;
  end process;
  
  -- send proc, machine functioning
  comm_send_machine_func_proc: process(clk, rst)
  begin
    if rst = '1' then
      send_copy_addr <= (others => '0');
      send_copy_size <= (others => '0');
      r_tx <= '0';
    elsif rising_edge(clk) then
      case comm_send_state is 
        when S_WAIT_PACKAGE =>
          send_copy_addr <= (others => '0');
          sent <= '0';
          if send = '1' then
            r_tx <= '1';
          end if;
        when S_SEND_HEADER =>
          if r_credit_i = '1' then
            send_copy_addr <= send_copy_addr + 4;
          end if;
        when S_SEND_SIZE =>
          send_copy_size <= m_data_i;
          if r_credit_i = '1' then
            send_copy_addr <= send_copy_addr + 4;
          end if;
        when S_SEND_PAYLOAD => --copy from memory to the output buffer
          if r_credit_i = '1' then
            send_copy_size <= send_copy_size - 1;
            send_copy_addr <= send_copy_addr + 4;
            if send_copy_size = send_copy_size'low then
              r_tx <= '0';
              sent <= '1';
            end if;
          end if;
        when S_WAIT_FLAG =>
      end case; 
    end if;	
  end process;

end orca_comm_send;
