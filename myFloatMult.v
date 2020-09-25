module myFloatMult (multIn1_44,multIn2_44,multOut_44,clk_44,reset_44,d_o_44);
//s = 	00 - half 01 - single 10 - double	
parameter	REG_SIZE = 16;
parameter	EXP_SIZE = 5;
parameter	FRA_SIZE = 10;
parameter	BIAS	 = 15;

input clk_44, reset_44;
input [REG_SIZE-1:0] multIn1_44,multIn2_44; // 16 for half
output reg [REG_SIZE-1:0] multOut_44;
output reg d_o_44;
reg s1,s2,sr,E,FR1,F11, s1_t,s2_t,start_mult, done, sr_12,d_i,d_t,d,d_12; //sign bits, 1 for all sizes
reg [EXP_SIZE-1:0] e1,e2,er,e1_t,e2_t,er_12; // 5 bits for half
reg [FRA_SIZE-1:0] f1,f2,f1_t,f2_t,fr;

reg [EXP_SIZE-1:0] exp_diff, mod_exp_diff;
reg [2*FRA_SIZE+1:0] f_mult, multres;

reg [REG_SIZE-1:0] frU,frL, frU_12, frL_12,temp, temp2;
integer SC,i;

/* read the numbers into appropriate representation
half-precision uses s|eeee_e|ffff_ffff_ff
*/ 

always @ (negedge reset_44) begin
	$display("HELLO WORLD");
	F11 = 1'b0;
	FR1 = 1'b0;
	temp = 16'b0;
	temp2 = 16'b0;
	
end

always @(posedge clk_44 or multIn1_44 or multIn2_44) begin

	if (temp!=multIn1_44 || temp2!=multIn2_44) begin
	d_i <= 1'b1;
	d_o_44 <= 1'b0;
	temp <= multIn1_44;
	temp2 <= multIn2_44;
	end
	
	else begin 
	d_i <= 1'b0;
	end
end


always @(posedge clk_44)
begin
if (d_i) begin
	//break into sign-exponent-fraction form
	s1_t <= multIn1_44[REG_SIZE-1]; 
	s2_t <= multIn2_44[REG_SIZE-1]; 					// sign bits

	e1_t <= multIn1_44[REG_SIZE-2:REG_SIZE-EXP_SIZE-1];
	e2_t <= multIn2_44[REG_SIZE-2:REG_SIZE-EXP_SIZE-1];	// exponents

	f1_t <= multIn1_44[FRA_SIZE-1:0];
	f2_t <= multIn2_44[FRA_SIZE-1:0]; 					// fractions

	d_i <= 1'b0;
	d_t <= 1'b1;
end
end



//find exaponents and sign, pipeline the rest
always @(posedge clk_44)
begin
if (d_t) begin	
	sr <= s1_t^s2_t;
	er <= e1_t + e2_t - BIAS;
	{frU,frL} <= {1'b1,f1_t} * {1'b1,f2_t}; //save result to a 32 bit reg built from frU and frL
	
	d_t <= 1'b0;
	d <= 1'b1;
end
end
	
//normalize	
always @(posedge clk_44)
begin
if (d) begin	
	sr_12 <= sr;
	if (frU[5]) begin
	
		{frU_12,frL_12} <= {frU,frL} >> 1;
		er_12 <= er+1;
		
	end
	else begin
		{frU_12,frL_12} <= {frU,frL};
		er_12 <= er;
	end
	
	d <= 1'b0;
	d_12 <= 1'b1;
end
end	

// combine and round up if necessary
always @(posedge clk_44)
begin
if (d_12) begin
	d_12 <= 1'b0;
	
	if (frL_12[9]) begin
		multOut_44 <= {sr_12,er_12,({frU_12[3:0],frL_12[15:10]}+1'b1)}; // if the highest trimmed bit is 1, round up
	end
	else begin 
		multOut_44 <= {sr_12,er_12,{frU_12[3:0],frL_12[15:10]}};
	end
	d_o_44 <= 1'b1;  // output is ready to be read
end
end	
	
endmodule



