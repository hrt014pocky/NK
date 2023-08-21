module fft1024 (
    input clk,
    input rst_n,
    input start,
    output reg fft_ok
);

wire [63:0] ramdata;
wire [15:0] ramaddr;

wire [63:0] btf_dout1;
wire [63:0] btf_dout2;
reg [63:0] btf_din1, btf_din2;
reg [31:0] btf_wn;

reg start1;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        start1 <= start;
    end
    else begin
        start1 <= start;
    end
end

reg [15:0] layer_cnt;
reg [15:0] grn_cnt;
reg [15:0] step_cnt;
reg [15:0] layer_cnt1 ;
reg [15:0] grn_cnt1   ;
reg [15:0] step_cnt1  ;
reg [15:0] layer;
reg [15:0] grn;
reg [15:0] step;
reg [15:0] cnt;
reg [15:0] wncnt;
reg btf_ok, btf_ok1, btf_ok2;
reg btf_start;
wire btf_start1; 



always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        layer       <= 16'd10;
        grn         <= 16'd1;
        step        <= 16'd512;
        layer_cnt   <= 16'd0;
        grn_cnt     <= 16'd0;
        step_cnt    <= 16'd0;
        layer_cnt1  <= 16'd0;
        grn_cnt1    <= 16'd0;
        step_cnt1   <= 16'd0;
        cnt         <= 16'd0;
        wncnt       <= 16'd0;
        fft_ok      <= 16'd0;
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

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        btf_din1 <= 64'd0;
        btf_din2 <= 64'd0;
        btf_wn   <= 32'd0;
    end
    else begin
        if(btf_start) begin
            // btf_din1 = xarr[cnt];
            // btf_din2 = xarr[cnt + step];
            // btf_wn = {sin_tb[wncnt], cos_tb[wncnt]};
        end
    end
end


assign btf_start1 = (start1 | (step_cnt != step_cnt1) | (grn_cnt != grn_cnt1)) & (!fft_ok);

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

wire [15:0] ramdata_o;

ram u_ram(
    .clk    (clk    ),
    .rst_n  (rst_n  ),
    .we_i   (we_i   ),
    .addr_i (ramaddr ),
    .data_i (ramdata ),
    .data_o (data_o  )
);

reg wnwe_i;
reg [15:0] wnaddr;
reg [15:0] wndata;
wire [15:0] wndata_o;

ramwn u_ramwn(
    .clk    (clk    ),
    .rst_n  (rst_n  ),
    .we_i   (wnwe_i ),
    .addr_i (wnaddr ),
    .data_i (wndata ),
    .data_o (wndata_o)
);



endmodule

