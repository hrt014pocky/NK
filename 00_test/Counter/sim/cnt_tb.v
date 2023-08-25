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


reg [15:0] a,b,c;

always @(*) begin
    if(!rst_n) begin
        a = 16'd111;
        b = 16'd222;
        c = 16'd333;
        
    end
    else begin
        a = a + 1;
    end
end


endmodule

