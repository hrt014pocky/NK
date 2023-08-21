module afft8 (
    input clk,
    input rst_n,
    input start,
    output [31:0] addr,
    output [31:0] data_o,
    input  [31:0] data_i,
    input  we, 
    input  req

);


/*----------------------------------------------------------

FFT内容：
1. 读取内存，包括数据的实数部分和虚数部分，旋转因子
2. 数据的下标设计
3. 蝶形运算
4. 数据存入内存

------------------------------------------------------------*/

reg [31:0] index, wnindex;
//-------------------------------------------------------------------
// 内存读写
//-------------------------------------------------------------------
wire real_we       ; // 实部内存写使能
reg  [15:0] xa     ; // 数据地址
reg  [31:0] xdr_i  ; // 实部数据输入
wire [31:0] xdr_o  ; // 实部数据输出
wire imag_we       ; // 虚部内存写使能
reg  [31:0] xdi_i  ; // 虚部数据输入
wire [31:0] xdi_o  ; // 虚部数据输出
wire wn_we         ; // 旋转因子内存使能
reg  [15:0] wna    ; // 旋转因子内存地址
wire [31:0] wnd_i  ; // 旋转因子内存读


//-------------------------------------------------------------------
// 蝶形运算数据
//-------------------------------------------------------------------
wire btf_start;
reg [63:0] btf_din1, btf_din2;
reg [31:0] btf_wn;
wire [63:0]btf_dout1;
wire [63:0]btf_dout2;


//-------------------------------------------------------------------
// 计算数据下标
//-------------------------------------------------------------------
reg [7:0]  layer_cnt;
reg [7:0]  grn_cnt;
reg [7:0]  step_cnt;
reg [7:0]  layer_cnt1;
reg [7:0]  grn_cnt1;
reg [7:0]  step_cnt1;
reg [7:0]  layer;
reg [7:0]  grn;
reg [7:0]  step;
reg [15:0] cnt;
reg [15:0] wncnt;
reg btf_ok;
reg fft_ok;


// 数据准备 读取内存
aram u_realram(
    .clk    (clk      ),
    .rst_n  (rst_n    ),
    .we_i   (real_we  ),
    .addr_i (xa       ),
    .data_i (xdr_i    ),
    .data_o (xdr_o    )
);

aram u_imagram(
    .clk    (clk      ),
    .rst_n  (rst_n    ),
    .we_i   (imag_we  ),
    .addr_i (xa       ),
    .data_i (xdi_i    ),
    .data_o (xdi_o    )
);

aramwn u_aramwn(
    .clk    (clk    ),
    .rst_n  (rst_n  ),
    .we_i   (wn_we  ),
    .addr_i (wna    ),
    .data_i (wnd_i  )
);

// 数据下标的就算
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        layer_cnt   <= 8'd0;
        grn_cnt     <= 8'd0;
        step_cnt    <= 8'd0;
        layer       <= 8'd3;
        grn         <= 8'd1;
        step        <= 8'd4;
        layer_cnt1  <= 8'd0;
        grn_cnt1    <= 8'd0;
        step_cnt1   <= 8'd0;
        cnt         <= 15'd0;
        wncnt       <= 15'd0;
        fft_ok      <= 1'd0;
    end
    else begin
        layer_cnt1  <= layer_cnt; 
        grn_cnt1    <= grn_cnt;   
        step_cnt1   <= step_cnt;  
        if(btf_ok) begin

            if(step_cnt < step-1) begin
                step_cnt <= step_cnt + 1'd1;
                cnt <= cnt + 1'd1;
                wncnt <= wncnt + grn;
            end
            else begin
                step_cnt <= 8'd0;
                if(grn_cnt < grn-1)begin
                    grn_cnt <= grn_cnt + 1'd1;
                    cnt <= cnt + 1'd1 + step;
                    wncnt <= 16'd0;
                end
                else begin
                    grn_cnt <= 8'd0;
                    cnt <= 16'd0;
                    wncnt <= 16'd0;
                    if(layer_cnt < layer - 1) begin
                        layer_cnt <= layer_cnt + 1'd1;
                        grn <= grn << 8'd1;
                        step <= step >> 8'd1;
                    end
                    else begin
                        layer_cnt <= 16'd0;
                        step_cnt <= 16'd0;
                        grn_cnt <= 16'd0;
                        fft_ok <= 1'd1;
                    end
                end
            end
        end
        else if(start) begin
            fft_ok <= 1'd0;
        end
    end
end

assign btf_start = (start | (step_cnt != step_cnt1) | (grn_cnt != grn_cnt1)) & (!fft_ok);

reg btf_ok1 , btf_ok2;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        btf_ok1 <= 1'd0;
        btf_ok2 <= 1'd0;
        btf_ok  <= 1'd0;
    end
    else begin
        btf_ok1 <= btf_start;
        btf_ok2 <= btf_ok1;
        btf_ok  <= btf_ok2;
    end
end

// 蝶形运算

reg [15:0] x1Index;
reg [15:0] x2Index;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        x1Index <= 16'd0;
        x2Index <= 16'd0;
    end
    else begin
        if(btf_start) begin
            
        end
    end
end

always @(*) begin
    if(!rst_n) begin
        btf_din1 <= 64'd0;
        btf_din2 <= 64'd0;
    end
    else begin
        btf_din1 <= 64'd0;
        btf_din2 <= 64'd0;
    end
end

btf u_btf(
    .clk   (clk   ),
    .rst_n (rst_n ),
    .din1  (btf_din1  ),
    .din2  (btf_din2  ),
    .wn    (btf_wn    ),
    .dout1 (btf_dout1 ),
    .dout2 (btf_dout2 )
);


// 计算结束，数据存储

endmodule


