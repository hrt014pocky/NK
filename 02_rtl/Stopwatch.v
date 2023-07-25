
/**
 *  项目名称：数字秒表
 *  包含内容：1、显示分、秒的数字秒表
 *           
 *   key 短按：开始、暂停；长按：停止
 *
*/

module Stopwatch 
#(  parameter       CLOCK = 8) //系统时钟50M
(
    input  clk,
    input  rst_n,
    input  key, 
    output reg [7 :0] millsecond_10,    // 10ms
    output reg [7 :0] second,           // s
    output reg [7 :0] minute            // min
);

wire [15:0] CLOCK_1 = (CLOCK>>1)-1;

// 状态机定义
parameter HALT  = 3'b001;
parameter START = 3'b010;
parameter PAUSE = 3'b100;

reg [2:0]  state, state_next;

reg  clk_100Hz, clk_1MHz, clk_1Hz, clk_1min;
reg [15:0] cnt_us, cnt_10ms, cnt_1s;
reg [16:0] Countup;
reg key_long, key_short;
reg [20:0] key_cnt;

// key scan
always @(posedge clk_1MHz or negedge rst_n) begin
    if(!rst_n) begin
        key_long  <= 1'd0;
        key_short <= 1'd0;
        key_cnt   <= 21'd0;
    end
    else begin
        if(!key) begin
            key_cnt <= key_cnt + 1'd1;
        end
        else begin
            // if(key_cnt >= 21'd2000000) begin // 按住时间大于2s
            if(key_cnt >= 21'd2000) begin // 仿真缩小1000
                key_long  <= 1'd1;
                key_short <= 1'd0;
                key_cnt   <= 21'd0;
            end
            // else if(key_cnt >= 21'd10000) begin // 按住时间大于0.01s
            else if(key_cnt >= 21'd10) begin // 按住时间大于0.01s
                key_long  <= 1'd0;
                key_short <= 1'd1;
                key_cnt   <= 21'd0;
            end
            else begin
                key_long  <= 1'd0;
                key_short <= 1'd0;
                key_cnt   <= 21'd0;
            end
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        clk_1MHz <= 1'd0;
        cnt_us   <= 16'd0;
    end
    else begin
        if(cnt_us >= CLOCK_1) begin
            cnt_us <= 16'd0;
            clk_1MHz <= ~clk_1MHz;
        end
        else begin
            cnt_us <= cnt_us + 1'd1;
            clk_1MHz <= clk_1MHz;
        end
    end
end



always @(posedge clk_1MHz or negedge rst_n) begin
    if(!rst_n) begin
        state <= HALT;
    end
    else begin
        state <= state_next;
    end
end

always@(*) begin
    state_next = HALT;
    case (state)
        HALT: begin
            if(key_short) begin
                state_next = START;
            end
            else begin
                state_next = HALT;
            end
        end
        START: begin
            if(key_short) begin
                state_next = PAUSE;
            end
            else if(key_long) begin
                state_next = HALT;
            end
            else begin
                state_next = START;
            end
        end
        PAUSE: begin
            if(key_short) begin
                state_next = START;
            end
            else if(key_long) begin
                state_next = HALT;
            end
            else begin
                state_next = PAUSE;
            end
        end
        default: ;
    endcase
end

always @(posedge clk_1MHz or negedge rst_n) begin
    if(!rst_n) begin
        clk_100Hz <= 1'd1;
        cnt_10ms   <= 16'd0;
    end
    else begin
        case(state) 
        HALT: begin
            clk_100Hz <= 1'd1;
            cnt_10ms   <= 16'd0;
        end 
        START: begin
            // if(cnt_10ms >= 16'd4999) begin
            if(cnt_10ms >= 16'd49) begin // 仿真缩小100倍
                cnt_10ms <= 16'd0;
                clk_100Hz <= ~clk_100Hz;
            end
            else begin
                cnt_10ms <= cnt_10ms + 1'd1;
                clk_100Hz <= clk_100Hz;
            end
        end 
        PAUSE: begin
            clk_100Hz <= clk_100Hz;
            cnt_10ms  <= cnt_10ms ;
        end
        default: ;
        endcase
    end
end

always @(posedge clk_100Hz or negedge rst_n) begin
    if(!rst_n) begin
        clk_1Hz <= 1'd1;
        millsecond_10   <= 16'd0;
    end
    else begin
        case(state) 
        HALT: begin
            clk_1Hz <= 1'd1;
            millsecond_10   <= 16'd0;
        end 
        START: begin
            if(millsecond_10 >= 16'd99) begin
                millsecond_10 <= 16'd0;
                clk_1Hz <= ~clk_1Hz;
            end
            else if(millsecond_10 == 16'd49)begin
                millsecond_10 <= millsecond_10 + 1'd1;
                clk_1Hz <= ~clk_1Hz;
            end
            else begin
                millsecond_10 <= millsecond_10 + 1'd1;
                clk_1Hz <= clk_1Hz;
            end
        end 
        PAUSE: begin
            clk_1Hz <= clk_1Hz;
            millsecond_10  <= millsecond_10 ;
        end
        default: ;
        endcase
    end
end

always @(posedge clk_1Hz or negedge rst_n) begin
    if(!rst_n) begin
        clk_1min <= 1'd1;
        second   <= 16'd0;
    end
    else begin
        case(state) 
        HALT: begin
            clk_1min <= 1'd1;
            second   <= 16'd0;
        end 
        START: begin
            if(second == 16'd59) begin
                second <= 16'd0;
                clk_1min <= ~clk_1min;
            end
            else if(second == 16'd29) begin
                second <= second + 1'd1;
                clk_1min <= ~clk_1min;
            end
            else begin
                second <= second + 1'd1;
                clk_1min <= clk_1min;
            end
        end 
        PAUSE: begin
            clk_1min <= clk_1min;
            second  <= second ;
        end
        default: ;
        endcase
    end
end



always @(posedge clk_1min or negedge rst_n) begin
    if(!rst_n) begin
        minute   <= 16'd0;
    end
    else begin
        case(state) 
        HALT: begin
            minute   <= 16'd0;
        end 
        START: begin
            minute <= minute + 1'd1;
        end 
        PAUSE: begin
            minute  <= minute ;
        end
        default: ;
        endcase
    end
end

endmodule

