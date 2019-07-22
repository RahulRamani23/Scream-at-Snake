module Sound_Module(sound, out, enable);
	input sound;
	input enable;
	output out;
	
	reg sig;
	always@(*)
	begin
		if(~sound)
			sig = 1'b1;
		if (sound)
			sig = 1'b0;
	end
	assign out = sig || ~enable;
	
endmodule	