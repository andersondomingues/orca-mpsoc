library ieee;

use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.math_real.log2;
use ieee.math_real.ceil;
use work.orca_defaults.all;

entity orca_ni_recv is

  --parameters come from the top level rtl (naming consistency
  --is preserved for all rtl files).
  port(
    clk : in std_logic;
    rst : in std_logic;
    rst_reload : out std_logic; -- reset cpu for reload app
    stall : out std_logic; -- holds the cpu and takes control on memory i/f
    intr  : out std_logic; -- interruption flag

    -- interface to the memory mux
    m_addr_o : out std_logic_vector((RAM_WIDTH - 1) downto 0);
    m_data_o : out std_logic_vector((RAM_WIDTH - 1) downto 0);
    m_wb_o   : out std_logic_vector(3 downto 0);

    -- router interface (receiving)
    r_clock_rx : in std_logic;
    r_rx       : in std_logic;
    r_data_i   : in std_logic_vector((TAM_FLIT - 1) downto 0);
    r_credit_o : out std_logic;

    -- dma programming (must be mapped into memory space)
    recv_reload : in std_logic;
    recv_start : in std_logic;
    recv_status : out std_logic_vector((RAM_WIDTH/2 - 1) downto 0);
    prog_address : in std_logic_vector((RAM_WIDTH - 1) downto 0);
    prog_size    : in std_logic_vector((RAM_WIDTH - 1) downto 0)
  );

end orca_ni_recv;

architecture orca_ni_recv of orca_ni_recv is

  -- typeing defs. 
  type recv_state_type is (

    -- preload means "put everything from the input into memory" 
    R_RELOAD_WAIT, -- initial state, happens once as long as "load" stays low
    R_RELOAD_SIZE, -- receive the second flit and stores burst lenght
    R_RELOAD_COPY, -- copy raw data from input to the memory
    R_RELOAD_FLUSH,

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
  signal data_temp : std_logic_vector((RAM_WIDTH - 1) downto 0);
  signal shift : std_logic_vector((INTEGER(CEIL(LOG2(REAL(RAM_WIDTH/TAM_FLIT)))))-1 downto 0);
  signal recv_copy_addr : std_logic_vector((RAM_WIDTH - 1) downto 0);
  signal recv_copy_size : std_logic_vector((TAM_FLIT - 1) downto 0);
  signal cpu_copy_addr : std_logic_vector((RAM_WIDTH - 1) downto 0);
  signal cpu_copy_size : std_logic_vector((TAM_FLIT - 1) downto 0);
  signal cpu_copy_size_dly : std_logic_vector((TAM_FLIT - 1) downto 0);
  
  --buffer i/f
  signal b_addr_o : std_logic_vector((RAM_WIDTH - 1) downto 0);
  signal b_data_i : std_logic_vector((TAM_FLIT - 1) downto 0);
  signal b_data_o : std_logic_vector((TAM_FLIT - 1) downto 0);
  signal b_cs_o   : std_logic_vector(3 downto 0);
  signal b_wb_o   : std_logic_vector(3 downto 0);
  signal m_data_o_internal : std_logic_vector(TAM_FLIT-1 downto 0);
  signal m_data_complement : std_logic_vector(RAM_WIDTH - 1 downto TAM_FLIT);

begin

  m_data_complement <= (others => '0');

  b_cs_o <= (others => '1');
  --memory buffer binding
  ni_recv_buffer_mod: entity work.single_port_ram_32bits
    generic map(
        RAM_DEPTH_I => BUFFER_DEPTH_NI
    )
    port map(
        clk => clk,
        rst => rst,

        addr_i => b_addr_o((INTEGER(CEIL(LOG2(REAL(BUFFER_DEPTH_NI)))))-1 downto 0),
        data_o => b_data_i,
        data_i => b_data_o,
        cs_i => b_cs_o,
        wb_i => b_wb_o
    );

  -- recv proc, state control
  recv_state_control_proc: process(clk, rst) 
  begin 
  
    if rst = '1' then
      recv_state <= R_RELOAD_WAIT;
    elsif rising_edge(clk) then

      case recv_state is 
      
        -- preload mode state machine 
        when R_RELOAD_WAIT => --wait for a flit to appear at the input
          if r_rx = '1' then
            recv_state <= R_RELOAD_SIZE;
          end if;
        when R_RELOAD_SIZE =>
          recv_state <= R_RELOAD_COPY;
        when R_RELOAD_COPY =>
          if recv_copy_size = recv_copy_size'low then
            recv_state <= R_RELOAD_FLUSH;
          end if;
        when R_RELOAD_FLUSH =>
          if recv_reload = '0' then
            recv_state <= R_WAIT_FLIT_ADDR;
          end if;
          
        -- driver mode state machine 
        when R_WAIT_FLIT_ADDR =>
          if recv_reload = '1' then
            recv_state <= R_RELOAD_WAIT;
          elsif r_rx = '1' then
            recv_state <= R_WAIT_FLIT_SIZE;
          end if;
        when R_WAIT_FLIT_SIZE => 
          if r_rx = '1' then
            recv_state <= R_WAIT_PAYLOAD;
          end if;
        when R_WAIT_PAYLOAD =>
          if recv_copy_size = recv_copy_size'low then
            recv_state <= R_WAIT_CONFIG_STALL;
          end if;
        when R_WAIT_CONFIG_STALL =>
          if recv_start = '1' then
            recv_state <= R_COPY_RELEASE;
          end if;
        when R_COPY_RELEASE =>
          if cpu_copy_size_dly = cpu_copy_size_dly'low then
            recv_state <= R_FLUSH;
          end if;
        when R_FLUSH =>
          if recv_start = '0' then
            recv_state <= R_WAIT_FLIT_ADDR;
          end if;

      end case;

    end if;
  end process;
  
  -- functional implementation
  recv_machine_funct: process(clk, rst) 
  begin 
    if rst = '1' then
      recv_copy_size <= (others => '1'); --reset internals
      recv_copy_addr <= (others => '0');
      cpu_copy_size <= (others => '0');
      cpu_copy_size_dly <= (others => '0');
      cpu_copy_addr <= (others => '0');
      data_temp <= (others => '0');
      shift <= (others => '0');
      stall <= '1'; -- cpu gets stalled until the end of reload
      rst_reload <= '1'; -- cpu reset for reload app
      recv_status <= (others => '0'); -- no memory space has been requested yet
      intr <= '0'; -- interruption starts lowered
    elsif rising_edge(clk) then
      case recv_state is 
      
        -- !!! -- preload mode
        --drop first flit and prepare to preload content
        when R_RELOAD_WAIT =>
          rst_reload <= '1';
          stall <= '1';
          recv_copy_size <= (others => '1');
          if r_rx = '1' then
            rst_reload <= '0';
            recv_copy_addr <= conv_std_logic_vector(PRELOAD_ADDR, RAM_WIDTH);
          end if;
        -- drop second flit and store size info.
        when R_RELOAD_SIZE =>
          if r_rx = '1' then 
            recv_copy_size <= r_data_i;
          end if;
        -- copy flits directly to the main memory
        when R_RELOAD_COPY =>
          if r_rx = '1' then
            recv_copy_size <= recv_copy_size - 1;
            recv_copy_addr <= recv_copy_addr + 4; -- << care mem. width!
          end if ;
        when R_RELOAD_FLUSH =>
          stall <= '0';



        -- !!! -- driver mode
        -- wait for a packet to arrive 
        when R_WAIT_FLIT_ADDR =>
          recv_copy_size <= (others => '1');
          stall <= '0'; --enable cpu to use memory until next packet arrival
          recv_copy_addr <= (others => '0');
          if r_rx = '1' then
            recv_copy_addr <= recv_copy_addr + 1; --advance mem. to 2nd position
          end if;
          
        -- wait for the size flit to arrive
        when R_WAIT_FLIT_SIZE => 
          if r_rx = '1' then
            recv_copy_addr <= recv_copy_addr + 1; --advances mem ptr.
            recv_copy_size <= r_data_i;
            recv_status <= r_data_i(15 downto 0); -- notify recv flits to cpu
          end if;
        
        --copy flits until no more payload is available
        when R_WAIT_PAYLOAD =>
          if r_rx = '1' then 
            recv_copy_addr <= recv_copy_addr + 1; --advances mem ptr.
            recv_copy_size <= recv_copy_size - 1;
          end if;
          
        -- raises interruption and wait the cpu to treat the request
        when R_WAIT_CONFIG_STALL =>
          intr <= '1'; -- raise interruption flag
          recv_copy_addr <= prog_address; --copy dma info
          cpu_copy_size <= prog_size(TAM_FLIT-1 downto 0) - 1;
          cpu_copy_addr <= recv_copy_addr + (cpu_copy_size(TAM_FLIT - 3) & "00");
          if recv_start = '1' then
            stall <= '1';
            cpu_copy_size_dly <= cpu_copy_size;
            cpu_copy_addr <= recv_copy_addr + (cpu_copy_size((TAM_FLIT - 3) downto 0) & "00");
            cpu_copy_size <= cpu_copy_size - 1;
          end if;
        when R_COPY_RELEASE =>
          stall <= '1'; -- stall cpu during copy
          cpu_copy_addr <= recv_copy_addr + (cpu_copy_size((TAM_FLIT - 3) downto 0) & "00");
          cpu_copy_size_dly <= cpu_copy_size;
          if cpu_copy_size /= cpu_copy_size'low then
            cpu_copy_size <= cpu_copy_size - 1;
          end if;
        when R_FLUSH =>
          stall <= '0';
          if recv_start = '0' then
            intr <= '0'; --low interruption 
          end if;
        
      end case;
    end if;  
  end process;

r_credit_o <= '0' when recv_copy_size = recv_copy_size'low else '1';

b_wb_o <= (others => '1') when (recv_state = R_WAIT_FLIT_ADDR or recv_state = R_WAIT_FLIT_SIZE or recv_state = R_WAIT_PAYLOAD) and r_rx = '1' else (others => '0');
b_addr_o <= recv_copy_addr when recv_state = R_WAIT_FLIT_ADDR or recv_state = R_WAIT_FLIT_SIZE or recv_state = R_WAIT_PAYLOAD else m_data_complement & cpu_copy_size;
b_data_o <= r_data_i when recv_state = R_WAIT_FLIT_ADDR or recv_state = R_WAIT_FLIT_SIZE or recv_state = R_WAIT_PAYLOAD else (others => '0');


m_wb_o <= (others => '1') when (recv_state = R_RELOAD_COPY and r_rx = '1') or recv_state = R_WAIT_CONFIG_STALL or recv_state = R_COPY_RELEASE else (others => '0');
m_addr_o <= cpu_copy_addr when recv_state = R_WAIT_CONFIG_STALL or recv_state = R_COPY_RELEASE else recv_copy_addr;
m_data_o_internal <= b_data_i when recv_state = R_WAIT_CONFIG_STALL or recv_state = R_COPY_RELEASE else r_data_i;
m_data_o <= m_data_complement & m_data_o_internal;
end orca_ni_recv;
