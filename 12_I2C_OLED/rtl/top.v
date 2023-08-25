module top (
    input  clk,
    input  rst_n,
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


oled_drv u_oled_drv(
    .clk         (i2c_clk    ),
    .rst_n       (rst_n      ),
    .i2c_done    (done   ),
    .word_addr   (word_addr  ),
    .wdata       (wdata      ),    
    .exec        (exec       )
);


ila_0 ila (
	.clk(clk), // input wire clk


	.probe0(u_i2c_drv.scl), // input wire [0:0]  probe0  
	.probe1(u_i2c_drv.sda), // input wire [0:0]  probe1 
	.probe2(u_i2c_drv.sda_sel), // input wire [0:0]  probe2 
	.probe3(done) // input wire [7:0]  probe3
);






endmodule

