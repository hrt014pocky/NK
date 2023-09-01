module top (
    input clk,
    input rst_n,

    input [3:0] key,

    output cs  ,
    output sck ,
    output mosi,
    input  miso
);

localparam flash_addr = 24'h000030;

wire key1_valid;
wire key2_valid;
wire key3_valid;
wire key4_valid;
wire key1_long;

reg [7 :0] cmd   ;
reg [23:0] addr  ;
wire [7 :0] wdata ;
wire [7:0] rdata ;
wire spi_start;
wire we;
wire done;
wire array_done;
reg flash_start;
reg  [7:0] write_data;
wire [7:0] read_data ;

reg [7:0] wr_cnt;
reg [7:0] data_num;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        wr_cnt <= 8'd0;
    else if(key4_valid)
        wr_cnt <= wr_cnt + 1'd1;
end


always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cmd   <= 0;
        addr  <= 0;
        flash_start <= 1'd0;
        write_data  <= 8'd0;
        data_num <= 8'd0;
    end
    else begin
        if(key1_valid) begin // 读ID
            cmd         <= 8'h90;
            addr        <= 24'd0;
            flash_start <= 1'd1;
            write_data  <= 8'd0;
            data_num    <= 8'd2;
        end
        else if(key1_long) begin // 写使能
            cmd         <= 8'h06;
            addr        <= 24'd0;
            flash_start <= 1'd1;
            write_data  <= 8'd0;
            data_num    <= 8'd0;
        end
        else if(key2_valid) begin // 读数据
            cmd         <= 8'h03;
            addr        <= flash_addr;
            flash_start <= 1'd1;
            write_data  <= 8'd0;
            data_num    <= 8'd20;
        end
        else if(key3_valid) begin // 扇区擦除
            cmd         <= 8'h20;
            addr        <= 24'd0;
            flash_start <= 1'd1;
            write_data  <= 8'd0;
            data_num    <= 8'd0;
        end
        else if(key4_valid) begin // Page Program 写数据
            cmd         <= 8'h02;
            addr        <= flash_addr;
            flash_start <= 1'd1;
            write_data  <= wr_cnt;
            data_num    <= 8'd10;
        end
        else begin
            cmd         <= cmd;
            addr        <= addr;
            flash_start <= 1'd0;
            write_data  <= write_data;
        end
    end
end


key u_key1(
    .clk         (clk        ),
    .rst_n       (rst_n      ),
    .key         (key[0]     ),
    .key_short   (key1_valid ),
    .key_long    (key1_long  )
);

key u_key2(
    .clk         (clk        ),
    .rst_n       (rst_n      ),
    .key         (key[1]     ),
    .key_short   (key2_valid )
);

key u_key3(
    .clk         (clk        ),
    .rst_n       (rst_n      ),
    .key         (key[2]     ),
    .key_short   (key3_valid )
);

key u_key4(
    .clk         (clk        ),
    .rst_n       (rst_n      ),
    .key         (key[3]     ),
    .key_short   (key4_valid )
);


spi_dri u_spi_dri
(
    .clk        (clk    ),
    .rst_n      (rst_n  ),
    .start      (spi_start    ),
    .we         (we     ),
    .array_done (array_done),
    .wdata      (wdata  ),
    .rdata      (rdata  ),
    .done       (done   ),
    .cs         (cs     ),
    .sck        (sck    ),
    .mosi       (mosi   ),
    .miso       (miso   )
);

spi_flash u_spi_flash(
    .clk           (clk          ),
    .rst_n         (rst_n        ),
    .flash_start   (flash_start  ),
    .cmd           (cmd          ),
    .addr          (addr         ),
    .write_data    (write_data   ),
    .read_data     (read_data    ),
    .data_num      (data_num     ),
    .spi_start     (spi_start    ),
    .spi_we        (we           ),
    .spi_done      (done         ),
    .array_done    (array_done   ),
    .spi_wdata     (wdata        ),
    .spi_rdata     (rdata        )

);

    
endmodule

