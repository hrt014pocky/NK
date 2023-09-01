module spi_flash (
    input clk,
    input rst_n,

    input flash_start,

    input  [7 :0] cmd,
    input  [23:0] addr,
    input  [7 :0] write_data,
    output [7 :0] read_data,
    input  [7 :0] data_num,

    output spi_start,
    output spi_we,
    input  spi_done,
    output array_done,
    output [7:0] spi_wdata,
    input  [7:0] spi_rdata
 
);

// 状态
localparam IDLE  = 8'd0;
localparam INST  = 8'd1;
localparam ADDR  = 8'd2;
localparam READ  = 8'd3;
localparam WRITE = 8'd4;

// 指令
localparam CMD_DEVICE_ID     =  8'h90;
localparam CMD_READ_DATA     =  8'h03;
localparam CMD_SECTOR_ERASE  =  8'h20;
localparam CMD_PAGE_PROGRAM  =  8'h02;
localparam CMD_WRITE_ENABLE  =  8'h06;

reg array_done_reg;
reg spi_start_reg;
reg spi_we_reg;
reg [7:0] wdata_reg;

reg inst2idle;
reg inst2addr;
reg addr2read;
reg addr2write;
reg read2idle;
reg addr2idle;
reg write2idle;

reg [7:0] addr_cnt;
reg [7:0] rd_cnt;
reg [7:0] wr_cnt;

reg [7:0] state, state_next;

// 时序逻辑状态转移
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        state <= IDLE;
    end
    else begin
        state <= state_next;
    end
end

// 组合逻辑状态转移条件
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
                if(inst2idle)
                    state_next = IDLE;
                else if(inst2addr)
                    state_next = ADDR;
                else
                    state_next = INST;
            end
            ADDR : begin
                if(addr2idle)
                    state_next = IDLE;
                else if(addr2read)
                    state_next = READ;
                else if(addr2write)
                    state_next = WRITE;
                else
                    state_next = ADDR;
            end
            READ : begin
                if(read2idle)
                    state_next = IDLE;
                else
                    state_next = READ;
            end
            WRITE : begin
                if(write2idle)
                    state_next = IDLE;
                else
                    state_next = WRITE;
            end
            default: ;
        endcase
    end
end

// SPI写使能
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        spi_we_reg <= 1'd0;
    else begin
        case (state)
            IDLE   : spi_we_reg <= 1'd1;
            INST   : spi_we_reg <= 1'd1;
            ADDR   : spi_we_reg <= 1'd1;
            READ   : spi_we_reg <= 1'd0;
            WRITE  : spi_we_reg <= 1'd1;
            default: spi_we_reg <= 1'd1;
        endcase
    end
end

// 地址数据Byte计数
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        addr_cnt <= 8'd0;
    else begin
        case (state)
            IDLE   : addr_cnt <= 8'd0;
            INST   : addr_cnt <= 8'd0;
            ADDR   : begin
                if(spi_done)
                    addr_cnt <= addr_cnt + 1'd1;
            end
            READ   : addr_cnt <= 8'd0;
            WRITE  : addr_cnt <= 8'd0;
            default: addr_cnt <= 8'd0;
        endcase
    end
end

// 读数据Byte计数
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        rd_cnt <= 8'd0;
    else begin
        case (state)
            IDLE   : rd_cnt <= 8'd0;
            INST   : rd_cnt <= 8'd0;
            ADDR   : rd_cnt <= 8'd0;
            READ   : begin
                if(spi_done && rd_cnt < data_num - 1) begin
                    rd_cnt <= rd_cnt + 1'd1;
                end
                else begin
                    rd_cnt <= rd_cnt;
                end
            end
            WRITE  : rd_cnt <= 8'd0;
            default: rd_cnt <= 8'd0;
        endcase
    end
end

// 写数据Byte计数
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        wr_cnt <= 8'd0;
    else begin
        case (state)
            IDLE   : wr_cnt <= 8'd0;
            INST   : wr_cnt <= 8'd0;
            ADDR   : wr_cnt <= 8'd0;
            READ   : wr_cnt <= 8'd0;
            WRITE  : begin
                if(spi_done && wr_cnt < data_num - 1) begin
                    wr_cnt <= wr_cnt + 1'd1;
                end
                else begin
                    wr_cnt <= wr_cnt;
                end
            end
            default: wr_cnt <= 8'd0;
        endcase
    end
end
// SPI启动
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        spi_start_reg  <= 1'd0;
    else if(flash_start) begin
        if(state == IDLE)
            spi_start_reg <= 1'd1;
    end
    else if(spi_done) begin
        if(state == INST) begin
            if(cmd != CMD_WRITE_ENABLE) 
                spi_start_reg <= 1'd1;
        end
        else if(state == ADDR) begin
            if(cmd == CMD_SECTOR_ERASE)
                if(addr_cnt < 3 - 1)
                    spi_start_reg <= 1'd1;
                else 
                    spi_start_reg <= 1'd0;
            else
                spi_start_reg <= 1'd1;
        end
        else if(state == READ) begin
            if(rd_cnt < data_num - 1)
                spi_start_reg <= 1'd1;
        end
        else if(state == WRITE) begin
            if(wr_cnt < data_num - 1)
                spi_start_reg <= 1'd1;
        end
        else
            spi_start_reg <= 1'd0;
    end
    else 
        spi_start_reg <= 1'd0;
end

// SPI串行数据结束信号
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        array_done_reg <= 1'd0;
    else if(read2idle || write2idle || addr2idle)
        array_done_reg <= 1'd1;
    else 
        array_done_reg <= 1'd0;
end

// 写入数据寄存
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
                wdata_reg <= cmd;
            end
            ADDR : begin
                case (addr_cnt)
                    0 : 
                        wdata_reg <= addr[23:16];
                    1 : 
                        wdata_reg <= addr[15:8];
                    2 : 
                        wdata_reg <= addr[7:0];
                    default: ;
                endcase
            end
            READ : begin
                wdata_reg <= 8'h00;
            end
            WRITE : begin
                wdata_reg <= write_data;
            end
            default: ;
        endcase
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        inst2idle  <= 1'd0;
        inst2addr  <= 1'd0;
        addr2read  <= 1'd0;
        addr2idle  <= 1'd0;
        read2idle  <= 1'd0;
        addr2write <= 1'd0;
        write2idle <= 1'd0;
    end
    else begin
        inst2idle  <= spi_done && cmd == CMD_WRITE_ENABLE;
        inst2addr  <= spi_done;
        addr2idle  <= spi_done && addr_cnt == 3 - 1 && cmd == CMD_SECTOR_ERASE;
        addr2read  <= spi_done && addr_cnt == 3 - 1 
                    && ((cmd == CMD_READ_DATA) || (cmd == CMD_DEVICE_ID));
        addr2write <= spi_done && addr_cnt == 3 - 1 && cmd == CMD_PAGE_PROGRAM;
        read2idle  <= spi_done && rd_cnt == data_num - 1;
        write2idle <= spi_done && wr_cnt == data_num - 1;
    end 
end


assign spi_start = spi_start_reg;
assign spi_we = spi_we_reg;
assign array_done = array_done_reg;
assign spi_wdata = wdata_reg;


endmodule

