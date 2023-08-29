module top (
    input  clk,
    input  rst_n,
    input  key,
    inout  SDA,
    output SCL
);

wire done;
wire exec      ;
wire we        ;
wire addr_hl   ;
wire [15:0] word_addr ;
wire [7:0] wdata     ;
wire [7:0] rdata     ;
wire i2c_clk;
wire [15:0] O_i2c_data;


reg [31:0] cnt0;
reg key_short, key_long;

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
        if((cnt0 > 32'd200_000) && (cnt0 < 32'd50_000_000)) begin
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



i2c_drv u_i2c_drv
(
    .clk             (clk       ),
    .rst_n           (rst_n     ),
    .exec            (exec      ),
    .we              (1'd1      ),
    .addr_hl         (1'd0      ),
    .word_addr       (word_addr ),
    .wdata           (wdata     ),
    .rdata           (rdata     ),
    .scl             (SCL       ),
    .sda             (SDA       ),
    .done            (done      ),
    .i2c_clk         (i2c_clk   ) 
);

// i2c_ctrl u_i2c_ctrl
// (
//     .sys_clk     (clk),   //输入系统时钟,50MHz
//     .sys_rst_n   (rst_n),   //输入复位信号,低电平有效
//     .wr_en       (1),   //输入写使能信号
//     .rd_en       (0),   //输入读使能信号
//     .i2c_start   (exec),   //输入i2c触发信号
//     .addr_num    (0),   //输入i2c字节地址字节数
//     .byte_addr   (O_i2c_data[15:8]),   //输入i2c字节地址
//     .wr_data     (O_i2c_data[7:0]),   //输入i2c设备数据
//     .i2c_clk     (i2c_clk),   //i2c驱动时钟
//     .i2c_end     (done),   //i2c一次读/写操作完成
//     .rd_data     (),   //输出i2c设备读取数据
//     .i2c_scl     (SCL),   //输出至i2c设备的串行时钟信号scl
//     .i2c_sda     (SDA)     //输出至i2c设备的串行数据信号sda
// );


oled_drv u_oled_drv(
    .clk         (clk        ),
    .rst_n       (rst_n      ),
    .i2c_done    (done       ),
    .key         (key_short),
    .word_addr   (word_addr  ),
    .wdata       (wdata      ),    
    .exec        (exec       )
);



// oled_ctrl U_OLED_CTRL(
//     .I_sys_clk      (i2c_clk) ,
//     .I_reset_n      (rst_n) ,
//     .I_i2c_done     (done) ,
//     .O_i2c_data     (O_i2c_data) ,
//     .O_i2c_exec     (exec) ,
//     .O_rd_addr      () ,
//     .I_ram_rd_data  () 
//     );


// ila_0 ila (
// 	.clk(clk), // input wire clk


// 	.probe0(u_i2c_drv.i2c_scl),    
// 	.probe1(u_i2c_drv.i2c_sda),    
// 	.probe2(exec),
// 	.probe3(done)
// );






endmodule

