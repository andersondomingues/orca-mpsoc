import HeMPS_defaults::*;

`define SOUTH = HeMPS_defaults.SOUTH;
`define LOCAL = HeMPS_defaults.LOCAL;

/*
constant NPORT: integer := 5;
constant EAST: integer := 0;
constant WEST: integer := 1;
constant NORTH : integer := 2;
constant SOUTH : integer := 3;
constant LOCAL : integer := 4;
*/

module RouterCC_prop (
	
    clock, reset,
	address, //<< from generics, see WTF this has to do with internal signals
    
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
	free //: regNport := (others=>'0');
);

//all interface signals must be marked as input 
input clock, reset;
input clock_rx, rx,  credit_i;  //rx
input arrayNport_regflit data_in;
input clock_tx, tx;
input arrayNport_regflit data_out;
input credit_o; //tx

//internals must be marked as input as well
input h, ack_h, data_av, sender, data_ack;
input data;
input mux_in, mux_out;
input free;

//from generics
input address;

//commented out due to we have both-edge enabled
//default clocking @(posedge clock); endclocking 

//disable everything when reset is risen
default disable iff reset; 

//check whether an arbitrary packet is routed properly
property p_route;
	@(posedge clock) (data_in[`SOUTH] == "00010001") |-> 
		##4 data_out[`LOCAL] == "00010001";
endproperty;
a_p_route : assert property (p_route);

endmodule //RouterCC

/*
property p_input;
	@(posedge clock) (ea != action) |=> 
		(r_bacon == 0) and (r_atum == 0)
		 and (r_green == 0) and (dev == 0) and (m100 == 0);
endproperty
a_p_input : assume property (p_input);

//same assumption as above but using the busy signal
property p_input;
	@(posedge clock) (busy) |=> 
		(r_bacon == 0) and (r_atum == 0)
		 and (r_green == 0) and (dev == 0) and (m100 == 0);
endproperty
a_p_input : assume property (p_input);


//Test whether signals reset to their default values on reset. Since we indicate "reset"
//as the reset signal in the tcl script, this asserts will never be checked, neither it
//serves as assumption to reduce execution time. TODO: remove this assertion.
property p_reset;
	@(posedge clock) (reset == 1) |=> 
		(r_bacon == 0) and (bacon == 0) and (pe == 0) and (m100 == 0) and (dev == 0) and 
		(r_atum == 0)  and (atum == 0)  and (ea == action) and (d100 == 0) and (busy == 0) and 
		(r_green == 0) and (green == 0) and (count == 0);
endproperty
a_p_reset : assume property (p_reset); 

// Busy signal must rise when treating inputs from user: M100, DEV, R_bacon, R_atum,
// or R_green (see specification).
property p_busy; //busy raises when any user input is given
	@(posedge clock) ((ea == action) and 
						(m100 or dev 
							or (r_bacon and count > `B_COST)
							or (r_green and count > `G_COST)
							or (r_atum  and count > `A_COST)
						)
					 ) |=> (busy);
endproperty 
a_p_busy: assert property (p_busy);

property p_bad_input; //rises when two or more sandwichs are requested at the same time
	@(posedge clock) ((ea == action) and (
		(r_bacon and r_green) or
		(r_bacon and r_atum) or
		(r_atum  and r_green))) |=> busy and (ea == nulo);
endproperty;
a_p_bad_input: assert property (p_bad_input);

//number of credits must be zero right after the devolution
property p_dev;
	@(posedge clock) ((ea == action) and dev) |=> (count == 1'b0);
endproperty 
a_p_dev : assert property (p_dev);

//increment on the number of credits
property p_cred;
	@(posedge clock) 
		(m100 and ea == action and count < "11111") 
			|=> (ea == soma) ##1 (count == $past(count) + 1);
endproperty
a_p_cred : assert property (p_cred);

//state machine validation (state transition action [m100]=> soma)
//property p_fsm_action_to_soma;
//	@(posedge clock) (state == action) and (m100) |-> hjasaha;
//endproperty
//a_p_busy_n : assert property (p_busy_n);


//price check on green, green costs G_COST
property p_gprice;
	@(posedge clock) 
		(r_green && count > `G_COST) 
			|=> (green)[->1:`G_TTD];
endproperty
a_p_gprice : assert property (p_gprice);

//price check on atum, atum costs G_ATUM
property p_aprice;
	@(posedge clock) 
		(r_green && count > `A_COST) 
			|=> (atum)[->1:`A_TTD];
endproperty
a_p_aprice : assert property (p_aprice);

endmodule //sanduba_prop
*/

