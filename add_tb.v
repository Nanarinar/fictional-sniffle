//----------------------------------------------------------------------------------------

module add_tb ();

parameter SIZE = 16;
reg [SIZE-1:0] x,y;
wire [SIZE-1:0] r;
reg dr;
reg clk,reset;

always #100 clk = ~clk;
myFloatAdd A1 (.addIn1_44(x),.addIn2_44(y),.addOut_44(r),.clk_44(clk), .reset_44(reset),.data_incoming_44(dr));

initial begin
clk = 0;
reset = 1;
#1 reset = 0;
#1 reset = 1;

x = 16'h2E66; // 0.1
y = 16'hB800; // -0.5 should result in 0xB666 or -0.4
dr = 1;
#10
dr = 0;
#2000
$display("%h + %h= %h or %b",x, y, r, r);

x = 16'hCB80; // -15.0
y = 16'h4200; // 3.0
dr = 1;
#10
dr = 0;
#2000
$display("%h + %h= %h",x, y, r);  // should be -12 or 0xCA00

x = 16'h4E46; // 25.1
y = 16'h4300; // 3.5
dr = 1;
#10
dr = 0;
#2000
$display("%h + %h= %h",x, y, r);  // should be 28.6 or 0x4F26

x = 16'hC0E6; // -2.45
y = 16'hC491; // -4.566
dr = 1;
#10
dr = 0;
#2000
$display("%h + %h= %h",x, y, r);  // should be -7.016 or 0xC704

$finish;

end

initial begin

$dumpfile("my_add.vcd");
$dumpvars();

end
endmodule


