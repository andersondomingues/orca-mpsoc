import hemps_defaults::*;

module RouterCC_prop (
	
    clock, reset,

	//transmit (tx, send) ports
	clock_rx, //in  regNport
    rx,       //in  regNport
    data_in,  //in  arrayNport_regflit
    credit_o, //out regNport

	//receive (rx) ports
    clock_tx, //out regNport
    tx,       //out regNport
    data_out, //out arrayNport_regflit
    credit_i, //in  regNport

	//internals
	h, ack_h, data_av, sender, data_ack, //: regNport := (others=>'0');
	data, //: arrayNport_regflit := (others=>(others=>'0'));
	mux_in, mux_out, //: arrayNport_reg3 := (others=>(others=>'0')); 
	free, //: regNport := (others=>'0');

	address //<< from generics, see WTF this has to do with internal signals
);

//all interface signals must be marked as input 
input logic clock, reset;
input arrayNport_regflit data_in, data_out;
input regNport clock_rx, rx, credit_i; //rx
input regNport clock_tx, tx, credit_o; //tx

//internals must be marked as input as well
input regNport h, ack_h, data_av, sender, data_ack;
input arrayNport_regflit data;
input arrayNport_reg3 mux_in, mux_out;
input regNport free;

//from generics
input regmetadeflit address;

//local params (replace const)
`include "hemps_defaults.sv"

//disable everything when reset is risen
default disable iff reset; 

//assume clock to be global, that is, the same for all ports and internal hardware
genvar i;
generate for (i=0; i<NPORT; i++) begin
	property p_global_clock_pos;
		@(posedge clock) clock == clock_tx[i];
	endproperty
	property p_global_clock_neg;
		@(negedge clock) clock == clock_tx[i];
	endproperty
	a_p_global_clock_pos : assume property (p_global_clock_pos);
	a_p_global_clock_neg : assume property (p_global_clock_neg);
end endgenerate;

//check whether ports are blocked when no more credit is available
generate for (i=0; i<NPORT; i++) begin
	property p_disable_credit_in;
		@(posedge clock) (credit_i[i] == 0) |-> (data_in[i] == $past(data_in[i]));
	endproperty
	a_p_disable_credit_in : assert property (p_disable_credit_in);

	property p_disable_credit_out;
		@(posedge clock) (credit_o[i] == 0) |-> (data_out[i] == $past(data_out[i]));
	endproperty
	a_p_disable_credit_out : assert property (p_disable_credit_out);

end endgenerate;






endmodule //RouterCC
