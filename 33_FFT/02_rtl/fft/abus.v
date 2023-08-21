module abus (
    input clk,
    input rst_n,

    // sample
    input      [31:0] m0_addr_i,
    input      [31:0] m0_data_i,
    output reg [31:0] m0_data_o,
    input             m0_we_i,
    input             m0_req,

    // fft
    input      [31:0] m1_addr_i,
    input      [31:0] m1_data_i,
    output reg [31:0] m1_data_o,
    input             m1_we_i,
    input             m1_req,

    // ram real
    output reg [31:0] s0_addr_o,
    input      [31:0] s0_data_i,
    output reg [31:0] s0_data_o,
    output reg        s0_we_o,

    // ram imag
    output reg [31:0] s1_addr_o,
    input      [31:0] s1_data_i,
    output reg [31:0] s1_data_o,
    output reg        s1_we_o,

    // ramwn
    output reg [31:0] s2_addr_o,
    input      [31:0] s2_data_i,
    output reg [31:0] s2_data_o,
    output reg        s2_we_o
);

localparam ZERO = 32'd0;
localparam WE_DISABLE = 1'd0;

// 总线仲裁
localparam MASTER0 = 2'b01;
localparam MASTER1 = 2'b10;

reg [3:0] grant;

always @(*) begin
    if(m1_req) begin
        grant  = MASTER1;
    end
    else begin
        grant  = MASTER0;
    end
end

always @(*) begin
    m0_data_o = ZERO;
    m1_data_o = ZERO;

    s0_addr_o = ZERO;
    s0_data_o = ZERO;
    s0_we_o   = WE_DISABLE;

    s1_addr_o = ZERO;
    s1_data_o = ZERO;
    s1_we_o   = WE_DISABLE;
    case (grant)
        2'd0: begin
            case (m0_addr_i[31:28])
                4'd0: begin // 
                    s0_addr_o = {4'd0, m0_addr_i[27:0]};
                    s0_data_o = m0_data_i;
                    m0_data_o = s0_data_i;
                    s0_we_o   = m0_we_i;
                end
                4'd1: begin
                    s1_addr_o = {4'd0, m0_addr_i[27:0]};
                    s1_data_o = m0_data_i;
                    m0_data_o = s1_data_i;
                    s1_we_o   = m0_we_i;
                end
                4'd2: begin
                    s2_addr_o = {4'd0, m0_addr_i[27:0]};
                    s2_data_o = m0_data_i;
                    m0_data_o = s2_data_i;
                    s2_we_o   = m0_we_i;
                end
                default: ;
            endcase
        end
        2'd1: begin
            case (m1_addr_i[31:28])
                4'd0: begin // 
                    s0_addr_o = {4'd0, m1_addr_i[27:0]};
                    s0_data_o = m1_data_i;
                    m1_data_o = s0_data_i;
                    s0_we_o   = m1_we_i;
                end
                4'd1: begin
                    s1_addr_o = {4'd0, m1_addr_i[27:0]};
                    s1_data_o = m1_data_i;
                    m1_data_o = s1_data_i;
                    s1_we_o   = m1_we_i;
                end
                4'd2: begin
                    s2_addr_o = {4'd0, m1_addr_i[27:0]};
                    s2_data_o = m1_data_i;
                    m1_data_o = s2_data_i;
                    s2_we_o   = m1_we_i;
                end
                default: ;
            endcase
        end
    endcase
end


endmodule
