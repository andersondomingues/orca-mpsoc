library ieee;
use ieee.std_logic_1164.all;
use work.orca_defaults.all;

--
-- Note entity name must match exactly name of sc_module class in
--  SystemC
--
entity inputmodule is
  port (
			clock	: in std_logic;
			reset	: in std_logic;
			address_ip : in regmetadeflit;
			outTx	: out std_logic;
			outData	: out regflit;
			inCredit: in std_logic
		);
end;

architecture SystemC of inputmodule is
--
-- Note that the foreign attribute string value must be "SystemC".
--
  attribute foreign of SystemC : architecture is "SystemC";
begin
end;

