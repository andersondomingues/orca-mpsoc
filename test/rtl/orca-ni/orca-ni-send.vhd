library ieee;

use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use work.orca_defaults.all;

entity orca_ni_send is

  port(
    clk : in std_logic;
    rst : in std_logic;
    stall : out std_logic; -- holds the cpu and takes control on memory i/f

    -- interface to the memory mux (data_o is supressed)
    m_data_i :  in std_logic_vector((RAM_WIDTH - 1) downto 0);
    m_addr_o : out std_logic_vector((RAM_WIDTH - 1) downto 0);
    m_wb_o   : out std_logic_vector(3 downto 0);

    -- router interface (transmiting)
    r_clock_tx  : out std_logic; 
    r_tx        : out std_logic;
    r_data_o    : out std_logic_vector(TAM_FLIT-1 downto 0);
    r_credit_i  : in std_logic;

    -- dma programming (must be mapped into memory space)
    send_start : in std_logic;
    prog_address : in std_logic_vector((RAM_WIDTH - 1) downto 0);
    prog_size    : in std_logic_vector((RAM_WIDTH - 1) downto 0);
    send_status : out std_logic
  );

end orca_ni_send;

architecture orca_ni_send of orca_ni_send is

  -- sends is NOT the same as in ORCA-SIM as we skip output buffering and push 
  -- data directly to the router's buffer
  type send_state_type is (
    S_WAIT_CONFIG_STALL, --wait for the software to configure the dma
    S_CONFIG_STALL,      --stalls cpu and set internal signals 
    S_COPY_AND_RELEASE,  --push data into router's input buffer
    S_FLUSH              --wait for the acknowledgement and goes back to WAIT_CONFIG_STALL
  );

  --storage for both machine states
  signal send_state : send_state_type;

  --temporary data
  signal send_copy_addr, send_copy_addr_dly : std_logic_vector((RAM_WIDTH - 1) downto 0);
  signal send_copy_size : std_logic_vector((RAM_WIDTH - 1) downto 0);
  signal previous_data : std_logic_vector((RAM_WIDTH - 1) downto 0);
  signal r_stall, credit_i_dly : std_logic;

begin

  -- transmitting clock stays the same as for the ni
  r_clock_tx <= clk;

process(clk, rst)
  begin
    if rst = '1' then
        credit_i_dly <= '0';
    elsif rising_edge(clk) then
        credit_i_dly <= r_credit_i;
    end if;
end process;


  -- send proc, state control
  send_state_control_proc: process(clk, rst)
  begin

	if rst = '1' then
        send_state <= S_WAIT_CONFIG_STALL;
    elsif rising_edge(clk) then

      case send_state is
        when S_WAIT_CONFIG_STALL => --  software programs the dma
          if send_start = '1' then
            send_state <= S_CONFIG_STALL;
          end if;
        when S_CONFIG_STALL => --stays for one cycle
          send_state <= S_COPY_AND_RELEASE;
        when S_COPY_AND_RELEASE =>  -- all flits have been copied
          if send_copy_size = send_copy_size'low and r_credit_i = '1' then
            send_state <= S_FLUSH;
          end if;
        when S_FLUSH =>
          if send_start = '0' then -- change states on acknowledgement
            send_state <= S_WAIT_CONFIG_STALL;
          end if;
      end case; --send state
    
    end if; -- clk
    
  end process;
  
  -- send proc, machine functioning
  send_machine_func_proc: process(clk,rst)
  begin
    if rst = '1' then
      send_status <= '0';
      r_stall <= '0'; --start with the cpu on control
      send_copy_addr <= (others => '0');
      send_copy_addr_dly <= (others => '0');
      send_copy_size <= (others => '0');
      r_tx <= '0'; -- make sure the router is not receiving anything
    elsif rising_edge(clk) then
      case send_state is 
        when S_WAIT_CONFIG_STALL =>
          r_stall <= '0'; --start with the cpu on control
          send_copy_addr <= (others => '0');
          send_copy_size <= (others => '0');
          r_tx <= '0'; -- make sure the router is not receiving anything

        when S_CONFIG_STALL => 
          r_stall <= '1'; -- stall cpu here
          send_status <= '1'; --set status to busy
          send_copy_addr <= prog_address; --copy dma info
          send_copy_size <= prog_size;
          previous_data <= m_data_i;
        
        when S_COPY_AND_RELEASE => --copy from memory to the output buffer
          if r_credit_i = '1' then
            --mem read
            --push to noc
            send_copy_addr_dly <= send_copy_addr;
            if send_copy_size /= send_copy_size'low then
               send_copy_size <= send_copy_size - 1;
               send_copy_addr <= send_copy_addr + 4;
            end if;
            if send_copy_size = send_copy_size'low then
               r_tx <= '0';
            else
               r_tx <= '1';
            end if;
          end if;
        when S_FLUSH =>
          r_stall <= '0';		  
          r_tx <= '0';
          if send_start = '0' then
            send_status <= '0'; -- lowers busy signal
          end if;
      end case; -- send state
  	end if;	
  end process;

  r_data_o <= m_data_i(TAM_FLIT-1 downto 0);

  stall <= r_stall;  

  -- sending does not requires the main memory to be in write mode
  m_wb_o <= (others => '0');

  m_addr_o <= send_copy_addr when r_credit_i = '1' else send_copy_addr_dly; --if credit_i is low, sustain previous memory address

end orca_ni_send;
