`timescale 1ns/1ns

module cnt_tb ();

initial
begin
   $dumpfile("tb.vcd");
   $dumpvars(0,cnt_tb);
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


endmodule

