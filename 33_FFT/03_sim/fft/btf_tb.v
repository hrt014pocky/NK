`timescale 1ns/1ns 

module btf_tb ();

initial
begin
   $dumpfile("tb.vcd");
   $dumpvars(0,btf_tb);
end

reg clk, rst_n;

always #10 clk = ~clk;

initial begin
    clk = 0;
    rst_n = 1;
    #8
    rst_n = 0;
    #8
    rst_n = 1;
    #50000;
    $finish;
end

reg [31:0] x1r, x1i, x2r, x2i;
reg [15:0] wnr, wni;
wire [63:0] dout1, dout2;
reg [63:0] din1, din2;
reg [31:0] wn;

initial begin
    x1r = 0;
    x1i = 0;
    x2i = 0;
    x2r = 0;
    wni = 0;
    wnr = 0;
    #300;
    x1r = 32'd500;
    x1i = 32'd0;
    x2r = 32'd0;
    x2i = -32'd500;
    wni = 16'd0;
    wnr = 16'd16384;
end

always @(*) begin
    din1 = {x1i,x1r};
    din2 = {x2i,x2r};
    wn = {wni, wnr};
end

btf u_btf(
    .clk   (clk   ),
    .rst_n (rst_n ),
    .din1  (din1  ),
    .din2  (din2  ),
    .wn    (wn    ),
    .dout1 (dout1 ),
    .dout2 (dout2 )
);

reg[31:0] num1;
reg [15:0] num2;

wire [63:0] re1 = {{32{num1[31]}}, num1} * {{48{num2[15]}}, num2};

initial begin
    num1 = -32'd50;
    num2 = 16'd11584;
end

endmodule

