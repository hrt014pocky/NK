module top 
    #(
        parameter   BAUDRATE        =   18'd115200     ,     //串口波特率
        parameter   CLK_FREQ        =   32'd50_000_000      //主时钟
    )
(
    input  clk,
    input  rst_n,
    input  key,
    input  rx,
    output tx

);


localparam BITPERIOD      =  CLK_FREQ / BAUDRATE;
localparam BITPERIOD_HALF = (CLK_FREQ / BAUDRATE) / 2;
localparam RX_IDLE     = 4'd0;
localparam RX_START    = 4'd1;
localparam RX_DATA     = 4'd2;
localparam RX_PARITY   = 4'd3;
localparam RX_STOP     = 4'd4;
localparam TX_IDLE     = 4'd0;
localparam TX_START    = 4'd1;
localparam TX_DATA     = 4'd2;
localparam TX_PARITY   = 4'd3;
localparam TX_STOP     = 4'd4;

wire rx_flag;
reg tx_flag;

reg [31:0] cnt0;
reg key_short, key_long;

reg [15:0] rx_cnt;
reg [15:0] rxbit_cnt;

reg [15:0] tx_cnt;
reg [15:0] txbit_cnt;
wire txbit_cnt_add, txbit_cnt_end;
wire rxbit_cnt_add, rxbit_cnt_end;
wire tx_cnt_add, tx_cnt_end;
wire rx_cnt_add, rx_cnt_end;

reg [7:0] tx_data;
reg tx_reg;
reg rx_reg;
reg [7:0] rx_buffer, rx_data;
reg rx_end;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        tx_data <= 8'ha;
    end
    else begin
        tx_data <= rx_data;
    end
end

//-------------------------------------------------------------------
// 按键
//-------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cnt0 <= 0;
    end
    else if(!key)
        cnt0 <= cnt0 + 1'd1;
    else
        cnt0 <= 0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        key_short <= 1'd0;
        key_long  <= 1'd0;
    end
    else if(key) begin
        if((cnt0 > 32'd2_000_000) && (cnt0 < 32'd50_000_000)) begin
            key_short <= 1'd1;
        end
        else if(cnt0 >= 32'd50_000_000) begin
            key_long <= 1'd1;
        end
        else begin
            key_short <= 1'd0;
            key_long  <= 1'd0;
        end
    end
    else begin
        key_short <= 1'd0;
        key_long  <= 1'd0;
    end
end

//-------------------------------------------------------------------
// 串口发送
//-------------------------------------------------------------------
reg [7:0] stateTX, stateTX_next;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        stateTX <= TX_IDLE;
    end
    else begin
        stateTX <= stateTX_next;
    end
end

always @(*) begin
    if(!rst_n) begin
        stateTX_next = TX_IDLE;
    end
    else begin
        case (stateTX)
            TX_IDLE     : begin
                if(key_short || rx_end) begin
                    stateTX_next = TX_START;
                end
                else begin
                    stateTX_next = TX_IDLE;
                end
            end
            TX_START    : begin
                if(tx_cnt_end) begin
                    stateTX_next = TX_DATA;
                end
                else begin
                    stateTX_next = TX_START;
                end
            end
            TX_DATA     : begin
                if(tx_cnt_end && txbit_cnt_end) begin
                    stateTX_next = TX_PARITY;
                end
                else begin
                    stateTX_next = TX_DATA;
                end
            end
            TX_PARITY : begin
                stateTX_next = TX_STOP;
            end
            TX_STOP     : begin
                if(tx_cnt_end) begin
                    stateTX_next = TX_IDLE;
                end
                else begin
                    stateTX_next = TX_STOP;
                end
            end
            default: ;
        endcase
    end
end

// txcnt 时钟周期计数器
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        tx_cnt <= 0;
    end
    else if(tx_cnt_add) begin
        if(tx_cnt_end)
            tx_cnt <= 0;
        else
            tx_cnt <= tx_cnt + 1'd1;
    end
end

assign tx_cnt_add = stateTX == TX_START || stateTX == TX_DATA || stateTX == TX_STOP;
assign tx_cnt_end = tx_cnt_add && tx_cnt == BITPERIOD - 1;

// txbitcnt 数据位计数器
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        txbit_cnt <= 0;
    end
    else if(txbit_cnt_add) begin
        if(txbit_cnt_end)
            txbit_cnt <= 0;
        else
            txbit_cnt <= txbit_cnt + 1'd1;
   end
end

assign txbit_cnt_add = stateTX == TX_DATA && tx_cnt_end;
assign txbit_cnt_end = txbit_cnt_add && txbit_cnt == 8 - 1;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        tx_reg <= 1'd1;
    end
    else begin
        case (stateTX)
            TX_IDLE : tx_reg <= 1'd1;
            TX_START: tx_reg <= 1'd0;
            TX_STOP : tx_reg <= 1'd0;
            TX_DATA : tx_reg <= tx_data[txbit_cnt];
            TX_PARITY : tx_reg <= tx_reg;
            default: ;
        endcase
    end
end

assign tx = tx_reg;

//-------------------------------------------------------------------
// 串口接收
//-------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        rx_reg <= 1'd0;
    end
    else begin
        rx_reg <= rx;
    end
end

reg [7:0] stateRX, stateRX_next;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        stateRX <= RX_IDLE;
    end
    else begin
        stateRX <= stateRX_next;
    end
end

assign rx_flag = !rx && stateRX == RX_IDLE;

always @(*) begin
    if(!rst_n) begin
        stateRX_next = RX_IDLE;
    end
    else begin
        case (stateRX)
            RX_IDLE     : begin
                if(rx_flag) begin
                    stateRX_next = RX_START;
                end
                else begin
                    stateRX_next = RX_IDLE;
                end
            end
            RX_START    : begin
                if(rx_cnt_end) begin
                    stateRX_next = RX_DATA;
                end
                else begin
                    stateRX_next = RX_START;
                end
            end
            RX_DATA     : begin
                if(rx_cnt_end && rxbit_cnt_end) begin
                    stateRX_next = RX_PARITY;
                end
                else begin
                    stateRX_next = RX_DATA;
                end
            end
            RX_PARITY : begin
                stateRX_next = RX_STOP;
            end

            RX_STOP     : begin
                if(rx_cnt_end) begin
                    stateRX_next = RX_IDLE;
                end
                else begin
                    stateRX_next = RX_STOP;
                end
            end
            default: ;
        endcase
    end
end

// rxcnt 时钟周期计数器
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        rx_cnt <= 0;
    end
    else if(rx_cnt_add) begin
        if(rx_cnt_end)
            rx_cnt <= 0;
        else
            rx_cnt <= rx_cnt + 1'd1;
    end
end

assign rx_cnt_add = stateRX == RX_START || stateRX == RX_DATA || stateRX == RX_STOP;
assign rx_cnt_end = rx_cnt_add && rx_cnt == BITPERIOD - 1;


// rxbitcnt 数据位计数器
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        rxbit_cnt <= 0;
    end
    else if(rxbit_cnt_add) begin
        if(rxbit_cnt_end)
            rxbit_cnt <= 0;
        else
            rxbit_cnt <= rxbit_cnt + 1'd1;
   end
end

assign rxbit_cnt_add = stateRX == RX_DATA && rx_cnt_end;
assign rxbit_cnt_end = rxbit_cnt_add && rxbit_cnt == 8 - 1;

// 寄存读取到的数据
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
        rx_buffer <= 8'd0;
    else if(stateRX == RX_DATA && rx_cnt == BITPERIOD_HALF) 
        rx_buffer <= {rx_reg, rx_buffer[7:1]};
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
        rx_end <= 1'd0;
    else if(stateRX == RX_STOP && rx_cnt_end) begin
        rx_end <= 1'd1;
    end
    else 
        rx_end <= 1'd0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
        rx_data <= 8'd0;
    else if(rx_end) begin
        rx_data <= rx_buffer;
    end
end

endmodule


