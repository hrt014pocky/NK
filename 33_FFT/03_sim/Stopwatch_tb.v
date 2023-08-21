`timescale 1ns/1ns

module Stopwatch_tb ();

initial
begin
   $dumpfile("tb.vcd");
   $dumpvars(0,Stopwatch_tb);
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
    #50000000;
    $finish;
end

reg key;
wire [7:0] millsecond_10, second, minute;

initial begin
    key = 1'd1;
    #3000
    key = 1'd0;
    #120000
    key = 1'd1;
end


Stopwatch u1
(
    .clk (clk),
    .rst_n (rst_n),
    .key (key), 
    .millsecond_10 (millsecond_10), 
    .second (second),        
    .minute (minute)         
);


endmodule

