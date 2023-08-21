`timescale 1ns/1ns 

module afft8_tb ();

initial
begin
   $dumpfile("tb.vcd");
   $dumpvars(0,afft8_tb);
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
wire [15:0] addr   ;
reg [31:0] data_i ;
wire [31:0] data_o ;
reg we;
reg req;

afft8 u_afft8(
    .clk    (clk    ),
    .rst_n  (rst_n  ),
    .start  (start  ),
    .addr   (addr   ),
    .data_o (data_o ),
    .data_i (data_i ),
    .we     (we     ),
    .req    (req    )
);

initial begin
    data_i = 0;
    we = 0;
    req = 0;
    #30 
    start = 0;
    #100
    start = 1;
    #20
    start = 0;
end


endmodule

