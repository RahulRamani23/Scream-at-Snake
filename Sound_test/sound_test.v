module sound_test(GPIO, LEDR, SW);
	input [0:0]GPIO;
	input [17:0]SW;
	output [17:0]LEDR;
	Sound_Module sound(.sound(GPIO[0]), .out(LEDR[0]), .enable(SW[1]));
endmodule
	