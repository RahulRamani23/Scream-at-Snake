`timescale 1ns / 1ns // `timescale time_unit/time_precision

//SW[2:0] data inputs
//SW[9] select signal

//LEDR[0] output display

module DectoHexDisplay(
    input [7:0] score_input
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
	end
	DtoHex hundred(
		.HexA(HEX2),
		.inD(value_2)
	);
	DtoHex tens(
		.HexA(HEX1),
		.inD(value_2)
	);
	DtoHex ones(
		.HexA(HEX0),
		.inD(value_2)
	);

endmodule

module DtoHex(input[6:0] HexA, input inD);
	reg [3:0] outB;
	// First convert from decimal to binary
	always @(*)
	begin
		if(inD == 1'd9)
		begin
			outB = 4'b1001;
		end
		else if(inD == 1'd8)
		begin
			outB = 4'b1000;
		end
		else if(inD == 1'd7)
		begin
			outB = 4'b0111;
		end
		else if(inD == 1'd6)
		begin
			outB = 4'b0101;
		end
		else if(inD == 1'd5)
		begin
			outB = 4'b0101;
		end
		else if(inD == 1'd4)
		begin
			outB = 4'b0100;
		end
		else if(inD == 1'd3)
		begin
			outB = 4'b0011;
		end
		else if(inD == 1'd2)
		begin
			outB = 4'b0011;
		end
		else if(inD == 1'd1)
		begin
			outB = 4'b0001;
		end
		else if(inD == 1'd0)
		begin
			outB = 4'b0000;
		end
	end
	
	// Call the Hex decoder to display on the hex
	HEXDec(
		.Input(outB),
		.Hex(HexA)
	);
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
<<<<<<< HEAD

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

=======
>>>>>>> parent of 43d94ee... Merge branch 'master' of https://github.com/RahulRamani23/Scream-at-Snake
	
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
