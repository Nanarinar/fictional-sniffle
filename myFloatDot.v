/*s = 	2'b00 - half
		2'b01 - single
		2'b10 - double*/

module myFloatDot (dataIn1_44, dataIn2_44, dataOut_44, clk_44, reset_44);

parameter	REG_SIZE = 16;
parameter	EXP_SIZE = 5;
parameter	FRA_SIZE = 10;
parameter	BIAS	 = 15;

input clk_44, reset_44;
input [REG_SIZE-1:0] dataIn1_44, dataIn2_44;
output [REG_SIZE-1:0] dataOut_44;

wire [REG_SIZE-1:0] mult_res_w, add_res_w;
wire data_ready_w; //data ready to add to accumulator wire 


myFloatMult mult_module (.multIn1_44(dataIn1_44),.multIn2_44(dataIn2_44),.multOut_44(mult_res_w),.clk_44(clk_44),.reset_44(reset_44),.d_o_44(data_ready_w));

myFloatAdd add_module (.addIn1_44(mult_res_w),.addIn2_44(add_res_w),.addOut_44(add_res_w),.clk_44(clk_44),.reset_44(reset_44),.data_incoming_44(data_ready_w));


assign dataOut_44 = add_res_w;


endmodule


//------------------------------------------------ TESTBENCH --------------------------------------

module dot_tb ();

parameter SIZE = 16;
reg [SIZE-1:0] x,y;
wire [SIZE-1:0] r;
reg clk,reset;

always #100 clk = ~clk;

myFloatDot dot_module (.dataIn1_44(x), .dataIn2_44(y), .dataOut_44(r), .clk_44(clk), .reset_44(reset));

initial begin
clk = 0;
reset = 1;
#1 reset = 0;
#1 reset = 1;

x = 16'h2E66; // 0.1
y = 16'h3452; // 0.27 should result in 0x26E9 or 0.027
#2000
$display("%h * %h= %h or %b",x, y, r, r);


x = 16'h3266; // 0.2
y = 16'hBB9A; // -0.95
#2000
$display("%h * %h + accum = %h",x, y, r); // new prod should be -0.19 or 0xB214->result -0.163 or 0xB137


x = 16'h3400; // 0.25
y = 16'h3000; // 0.125
#2000
$display("%h + %h= %h",x, y, r);  // should be 3.125E-2 or 0x2800, total now 0xB037 (-0.1317 decimal)

//-------------------------------------------------------------------
x = 16'hB4CD; // -0.3
y = 16'h3A66; // 0.8
#2000
$display("%h + %h= %h, %b",x, y, r,r);  // (-0.24, 0xB3AE) + (-0.1317) = -0.3716 ( B5F2)


x = 16'h3666; // 0.4
y = 16'h3B00; // 0.875
#2000
$display("%h + %h= %h, %b",x, y, r,r);  // 0.3499, 0x3599 + (-0.3716) = -2.173E-2 (0xA590)

x = 16'h3800; // 0.5
y = 16'hBA00; // -0.75
#2000
$display("%h + %h= %h, %b",x, y, r,r);  // -0.375, 0xB600 + (-2.173E-2) = -0.3967 (0xB659)

x = 16'h3866; // 0.55
y = 16'h3666; // 0.4
#2000
$display("%h + %h= %h, %b",x, y, r,r);  // 0.2198, 0x3309 + (-0.3967) = -0.1769 (0xB1A9) mine b1aa??

x = 16'h38CD; // 0.6
y = 16'h38CD; // 0.6
#2000
$display("%h + %h= %h, %b",x, y, r,r);  // 0.36, 0x35C3 + (-0.1769) = 0.1832 (0x31DD) mine 31dc??

x = 16'hBA00; // -0.75
y = 16'h30CD; // 0.15
#2000
$display("%h + %h= %h, %b",x, y, r,r);  // -1.1255E-1, 0xAF34 + (0.1832) = 0.0707 (0x2C86) mine 2c84

x = 16'h3A66; // 0.8
y = 16'h3400; // 0.25
#2000
$display("%h + %h= %h, %b",x, y, r,r);  // 0.2, 0x3266 + (0.0707) = 0.2705 (0x3454)

x = 16'h3B00; // 0.875
y = 16'hB666; // -0.4
#2000
$display("%h + %h= %h, %b",x, y, r,r);  // -0.3499, 0xB599 + 0.2705 = -7.935E-2 (0xAD14)
x = 16'h3B33; // 0.9
y = 16'h3866; // 0.55
#2000
$display("%h + %h= %h, %b",x, y, r,r);  // 0.4949, 0x37EB + (-7.935E-2) = 0.4155 (0x36a6)




$finish;

end

initial begin

$dumpfile("my_dot.vcd");
$dumpvars();

end
endmodule





