`timescale 1ns/1ns

module usart_tb ();

initial
begin
   $dumpfile("tb.vcd");
   $dumpvars(0,usart_tb);
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
    // #50000;
    // $finish;
end

reg key;
wire tx;
reg rx;

initial begin
    key = 0;
    #200;
    // key = 1;
    #50000;
    key = 0;
end

initial begin
    rx = 1;
    #500000;
    rx = 0;
    #5000;
    rx = 1;
    #104000;
    rx = 0;
    #40000;
    rx = 1;
end


top u_top 
(
    .clk     (clk   ),
    .rst_n   (rst_n ),
    .key     (key   ),
    .rx      (rx    ),
    .tx      (tx    )

);


endmodule

