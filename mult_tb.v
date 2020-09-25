
//-------------------------------------- TESTBENCH --------------------------------------------


module mult_tb ();

parameter SIZE = 16;
reg [SIZE-1:0] x,y;
wire [SIZE-1:0] r;
wire d_o;
reg clk,reset;

always #100 clk = ~clk;
myFloatMult M1 (.multIn1_44(x),.multIn2_44(y),.multOut_44(r),.clk_44(clk),.reset_44(reset), .d_o_44(d_o));

initial begin
clk = 0;
reset = 1;
#1 reset = 0;
#1 reset = 1;

x = 16'h2E66; // 0.1
y = 16'hB800; // -0.5 should result in 0xAA66 or -0.05
#2000
$display("%h * %h= %h or %b",x, y, r, r);

x = 16'hB4CD; // -0.3
y = 16'h3A66; // 0.8
#2000
$display("%h * %h= %h or %b",x, y, r, r);  // should be -0.24 or 0xB3AE

x = 16'h4E46; // 25.1
y = 16'h4300; // 3.5
#2000
$display("%h * %h= %h or %b",x, y, r, r);  // should be 87.8 or 0x557D

x = 16'hC0E6; // -2.45
y = 16'hC491; // -4.566
#2000
$display("%h * %h= %h or %b",x, y, r, r);  // should be 11.19 or 0x4998

$finish;

end

initial begin

$dumpfile("my_mult.vcd");
$dumpvars();

end
endmodule
