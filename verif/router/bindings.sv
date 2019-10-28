module RouterCC_bind_top #(parameter address = 8'b00010001);

	bind RouterCC RouterCC_prop RouterCC_bind(

		.clock(clock), .reset(reset),
		
		//from generics
		.address(address),
		
		//transmit (tx, send) ports
		.clock_rx(clock_rx),    .rx(rx),
		.data_in(data_in),      .credit_o(credit_o),

		//receive (rx) ports
		.clock_tx(clock_tx),    .tx(tx),
		.data_out(data_out),    .credit_i(credit_i),

		//internals
		.h(h), .ack_h(ack_h), .data_av(data_av), 
		.sender(sender), .data_ack(data_ack),
		.data(data), .mux_in(mux_in), .mux_out(mux_out),
		.free(free)
	);

endmodule //RouterCC_bind_top

