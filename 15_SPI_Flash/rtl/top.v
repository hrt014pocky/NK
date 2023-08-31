module top (
    input clk,
    input rst_n,

    input key,

    output cs  ,
    output sck ,
    output mosi,
    input  miso
);


reg [7 :0] cmd   ;
reg [23:0] addr  ;
wire [7 :0] wdata ;
wire [7:0] rdata ;
wire spi_start;
wire we;
wire done;
wire array_done;



always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cmd   <= 0;
        addr  <= 0;
    end
    else begin
        cmd   <= 8'h90;
        addr  <= 24'd0;
    end
end



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


// spi_dri u_spi_dri
// (
//     .clk      (clk    ),
//     .rst_n    (rst_n  ),
//     .key      (key_short    ),
//     .cmd      (cmd    ),
//     .addr     (addr   ),
//     .wdata    (wdata  ),
//     .rdata    (rdata  ),
//     .cs       (cs     ),
//     .sck      (sck    ),
//     .mosi     (mosi   ),
//     .miso     (miso   )
// );

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
    .flash_start   (key_short          ),
    .spi_start     (spi_start    ),
    .spi_we        (we           ),
    .spi_done      (done         ),
    .array_done    (array_done   ),
    .wdata         (wdata        ),
    .rdata         (rdata        )

);

    
endmodule

