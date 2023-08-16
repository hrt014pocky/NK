module fft8 (
    input clk,
    input rst_n,
    input start,
    input  [15:0] data_in1,
    input  [15:0] data_in2,
    input  [15:0] data_in3,
    input  [15:0] data_in4,
    input  [15:0] data_in5,
    input  [15:0] data_in6,
    input  [15:0] data_in7,
    input  [15:0] data_in8,
    output [15:0] data_out1,
    output [15:0] data_out2,
    output [15:0] data_out3,
    output [15:0] data_out4,
    output [15:0] data_out5,
    output [15:0] data_out6,
    output [15:0] data_out7,
    output [15:0] data_out8

);

wire [15:0] x10_real;
wire [15:0] x11_real;
wire [15:0] x12_real;
wire [15:0] x13_real;
wire [15:0] x20_real;
wire [15:0] x21_real;
wire [15:0] x22_real;
wire [15:0] x23_real;
wire [15:0] x10_imag;
wire [15:0] x11_imag;
wire [15:0] x12_imag;
wire [15:0] x13_imag;
wire [15:0] x20_imag;
wire [15:0] x21_imag;
wire [15:0] x22_imag;
wire [15:0] x23_imag;

wire [15:0] x110_real;
wire [15:0] x111_real;
wire [15:0] x120_real;
wire [15:0] x121_real;
wire [15:0] x210_real;
wire [15:0] x211_real;
wire [15:0] x220_real;
wire [15:0] x221_real;
wire [15:0] x110_imag;
wire [15:0] x111_imag;
wire [15:0] x120_imag;
wire [15:0] x121_imag;
wire [15:0] x210_imag;
wire [15:0] x211_imag;
wire [15:0] x220_imag;
wire [15:0] x221_imag;

wire [15:0] X0_real;
wire [15:0] X1_real;
wire [15:0] X2_real;
wire [15:0] X3_real;
wire [15:0] X4_real;
wire [15:0] X5_real;
wire [15:0] X6_real;
wire [15:0] X7_real;
wire [15:0] X0_imag;
wire [15:0] X1_imag;
wire [15:0] X2_imag;
wire [15:0] X3_imag;
wire [15:0] X4_imag;
wire [15:0] X5_imag;
wire [15:0] X6_imag;
wire [15:0] X7_imag;

wire signed [15:0] WN80_real = 16'd16384; 
wire signed [15:0] WN81_real = 16'd11585;
wire signed [15:0] WN82_real = -16'd16384;
wire signed [15:0] WN83_real = -16'd11585;
wire signed [15:0] WN80_imag = 16'd0; 
wire signed [15:0] WN81_imag = -16'd11585;
wire signed [15:0] WN82_imag = -16'd0;
wire signed [15:0] WN83_imag = -16'd11585;

assign x10_real = data_in1 + data_in5;
assign x11_real = data_in2 + data_in6;
assign x12_real = data_in3 + data_in7;
assign x13_real = data_in4 + data_in8;
assign x10_imag = 16'd0;
assign x11_imag = 16'd0;
assign x12_imag = 16'd0;
assign x13_imag = 16'd0;

wire [15:0] x0_minus_x4_real = data_in1 - data_in5;
wire [15:0] x1_minus_x5_real = data_in2 - data_in6;
wire [15:0] x2_minus_x6_real = data_in3 - data_in7;
wire [15:0] x3_minus_x7_real = data_in4 - data_in8;
wire [15:0] x0_minus_x4_imag = 0;
wire [15:0] x1_minus_x5_imag = 0;
wire [15:0] x2_minus_x6_imag = 0;
wire [15:0] x3_minus_x7_imag = 0;

assign x20_real = (x0_minus_x4_real * WN80_real - x0_minus_x4_imag * WN80_imag) >> 16'd14;
assign x21_real = (x1_minus_x5_real * WN81_real - x1_minus_x5_imag * WN81_imag) >> 16'd14;
assign x22_real = (x2_minus_x6_real * WN82_real - x2_minus_x6_imag * WN82_imag) >> 16'd14;
assign x23_real = (x3_minus_x7_real * WN83_real - x3_minus_x7_imag * WN83_imag) >> 16'd14;
assign x20_imag = (x0_minus_x4_real * WN80_imag + x0_minus_x4_imag * WN80_real) >> 16'd14;
assign x21_imag = (x1_minus_x5_real * WN81_imag + x1_minus_x5_imag * WN81_real) >> 16'd14;
assign x22_imag = (x2_minus_x6_real * WN82_imag + x2_minus_x6_imag * WN82_real) >> 16'd14;
assign x23_imag = (x3_minus_x7_real * WN83_imag + x3_minus_x7_imag * WN83_real) >> 16'd14;

assign x110_real =   x10_real + x12_real;
assign x111_real =   x11_real + x13_real;
assign x120_real = ((x10_real - x12_real) * WN80_real - (x10_imag - x12_imag) * WN80_imag) >> 16'd14;
assign x121_real = ((x11_real - x13_real) * WN82_real - (x11_imag - x13_imag) * WN82_imag) >> 16'd14;
assign x110_imag =   x10_imag + x12_imag;
assign x111_imag =   x11_imag + x13_imag;
assign x120_imag = ((x10_real - x12_real) * WN80_imag + (x10_imag - x12_imag) * WN80_real) >> 16'd14;
assign x121_imag = ((x11_real - x13_real) * WN82_imag + (x11_imag - x13_imag) * WN82_real) >> 16'd14;
assign x210_real =   x20_real + x22_real;
assign x211_real =   x21_real + x23_real;
assign x220_real = ((x20_real - x22_real) * WN80_real - (x20_imag - x22_imag) * WN80_imag) >> 16'd14;
assign x221_real = ((x21_real - x23_real) * WN82_real - (x21_imag - x23_imag) * WN82_imag) >> 16'd14;
assign x210_imag =   x20_imag + x22_imag;
assign x211_imag =   x21_imag + x23_imag;
assign x220_imag = ((x20_real - x22_real) * WN80_imag + (x20_imag - x22_imag) * WN80_real) >> 16'd14;
assign x221_imag = ((x21_real - x23_real) * WN82_imag + (x21_imag - x23_imag) * WN82_real) >> 16'd14;

assign X0_real =  x110_real + x111_real;
assign X4_real = ((x110_real - x111_real) * WN80_real - (x110_imag - x111_imag) * WN80_imag) >> 16'd14;
assign X2_real =  x120_real + x121_real;
assign X6_real = ((x120_real - x121_real) * WN80_real - (x120_imag - x121_imag) * WN80_imag) >> 16'd14;
assign X1_real =  x210_real + x211_real;
assign X5_real = ((x210_real - x211_real) * WN80_real - (x210_imag - x211_imag) * WN80_imag) >> 16'd14;
assign X3_real =  x220_real + x221_real;
assign X7_real = ((x220_real - x221_real) * WN80_real - (x220_imag - x221_imag) * WN80_imag) >> 16'd14;

assign X0_imag = x110_imag + x111_imag;
assign X4_imag = ((x110_real - x111_real) * WN80_imag + (x110_imag - x111_imag) * WN80_real) >> 16'd14;
assign X2_imag = x120_imag + x121_imag;
assign X6_imag = ((x120_real - x121_real) * WN80_imag + (x120_imag - x121_imag) * WN80_real) >> 16'd14;
assign X1_imag = x210_imag + x211_imag;
assign X5_imag = ((x210_real - x211_real) * WN80_imag + (x210_imag - x211_imag) * WN80_real) >> 16'd14;
assign X3_imag = x220_imag + x221_imag;
assign X7_imag = ((x220_real - x221_real) * WN80_imag + (x220_imag - x221_imag) * WN80_real) >> 16'd14;




    
endmodule


