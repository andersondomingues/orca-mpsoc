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
    PRELOAD_ADDR : natural; --base addres for memory preload
    BUFFER_DEPTH : natural -- size of internal buffer (max pkt size)
  );

  port(
    clk : in std_logic;
    rst : in std_logic;
    stall : out std_logic; -- holds the cpu and takes control on memory i/f
    intr  : out std_logic; -- interruption flag

    -- interface to the memory mux
    m_addr_o : out std_logic_vector((RAM_WIDTH - 1) downto 0);
    m_data_o : out std_logic_vector((RAM_WIDTH - 1) downto 0);
    m_wb_o   : out std_logic_vector(3 downto 0);

    -- router interface (receiving)
    r_clock_rx : in std_logic;
    r_rx       : in std_logic;
    r_data_i   : in std_logic_vector((FLIT_WIDTH - 1) downto 0);
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
  
  --buffer i/f
  signal b_addr_o : std_logic_vector((RAM_WIDTH - 1) downto 0);
  signal b_data_i : std_logic_vector((RAM_WIDTH - 1) downto 0);
  signal b_data_o : std_logic_vector((RAM_WIDTH - 1) downto 0);
  signal b_wb_o   : std_logic_vector(3 downto 0);

begin

  --memory buffer binding
  ni_recv_buffer_mod: entity work.single_port_ram
    generic map(
        RAM_WIDTH => RAM_WIDTH,
        RAM_DEPTH => BUFFER_DEPTH
    )
    port map(
        clk => clk,
        rst => rst,

        addr_i => b_addr_o,
        data_o => b_data_i,
        data_i => b_data_o,
        wb_i => b_wb_o
    );

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
            recv_state <= R_PRELOAD_SIZE;
          end if;
        when R_PRELOAD_SIZE =>
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
  
  -- functional implementation
  recv_machine_funct: process(clk) 
  begin 
    if rst = '1' then
      recv_copy_size <= (others => '0'); --reset internals
      recv_copy_addr <= (others => '0');
      stall <= '1'; -- cpu gets stalled until the end of preload
      r_credit_o <= '1'; -- credit is up when not copying to memory
      m_wb_o <= (others => '0'); --set memory to read mode
      b_wb_o <= (others => '0'); --set buffer to read mode
      recv_status <= (others => '0'); -- no memory space has been requested yet
      intr <= '0'; -- interruption starts lowered
    elsif rising_edge(clk) then
      case recv_state is 
      
        -- !!! -- preload mode
        --drop first flit and prepare to preload content
        when R_PRELOAD_WAIT => 
          if r_rx = '1' then
            recv_copy_addr <= conv_std_logic_vector(PRELOAD_ADDR, 32);
          end if;
        -- drop second flit and store size info.
        when R_PRELOAD_SIZE =>
          if r_rx = '1' then 
            recv_copy_size <= r_data_i;
          end if;
        -- copy flits directly to the main memory
        when R_PRELOAD_COPY =>
          if r_rx = '1' then
            m_addr_o <= recv_copy_addr;
            m_data_o <= r_data_i;
            m_wb_o <= x"1";
            
            recv_copy_size <= recv_copy_size - 1;
            recv_copy_addr <= recv_copy_addr + 4; -- << care mem. width!
          else
            m_wb_o <= x"0"; --prevent memory from being written during slack time
          end if ;

        -- !!! -- driver mode
        -- wait for a packet to arrive 
        when R_WAIT_FLIT_ADDR =>
          if r_rx = '1' then

            b_data_o <= r_data_i; -- write first flit to buffer
            b_wb_o <= x"1";
            b_addr_o <= (others => '0');
            
            recv_copy_addr <= x"00000004"; --advance mem. to 2nd position
          else
            b_wb_o <= x"0";
          end if;
          
        -- wait for the size flit to arrive
        when R_WAIT_FLIT_SIZE => 
          if r_rx = '1' then
            b_data_o <= r_data_i; -- write to the 2nd position
            b_wb_o <= x"1";
            b_addr_o <= recv_copy_addr;
            
            recv_copy_addr <= recv_copy_addr + 4; --advances mem ptr.
            recv_copy_size <= r_data_i;
            recv_status <= r_data_i; -- notify recv flits to cpu
          else 
            b_wb_o <= x"0";
          end if;
        
        --copy flits until no more payload is available
        when R_WAIT_PAYLOAD =>
          if r_rx = '1' then 
            b_data_o <= r_data_i; -- write to the 3nd position and beyond
            b_wb_o <= x"1";
            b_addr_o <= recv_copy_addr;
            
            recv_copy_addr <= recv_copy_addr + 4; --advances mem ptr.
            recv_copy_size <= recv_copy_size - 1;
          else
            b_wb_o <= x"0";
          end if;
          
        -- raises interruption and wait the cpu to treat the request
        when R_WAIT_CONFIG_STALL =>
          intr <= '1'; -- raise interruption flag
          recv_copy_addr <= prog_address; --copy dma info
          recv_copy_size <= prog_size;

        when R_COPY_RELEASE =>
          b_wb_o <= x"0"; --read from buffer
          b_addr_o <= (
            recv_copy_size + recv_copy_size + recv_copy_size + recv_copy_size
          ); -- copy from the last to the first
            
          m_wb_o <= x"1";
          m_addr_o <= recv_copy_addr + (
            recv_copy_size + recv_copy_size + recv_copy_size + recv_copy_size
          );
          m_data_o <= b_data_i;
          
          recv_copy_size <= recv_copy_size -1;

        when R_FLUSH =>
          m_wb_o <= x"0"; -- disable mem write for until next packet
          if recv_start = '0' then
            intr <= '0'; --low interruption 
          end if;
        
      end case;
    end if;  
  end process;

end orca_ni_recv;
