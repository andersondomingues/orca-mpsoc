import hemps_defaults::*;

`undef ENABLE_HARDCOVERS

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
input regNport h, ack_h, data_av, sender, data_ack, free;
input arrayNport_regflit data;
input arrayNport_reg3 mux_in, mux_out;

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

//adjust clock to tick together
generate for (genvar i = 0; i<NPORT; i++) begin
	property p_global_clock_pos;
		@(posedge clock) clock_tx[i];   //<-- cannot use these 
	endproperty

	property p_global_clock_neg;
		@(negedge clock) !clock_tx[i];
	endproperty

	//a_p_global_clock_pos : assume property (p_global_clock_pos);
	//a_p_global_clock_neg : assume property (p_global_clock_neg);
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
// SEQUENCES
//================================================================================
//sequence onehot_port(packet_t t)
	//if($size(t) == 0)
	//	1;
	//else
		//data_(rx[port] == 1) and $onehot(rx) and (credit_i[port] == 1)and $onehot(credit_i);
///endsequence;

//================================================================================
// COVER POINTS
//================================================================================
//state cover
`ifdef ENABLE_HARDCOVERS
generate for(genvar i = 0; i <= 4; i++) begin
	c_p_south : cover property (@(posedge clock)(FSouth.EA == i));
	c_p_north : cover property (@(posedge clock)(FNorth.EA == i));
	c_p_east  : cover property (@(posedge clock)(FEast.EA == i));
	c_p_west  : cover property (@(posedge clock)(FWest.EA == i));
	c_p_local : cover property (@(posedge clock)(FLocal.EA == i));
end endgenerate;
`endif /* ENABLE_HARDCOVERS */

// -- all possible values for credit_o and credit_i
`ifdef ENABLE_HARDCOVERS
generate 
	for (genvar i = 0; i < 0/*NPORT*/; i++) begin
		for (genvar j = 0; j < MAX_REGFLIT_VAL; j++) begin
			cover_credit_i : cover property (credit_i[i] == j);    << DO NOT USE THOSE,
			cover_credit_o : cover property (credit_o[i] == j);    << TOOL GONNA HANG!!
		end 
	end 
endgenerate;
`endif

//all possible values for nport signals
`ifdef ENABLE_HARDCOVERS
generate for(genvar i = 0; i <= MAX_REGNPORT_VAL; i++) begin
	c_p_val_h        : cover property (@(posedge clock)(h == i));
	c_p_val_data_av  : cover property (@(posedge clock)(data_av == i));
	c_p_val_sender   : cover property (@(posedge clock)(sender == i));
	c_p_val_data_ack : cover property (@(posedge clock)(data_ack == i));
	c_p_val_free     : cover property (@(posedge clock)(free == i));
	//NOTE: ack_h won't have any possible value, see "a_p_ack_h"
end endgenerate;
`endif /* ENABLE_HARDCOVERS */

//================================================================================
// ASSERTIONS
//================================================================================
//check whether only a port can be acknowledged at once
property p_ack_h;
	@(posedge clock) $onehot0(ack_h);
endproperty;

a_p_ack_h : assert property (p_ack_h);

//at most two port can be send flits at the same time
property p_max_senders;
	@(posedge clock) $countones(tx) <= 4;
endproperty;

a_p_max_senders : assert property (p_max_senders);

//check whether buffer lower credit_o when no more room is available for new data
property p_credit_o;
	@(posedge clock) (credit_o[SOUTH]) |-> 
		if (FSouth.first == 0) begin
			(FSouth.last
		end else begin

		end
endproperty;
a_p_credit_o : assert property (p_credit_o);

//property p_buffer_size;
//	@(posedge clock) (!credit_i and !rx and !tx) |=> 1;		
//endproperty;
//a_p_buffer_size : assert property (p_buffer_size);

//property p_packet_rec_queue(regflit packet[]);

	//@(posedge clock) onehot_port(SOUTH)
//		|-> data;

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

//a_p_packet_rec_queue : assert property (p_packet_rec_queue(gen_pkt(16'h0011, 16'h0001)));



endmodule //RouterCC












