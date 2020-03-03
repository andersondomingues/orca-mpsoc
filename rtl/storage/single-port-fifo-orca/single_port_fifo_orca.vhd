library ieee;
use ieee.std_logic_1164.all;
 
entity fifo_orca is

  generic (
    RAM_WIDTH : natural;
    RAM_DEPTH : natural
  );
  
  port (
    clk : in std_logic;
    rst : in std_logic;

    -- interface
    data_o : out std_logic_vector(RAM_WIDTH - 1 downto 0); --always display top value (if any)
    data_i : in std_logic_vector(RAM_WIDTH - 1 downto 0); --value to be pushed to the queue

    -- control byte (0: none, 1: queue/push/insert, 2: dequeue/pop/delete)
    ctrl_i   : in std_logic_vector(0 downto 3);

    -- status flags 
    -- 1xxx : full
    -- x1xx : empty
    -- xx1x : could not push to the queue, queue is full
    -- xxx1 : could not pop from the queue, queue is empty
    f_full  : out std_logic;
    f_empty : out std_logic;
    f_overflow  : out std_logic;
    f_underflow : out std_logic;
   
    -- number of elements in the queue
    -- size  : out std_logic_vector(data_i'range); -- maximum queue size

    --memory interface (single port)
    m_addr_i :  in std_logic_vector((RAM_WIDTH - 1) downto 0);
    m_head   : out std_logic_vector((RAM_WIDTH - 1) downto 0);
    m_data_i :  in std_logic_vector((RAM_WIDTH - 1) downto 0);
    m_wb_i   :  in std_logic_vector(3 downto 0)

  );
end fifo_orca;

architecture fifo_orca of fifo_orca is

  --sentinels
  signal head : integer range RAM_DEPTH - 1 downto 0;
  signal tail : integer range RAM_DEPTH - 1 downto 0;

  --sentinel increment (with wrap up)
  procedure incr(signal index : inout index_type) is
  begin
    if index = index_type'high then
      index <= index_type'low;
    else
      index <= index + 1;
    end if;
  end procedure;
  
  --state definition and storage
  type state_type is (
    IDLE,  --no operation is being executed, value at the output is the top os the queue (if any)
    PUSH,  --value at the input is pushed to the memory, output is garbage
    POP,   --value at the output is the top of the queue, pop
    RESET  --value at the output is garbage, sentinels get reset to the beggining of memory
  );
  signal state : state_type;

begin

  --state machine control
  state_control : process(clk, rst)
  begin
    if rst = rst'high then
      state <= RESET;
    else
      if ctrl_i = '1' then
        state <= PUSH;
      elsif ctrl_i = '2' then 
        state <= POP;
      else
        state <= IDLE;
      end if;
    end if;
  end;
  
  --operation control
  operation : process(clk)
  begin 
    -- When at the reset state, sentinels are send back to the first address 
    -- of the queue. We assume that the queue always start at the position 
    -- zero, with the last position assigned to RAM_DEPTH - 1. Memory is not 
    -- written here, so data is virtually available (possible security hazard?)
    if state = RESET then
      head <= 0;
      tail <= 0;
    
    -- When pushing to the queue, the tail sentinels advances one position if the
    -- queue has at least one position to store input data. Otherwise, no operation
    -- is performed on the sentinels, and the flag for queue full (1xxx) rises. Since 
    -- we use a single port ram here, output can be read during the pushing operation, 
    -- although it cannot be popped in the same cycle.
    else if state = PUSH then 

      if f_full = f_full'high then
        f_overflow <= '1';
      else
        wb_o <= '1'; -- memory write
        m_address_o = tail;
        m_data_o <= data_i;
        f_overflow <= '0'; -- lowers overflow flag
        incr(tail);
      end if;

    -- When popping from the queue, the head sentinel advances one position, and data
    -- at the input is written to the memory module
    else if state = POP then
      if f_empty = f_empty'high then
        f_underflow <= '1';
      else 
        incr(head);
        m_address_o <= head;
        f_underflow <= '0';        
      end if;
    
    -- When in idle, the sentinels stay in the same place
    else
      -- nothing to be done (check whether the compiler warns about empty states)
    end if;
  
  end;
  
  -- head of the queue is always pushed to the output, if any
  -- in case of an empty queue, garbage is pushed to that output
  data_o <= m_data_o;
  f_empty <= tail = head;
  f_full  <= (head = tail - 1) or (head = head'low and tail = tail'high);
  f_underflow <= underflow;
  f_overflow <= overflow;
  
end architecture;