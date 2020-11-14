library ieee;

use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.Numeric_Std.all;
use ieee.math_real.log2;
use ieee.math_real.ceil;
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
    prog_dest    : in std_logic_vector((RAM_WIDTH - 1) downto 0);
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
    S_SEND_DESTINY,      --send the first flit of the header
    S_SEND_SIZE,         --send the second flit of the header 
    S_PAYLOAD,           --push data into router's input buffer
    S_FLUSH              --wait for the acknowledgement and goes back to WAIT_CONFIG_STALL
  );

  --storage for both machine states
  signal send_state,previous_state : send_state_type;

  type mux_inputs is array(0 to INTEGER(RAM_WIDTH/TAM_FLIT)-1) of std_logic_vector(TAM_FLIT-1 downto 0);
  signal mux : mux_inputs;

  --temporary data
  signal send_copy_addr, send_copy_addr_dly : std_logic_vector((RAM_WIDTH - 1) downto 0);
  signal send_copy_size : std_logic_vector((RAM_WIDTH - 1) downto 0);
  signal r_stall: std_logic;
  --signal credit_i_dly : std_logic;
  signal shift : std_logic_vector(INTEGER(CEIL(LOG2(REAL(RAM_WIDTH/TAM_FLIT))))-1 downto 0);
  signal shift_high : std_logic_vector(INTEGER(CEIL(LOG2(REAL(RAM_WIDTH/TAM_FLIT))))-1 downto 0);
  signal quarter_flit_complement : std_logic_vector(QUARTOFLIT-1 downto 0);
  signal half_flit_complement : std_logic_vector(TAM_FLIT-1 downto TAM_FLIT/2);

begin

  -- transmitting clock stays the same as for the ni
  r_clock_tx <= clk;

  quarter_flit_complement <= (others => '0');
  half_flit_complement <= (others => '0');
  shift_high <= (others => '1');

--process(clk, rst)
--  begin
--    if rst = '1' then
--        credit_i_dly <= '0';
--    elsif rising_edge(clk) then
--        credit_i_dly <= r_credit_i;
--    end if;
--end process;


  -- send proc, state control
  send_state_control_proc: process(clk, rst)
  begin

    if rst = '1' then
      send_state <= S_WAIT_CONFIG_STALL;
      previous_state <= S_WAIT_CONFIG_STALL;
    elsif rising_edge(clk) then

      previous_state <= send_state;

      case send_state is
        when S_WAIT_CONFIG_STALL => --  software programs the dma
          if send_start = '1' then
            send_state <= S_CONFIG_STALL;
          end if;
        when S_CONFIG_STALL => --stays for one cycle
          send_state <= S_SEND_DESTINY;
        when S_SEND_DESTINY => --  software programs the dma
          if r_credit_i = '1' then
            send_state <= S_SEND_SIZE;
          end if;
        when S_SEND_SIZE => --  software programs the dma
          if r_credit_i = '1' then
            send_state <= S_PAYLOAD;
          end if;
        when S_PAYLOAD =>  -- all flits have been copied
          if send_copy_size = send_copy_size'low and shift = shift_high and r_credit_i = '1' then
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
      shift <= (others => '0');
      r_tx <= '0'; -- make sure the router is not receiving anything
    elsif rising_edge(clk) then
      case send_state is 
        when S_WAIT_CONFIG_STALL =>
          r_stall <= '0'; --start with the cpu on control
          send_copy_addr <= prog_address; --copy dma info
          send_copy_size <= prog_size;
          send_copy_addr_dly <= send_copy_addr;
          r_tx <= '0'; -- make sure the router is not receiving anything
          shift <= (others => '0');

        when S_CONFIG_STALL => 
          r_stall <= '1'; -- stall cpu here
          send_status <= '1'; --set status to busy
          send_copy_addr <= prog_address; --copy dma info
          send_copy_size <= prog_size;
          send_copy_addr_dly <= send_copy_addr;

        when S_SEND_DESTINY => 
          if r_credit_i = '1' then
             r_tx <= '1';
--             send_copy_size <= send_copy_size - 1;
--             send_copy_addr <= send_copy_addr + 4;
--             send_copy_addr_dly <= send_copy_addr;
          end if;

        when S_SEND_SIZE => 
          if r_credit_i = '1' then
--             send_copy_size <= send_copy_size - 1;
--             send_copy_addr <= send_copy_addr + 4;
--             send_copy_addr_dly <= send_copy_addr;
          end if;
        
        when S_PAYLOAD => --copy from memory to the output buffer
          if r_credit_i = '1' then
            --mem read
            --push to noc
            if INTEGER(CEIL(LOG2(REAL(RAM_WIDTH/TAM_FLIT)))) /= 0 then
              if (previous_state /= S_SEND_SIZE) then
                shift <= shift + 1;
                if shift+1 = shift_high then
                   if send_copy_size /= send_copy_size'low then
                      send_copy_size <= send_copy_size - 1;
                      send_copy_addr <= send_copy_addr + 4;
                      send_copy_addr_dly <= send_copy_addr;
                   end if;
                end if;
              end if;
            else
              if send_copy_size /= send_copy_size'low then
                 send_copy_size <= send_copy_size - 1;
                 send_copy_addr <= send_copy_addr + 4;
                 send_copy_addr_dly <= send_copy_addr;
              end if;
            end if;
            if send_copy_size = send_copy_size'low and shift = shift_high then
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

  GEN : for i in 0 to (INTEGER(RAM_WIDTH/TAM_FLIT)-1) generate
    mux(i) <= m_data_i((TAM_FLIT*(i+1)) - 1 downto (TAM_FLIT*i)) when send_state = S_PAYLOAD else (others => '0');
  end generate;

  r_data_o <= half_flit_complement & prog_dest(RAM_WIDTH/4+TAM_FLIT/4-1 downto RAM_WIDTH/4) & prog_dest(TAM_FLIT/4-1 downto 0) when previous_state = S_SEND_DESTINY else prog_size(TAM_FLIT-INTEGER(CEIL(LOG2(REAL(RAM_WIDTH/TAM_FLIT))))-1 downto 0) & shift when previous_state = S_SEND_SIZE else mux(to_integer(unsigned(shift))) when previous_state = S_PAYLOAD else (others => '0');

  stall <= r_stall;  

  -- sending does not requires the main memory to be in write mode
  m_wb_o <= (others => '0');

  m_addr_o <= send_copy_addr_dly when shift = shift_high and r_credit_i = '0' else send_copy_addr;

end orca_ni_send;
