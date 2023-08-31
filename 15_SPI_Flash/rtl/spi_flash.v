module spi_flash (
    input clk,
    input rst_n,

    input flash_start,

    output spi_start,
    output spi_we,
    input  spi_done,
    output array_done,

    output [7:0] wdata,
    input  [7:0] rdata
 
);


localparam IDLE  = 8'd0;
localparam INST  = 8'd1;
localparam ADDR  = 8'd2;
localparam READ  = 8'd3;

reg array_done_reg;
reg spi_start_reg;
reg spi_we_reg;
reg [7:0] wdata_reg;

reg inst2addr;
reg addr2read;
reg read2idle;

reg [7:0] addr_cnt;
reg [7:0] rd_cnt;

reg [7:0] state, state_next;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        state <= IDLE;
    end
    else begin
        state <= state_next;
    end
end

always @(*) begin
    if(!rst_n) begin
        state_next = IDLE;
    end
    else begin
        case (state)
            IDLE : begin
                if(flash_start)
                    state_next = INST;
                else
                    state_next = IDLE;
            end
            INST :begin
                if(inst2addr)
                    state_next = ADDR;
                else
                    state_next = INST;
            end
            ADDR : begin
                if(addr2read)
                    state_next = READ;
                else
                    state_next = ADDR;
            end
            READ : begin
                if(read2idle)
                    state_next = IDLE;
                else
                    state_next = READ;
            end
            default: ;
        endcase
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        spi_start_reg <= 1'd0;
        spi_we_reg <= 1'd0;
        addr_cnt <= 8'd0;
        rd_cnt <= 8'd0;
        array_done_reg <= 1'd0; 
    end
    else begin
        case (state)
            IDLE : begin
                array_done_reg <= 1'd0; 
                addr_cnt <= 1'd0;
                spi_we_reg <= 1'd1;
                if(flash_start) 
                    spi_start_reg <= 1'd1;
            end
            INST : begin
                spi_we_reg <= 1'd1;
                if(spi_done) 
                    spi_start_reg <= 1'd1;
            end
            ADDR : begin
                spi_we_reg <= 1'd1;
                if(spi_done) begin
                    spi_start_reg <= 1'd1;
                    addr_cnt <= addr_cnt + 1'd1;
                end
                else begin
                    spi_start_reg <= 1'd0;
                    addr_cnt <= addr_cnt;
                end
            end
            READ : begin
                spi_we_reg <= 1'd0;
                if(spi_done && rd_cnt < 2 - 1) begin
                    spi_start_reg <= 1'd1;
                    rd_cnt <= rd_cnt + 1'd1;
                end
                else if(read2idle) begin
                    array_done_reg <= 1'd1;
                end
                else begin
                    spi_start_reg <= 1'd0;
                    rd_cnt <= rd_cnt;
                end
            end
            default: ;
        endcase
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        wdata_reg <= 8'd0;
    end
    else begin
        case (state)
            IDLE : begin
                wdata_reg <= 8'd0;
            end
            INST : begin
                wdata_reg <= 8'h90;
            end
            ADDR : begin
                case (addr_cnt)
                    0 : 
                        wdata_reg <= 8'h00;
                    1 : 
                        wdata_reg <= 8'h00;
                    2 : 
                        wdata_reg <= 8'h00;
                    default: ;
                endcase
            end
            READ : begin
                wdata_reg <= 8'h00;
            end
            default: ;
        endcase
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        inst2addr <= 1'd0;
        addr2read <= 1'd0;
        read2idle <= 1'd0;
    end
    else begin
        inst2addr <= spi_done;
        addr2read <= spi_done && addr_cnt == 3 - 1;
        read2idle <= spi_done && rd_cnt == 2 - 1;
    end 
end


assign spi_start = spi_start_reg;
assign spi_we = spi_we_reg;
assign array_done = array_done_reg;
assign wdata = wdata_reg;


endmodule

