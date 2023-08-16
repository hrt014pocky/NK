`timescale 1ns/1ns 

module a_tb ();

initial
begin
   $dumpfile("tb.vcd");
   $dumpvars(0,a_tb);
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
    #200000;
    $finish;
end


initial begin
    $readmemh("datasin2+6.inst", u_ram._ram);
end

endmodule

