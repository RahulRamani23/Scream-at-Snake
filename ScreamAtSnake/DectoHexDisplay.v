`timescale 1ns / 1ns // `timescale time_unit/time_precision

//SW[2:0] data inputs
//SW[9] select signal

//LEDR[0] output display

module DectoHexDisplay(
    input [7:0] score_input,
	 output [11:0] hexval 
);

	wire [29:0] digit_2, digit_1, digit_0;
	reg [3:0] value_2, value_1, value_0;
	wire [3:0] hund, ten, one;
	
	// get the value of each digit
	always @(*)
	begin
		 value_2 <= (score_input / 100) % 10; // Hundreds
		 value_1 <= (score_input / 10) % 10; // tens
		 value_0 <= score_input % 10 ; // ones
		 if(value_2 == 4'b0010 & value_1 == 4'b0101 & value_0 == 4'b0001)
		 begin
			value_2 <= 4'b0000;
			value_1 <= 4'b0000;
			value_0 <= 4'b0000;
		 end
	end
	assign hexval = {value_2, value_1, value_0};
endmodule

module HEXDec(Input, Hex);
	input [3:0] Input;
	output [6:0] Hex;
	HexSeg_0 seg0(.c0(Input[0]), .c1(Input[1]), .c2(Input[2]), .c3(Input[3]), .m(Hex[0]));
	HexSeg_1 seg1(.c0(Input[0]), .c1(Input[1]), .c2(Input[2]), .c3(Input[3]), .m(Hex[1]));
	HexSeg_2 seg2(.c0(Input[0]), .c1(Input[1]), .c2(Input[2]), .c3(Input[3]), .m(Hex[2]));
	HexSeg_3 seg3(.c0(Input[0]), .c1(Input[1]), .c2(Input[2]), .c3(Input[3]), .m(Hex[3]));
	HexSeg_4 seg4(.c0(Input[0]), .c1(Input[1]), .c2(Input[2]), .c3(Input[3]), .m(Hex[4]));
	HexSeg_5 seg5(.c0(Input[0]), .c1(Input[1]), .c2(Input[2]), .c3(Input[3]), .m(Hex[5]));
	HexSeg_6 seg6(.c0(Input[0]), .c1(Input[1]), .c2(Input[2]), .c3(Input[3]), .m(Hex[6]));
	
	
endmodule

module HEXH(Hex);
	output [6:0] Hex;
	assign Hex[0] = 1'b1;
	assign Hex[1] = 1'b0;
	assign Hex[2] = 1'b0;
	assign Hex[3] = 1'b1;
	assign Hex[4] = 1'b0;
	assign Hex[5] = 1'b0;
	assign Hex[6] = 1'b0;
	
	
endmodule

	
module HexSeg_0(c0, c1, c2, c3, m);
	input c0, c1, c2, c3;
	output m;
	
	assign m = ~c3 & c2 & ~c1 & ~c0 | ~c3 & ~c2 & ~c1 & c0 | c3 & c2 & ~c1 & c0 | c3 & ~c2 & c1 & c0;
endmodule

module HexSeg_1(c0, c1, c2, c3, m);
	input c0, c1, c2, c3;
	output m;
	
	assign m = ~c3 & c2 & ~c1 & c0 | c3 & c2 & ~c0 | c3 & c1 & c0 | c2 & c1 & ~c0;
endmodule

module HexSeg_2(c0, c1, c2, c3, m);
	input c0, c1, c2, c3;
	output m;
	
	assign m = c3 & c2 & c1 | c3 & c2 & ~c0 | ~c3 & ~c2 & c1 & ~c0;
endmodule

module HexSeg_3(c0, c1, c2, c3, m);
	input c0, c1, c2, c3;
	output m;
	
	assign m = c2 & c1 & c0 | ~c3 & ~c2 & ~c1 & c0 | ~c3 & c2 & ~c1 & ~c0 | c3 & ~c2 & c1 & ~c0;
endmodule

module HexSeg_4(c0, c1, c2, c3, m);
	input c0, c1, c2, c3;
	output m;
	
	assign m = ~c3 & c0 | ~c2 & ~c1 & c0 | ~c3 & c2 & ~c1;
endmodule

module HexSeg_5(c0, c1, c2, c3, m);
	input c0, c1, c2, c3;
	output m;
	
	assign m = ~c3 & ~c2 & c0 | ~c3 & c1 & c0 | ~c3 & ~c2 & c1 & ~c0 | c3 & c2 & ~c1 & c0;
	
endmodule


module HexSeg_6(c0, c1, c2, c3, m);
	input c0, c1, c2, c3;
	output m;
	
	assign m = ~c3 & ~c2 & ~c1 | c3 & c2 & ~c1 & ~c0 | ~c3 & c2 & c1 & c0;
	
endmodule