module fft8 (
    input clk,
    input rst_n,
    input start,
    input  [63:0] data_in1,
    input  [63:0] data_in2,
    input  [63:0] data_in3,
    input  [63:0] data_in4,
    input  [63:0] data_in5,
    input  [63:0] data_in6,
    input  [63:0] data_in7,
    input  [63:0] data_in8,
    output reg fft_ok,
    output reg dout
);
integer j;
reg [63:0] xarr[0:7];
reg [15:0] sin_tb[0:3];
reg [15:0] cos_tb[0:3];
wire [63:0] btf_dout1;
wire [63:0] btf_dout2;
reg btf_ok, btf_ok1, btf_ok2;

reg [7:0] layer_cnt;
reg [7:0] grn_cnt;
reg [7:0] step_cnt;
reg [7:0] layer_cnt1 ;
reg [7:0] grn_cnt1   ;
reg [7:0] step_cnt1  ;
reg [7:0] layer;
reg [7:0] grn;
reg [7:0] step;
reg [15:0] cnt;
reg [15:0] wncnt;


wire [31:0] x1r = xarr[0][31:0];
wire [31:0] x2r = xarr[1][31:0];
wire [31:0] x3r = xarr[2][31:0];
wire [31:0] x4r = xarr[3][31:0];
wire [31:0] x5r = xarr[4][31:0];
wire [31:0] x6r = xarr[5][31:0];
wire [31:0] x7r = xarr[6][31:0];
wire [31:0] x8r = xarr[7][31:0];
wire [31:0] x1i = xarr[0][63:32];
wire [31:0] x2i = xarr[1][63:32];
wire [31:0] x3i = xarr[2][63:32];
wire [31:0] x4i = xarr[3][63:32];
wire [31:0] x5i = xarr[4][63:32];
wire [31:0] x6i = xarr[5][63:32];
wire [31:0] x7i = xarr[6][63:32];
wire [31:0] x8i = xarr[7][63:32];

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(j = 0; j <= 3; j = j+1) begin
            sin_tb[j] <= 16'd0;
            cos_tb[j] <= 16'd0;
        end
    end
    else begin
        sin_tb[0] <= 16'd0;
        sin_tb[1] <= -16'd11584;
        sin_tb[2] <= -16'd16384;
        sin_tb[3] <= -16'd11584;
        cos_tb[0] <= 16'd16384;
        cos_tb[1] <= 16'd11584;
        cos_tb[2] <= 16'd0;
        cos_tb[3] <= -16'd11584;
    end
end

reg start1;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        start1 <= start;
    end
    else begin
        start1 <= start;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(j = 0; j <= 7; j = j+1) begin
            xarr[j] <= 64'd0;
        end
    end
    else begin
        if(start) begin
            xarr[0] <= data_in1;
            xarr[1] <= data_in2;
            xarr[2] <= data_in3;
            xarr[3] <= data_in4;
            xarr[4] <= data_in5;
            xarr[5] <= data_in6;
            xarr[6] <= data_in7;
            xarr[7] <= data_in8;
        end
        else if(btf_ok) begin
            xarr[cnt] <= btf_dout1;
            xarr[cnt+step] <= btf_dout2;
        end
    end
end


always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        layer       <= 8'd3;
        grn         <= 8'd1;
        step        <= 8'd4;
        layer_cnt   <= 8'd0;
        grn_cnt     <= 8'd0;
        step_cnt    <= 8'd0;
        layer_cnt1  <= 8'd0;
        grn_cnt1    <= 8'd0;
        step_cnt1   <= 8'd0;
        fft_ok      <= 1'd0;
        cnt         <= 16'd0;
        wncnt       <= 16'd0;
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
    end
end

reg [63:0] btf_din1, btf_din2;
reg [31:0] btf_wn;
reg btf_start;
wire btf_start1; 

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        btf_din1 <= 64'd0;
        btf_din2 <= 64'd0;
        btf_wn   <= 32'd0;
    end
    else begin
        if(btf_start) begin
            btf_din1 = xarr[cnt];
            btf_din2 = xarr[cnt + step];
            btf_wn = {sin_tb[wncnt], cos_tb[wncnt]};
        end
    end
end

assign btf_start1 = (start1 | (step_cnt != step_cnt1) | (grn_cnt != grn_cnt1)) & (!fft_ok);
wire [15:0] sin = btf_wn[31:16];
wire [15:0] cos = btf_wn[15:0];

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        btf_ok1 <= 1'd0;
        btf_ok2 <= 1'd0;
        btf_ok  <= 1'd0;
        btf_start <= 1'd0;
    end
    else begin
        btf_start <= btf_start1;
        btf_ok1 <= btf_start;
        btf_ok2 <= btf_ok1;
        btf_ok  <= btf_ok2;
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

wire [31:0] din1r = btf_din1[31:0];
wire [31:0] din1i = btf_din1[63:32];
wire [31:0] din2r = btf_din2[31:0];
wire [31:0] din2i = btf_din2[63:32];


reg [63:0] datafft[0:7];

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(j = 0; j <= 7; j = j+1) begin
            datafft[j] <= 64'd0;
        end
    end
    else begin
        for(j = 0; j <= 7; j = j+1) begin
            datafft[j] <= xarr[{j[0], j[1], j[2]}];
        end
    end
end

reg [63:0] datafftr[0:7];
reg [63:0] dataffti[0:7];

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(j = 0; j <= 7; j = j+1) begin
            datafftr[j] <= 64'd0;
            dataffti[j] <= 64'd0;
        end
    end
    else begin
        for(j = 0; j <= 7; j = j+1) begin
            datafftr[j] <= datafft[j][31:0];
            dataffti[j] <= datafft[j][63:32];
        end
    end
end

wire [31:0] datafftr1 = datafft[0][31:0];
wire [31:0] datafftr2 = datafft[1][31:0];
wire [31:0] datafftr3 = datafft[2][31:0];
wire [31:0] datafftr4 = datafft[3][31:0];
wire [31:0] datafftr5 = datafft[4][31:0];
wire [31:0] datafftr6 = datafft[5][31:0];
wire [31:0] datafftr7 = datafft[6][31:0];
wire [31:0] datafftr8 = datafft[7][31:0];

wire [31:0] dataffti1 = datafft[0][63:32];
wire [31:0] dataffti2 = datafft[1][63:32];
wire [31:0] dataffti3 = datafft[2][63:32];
wire [31:0] dataffti4 = datafft[3][63:32];
wire [31:0] dataffti5 = datafft[4][63:32];
wire [31:0] dataffti6 = datafft[5][63:32];
wire [31:0] dataffti7 = datafft[6][63:32];
wire [31:0] dataffti8 = datafft[7][63:32];

endmodule


