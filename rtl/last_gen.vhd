------------------------------------------------------------------------------------------------
--
--  DISTRIBUTED HEMPS  - version 5.0
--  Research group: GAPH-PUCRS
--  Distribution:  June 2020
--  Author: Alexandre Amory: amamory@gmail.com
--  Source name:  last_gen.vhd
--
--  'last' signal generator to keep compability with AXI streaming interface
--  this port is high when the last flit is sent
--
----------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use work.orca_defaults.all;

entity last_gen is
port(
        clock:    in  std_logic;
        reset:    in  std_logic;
        -- these to the external side
        validL_o: out std_logic;
        lastL_o:  out std_logic;
        dataL_o:  out std_logic_vector(TAM_FLIT-1 downto 0);
        readyL_i: in  std_logic;
        -- these go to the router side
        valid_i:  in  std_logic;
        data_i:   in  std_logic_vector(TAM_FLIT-1 downto 0);
        ready_o:  out  std_logic
);
end last_gen;

architecture last_gen of last_gen is

type state_type is (WAIT_HEADER,HEADER,PKT_SIZE,PAYLOAD,LAST_FLIT);
signal state: state_type;

-- the max packet size is 2^max_packet_size
-- there is no need to use 32 bits for this counter
constant MAX_PACKET_SIZE : integer := 10;

signal flit_cnt: std_logic_vector(MAX_PACKET_SIZE-1 downto 0);
signal data_s: std_logic_vector(TAM_FLIT-1 downto 0);
signal valid_s, readyL_s , lastL_s: std_logic;

begin

    validL_o <= valid_s;
    dataL_o  <= data_s;
    ready_o  <= readyL_s;
    
    process(reset, clock)
    begin
        if reset='1' then
            valid_s <= '0';
            data_s  <= (others => '0');
            readyL_s  <= '0';
            lastL_o <= '0';
        elsif clock'event and clock='1' then
            valid_s <= valid_i;
            data_s  <= data_i;
            readyL_s  <= readyL_i;
            lastL_o   <= lastL_s;
        end if;
    end process;    
    
    
    process(reset,clock)
    begin
        if reset='1' then
            state<=WAIT_HEADER;
            flit_cnt <= (others => '0'); 
            lastL_s <= '0';
        elsif clock'event and clock='0' then
            case state is
                when WAIT_HEADER => 
                    flit_cnt <= (others => '0'); 
                    lastL_s <= '0';
                    state <= WAIT_HEADER;
                    if readyL_i = '1' and valid_i = '1' then
                        state <= HEADER;
                    end if;
                when HEADER =>
                    state <= HEADER;
                    if readyL_i = '1' and valid_i = '1' then
                        state <= PKT_SIZE;
                        flit_cnt <= data_i(MAX_PACKET_SIZE-1 downto 0);
                    end if;
                when PKT_SIZE =>
                    state <= PKT_SIZE;
                    if readyL_i = '1' and valid_i = '1' then
                        if flit_cnt = 1 then
                            state <= WAIT_HEADER;
                            lastL_s <= '1';
                        else
                            state <= PAYLOAD;
                         end if; 
                    end if;
                when PAYLOAD =>
                    state <= PAYLOAD;
                    if readyL_i = '1' and valid_i = '1' then
                        flit_cnt <= flit_cnt -1;
                        if flit_cnt = x"0002" then
                            state <= WAIT_HEADER;
                            lastL_s <= '1';
                        end if;
                    end if;
                when LAST_FLIT =>
                    lastL_s <= '0';
                    state <= LAST_FLIT;
                    if readyL_i = '1' and valid_i = '1' then
                        state <= WAIT_HEADER;
                        
                    end if;
                when others => 
                    state <= WAIT_HEADER;
            end case;
        end if;
    end process;
    
    --lastL_o <= '1' when  readyL_s = '1' and valid_s = '1' and state = LAST_FLIT else '0';

end last_gen;
