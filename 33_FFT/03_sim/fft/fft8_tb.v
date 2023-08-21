`timescale 1ns/1ns 

module fft8_tb ();

initial
begin
   $dumpfile("tb.vcd");
   $dumpvars(0,fft8_tb);
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
    x1r = 32'h64;
    x1i = 32'h14;
    x2r = 32'hc8;
    x2i = 32'h46;
    wni = 16'd11584;
    wnr = 16'd11584;
end

always @(*) begin
    din1 = {x1i,x1r};
    din2 = {x2i,x2r};
    wn = {wni, wnr};
end

// btf u_btf(
//     .clk   (clk   ),
//     .rst_n (rst_n ),
//     .din1  (din1  ),
//     .din2  (din2  ),
//     .wn    (wn    ),
//     .dout1 (dout1 ),
//     .dout2 (dout2 )
// );
reg [63:0] data_in1;
reg [63:0] data_in2;
reg [63:0] data_in3;
reg [63:0] data_in4;
reg [63:0] data_in5;
reg [63:0] data_in6;
reg [63:0] data_in7;
reg [63:0] data_in8;

initial begin
    data_in1 = 64'd500;
    data_in2 = 64'd500;
    data_in3 = 64'd500;
    data_in4 = 64'd500;
    data_in5 = 64'd0;
    data_in6 = 64'd0;
    data_in7 = 64'd0;
    data_in8 = 64'd0;
end

reg start;
initial begin
    start = 0;
    #500;
    start = 1;
    #20;
    start = 0;
end


fft8 u_fft8(
    .clk      (clk      ),
    .rst_n    (rst_n    ),
    .start    (start    ),
    .data_in1 (data_in1 ),
    .data_in2 (data_in2 ),
    .data_in3 (data_in3 ),
    .data_in4 (data_in4 ),
    .data_in5 (data_in5 ),
    .data_in6 (data_in6 ),
    .data_in7 (data_in7 ),
    .data_in8 (data_in8 ),
    .fft_ok   (fft_ok   ),
    .dout     (dout     )
);



endmodule

