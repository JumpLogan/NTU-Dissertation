module QPSK(
		CLK,
		serial_in,
		Ik,
		Qk);
		
input	CLK;
input	serial_in;
output signed [2:0]	Ik, Qk;

reg oldI1, oldI2, newI1, newI2;
reg signed [2:0]	Ik, Qk;
reg [2:0] count;
reg [3:0] shift, parallel_out;

initial begin
	count = 3'b000;
	shift = 4'b0000;
	parallel_out = 4'b0000;
	oldI1 = 1;
	oldI2 = 0;
end 

always@(posedge CLK) begin
	
	// Shift register
		count = count + 3'b001;
		shift = {shift[2:0],serial_in};
		if (count == 4) begin
			parallel_out = shift;
			count = 0;
		end
		//Differential coding
		if (oldI1 == oldI2) begin
			newI1 = parallel_out[0] ^ oldI1;
			newI2 = parallel_out[1] ^ oldI2;
		end
		else begin
			newI1 = parallel_out[1] ^ oldI1;
			newI2 = parallel_out[0] ^ oldI2;
		end

		oldI1 = newI1;
		oldI2 = newI2;
		
		 //Remap to {-2,-1,1,2} 00->-2, 01->-1, 11->1 10->2
		if (~newI1 & ~newI2)
			Ik = -2;
		if (~newI1 & newI2)
			Ik = -1;
		if (newI1 & newI2)
			Ik = 1;
		if (newI1 & ~newI2)
			Ik = 2;
		if (~parallel_out[2] & ~parallel_out[3])
			Qk = -2;
		if (~parallel_out[2] & parallel_out[3])
			Qk = -1;
		if (parallel_out[2] & parallel_out[3])
			Qk = 1;
		if (parallel_out[2] & ~parallel_out[3])
			Qk = 2;	
end	
endmodule

