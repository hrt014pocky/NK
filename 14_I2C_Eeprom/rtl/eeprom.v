module eeprom (
    input  clk,
    input  rst_n,
    input  i2c_done,
    input  [7 :0] rdata,
    input  start,

    output [15:0] word_addr, // 数据地址
    output [7 :0] wdata,     // 写数据内容
    output we_o,             // 写使能
    output addr_hl,          // 地址字节数选择
    output exec,             // 写开始信号
    output checkok
);

localparam WNUM = 1;

assign addr_hl = 1'd1;
assign word_addr = 0;

reg [7:0] wdata_reg;
reg [7:0] rdata_reg;
reg exec_reg;
reg wr_flag;

reg [3:0] wnum; // 写入数据个数
reg [3:0] wcnt; // 写入数据计数器
wire wcnt_add;
wire wcnt_end;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
        wr_flag <= 1'd1;
    else if(i2c_done && wr_flag)
        wr_flag <= 1'd0;
    else if(i2c_done && !wr_flag)
        wr_flag <= 1'd1;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
        wdata_reg <= 8'haa;
    else if(start)
        wdata_reg <= wdata_reg + 1'd1;
end

assign wdata = wdata_reg;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
        exec_reg <= 1'd0;
    else if(start)
        exec_reg <= 1'd1;
    else if(i2c_done && wr_flag)
        exec_reg <= 1'd1;
    else
        exec_reg <= 1'd0;
end

reg [31:0] cnt;
wire cnt_add, cnt_end;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cnt <= 0;
    end
    else if(cnt_add) begin
        if(cnt_end)
            cnt <= 0;
        else
            cnt <= cnt + 1'd1;
    end
    else if(exec_reg)
        cnt <= 1'd1;
end

assign cnt_add = cnt != 0;
assign cnt_end = cnt_add && cnt == 32'd4_000;

assign exec = cnt_end;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        wcnt <= 0;
    end
    else if(wcnt_add) begin
        if(wcnt_end)
            wcnt <= 0;
        else
            wcnt <= wcnt + 1'd1;
    end
end

assign wcnt_add = wr_flag  && i2c_done;
assign wcnt_end = wcnt_add && wcnt == WNUM - 1;

assign we_o = wr_flag;


// 读数据
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        rdata_reg <= 8'd0;
    end
    else if(wr_flag  && i2c_done) begin
        rdata_reg <= rdata;
    end
end

assign checkok = wdata_reg == rdata_reg;


endmodule

