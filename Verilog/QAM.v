module QAM(
		CLK,
		serial_in,
		Ik,
		Qk,
		Isam,
		Qsam,
		Irrc,
		Qrrc);

input CLK;
input	serial_in;
output signed [2:0]	Ik, Qk;
output signed [2:0]	Isam, Qsam;
output signed [2:0]	Irrc, Qrrc;

wire	signed [2:0]	Ik, Qk;
wire	signed [2:0]	Isam, Qsam;
wire	signed [2:0]	Irrc, Qrrc;

IQ U_iq(
	.CLK				(CLK),
	.serial_in		(serial_in),
	.Ik				(Ik),
	.Qk				(Qk));

Upsample U_upsample(
	.CLK				(CLK),
	.Ik				(Ik),
	.Qk				(Qk),
	.Isam				(Isam),
	.Qsam				(Qsam));

RRC_filter U_rrc(
	.CLK				(CLK),
	.Isam				(Isam),
	.Qsam				(Qsam),
	.Irrc				(Irrc),
	.Qrrc				(Qrrc));
	
endmodule

module IQ(
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

module Upsample(
    CLK,
	 Ik,
	 Qk,
	 Isam,
	 Qsam);

input	CLK;
input	signed [2:0]	Ik, Qk;
output signed [2:0]	Isam, Qsam;

parameter NUM_SAMPLES = 16;

reg signed [2:0]	Isam, Qsam;
integer i;

initial i = 0;

always@(posedge CLK) begin
	if(i % NUM_SAMPLES == 0) begin
		Isam = Ik;
		Qsam = Qk;
	end
	else begin
		Isam = 0;
		Qsam = 0;
	end
	i = i + 1;
end
endmodule

module RRC_filter(
	CLK,
	Isam,
	Qsam,
	Irrc,
	Qrrc);

input	CLK;
input	signed [2:0]	Isam, Qsam;
output signed [2:0]	Irrc, Qrrc;

parameter NUM_TAPS = 40;
parameter c0 = 184,
	c1 = 278,
	c2 = 331,
	c3 = 320,
	c4 = 231,
	c5 = 67,
	c6 = -156,
	c7 = -403,
	c8 = -629,
	c9 = -778,
	c10 = -798,
	c11 = -648,
	c12 = -307,
	c13 = 223,
	c14 = 912,
	c15 = 1703,
	c16 = 2520,
	c17 = 3278,
	c18 = 3892,
	c19 = 4292,
	c20 = 4431,
	c21 = 4292,
	c22 = 3892,
	c23 = 3278,
	c24 = 2520,
	c25 = 1703,
	c26 = 912,
	c27 = 223,
	c28 = -307,
	c29 = -648,
	c30 = -798,
	c31 = -778,
	c32 = -629,
	c33 = -403,
	c34 = -156,
	c35 = 67,
	c36 = 231,
	c37 = 320,
	c38 = 331,
	c39 = 278,
	c40 = 184;
	
reg signed [2:0] Ireg	[NUM_TAPS-1 : 0];
reg signed [2:0] Qreg	[NUM_TAPS-1 : 0];
reg signed [2:0] Irrc, Qrrc;
reg signed [15:0] Iacc, Qacc;
integer i;

always@(posedge CLK) begin
	Ireg[0] = Isam; 
	Qreg[0] = Qsam;
	
	Iacc = c0*Ireg[0] + c1*Ireg[1] + c2*Ireg[2] + c3*Ireg[3] + c4*Ireg[4] + c5*Ireg[5] + c6*Ireg[6] + c7*Ireg[7] + c8*Ireg[8] + c9*Qreg[9] 
		+ c10*Ireg[10] + c11*Ireg[11] + c12*Ireg[12] + c13*Ireg[13] + c14*Ireg[14] + c15*Ireg[15] + c16*Ireg[16] + c17*Ireg[17] + c18*Qreg[18] + c19*Qreg[19] 
		+ c20*Ireg[20] + c21*Ireg[21] + c22*Ireg[22] + c23*Ireg[23] + c24*Ireg[24] + c25*Ireg[25] + c26*Ireg[26] + c27*Ireg[27] + c28*Qreg[28] + c29*Qreg[29] 
		+ c30*Ireg[30] + c31*Ireg[31] + c32*Ireg[32] + c33*Ireg[33] + c34*Ireg[34] + c35*Ireg[35] + c36*Ireg[36] + c37*Ireg[37] + c38*Qreg[38] + c39*Qreg[39];
		
	Qacc = c0*Qreg[0] + c1*Qreg[1] + c2*Qreg[2] + c3*Qreg[3] + c4*Qreg[4] + c5*Qreg[5] + c6*Qreg[6] + c7*Qreg[7] + c8*Qreg[8] + c9*Qreg[9] 
		+ c10*Qreg[10] + c11*Qreg[11] + c12*Qreg[12] + c13*Qreg[13] + c14*Qreg[14] + c15*Qreg[15] + c16*Qreg[16] + c17*Qreg[17] + c18*Qreg[18] + c19*Qreg[19] 
		+ c20*Qreg[20] + c21*Qreg[21] + c22*Qreg[22] + c23*Qreg[23] + c24*Qreg[24] + c25*Qreg[25] + c26*Qreg[26] + c27*Qreg[27] + c28*Qreg[28] + c29*Qreg[29] 
		+ c30*Qreg[30] + c31*Qreg[31] + c32*Qreg[32] + c33*Qreg[33] + c34*Qreg[34] + c35*Qreg[35] + c36*Qreg[36] + c37*Qreg[37] + c38*Qreg[38] + c39*Qreg[39];
	
	Irrc = Iacc << 15;
	Qrrc = Qacc << 15;
	
	for(i = NUM_TAPS-1; i > 0; i=i-1) begin	/* Shift delay samples */
		Ireg[i] = Ireg[i-1];
		Qreg[i] = Qreg[i-1];
	end
end
endmodule
