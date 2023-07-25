`timescale 1ns/1ns

module led_tb ();

initial
begin
   $dumpfile("tb.vcd");
   $dumpvars(0,led_tb);
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

reg led;
reg[15:0] cnt;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        led <= 1'd0;
        cnt <= 16'd0;
    end
    else begin
        led <= cnt[5];
        cnt <= cnt + 1'd1;
    end
end

endmodule

