module spi_dri
(
    input clk,
    input rst_n,

    input start,
    input we,
    input array_done,

    input  [7:0] wdata,
    output [7:0] rdata,

    output done,

    output cs  ,
    output sck ,
    output mosi,
    input  miso

);

localparam IDLE  = 8'd0;
localparam READ  = 8'd1;
localparam WRITE = 8'd2;

reg [7:0] state, state_next;

reg state_done;
wire bit_cnt_flag;
reg [7:0] rdata_reg;

reg do_reg;
reg cs_reg;
reg sck_reg;
reg done_reg;
reg bitstop;


reg [15:0] cnt_clk;
wire cnt_clk_clr, cnt_clk_add, cnt_clk_end;
reg [15:0] cnt_sck;
wire cnt_sck_clr, cnt_sck_add, cnt_sck_end;
reg [15:0] cnt_bit;
wire cnt_bit_add;
reg  cnt_bit_end;
reg [15:0] delay;
wire delay_add, delay_end;


wire sck_pedge;
wire sck_nedge;


always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        delay <= 0;
    end
    else if(state == IDLE)
        delay <= 0;
    else if(delay_end) begin
        delay <= 20;
    end
    else if(delay_add) begin
        delay <= delay + 1'd1;
    end
end

assign delay_add = delay < 20;
assign delay_end = delay == 20;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cnt_clk <= 0;
    end
    else if(cnt_clk_clr)
        cnt_clk <= 0;
    else if(cnt_clk_add) begin
        if(cnt_clk_end)
            cnt_clk <= 0;
        else
            cnt_clk <= cnt_clk + 1'd1;
    end
end

assign cnt_clk_clr = state == IDLE;
assign cnt_clk_add = delay_end;
assign cnt_clk_end = cnt_clk_add && cnt_clk == 5 - 1;


always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cnt_sck <= 0;
    end
    else if(cnt_sck_clr)
        cnt_sck <= 0;
    else if(cnt_sck_add) begin
        if(cnt_sck_end)
            cnt_sck <= 0;
        else
            cnt_sck <= cnt_sck + 1'd1;
    end
end

assign cnt_sck_clr = state == IDLE;
assign cnt_sck_add = cnt_clk_end;
assign cnt_sck_end = cnt_sck_add && cnt_sck == 4-1;

assign sck_pedge   = cnt_sck == 3 && cnt_clk_end;
assign sck_nedge   = cnt_sck == 1 && cnt_clk_end;
assign sck_bitedge = cnt_sck == 0 && cnt_clk_end;


always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cnt_bit <= 0;
    end
    else if(cnt_bit_add) begin
        if(cnt_bit_end)
            cnt_bit <= 0;
        else
            cnt_bit <= cnt_bit + 1'd1;
    end
end

assign cnt_bit_add = sck_bitedge && sck_reg;

always @(*) begin
    if(!rst_n)
        cnt_bit_end = 1'd0;
    else if(state == WRITE)
        cnt_bit_end = cnt_bit_add && cnt_bit == 8-1;
    else if(state == READ)
        cnt_bit_end = cnt_bit_add && cnt_bit == 8-1;
    else
        cnt_bit_end = 1'd0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        sck_reg <= 1'd0;
    else if(sck_pedge)
        sck_reg <= 1'd1;
    else if(sck_nedge)
        sck_reg <= 1'd0;
end

always @(*) begin
    if(!rst_n)
        cs_reg <= 1'd1;
    else if(start)
        cs_reg <= 1'd0;
    else if(array_done)
        cs_reg <= 1'd1;
    else 
        cs_reg <= cs_reg;
end

always @(*) begin
    if(!rst_n)
        done_reg <= 1'd0;
    else if(state == READ || state == WRITE) begin
        if(state_done == 1)
            done_reg <= 1'd1;
        else 
            done_reg <= 1'd0;
    end
    else 
        done_reg <= 1'd0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        state <= IDLE;
    end
    else begin
        state <= state_next;
    end
end

always @(*) begin
    if(!rst_n) begin
        state_next = IDLE;
    end
    else begin
        case (state)
            IDLE  : begin
                if(start)
                    if(we)
                        state_next = WRITE;
                    else 
                        state_next = READ;
                else
                    state_next = IDLE;
            end
            READ  : begin
                if(state_done)
                    state_next = IDLE;
                else 
                    state_next = READ;
            end
            WRITE : begin
                if(state_done)
                    state_next = IDLE;
                else 
                    state_next = WRITE;
            end
            default: ;
        endcase
    end
end


always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        do_reg <= 1'd0;
        rdata_reg <= 8'd0;
        bitstop <= 1'd0;
    end
    else begin
        case (state)
            IDLE  : begin
                do_reg <= 1'd0;
                rdata_reg <= 8'd0;
                bitstop <= 1'd0;
            end
            READ  : begin
                if(sck_nedge)
                    rdata_reg[7 - cnt_bit] <= miso;
            end
            WRITE : begin
                if(cnt_bit_end)
                    bitstop <= 1'd1;
                if(sck_nedge && !bitstop) begin
                    do_reg <= wdata[7 - cnt_bit];
                end
            end
            default: ;
        endcase
    end
end

reg s2idle_flag;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        state_done <= 1'd0;
        s2idle_flag <= 1'd0;
    end
    else begin
        if(state == IDLE)
            state_done <= 1'd0;
        else if(state == WRITE) begin
            if(cnt_bit_end)
                s2idle_flag <= 1'd1;
            else if(s2idle_flag && cnt_sck == 3) begin
                s2idle_flag <= 1'd0;
                state_done  <= 1'd1;
            end
        end
        else if(state == READ) begin
            if(cnt_bit_end)
                s2idle_flag <= 1'd1;
            else if(s2idle_flag && cnt_sck == 3) begin
                s2idle_flag <= 1'd0;
                state_done  <= 1'd1;
            end
        end
        else 
            state_done <= 1'd0;
    end
end

assign mosi = do_reg;
assign sck = sck_reg;
assign cs = cs_reg;
assign done = done_reg;
assign rdata = rdata_reg;
    
endmodule


