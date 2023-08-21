module btf (
    input clk,
    input rst_n,
    input [63:0] din1,
    input [63:0] din2,
    input [31:0] wn,
    output reg [63:0] dout1,
    output reg [63:0] dout2
);

// 高32位虚部 低32位虚部

wire [31:0] xpr = din1[31:0] - din2[31:0];
wire [31:0] xpi = din1[63:32] - din2[63:32];
wire [15:0] wnr = wn[15:0];
wire [15:0] wni = wn[31:16];
wire [63:0] xprwnr = {{32{xpr[31]}}, xpr} * {{48{wnr[15]}}, wnr};
wire [63:0] xpiwni = {{32{xpi[31]}}, xpi} * {{48{wni[15]}}, wni};
wire [63:0] xprwni = {{32{xpr[31]}}, xpr} * {{48{wni[15]}}, wni};
wire [63:0] xpiwnr = {{32{xpi[31]}}, xpi} * {{48{wnr[15]}}, wnr};
wire [31:0] xprwnrshitf = xprwnr[45:14];
wire [31:0] xpiwnishitf = xpiwni[45:14];
wire [31:0] xprwnishitf = xprwni[45:14];
wire [31:0] xpiwnrshitf = xpiwnr[45:14];
wire [31:0] res1r = din1[31:0 ] + din2[31:0 ];
wire [31:0] res1i = din1[63:32] + din2[63:32];
wire [31:0] res2r = xprwnrshitf - xpiwnishitf;
wire [31:0] res2i = xprwnishitf + xpiwnrshitf;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        dout1 <= 64'd0;
        dout2 <= 64'd0;
    end
    else begin
        dout1 <= {res1i, res1r};
        dout2 <= {res2i, res2r};
    end
end





endmodule

