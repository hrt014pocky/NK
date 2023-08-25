module oled_drv (
    input clk,
    input rst_n,

    input i2c_done,

    output [7:0] word_addr, // 数据地址
    output [7:0] wdata,     // 写数据内容
    output exec             // 写开始信号

);

parameter CMD_NUM = 15'd29;
localparam INIT_DELAY = 16'd2000;

reg [7:0] init_word; // 初始化数据
reg [7:0] init_addr; // 初始化地址
reg [7:0] data_addr; // 显示内容地址
reg [7:0] data_word; // 显示内容数据
reg exec_reg;

reg init_done;
reg [15:0] oled_init_cnt;
reg [15:0] oled_data_cnt;

reg [15:0] delay;
wire[15:0] delay_add, delay_end;

wire oled_init_cnt_add, oled_init_cnt_end;
wire oled_data_cnt_add, oled_data_cnt_end;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        exec_reg <= 1'd0;
    end
    else begin
        if(delay == INIT_DELAY - 1)
            exec_reg <= 1'd1;
        else if(i2c_done)
            exec_reg <= 1'd1;
        else
            exec_reg <= 1'd0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        oled_init_cnt <= 0;
    end
    else if(oled_init_cnt_add) begin
        oled_init_cnt <= oled_init_cnt + 1'd1;
   end
end

assign oled_init_cnt_add = exec_reg && oled_init_cnt < CMD_NUM;

// always @(posedge clk or negedge rst_n) begin
//     if(!rst_n) begin
//         oled_data_cnt <= 0;
//     end
//     else if(oled_data_cnt_add) begin
//         oled_data_cnt <= oled_data_cnt + 1'd1;
//    end
// end

// assign oled_data_cnt_add = init_done && exec_reg;

//-------------------------------------------------------------------
// oled初始化
//-------------------------------------------------------------------
// 初始化延迟
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
        delay <= 0;
    else if(delay_add)
        delay <= delay + 1'd1;
end

assign delay_add = delay < INIT_DELAY;
assign delay_end = delay == INIT_DELAY;

//初始化与数据刷新
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        init_word <= 8'd0;
        init_addr <= 8'd0;
    end
    else begin
        init_addr <= 8'd0;
        if(!init_done) begin // 初始化未完成
            case (oled_init_cnt)
                1 : init_word <= 8'hAE; //--turn off oled panel
                2 : init_word <= 8'h00; //---set low column address
                3 : init_word <= 8'h10; //---set high column address
                4 : init_word <= 8'h40; //--set start line address  Set Mapping RAM Display Start Line (0x00~0x3F)
                5 : init_word <= 8'h81; //--set contrast control register
                6 : init_word <= 8'hCF; // Set SEG Output Current Brightness
                7 : init_word <= 8'hA1; //--Set SEG/Column Mapping     0xa0左右反置 0xa1正常
                8 : init_word <= 8'hC8; //Set COM/Row Scan Direction   0xc0上下反置 0xc8正常
                9 : init_word <= 8'hA6; //--set normal display
                10: init_word <= 8'hA8; //--set multiplex ratio(1 to 64)
                11: init_word <= 8'h3F; //--1/64 duty
                12: init_word <= 8'hD3; //-set display offset	Shift Mapping RAM Counter (0x00~0x3F
                13: init_word <= 8'h00; //-not offset
                14: init_word <= 8'hD5; //--set display clock divide ratio/oscillator frequency
                15: init_word <= 8'h80; //--set divide ratio, Set Clock as 100 Frames/Sec
                16: init_word <= 8'hD9; //--set pre-charge period
                17: init_word <= 8'hF1; //Set Pre-Charge as 15 Clocks & Discharge as 1 Clock
                18: init_word <= 8'hDA; //--set com pins hardware configuration
                19: init_word <= 8'h12; //
                20: init_word <= 8'hDB; //--set vcomh
                21: init_word <= 8'h40; //Set VCOM Deselect Level
                22: init_word <= 8'h20; //-Set Page Addressing Mode (0x00/0x01/0x02)
                23: init_word <= 8'h02; //
                24: init_word <= 8'h8D; //--set Charge Pump enable/disable
                25: init_word <= 8'h14; //--set(0x10) disable
                26: init_word <= 8'hA4; // Disable Entire Display On (0xa4/0xa5)
                27: init_word <= 8'hA6; // Disable Inverse Display On (0xa6/a7) 
                28: init_word <= 8'hAF;
                default: ;
            endcase
        end
    end
end

//初始化完成信号
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
        init_done <= 1'd0;
    else if((oled_init_cnt == CMD_NUM - 1) && i2c_done)
        init_done <= 1'd1;
end


//-------------------------------------------------------------------
// oled显示
//-------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        data_addr <= 8'd0;
        data_word <= 8'd0;
    end
    else begin
        data_addr <= 8'd0;
        case (oled_data_cnt)
            15'd0:  data_word <= {8'h00,8'hB0};
            15'd1:  data_word <= {8'h00,8'h00}; 
            15'd2:  data_word <= {8'h00,8'h10};
            // page 0
            15'd131:data_word <= {8'h00,8'hB1};
            15'd132:data_word <= {8'h00,8'h00}; 
            15'd133:data_word <= {8'h00,8'h10};
            // page 1
            15'd262:data_word <= {8'h00,8'hB2};
            15'd263:data_word <= {8'h00,8'h00}; 
            15'd264:data_word <= {8'h00,8'h10};
            // page 2
            15'd393:data_word <= {8'h00,8'hB3};
            15'd394:data_word <= {8'h00,8'h00}; 
            15'd395:data_word <= {8'h00,8'h10};
            // page 3
            15'd524:data_word <= {8'h00,8'hB4};
            15'd525:data_word <= {8'h00,8'h00}; 
            15'd526:data_word <= {8'h00,8'h10};
            // page 4
            15'd655:data_word <= {8'h00,8'hB5};
            15'd656:data_word <= {8'h00,8'h00}; 
            15'd657:data_word <= {8'h00,8'h10};
            // page 5
            15'd786:data_word <= {8'h00,8'hB6};
            15'd787:data_word <= {8'h00,8'h00}; 
            15'd789:data_word <= {8'h00,8'h10};
            // page 6
            15'd917:data_word <= {8'h00,8'hB7};
            15'd918:data_word <= {8'h00,8'h00}; 
            15'd919:data_word <= {8'h00,8'h10};
            default:data_word <= {8'h00,8'haa};
        endcase
    end
end


assign word_addr = init_done ? data_addr:init_addr;
assign wdata     = init_done ? data_word:init_word;
assign exec = exec_reg;


endmodule

