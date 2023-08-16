`timescale 1ns/1ns 

module fft1024_tb ();

initial
begin
   $dumpfile("tb.vcd");
   $dumpvars(0,fft1024_tb);
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
wire fft_ok;

initial begin
    start = 0;
end

fft1024 u_fft1024(
    .clk    (clk    ),
    .rst_n  (rst_n  ),
    .start  (start  ),
    .fft_ok (fft_ok )
);


initial begin
    $readmemh("datasin2+6.inst", u_fft1024.u_ram._ram);
end

initial begin
    $readmemh("data.inst", u_fft1024.u_ramwn._ram);
end

endmodule

