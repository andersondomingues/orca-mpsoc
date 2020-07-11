
--! @file Hermes_buffer.vhd
--! Based on original input_buffer.vhd from Hermes YeAH
--! @brief Input buffer
--! @author Guilherme Heck, guilherme.heck@acad.pucrs.br
--! @author Leandro Heck, leandro.heck@acad.inf.pucrs.br
--! @author Matheus Moreira, matheus.moreira@pucrs.br
--! @date 2013-05-8

------------------------------------------------------------------------
-- Dependencies:
-- > orca_defaults.vhd
------------------------------------------------------------------------
------------------------------------------------------------------------
-- Interface description:
--                          -------------
--                         |             |
--         clock---------->|             |---------->credit_o
--                         |             |
--         reset---------->|             |---------->h
--                         |             |
--      clock_rx---------->|             |---------->data_av
--                         |             | FLIT_SIZE
--            rx---------->|             |=====/====>data
--               FLIT_SIZE |             |
--        data_in====/====>|             |---------->sender
--                         |             |
--          ack_h--------->|             |
--                         |             |
--       data_ack--------->|             |
--                         |             |
--                          -------------
------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
--use ieee.math_real.log2;
--use ieee.math_real.ceil;
use work.orca_defaults.all;


entity Hermes_buffer is
	port(
		clock    : in  std_logic;
		reset    : in  std_logic;
		clock_rx : in  std_logic;
		rx       : in  std_logic;
		data_in  : in  regflit;
		credit_o : out std_logic;
		h        : out std_logic;
		ack_h    : in  std_logic;
		data_av  : out std_logic;
		data     : out regflit;
		data_ack : in  std_logic;
		sender   : out  std_logic
	);
end Hermes_buffer;

--! @brief YeAH default input buffer architecture.
--! @details  YeAH default input buffer architecture.
architecture Hermes_buffer of Hermes_buffer is

	--type fifo_states is (S_INIT, S_HEADER, S_SENDHEADER, S_PAYLOAD, S_END);
	type fifo_states is (S_INIT, S_HEADER, S_PAYLOAD, S_END);
	signal current_state : fifo_states;

        signal buf: buff;

	signal read_pointer,write_pointer: pointer;
	signal counter_flit : regflit;

	signal data_available : std_logic;

begin

	-- FIFO WRITE
	--=========================================================================

	process(reset, clock)
	begin
		if reset='1' then
			buf <= (others=>(others => '0'));
			write_pointer <= (others => '0');
		elsif clock'event and clock='1' then
			-- If receiving data and fifo isn`t empty,
			-- record data on fifo and increase write pointer
			if rx = '1' and write_pointer /= read_pointer then
				buf(CONV_INTEGER(write_pointer)) <= data_in;
				write_pointer <= write_pointer + 1;
			end if;
		end if;
	end process;

	-- If fifo isn`t empty, credit is high. Else, low
	credit_o <= '1' when write_pointer /= read_pointer else '0';


	-- FIFO READ
	--=========================================================================

	-- Available the data to transmition (asynchronous read).
	data <= buf(CONV_INTEGER(read_pointer));

	process(reset, clock)
	begin
		if reset='1' then
			counter_flit <= (others=>'0');
			h <= '0';
			data_available <= '0';
			sender <=  '0';
			-- Initialize the read pointer with one position before the write pointer
			read_pointer <= (others=>'1');
			current_state <= S_INIT;

		elsif clock'event and clock='1' then

			case current_state is

				when S_INIT =>
					counter_flit <= (others=>'0');
					h<='0';
					data_available <= '0';
					-- If fifo isn`t empty
					if (rx='1' or read_pointer + 1 /= write_pointer) then
						-- Routing request to Switch Control
						h<='1';
						sender  <= '1';
						data_available <= '1';
						-- Increase the read pointer position with a valid data
						read_pointer <= read_pointer + 1;
						current_state <= S_HEADER;
						-- Enable wrapper signal to packet transmition
					end if;

				when S_HEADER =>
					-- When the Switch Control confirm the routing
					if ack_h ='1' then
						-- Disable the routing request
						h <= '0';
						--current_state      <= S_SENDHEADER ;
						if rx='1' or read_pointer + 1 /= write_pointer then
							read_pointer   <= read_pointer + 1;
							current_state <= S_PAYLOAD;
							data_available <= '1';
						else
							current_state <= S_HEADER;
							data_available <= '0';
						end if;
					end if;

				-- when S_SENDHEADER  =>
				-- 	-- If the data available is read or was read
				-- 	if data_ack = '1' or data_available = '0' then
				-- 		-- If fifo isn`t empty
				-- 		if (read_pointer + 1 /= write_pointer) then
				-- 			data_available   <= '1';
				-- 		-- If fifo is empty (protection clause)
				-- 		else
				-- 			data_available <= '0';
				-- 		end if;
				-- 	end if;

				when S_PAYLOAD =>
					-- If the data available is read or was read
					if data_ack = '1' or data_available = '0' then
						-- If fifo isn`t empty or is tail
						if (read_pointer + 1 /= write_pointer) or counter_flit = x"1" then
							-- If the second flit, memorize the packet size
							if counter_flit = x"0"   then
						                counter_flit <=  buf(CONV_INTEGER(read_pointer));
							elsif counter_flit /= x"1" then
								counter_flit <=  counter_flit - 1;
							end if;
							-- If the tail flit
				                        if counter_flit = x"1" then
								-- If tail is send
								if data_ack = '1' then
									data_available <= '0';
									sender <= '0';
						                        current_state <= S_INIT;
								else
									current_state <= S_END;
								end if;
							-- Else read the next position
        	                			else
								data_available <= '1';
								read_pointer <= read_pointer + 1;
					                end if;
						-- If fifo is empty (protection clause)
						else
							data_available <= '0';
						end if;
					end if;

				when S_END =>
					-- When tail is send
					if data_ack = '1' then
						data_available <= '0';
						sender <= '0';
			                        current_state <= S_INIT;
					end if;
			end case;
		end if;
	end process;

	data_av <= data_available;

end Hermes_buffer;
