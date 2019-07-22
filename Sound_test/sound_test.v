module sound_test(GPIO, LEDR, CLOCK50, KEY);
	input [0:0]GPIO;
	input CLOCK50;
	input [3:0]KEY;
	output [17:0]LEDR;
	Sound_Module sound(GPIO[0], LEDR[0]);
	assign LEDR[1] = KEY[0];
endmodule
	