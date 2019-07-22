module Sound_Module(sound, out);
	input sound;
	output out;
	
	reg sig;
	always@(*)
	begin
		if(~sound)
			sig = 1'b1;
		if (sound)
			sig = 1'b0;
	end
	assign out = sig;
	
endmodule	