library ieee;

use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity orca_ni_send is

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

    -- router interface (transmiting)
    r_clock_tx  : out std_logic; 
    r_tx        : out std_logic;
    r_data_o    : out std_logic_vector(FLIT_WIDTH downto 0);
    r_credit_i  : in std_logic;

    -- dma programming (must be mapped into memory space)
    send_start : in std_logic;
    send_status : out std_logic_vector(31 downto 0);
    prog_address : in std_logic_vector(31 downto 0);
    prog_size    : in std_logic_vector(31 downto 0)

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
  signal send_copy_addr : std_logic_vector(31 downto 0);
  signal send_copy_size : std_logic_vector(31 downto 0);

begin

  -- transmitting clock stays the same as for the ni
  r_clock_tx <= clk;

  -- send proc, state control
  send_state_control_proc: process(clk, rst)
  begin

	if rst = '1' then
        send_state <= S_WAIT_CONFIG_STALL;
    elsif rising_edge(clk) then

      case send_state is
        when S_WAIT_CONFIG_STALL => -- change states when software programs the dma
          if send_start = '1' then
            send_state <= S_COPY_AND_RELEASE;
          end if;
        when S_CONFIG_STALL => --stays for one cycle
          send_state <= S_COPY_AND_RELEASE;
        when S_COPY_AND_RELEASE =>  -- change states when all flits have been copied
          if send_copy_size = 0 then
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
  send_machine_func_proc: process(clk)
  begin
    case send_state is 
      when S_WAIT_CONFIG_STALL =>
        r_tx <= '0'; -- make sure the router is not receiving anything
      when S_CONFIG_STALL => 
        stall <= '1'; -- stall cpu here
        send_status <= "1"; --set status to busy
        send_copy_addr <= prog_address; --copy dma info
        send_copy_size <= prog_size;
      when S_COPY_AND_RELEASE => --copy from memory to the output buffer
        if r_credit_i = '1' then
          --mem read
          m_addr_o <= send_copy_addr; --origin of data
          --push to noc
          r_tx <= '1'; --!!NOTE: clock_tx being ignored
          send_copy_size <= send_copy_size - RAM_WIDTH;
        else
          r_tx <= '0';
        end if;
      when S_FLUSH =>
          r_tx <= '0';
          if send_start = '0' then
            send_status <= "0"; -- lowers busy signal
          end if;
    end case; -- send state
  
  end process;

  --buffer output always comes from memory 
  r_data_o <= m_data_i;

  -- sending does not requires the main memory to be in write mode
  m_wb_o <= "0000";

end orca_ni_send;
