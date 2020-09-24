

module myFloatAdd #( parameter s = 2'b00 ) (addIn1_44,addIn2_44,addOut_44,clk_44,reset_44);

parameter	REG_SIZE = s[1] ? 64: (s[0] ? 32: 16);
parameter	EXP_SIZE = s[1] ? 11: (s[0] ? 8: 5);
parameter	FRA_SIZE = s[1] ? 52: (s[0] ? 23: 10);
parameter	BIAS	 = s[1] ? 1023: (s[0] ? 127: 15);

input clk_44, reset_44;
input [REG_SIZE-1:0] addIn1_44,addIn2_44; // input data 
output reg [REG_SIZE-1:0] addOut_44; // summation result
reg s1,s2,sr,read_en, E, A1,B1,A1_12, B1_12,A1_out,s1_12,s2_12,s1_23,s2_23,A1_23,E_23, done, norm_en,s1_t,s2_t,s1_out,s2_out; //sign bits
reg [EXP_SIZE-1:0] e1,e2,er,e1_12,e1_23,e2_12,e2_23,e1_t,e2_t,e1_out,e2_out;
reg [FRA_SIZE-1:0] f1,f2,fr,f1_12,f1_23,f2_12,f2_23,f1_t,f2_t,f1_out,f2_out;

//reg [FRA_SIZE:0] f1_t,f2_t;
//reg [FRA_SIZE+1:0] sum,save;
//reg [EXP_SIZE-1:0] exp_diff, mod_exp_diff;


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

/*	s1_t <= 0;
	s2_t <= 0;
	e1_t <= 0;
	e2_t <= 0;
	f1_t <= 0;
	f2_t <= 0;
*/
	E_23 <=1'b0;
	done <= 1'b1;
	A1 <=1'b1;
	B1 <=1'b1;
	read_en <=1'b1;
	//$display("Selected params REG_SIZE %d , BIAS %d, EXP_SIZE %D, FRA_SIZE %d", REG_SIZE, BIAS, EXP_SIZE, FRA_SIZE);

end

//------------------------------------------------------------------------------------
always @ (posedge clk_44 ) begin //read_en==1

//read_en <=0;
//done <=0;
//break into components (sign, fraction, exponent)

s1_t <= addIn1_44[REG_SIZE-1]; 
s2_t <= addIn2_44[REG_SIZE-1]; // sign bits

e1_t <= addIn1_44[REG_SIZE-2:REG_SIZE-EXP_SIZE-1];
e2_t <= addIn2_44[REG_SIZE-2:REG_SIZE-EXP_SIZE-1];			 // exponents

f1_t <= addIn1_44[FRA_SIZE-1:0];
f2_t <= addIn2_44[FRA_SIZE-1:0]; 					// fractions with appended 1.
$display("The inputs are \nData 1 : \t %b %b %b %h \nData 2 : \t %b %b %b %h", s1, f1, e1, addIn1_44,s2,f2,e2, addIn2_44);
end

//input pipeline stage
always @ (posedge clk_44) begin 

f1 <= f1_t;
f2 <= f2_t;
s1 <= s1_t;
s2 <= s2_t;
e1 <= e1_t;
e2 <= e2_t;

end 



//-----------------------------------------------------------------------------
//compare exponents and align if needed

always @ (posedge clk_44) begin 
$display("********1.BEGIN COMPARION OF EXPONENTS********"); 
if (e1>e2) begin
	{B1_12,f2_12} <= {B1,f2} >> (e1-e2);
	{A1_12,f1_12} <= {A1,f1};
	e2_12 <= e2 + (e1-e2);
	e1_12 <= e1;
end

else if (e2>e1) begin 
	{A1_12,f1_12} <= {A1,f1} >> (e2-e1);
	{B1_12,f2_12} <= {B1,f2};
	e1_12 <= e1 + (e2-e1);
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
end 

//----------------------------------------------------------------------------------------


//mantissa addition
always @ (posedge clk_44) begin
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
		{A1_23,f1_23} = {~A1_23,~f1_12} +1'b1;
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
$display("\n\n\n (2)IN TEST RESULTS s1_23= %b , A1_23= %b, E_23 = %b, f1_23=%b \n\n\n ", s1_23, A1_23, E_23, f1_23);
end




//normalization
always @ (posedge clk_44 ) begin // && norm_en?
$display("********3.BEGIN NORMALIZATION********, s1_23= %b, A1_23= %b, E_23 = %b", s1_23, A1_23, E_23); 
$display("\n\n\n (3)IN TEST RESULTS s1_23= %b , A1_23= %b, E_23 = %b, f1_23=%b \n\n\n ", s1_23, A1_23, E_23, f1_23);
if (s1_23) begin 					//if sign bit is 1
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

// output pipeline regs
always @ (posedge clk_44 && done) begin

//f1_out <= f1_23;
f2_out <= f2_23;
s1_out <= s1_23;
s2_out <= s2_23;
//e1_out <= e1_23;
e2_out <= e2_23;
end


//combine parts back into 16 bit float
always @ (posedge clk_44 && done) begin
$display("********4.SAVE THE RESULT********"); 
	addOut_44 <= {s1_out, e1_out, f1_out};
	if (addOut_44 != 16'bx) done <= 0;
	$display("^^^^^^^^^^^^^\n\nDONE\n\n^^^^^^^^^^^^^^^");
end


endmodule

//----------------------------------------------------------------------------------------

module add_tb ();

parameter SIZE = 16;
reg [SIZE-1:0] x,y;
wire [SIZE-1:0] r;
reg clk,reset;

always #100 clk = ~clk;
myFloatAdd A1 (.addIn1_44(x),.addIn2_44(y),.addOut_44(r),.clk_44(clk), .reset_44(reset));

initial begin
clk = 0;
reset = 1;
#1 reset = 0;
#1 reset = 1;

x = 16'h2E66; // 0.1
y = 16'hB800; // -0.5 should result in 0xB666 or -0.4
#2000
$display("%h + %h= %h or %b",x, y, r, r);

/*
x = 'h4251b852;//52.43
y = 'hc1e8e148;//-29.11 should be 23.32 or 41ba8f5c
#20
$display("%h + %h= %h",x, y, r); 

x = 'h42daaeb2;//109.3412
y = 'h45db9758;//7026.918 should be 7136.2592 or 45df0213 
#20
$display("%h + %h= %h",x, y, r);
 */

x = 16'hCB80; // -15.0
y = 16'h4200; // 3.0
#2000
$display("%h + %h= %h",x, y, r);  // should be -12 or 0xCA00

x = 16'h4E46; // 25.1
y = 16'h4300; // 3.5
#2000
$display("%h + %h= %h",x, y, r);  // should be 28.6 or 0x4F26

x = 16'hC0E6; // -2.45
y = 16'hC491; // -4.566
#2000
$display("%h + %h= %h",x, y, r);  // should be -7.016 or 0xC704
/*
x = 'h407C81C6A7EF9DB2;// 456.111
y = 'hC0743CA031CEAF25;// -323.78911 added should be 132.32189 or 40608a4cec41dd1a
#30
$display("%h + %h= %h",x, y, r);
*/
/*
x = 'hC2FAA666;
y = 'hBEF33333;
#20
$display("%h + %h= %h",x, y, r);
*/
$finish;

end

initial begin

$dumpfile("my_add.vcd");
$dumpvars();

end
endmodule



