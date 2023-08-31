module i2c_drv 
    #(
      parameter   SLAVE_ADDR = 7'b0111100   ,  
      parameter   CLK_FREQ   = 32'd50_000_000, 
      parameter   I2C_FREQ   = 32'd400_000     
    )
(    
    input clk,
    input rst_n,

    input exec,
    input we,
    input addr_hl,
    input [15:0] word_addr,
    input  [7:0] wdata,
    output [7:0] rdata,
    output scl,
    inout  sda,
    output done,
    output reg i2c_clk
);

localparam CNTCLK_MAX = CLK_FREQ/I2C_FREQ >> 2'd3;

localparam IDLE         = 8'd0;
localparam START1       = 8'd1;
localparam DEVICE1_ADDR = 8'd2;
localparam ACK1         = 8'd3;
localparam WORD_ADDRH   = 8'd4;
localparam ACK2         = 8'd5;
localparam WORD_ADDRL   = 8'd6;
localparam ACK3         = 8'd7;
localparam WR_DATA      = 8'd8;
localparam ACK4         = 8'd9;
localparam START2       = 8'd10;
localparam DEVICE2_ADDR = 8'd11;
localparam ACK5         = 8'd12;
localparam RD_DATA      = 8'd13;
localparam NOACK        = 8'd14;
localparam STOP         = 8'd15;

wire sda_in;

reg [7:0] rdata_reg;
reg scl_reg, sda_reg;
wire sda_sel;

reg [1:0] done_reg;

wire i2c_edge ;
wire i2c_nedge;

reg [7:0] state, state_next;

reg [15:0] cntclk;
wire cntclk_end;
reg [1:0] cntscl;
reg cntscl_en;

reg [15:0] cntbit;
wire cntbit_add, cntbit_end, cntbit_ret;

reg exec_reg;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        exec_reg <= 1'd0;
    end
    else if(exec)
        exec_reg <= 1'd1;
    else if(i2c_edge) 
        exec_reg <= 1'd0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        done_reg <= 1'd0;
    else if(state == STOP && i2c_nedge && cntclk_end) 
        done_reg <= done_reg + 1;
    else if(state == STOP)
        done_reg <= done_reg;
    else 
        done_reg <= 1'd0;
end

assign done = done_reg[1];

// i2c 时钟生成
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cntclk <= 0;
    end
    else if(cntclk_end)
        cntclk <= 0;
    else
        cntclk <= cntclk + 1'd1;
end

assign cntclk_end = cntclk == CNTCLK_MAX - 1;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        i2c_clk <= 1'd1;
    end
    else if(cntclk_end) begin
        i2c_clk <= ~i2c_clk;
    end
end

always @(posedge i2c_clk or negedge rst_n) begin
    if(!rst_n) 
        cntscl_en <= 1'd0;
    else if(exec_reg)
        cntscl_en <= 1'd1;
    else if(state == STOP && i2c_nedge)
        cntscl_en <= 1'd0;
end

always @(posedge i2c_clk or negedge rst_n) begin
    if(!rst_n) 
        cntscl <= 0;
    else if(cntscl_en) 
        cntscl <= cntscl + 1'd1;
    else 
        cntscl <= 0;
end

assign i2c_edge  = cntscl == 2'd3;
assign i2c_nedge = cntscl == 2'd1;

always @(posedge i2c_clk or negedge rst_n) begin
    if(!rst_n)
        scl_reg <= 1'd1;
    else if(i2c_edge)
        scl_reg <= 1'd1;
    else if(i2c_nedge && (state != STOP))
        scl_reg <= 1'd0;
    else if(state == IDLE)
        scl_reg <= 1'd1;
    else
        scl_reg <= scl_reg;
end

always @(posedge i2c_clk or negedge rst_n) begin
    if(!rst_n) 
        cntbit <= 0;
    else if(cntbit_end || cntbit_ret) 
        cntbit <= 0;
    else if(cntbit_add) 
        cntbit <= cntbit + 1'd1;
end

assign cntbit_add =  cntscl == 1 && ((state == DEVICE1_ADDR) || (state == WR_DATA) 
                    || (state == RD_DATA) || (state == WORD_ADDRH)
                    || (state == WORD_ADDRL) || (state == DEVICE2_ADDR));
assign cntbit_ret = cntbit_add && cntbit == 8;
assign cntbit_end = (state == IDLE) || (state == STOP) || (state == ACK1) 
                 || (state == ACK2) || (state == ACK3) || (state == ACK4) 
                 || (state == ACK5) || (state == NOACK) || (state == START1) || (state == START2);

// i2c状态机
always @(posedge i2c_clk or negedge rst_n) begin
    if(!rst_n) 
        state <= IDLE;
    else 
        state <= state_next;
end

always @(*) begin
    if(!rst_n) begin
        state_next = IDLE;
    end
    else begin
        case (state)
            IDLE         : begin
                if(exec_reg )
                    state_next = START1;
                else
                    state_next = IDLE;
            end
            START1       : begin
                if(cntscl == 2) 
                    state_next = DEVICE1_ADDR;
                else
                    state_next = START1;
            end
            DEVICE1_ADDR : begin
                if(cntscl == 2 && cntbit == 8)
                    state_next = ACK1;
                else 
                    state_next = DEVICE1_ADDR;
            end
            ACK1         : begin
                if(cntscl == 2) begin
                    if(addr_hl)
                        state_next = WORD_ADDRH;
                    else
                        state_next = WORD_ADDRL;                    
                end
                else 
                    state_next = ACK1;
            end
            WORD_ADDRH   : begin
                if(cntscl == 2 && cntbit == 8)
                    state_next = ACK2;
                else 
                    state_next = WORD_ADDRH;
            end
            ACK2         : begin
                if(cntscl == 2) 
                    state_next = WORD_ADDRL;
                else
                    state_next = ACK2;
            end
            WORD_ADDRL   : begin
                if(cntscl == 2 && cntbit == 8)
                    state_next = ACK3;
                else 
                    state_next = WORD_ADDRL;
            end
            ACK3         : begin
                if(cntscl == 2) begin
                    if(we)
                        state_next = WR_DATA;
                    else
                        state_next = START2;                    
                end
                else
                    state_next = ACK3;
            end
            WR_DATA      : begin
                if(cntscl == 2 && cntbit == 8)
                    state_next = ACK4;
                else 
                    state_next = WR_DATA;
            end
            ACK4         : begin
                if(cntscl == 2) 
                    state_next = STOP;
                else
                    state_next = ACK4;
            end
            START2       : begin
                if(cntscl == 2) 
                    state_next = DEVICE2_ADDR;
                else
                    state_next = START2;
            end
            DEVICE2_ADDR : begin
                if(cntscl == 2 && cntbit == 8)
                    state_next = ACK5;
                else 
                    state_next = DEVICE2_ADDR;
            end
            ACK5         : begin
                if(cntscl == 2) 
                    state_next = RD_DATA;
                else
                    state_next = ACK5;
            end
            RD_DATA      : begin
                if(cntscl == 2 && cntbit == 8)
                    state_next = NOACK;
                else 
                    state_next = RD_DATA;
            end
            NOACK        : begin
                if(cntscl == 2) 
                    state_next = STOP;
                else
                    state_next = NOACK;
            end
            STOP         : begin
                if(cntscl == 1) 
                    state_next = IDLE;
                else
                    state_next = STOP;
            end
            default: ;
        endcase
    end
end

always @(posedge i2c_clk or negedge rst_n) begin
    if(!rst_n) begin
        sda_reg <= 1'd1;
        rdata_reg <= 8'd0;
    end
    else begin
        case (state)
            IDLE         : begin
                sda_reg <= 1'd1;
                rdata_reg <= 8'd0;
            end
            START1       : begin
                if(cntscl == 2'd0) begin
                    sda_reg <= 1'd0;
                end
            end
            DEVICE1_ADDR : begin
                if(cntbit <= 6)
                    sda_reg <= SLAVE_ADDR[6 - cntbit];
                else 
                    sda_reg <= 0;
            end
            ACK1         : begin
                if(addr_hl) 
                    sda_reg <= word_addr[15];
                else 
                    sda_reg <= word_addr[7];
            end
            WORD_ADDRH   : begin
                sda_reg <= word_addr[15 - cntbit];
            end
            ACK2         : begin
                sda_reg <= word_addr[7];
            end
            WORD_ADDRL   : begin
                sda_reg <= word_addr[7 - cntbit];
            end
            ACK3         : begin
                if(we)
                    sda_reg <= wdata[7];
                else
                    sda_reg <= 1'd1;
            end
            WR_DATA      : begin
                sda_reg <= wdata[7 - cntbit];
            end
            ACK4         : begin
                sda_reg <=  1'b0;
            end
            START2       : begin
                if(cntscl == 0)
                    sda_reg <= 1'd0;
            end
            DEVICE2_ADDR : begin
                if(cntbit <= 6)
                    sda_reg <= SLAVE_ADDR[6 - cntbit];
                else 
                    sda_reg <= 1;
            end
            ACK5         : begin
                sda_reg <=  1'b1;
            end
            RD_DATA      : begin
                if(cntscl == 0)begin
                    rdata_reg[7 - cntbit] = sda_in;
                end
            end
            NOACK        : begin
                sda_reg <=  1'b0;
            end
            STOP         : begin
                if(cntscl == 0)
                    sda_reg <= 1'd1;
            end
            default: ;
        endcase
    end
end

assign sda_in = sda;
assign scl = scl_reg;

// 0:读，1：写
assign sda_sel = (state == IDLE         ) || (state == START1       ) 
              || (state == DEVICE1_ADDR ) || (state == WORD_ADDRH   ) 
              || (state == WORD_ADDRL   ) || (state == WR_DATA      ) 
              || (state == START2       ) || (state == DEVICE2_ADDR ) 
              || (state == STOP         );

assign  sda = (sda_sel == 1'b1) ? sda_reg : 1'bz;

assign rdata = rdata_reg;

endmodule

