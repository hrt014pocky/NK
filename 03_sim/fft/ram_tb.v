`timescale 1ns/1ns 

module ram_tb ();

initial
begin
   $dumpfile("tb.vcd");
   $dumpvars(0,ram_tb);
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

reg [15:0] mem[0:255];

initial begin
    $readmemh("data.inst", mem);
end


reg [7:0] j;

reg [15:0] sin360;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        sin360 <= 16'd0;
        j<=8'd0;
    end
    else begin
        sin360 <= mem[j];
        j<=j+1;
    end
end

reg we_i;
reg [9:0] addr_i, data_i;
wire[15:0] data_o;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        addr_i <= 10'd0;
    end
    else begin
        addr_i <= addr_i + 16'd1;
    end
end

ram u_ram(
    .clk    (clk    ),
    .rst_n  (rst_n  ),
    .we_i   (we_i   ),
    .addr_i ({6'd0, addr_i} ),
    .data_i (data_i ),
    .data_o (data_o )
);


initial begin
    $readmemh("datasin2+6.inst", u_ram._ram);
end

endmodule

