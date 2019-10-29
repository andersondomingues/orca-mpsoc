import hemps_defaults::*;

//================================================================================
// INTERFACE
//================================================================================
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

//================================================================================
// ASSUMPTIONS
//================================================================================
//assume clock to be global, that is, the same for all ports and internal hardware

generate for (genvar i = 0; i<NPORT; i++) begin
	property p_global_clock_pos;
		@(posedge clock) clock == clock_tx[i];
	endproperty

	property p_global_clock_neg;
		@(negedge clock) clock == clock_tx[i];
	endproperty

	a_p_global_clock_pos : assume property (p_global_clock_pos);
	a_p_global_clock_neg : assume property (p_global_clock_neg);
end endgenerate;

//check whether ports are blocked when no more credit is available (TODO: number of cycles)
generate for (genvar i = 0; i<NPORT; i++) begin
	property p_disable_credit_in;
		@(posedge clock) (!credit_i[i]) |-> (data_out[i] == $past(data_out[i]) and !tx);
	endproperty

	property p_disable_credit_out;
		@(posedge clock) (!credit_o[i]) |-> (data_in[i] == $past(data_in[i]) and !rx);
	endproperty

	a_p_disable_credit_in  : assume property (p_disable_credit_in);
	a_p_disable_credit_out : assume property (p_disable_credit_out);
end endgenerate;

//================================================================================
// COVER POINTS
//================================================================================
// -- all possible values for credit_o and credit_i
//generate 
//	for (genvar i = 0; i < NPORT; i++) begin
//		for (genvar j = 0; j < MAX_REGFLIT_VAL; j++) begin
//			cover_credit_i : cover property (credit_i[i] == j);    << DO NOT USE THOSE,
//			cover_credit_o : cover property (credit_o[i] == j);    << TOOL GONNA HANG!!
//		end 
//	end 
//endgenerate;


//================================================================================
// ASSERTIONS
//================================================================================
//property p_buffer_size;
//	@(posedge clock) (!credit_i and !rx and !tx) |=> 1;		
//endproperty;
//a_p_buffer_size : assert property (p_buffer_size);

//property p_in_order_5(header_addr, header_size);

	//regflit packet[]; //generate a new packet
	//regflit packet[$];

	/*@(posedge clock) (
		(data_in[SOUTH] == data[0] and rx[SOUTH]) ##1
		(data_in[SOUTH] == data[1] and rx[SOUTH]) ##1
		(data_in[SOUTH] == data[2] and rx[SOUTH]) ,
	
		gen_pkt(header_addr, header_size, packet) 
	) |-> 
		##[0:$] (data_out[LOCAL] == packet[0])
		##[0:$] (data_out[LOCAL] == packet[1])
		##[0:$] (data_out[LOCAL] == packet[2]);
	*/

	//@(posedge clock) (
	//	credit_o,
	//	if 

	//) |->

//endproperty;
//a_p_in_order_5 : assert property (p_in_order_5(16'h0011, 16'h0001));



endmodule //RouterCC












