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

reg start;
reg [15:0] data_in1;
reg [15:0] data_in2;
reg [15:0] data_in3;
reg [15:0] data_in4;
reg [15:0] data_in5;
reg [15:0] data_in6;
reg [15:0] data_in7;
reg [15:0] data_in8;
wire[15:0] data_out1;
wire[15:0] data_out2;
wire[15:0] data_out3;
wire[15:0] data_out4;
wire[15:0] data_out5;
wire[15:0] data_out6;
wire[15:0] data_out7;
wire[15:0] data_out8;



initial begin
    start = 0;
    #20
    data_in1 = 128;
    data_in2 = 128;
    data_in3 = 128;
    data_in4 = 128;
    data_in5 = 0;
    data_in6 = 0;
    data_in7 = 0;
    data_in8 = 0;
    #300;
    start = 1;
    #50
    start = 0;
end

fft8 u_fft8(
    .clk       (clk       ),
    .rst_n     (rst_n     ),
    .start     (start     ),
    .data_in1  (data_in1  ),
    .data_in2  (data_in2  ),
    .data_in3  (data_in3  ),
    .data_in4  (data_in4  ),
    .data_in5  (data_in5  ),
    .data_in6  (data_in6  ),
    .data_in7  (data_in7  ),
    .data_in8  (data_in8  ),
    .data_out1 (data_out1 ),
    .data_out2 (data_out2 ),
    .data_out3 (data_out3 ),
    .data_out4 (data_out4 ),
    .data_out5 (data_out5 ),
    .data_out6 (data_out6 ),
    .data_out7 (data_out7 ),
    .data_out8 (data_out8 )
);


endmodule

