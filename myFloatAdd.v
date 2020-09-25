

module myFloatAdd (addIn1_44,addIn2_44,addOut_44,clk_44,reset_44, data_incoming_44);

parameter	REG_SIZE = 16;
parameter	EXP_SIZE = 5;
parameter	FRA_SIZE = 10;
parameter	BIAS	 = 15;

input clk_44, reset_44, data_incoming_44;
input [REG_SIZE-1:0] addIn1_44,addIn2_44; // input data 
output reg [REG_SIZE-1:0] addOut_44; // summation result
reg d0,d1,d2,d3,d4,d5,data_ready, s1,s2,sr,read_en, E, A1,B1,A1_12, B1_12,A1_out,s1_12,s2_12,s1_23,s2_23,A1_23,E_23, done, norm_en,s1_t,s2_t,s1_out,s2_out; //sign bits
reg [EXP_SIZE-1:0] e1,e2,er,e1_12,e1_23,e2_12,e2_23,e1_t,e2_t,e1_out,e2_out;
reg [FRA_SIZE-1:0] f1,f2,fr,f1_12,f1_23,f2_12,f2_23,f1_t,f2_t,f1_out,f2_out;


function [FRA_SIZE-1:0] findOne (input [REG_SIZE-1:0] a);
/* count the number of iterations needed to find first 1 in input a*/
integer i;
reg [REG_SIZE-1:0] count;
begin 
	count = 16'b0;	
	for (i = FRA_SIZE-2; i>0; i=i-1) begin
		count = count+1;
		if (a[i] == 1) i = 0;
	end
	findOne = count;
	$display ("The shift amount is %d", findOne);
end
	
endfunction

//RESET initializations
always @ (negedge reset_44) begin

	E_23 =1'b0;
	done = 1'b1;
	A1 =1'b1;
	B1 =1'b1;
	read_en =1'b1;
	addOut_44 = 16'b0;
	$display("----> we start as this %b", addOut_44);
end

always @ (posedge data_incoming_44) begin
	
	if (!addIn2_44) begin
	addOut_44 <= addIn1_44;
	end
	else data_ready <= 1'b1;
	$display("----> 1.now this this %b", addOut_44);

end


//------------------------------------------------------------------------------------
always @ (posedge clk_44) begin 
if(data_ready) begin
	data_ready <= 1'b0;

	//break into components (sign, fraction, exponent)

	s1_t <= addIn1_44[REG_SIZE-1]; 
	s2_t <= addIn2_44[REG_SIZE-1]; // sign bits

	e1_t <= addIn1_44[REG_SIZE-2:REG_SIZE-EXP_SIZE-1];
	e2_t <= addIn2_44[REG_SIZE-2:REG_SIZE-EXP_SIZE-1];			 // exponents

	f1_t <= addIn1_44[FRA_SIZE-1:0];
	f2_t <= addIn2_44[FRA_SIZE-1:0]; 					// fractions

	d0 <= 1'b1;
	//$display("----> 1.now this this %b %b", addOut_44, {);
end
end

//input pipeline stage
always @ (posedge clk_44) begin 

if (d0) begin
	f1 <= f1_t;
	f2 <= f2_t;
	s1 <= s1_t;
	s2 <= s2_t;
	e1 <= e1_t;
	e2 <= e2_t;
	
	d0 <= 1'b0;
	d1 <= 1'b1;
end

end 



//-----------------------------------------------------------------------------
//compare exponents and align if needed

always @ (posedge clk_44) begin 
if (d1) begin
	$display("********1.BEGIN COMPARION OF EXPONENTS********"); 
	if (e1>e2) begin
	$display("E1>E2");
		{B1_12,f2_12} <= {B1,f2} >> (e1-e2);
		{A1_12,f1_12} <= {A1,f1};
		e2_12 <= e2 + (e1-e2);
		e1_12 <= e1;
		$display("{B1,f2} = %b, {B1_12,f2_12} = %b", {B1,f2},{B1_12,f2_12} );
	end

	else if (e2>e1) begin
	$display("E2>E1");	
		{A1_12,f1_12} <= {A1,f1} >> (e2-e1);
		{B1_12,f2_12} <= {B1,f2};
		e1_12 <= e1 + (e2-e1);
		e2_12 <= e2;
	end
	
	else if (e2==e1) begin
		{A1_12,f1_12} <= {A1,f1};
		{B1_12,f2_12} <= {B1,f2};
		e1_12 <= e1;
		e2_12 <= e2;
	end

	// stage 1->2 registers
	$display("********PIPELINE STAGE 1->2********"); 
	//f1_12 <= f1;
	//f2_12 <= f2;
	s1_12 <= s1;
	s2_12 <= s2;
	//e1_12 <= e1;
	//e2_12 <= e2;
	//A1_12 <= A1;
	//B1_12 <= B1;
	d1 <= 1'b0;
	d2 <= 1'b1;
end
end 

//----------------------------------------------------------------------------------------


//mantissa addition
always @ (posedge clk_44) begin
if(d2) begin
	$display("********2.BEGIN ADDITION******** , {A1_12,f1_12}= %b and {B1_12,f2_12}= %b @ time %t", {A1_12,f1_12}, {B1_12,f2_12}, $time); 
	if (!(s1_12^s2_12)) begin
		$display("********THE SIGNS ARE THE SAME********, @ time %t", $time);
		{E_23,A1_23,f1_23} = {A1_12,f1_12} + {B1_12,f2_12}; // if same sign
		s1_23 = s1_12;
	end
	else if ((s1_12^s2_12)) begin 													//if sign bit is 1
		$display("********THE SIGNS ARE DIFFERENT********, @ time %t", $time); 
		{E_23,A1_23,f1_23} = {A1_12,f1_12} + {~B1_12,~f2_12} + 1'b1;
		$display("\n\n\n IN TEST RESULTS {E_23,A1_23,f1_23}= %b s1_12=%b s2_12=%b \n\n\n ",{E_23,A1_23,f1_23}, s1_12, s2_12 );
		if (!E_23) begin
			{A1_23,f1_23} = {~A1_23,~f1_23} +1'b1; //??????????
			s1_23 = ~s1_12;
			$display("\n AFTER MANTISSA ADDITION with E_23=0 results are\nA1_23= %b, f1_23=%b",A1_23, f1_23);
		end
		else begin
			
		s1_23 = s1_12;
		
		end
	end

	//stage 2->3 registers

	$display("********PIPELINE STAGE 2->3********"); 
	//f1_23 <= f1_12;
	f2_23 = f2_12;
	//s1_23 <= s1_12;
	s2_23 = s2_12;
	e1_23 = e1_12;
	e2_23 = e2_12;
	//A1_23 <= A1;
	//E_23 <= E;
	//norm_en <=1'b1;
	d2 = 1'b0;
	d3 = 1'b1;
	$display("\n\n\n (2)IN TEST RESULTS s1_23= %b , A1_23= %b, E_23 = %b, f1_23=%b \n\n\n ", s1_23, A1_23, E_23, f1_23);
end
end




//normalization
always @ (posedge clk_44 ) begin // && norm_en?
if (d3) begin
	d3 <= 1'b0;
	d4 <= 1'b1;
	$display("********3.BEGIN NORMALIZATION********, s1_23= %b, A1_23= %b, E_23 = %b", s1_23, A1_23, E_23); 
	$display("\n\n\n (3)IN TEST RESULTS s1_23= %b , A1_23= %b, E_23 = %b, f1_23=%b \n\n\n ", s1_23, A1_23, E_23, f1_23);
	if (s1_23^s2_23) begin 					//if sign bit is 1
		$display("BEFORE RUNNING...\nA1_23=%b\t{A1_23,f1_23}=%b",A1_23,{A1_23,f1_23});
		if (!A1_23) begin
			{A1_out,f1_out} <= {A1_23,f1_23} << findOne(f1_23);
			e1_out <= e1_23 - findOne(f1_23);
			$display("RUNNING...\nA1_23=%b\t{A1_23,f1_23}=%b",A1_23,{A1_23,f1_23});
			end
		if (A1_23) begin
			{A1_out,f1_out} <= {A1_23,f1_23};
			e1_out <= e1_23;
			done <= 1;
			$display("=============\n\DONE CUZ NO NORMALIZATION NEEDED\n\n==============");
		end
		
	end
	else begin
		if(E_23) begin
			{A1_out,f1_out} <= {A1_23,f1_23} >> 1;
			A1_out <= E_23;
			e1_out <= e1_23 + 1'b1;
			done <= 1;
			$display("=============\n\DONE NORMALIZING\n\n==============");
		end
		else begin
			{A1_out,f1_out} <= {A1_23,f1_23};
			e1_out <= e1_23;
			done <= 1;
		end
	end
end
end

// output pipeline regs
always @ (posedge clk_44) begin
if (d4) begin
	//f1_out <= f1_23;
	f2_out <= f2_23;
	s1_out <= s1_23;
	s2_out <= s2_23;
	//e1_out <= e1_23;
	e2_out <= e2_23;
	d4 <= 1'b0;
	d5 <= 1'b1;
end
end


//combine parts back into 16 bit float
always @ (posedge clk_44) begin
if (d5) begin
	$display("********4.SAVE THE RESULT********"); 
	addOut_44 <= {s1_out, e1_out, f1_out};
	if (addOut_44 != 16'bx) done <= 0;
	$display("^^^^^^^^^^^^^\n\nDONE\n\n^^^^^^^^^^^^^^^");
	d5 <= 1'b0;
end	
end









endmodule





