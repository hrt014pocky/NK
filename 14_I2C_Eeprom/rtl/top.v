module top (
    input  clk   ,
    input  rst_n ,
    input  key   ,
    output scl   ,
    output led   ,
    inout  sda
);


reg [31:0] cnt0;
reg key_short, key_long;

reg [3:0] clkcnt;
wire clk_div16/* synthesis keep */;
assign  clk_div16 = clkcnt[3];

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        clkcnt <= 3'd0;
    end
    else begin
        clkcnt <= clkcnt + 1'd1;
    end
end

assign led = clk_div16;

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
        if((cnt0 > 32'd200) && (cnt0 < 32'd50_000_000)) begin
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

wire i2c_clk, i2c_done, we, exec, addr_hl;
wire [15:0] word_addr;
wire [7:0] wdata, rdata;




eeprom u_eeprom 
(
    .clk          (clk         ),
    .rst_n        (rst_n       ),
    .i2c_done     (i2c_done    ),
    .rdata        (rdata       ),
    .start        (key_short   ),
    .word_addr    (word_addr   ),
    .wdata        (wdata       ),
    .we_o         (we          ),
    .addr_hl      (addr_hl     ),
    .exec         (exec        )
);


i2c_drv u_i2c_drv
(    
    .clk         (clk       ),
    .rst_n       (rst_n     ),
    .exec        (exec      ),
    .we          (we        ),
    .addr_hl     (addr_hl   ),
    .word_addr   (word_addr ),
    .wdata       (wdata     ),
    .rdata       (rdata     ),
    .scl         (scl       ),
    .sda         (sda       ),
    .done        (i2c_done  ),
    .i2c_clk     (i2c_clk   )
);





endmodule






