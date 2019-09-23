library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.Numeric_Std.all;

entity ram is
	port(
	    clk : in std_logic;
	    addr_i:		in std_logic_vector(31 downto 0);
        data_o:     out std_logic_vector(31 downto 0);
        data_i:     in std_logic_vector(31 downto 0);
        data_w_i:   in std_logic_vector(3 downto 0)
    );
end ram; --entity ram     

architecture generic_ram of ram is
   type ram_type is array (0 to (2 ** addr_i'length) -1) of std_logic_vector(data_i'range);
   signal ram : ram_type;
   signal c_read: std_logic_vector(addr_i'range);
begin

    ram_process: process(clk) is
    
    begin
      if rising_edge(clk) then
        if data_w_i = "1" then
          ram(to_integer(unsigned(addr_i))) <= data_i;
        end if;
        c_read <= addr_i;
      end if;
    end process ram_process;

    data_o <= ram(to_integer(unsigned(c_read)));
    
end generic_ram;