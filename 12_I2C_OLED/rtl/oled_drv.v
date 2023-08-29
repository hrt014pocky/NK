module oled_drv (
    input clk,
    input rst_n,

    input i2c_done,
    input  key,

    output [7:0] word_addr, // 数据地址
    output [7:0] wdata,     // 写数据内容
    output exec             // 写开始信号

);
/*
{0x08,0xF8,0x08,0x00,0x00,0x08,0xF8,0x08,0x20,0x3F,0x21,0x01,0x01,0x21,0x3F,0x20},  "H",
{0x00,0x00,0x80,0x80,0x80,0x80,0x00,0x00,0x00,0x1F,0x24,0x24,0x24,0x24,0x17,0x00},  "e",
{0x00,0x10,0x10,0xF8,0x00,0x00,0x00,0x00,0x00,0x20,0x20,0x3F,0x20,0x20,0x00,0x00},  "l",
{0x00,0x10,0x10,0xF8,0x00,0x00,0x00,0x00,0x00,0x20,0x20,0x3F,0x20,0x20,0x00,0x00},  "l",
{0x00,0x00,0x80,0x80,0x80,0x80,0x00,0x00,0x00,0x1F,0x20,0x20,0x20,0x20,0x1F,0x00},  "o",
{0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00},  " ",
{0x08,0xF8,0x00,0xF8,0x00,0xF8,0x08,0x00,0x00,0x03,0x3E,0x01,0x3E,0x03,0x00,0x00},  "W",
{0x00,0x00,0x80,0x80,0x80,0x80,0x00,0x00,0x00,0x1F,0x20,0x20,0x20,0x20,0x1F,0x00},  "o",
{0x80,0x80,0x80,0x00,0x80,0x80,0x80,0x00,0x20,0x20,0x3F,0x21,0x20,0x00,0x01,0x00},  "r",
{0x00,0x10,0x10,0xF8,0x00,0x00,0x00,0x00,0x00,0x20,0x20,0x3F,0x20,0x20,0x00,0x00},  "l",
{0x00,0x00,0x80,0x80,0x80,0x90,0xF0,0x00,0x00,0x1F,0x20,0x20,0x20,0x10,0x3F,0x20},  "d",
*/


localparam CMD_NUM = 15'd29;
localparam INIT_DELAY = 32'd20_000;

reg [15:0] init_word; // 初始化数据
reg [15:0] init_addr; // 初始化地址
reg [15:0] data_addr; // 显示内容地址
reg [15:0] data_word; // 显示内容数据
reg exec_reg;

reg init_done;
reg [7:0] oled_init_cnt;
reg signed  [15:0] oled_data_cnt;

reg [31:0] delay;
wire delay_add, delay_end;
reg exec_ok;

wire oled_init_cnt_add, oled_init_cnt_end;
wire oled_data_cnt_add, oled_data_cnt_end;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        exec_reg <= 1'd0;
    end
    else begin
        if(delay_end)
            exec_reg <= 1'd1;
        else
            exec_reg <= 1'd0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        oled_init_cnt <= 0;
    end
    else if(oled_init_cnt_add) 
        oled_init_cnt <= oled_init_cnt + 1'd1;
    else if(oled_init_cnt == CMD_NUM)
        oled_init_cnt <= 0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        oled_data_cnt <= -1;
    end
    else if(oled_data_cnt == 16'd1047)
        oled_data_cnt <= 0;
    else if(oled_data_cnt_add) 
        oled_data_cnt <= oled_data_cnt + 1'd1;
end

// assign oled_init_cnt_add = exec_reg;
assign oled_init_cnt_add = exec_reg && oled_init_cnt < CMD_NUM;

assign oled_data_cnt_add = init_done && exec_reg && init_done;

//-------------------------------------------------------------------
// oled初始化
//-------------------------------------------------------------------
// 初始化延迟
/*
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        delay <= 16'd0;
        exec_ok <= 1'd0;
    end
    else if(delay_add) begin
        delay <= delay + 1'd1;
        exec_ok <= 1'd0;
    end
    else if(delay_end) begin
        if(key) begin
            exec_ok <= 1'd1;
            delay <= 1'd0;
        end
    end
    else if(i2c_done) begin
        exec_ok <= 1'd0;
    end
end
*/
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        delay <= 16'd0;
        exec_ok <= 1'd0;
    end
    else if(delay_end) begin
        delay <= 1'd0;
    end
    else if(delay_add) begin
        if(delay_end)
            delay <= 1'd0;
        else 
            delay <= delay + 1'd1;
    end
    // else if(i2c_done) begin
    //     exec_ok <= 1'd0;
    // end
end


assign delay_add = 1'd1;
assign delay_end = delay_add && delay == INIT_DELAY - 1;

//初始化与数据刷新
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        init_word <= 16'd0;
    end
    else begin
        if(!init_done) begin // 初始化未完成
            case (oled_init_cnt)
                0 : init_word <= {8'h00 ,8'hAE}; //--turn off oled panel
                1 : init_word <= {8'h00 ,8'hAE}; //--turn off oled panel
                2 : init_word <= {8'h00 ,8'h00}; //---set low column address
                3 : init_word <= {8'h00 ,8'h10}; //---set high column address
                4 : init_word <= {8'h00 ,8'h40}; //--set start line address  Set Mapping RAM Display Start Line (0x00~0x3F)
                5 : init_word <= {8'h00 ,8'h81}; //--set contrast control register
                6 : init_word <= {8'h00 ,8'hCF}; // Set SEG Output Current Brightness
                7 : init_word <= {8'h00 ,8'hA1}; //--Set SEG/Column Mapping     0xa0左右反置 0xa1正常
                8 : init_word <= {8'h00 ,8'hC8}; //Set COM/Row Scan Direction   0xc0上下反置 0xc8正常
                9 : init_word <= {8'h00 ,8'hA6}; //--set normal display
                10: init_word <= {8'h00 ,8'hA8}; //--set multiplex ratio(1 to 64)
                11: init_word <= {8'h00 ,8'h3F}; //--1/64 duty
                12: init_word <= {8'h00 ,8'hD3}; //-set display offset	Shift Mapping RAM Counter (0x00~0x3F
                13: init_word <= {8'h00 ,8'h00}; //-not offset
                14: init_word <= {8'h00 ,8'hD5}; //--set display clock divide ratio/oscillator frequency
                15: init_word <= {8'h00 ,8'h80}; //--set divide ratio, Set Clock as 100 Frames/Sec
                16: init_word <= {8'h00 ,8'hD9}; //--set pre-charge period
                17: init_word <= {8'h00 ,8'hF1}; //Set Pre-Charge as 15 Clocks & Discharge as 1 Clock
                18: init_word <= {8'h00 ,8'hDA}; //--set com pins hardware configuration
                19: init_word <= {8'h00 ,8'h12}; //
                20: init_word <= {8'h00 ,8'hDB}; //--set vcomh
                21: init_word <= {8'h00 ,8'h40}; //Set VCOM Deselect Level
                22: init_word <= {8'h00 ,8'h20}; //-Set Page Addressing Mode (0x00/0x01/0x02)
                23: init_word <= {8'h00 ,8'h02}; //
                24: init_word <= {8'h00 ,8'h8D}; //--set Charge Pump enable/disable
                25: init_word <= {8'h00 ,8'h14}; //--set(0x10) disable
                26: init_word <= {8'h00 ,8'hA4}; // Disable Entire Display On (0xa4/0xa5)
                27: init_word <= {8'h00 ,8'hA6}; // Disable Inverse Display On (0xa6/a7) 
                28: init_word <= {8'h00 ,8'hAF};
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
        case (oled_data_cnt)
            15'd0:  data_word <= {8'h00 ,8'hB0};
            15'd1:  data_word <= {8'h00 ,8'h00}; 
            15'd2:  data_word <= {8'h00 ,8'h10};
            // page 0
            15'd131:data_word <= {8'h00 ,8'hB1};
            15'd132:data_word <= {8'h00 ,8'h00}; 
            15'd133:data_word <= {8'h00 ,8'h10};
            // page 1
            15'd262:data_word <= {8'h00 ,8'hB2};
            15'd263:data_word <= {8'h00 ,8'h00}; 
            15'd264:data_word <= {8'h00 ,8'h10};
            // page 2
            15'd393:data_word <= {8'h00 ,8'hB3};
            15'd394:data_word <= {8'h00 ,8'h00}; 
            15'd395:data_word <= {8'h00 ,8'h10};
            // page 3
            15'd524:data_word <= {8'h00 ,8'hB4};
            15'd525:data_word <= {8'h00 ,8'h00}; 
            15'd526:data_word <= {8'h00 ,8'h10};
            // page 4
            15'd655:data_word <= {8'h00 ,8'hB5};
            15'd656:data_word <= {8'h00 ,8'h00}; 
            15'd657:data_word <= {8'h00 ,8'h10};
            // page 5
            15'd786:data_word <= {8'h00 ,8'hB6};
            15'd787:data_word <= {8'h00 ,8'h00}; 
            15'd789:data_word <= {8'h00 ,8'h10};
            // page 6
            15'd917:data_word <= {8'h00 ,8'hB7};
            15'd918:data_word <= {8'h00 ,8'h00}; 
            15'd919:data_word <= {8'h00 ,8'h10};
            
            3   : data_word <= {8'h40,8'h08};
            4   : data_word <= {8'h40,8'hF8};
            5   : data_word <= {8'h40,8'h08};
            6   : data_word <= {8'h40,8'h00};
            7   : data_word <= {8'h40,8'h00};
            8   : data_word <= {8'h40,8'h08};
            9   : data_word <= {8'h40,8'hF8};
            10  : data_word <= {8'h40,8'h08};
            134 : data_word <= {8'h40,8'h20};
            135 : data_word <= {8'h40,8'h3F};
            136 : data_word <= {8'h40,8'h21};
            137 : data_word <= {8'h40,8'h01};
            138 : data_word <= {8'h40,8'h01};
            139 : data_word <= {8'h40,8'h21};
            140 : data_word <= {8'h40,8'h3F};
            141 : data_word <= {8'h40,8'h20};



            11  : data_word <= {8'h40, 8'h00};
            12  : data_word <= {8'h40, 8'h00};
            13  : data_word <= {8'h40, 8'h80};
            14  : data_word <= {8'h40, 8'h80};
            15  : data_word <= {8'h40, 8'h80};
            16  : data_word <= {8'h40, 8'h80};
            17  : data_word <= {8'h40, 8'h00};
            18  : data_word <= {8'h40, 8'h00};
            19  : data_word <= {8'h40, 8'h00};
            20  : data_word <= {8'h40, 8'h10};
            21  : data_word <= {8'h40, 8'h10};
            22  : data_word <= {8'h40, 8'hF8};
            23  : data_word <= {8'h40, 8'h00};
            24  : data_word <= {8'h40, 8'h00};
            25  : data_word <= {8'h40, 8'h00};
            26  : data_word <= {8'h40, 8'h00};
            27  : data_word <= {8'h40, 8'h00};
            28  : data_word <= {8'h40, 8'h10};
            29  : data_word <= {8'h40, 8'h10};
            30  : data_word <= {8'h40, 8'hF8};
            31  : data_word <= {8'h40, 8'h00};
            32  : data_word <= {8'h40, 8'h00};
            33  : data_word <= {8'h40, 8'h00};
            34  : data_word <= {8'h40, 8'h00};
            35  : data_word <= {8'h40, 8'h00};
            36  : data_word <= {8'h40, 8'h00};
            37  : data_word <= {8'h40, 8'h80};
            38  : data_word <= {8'h40, 8'h80};
            39  : data_word <= {8'h40, 8'h80};
            40  : data_word <= {8'h40, 8'h80};
            41  : data_word <= {8'h40, 8'h00};
            42  : data_word <= {8'h40, 8'h00};
            43  : data_word <= {8'h40, 8'h00};
            44  : data_word <= {8'h40, 8'h00};
            45  : data_word <= {8'h40, 8'h00};
            46  : data_word <= {8'h40, 8'h00};
            47  : data_word <= {8'h40, 8'h00};
            48  : data_word <= {8'h40, 8'h00};
            49  : data_word <= {8'h40, 8'h00};
            50  : data_word <= {8'h40, 8'h00};
            51  : data_word <= {8'h40, 8'h08};
            52  : data_word <= {8'h40, 8'hF8};
            53  : data_word <= {8'h40, 8'h00};
            54  : data_word <= {8'h40, 8'hF8};
            55  : data_word <= {8'h40, 8'h00};
            56  : data_word <= {8'h40, 8'hF8};
            57  : data_word <= {8'h40, 8'h08};
            58  : data_word <= {8'h40, 8'h00};
            59  : data_word <= {8'h40, 8'h00};
            60  : data_word <= {8'h40, 8'h00};
            61  : data_word <= {8'h40, 8'h80};
            62  : data_word <= {8'h40, 8'h80};
            63  : data_word <= {8'h40, 8'h80};
            64  : data_word <= {8'h40, 8'h80};
            65  : data_word <= {8'h40, 8'h00};
            66  : data_word <= {8'h40, 8'h00};
            67  : data_word <= {8'h40, 8'h80};
            68  : data_word <= {8'h40, 8'h80};
            69  : data_word <= {8'h40, 8'h80};
            70  : data_word <= {8'h40, 8'h00};
            71  : data_word <= {8'h40, 8'h80};
            72  : data_word <= {8'h40, 8'h80};
            73  : data_word <= {8'h40, 8'h80};
            74  : data_word <= {8'h40, 8'h00};
            75  : data_word <= {8'h40, 8'h00};
            76  : data_word <= {8'h40, 8'h10};
            77  : data_word <= {8'h40, 8'h10};
            78  : data_word <= {8'h40, 8'hF8};
            79  : data_word <= {8'h40, 8'h00};
            80  : data_word <= {8'h40, 8'h00};
            81  : data_word <= {8'h40, 8'h00};
            82  : data_word <= {8'h40, 8'h00};
            83  : data_word <= {8'h40, 8'h00};
            84  : data_word <= {8'h40, 8'h00};
            85  : data_word <= {8'h40, 8'h80};
            86  : data_word <= {8'h40, 8'h80};
            87  : data_word <= {8'h40, 8'h80};
            88  : data_word <= {8'h40, 8'h90};
            89  : data_word <= {8'h40, 8'hF0};
            90  : data_word <= {8'h40, 8'h00};

            // 142 : data_word <= {8'h40, 8'h20};
            // 143 : data_word <= {8'h40, 8'h3F};
            // 144 : data_word <= {8'h40, 8'h21};
            // 145 : data_word <= {8'h40, 8'h01};
            // 146 : data_word <= {8'h40, 8'h01};
            // 147 : data_word <= {8'h40, 8'h21};
            // 148 : data_word <= {8'h40, 8'h3F};
            // 149 : data_word <= {8'h40, 8'h20};
            142 : data_word <= {8'h40, 8'h00};
            143 : data_word <= {8'h40, 8'h1F};
            144 : data_word <= {8'h40, 8'h24};
            145 : data_word <= {8'h40, 8'h24};
            146 : data_word <= {8'h40, 8'h24};
            147 : data_word <= {8'h40, 8'h24};
            148 : data_word <= {8'h40, 8'h17};
            149 : data_word <= {8'h40, 8'h00};
            150 : data_word <= {8'h40, 8'h00};
            151 : data_word <= {8'h40, 8'h20};
            152 : data_word <= {8'h40, 8'h20};
            153 : data_word <= {8'h40, 8'h3F};
            154 : data_word <= {8'h40, 8'h20};
            155 : data_word <= {8'h40, 8'h20};
            156 : data_word <= {8'h40, 8'h00};
            157 : data_word <= {8'h40, 8'h00};
            158 : data_word <= {8'h40, 8'h00};
            159 : data_word <= {8'h40, 8'h20};
            160 : data_word <= {8'h40, 8'h20};
            161 : data_word <= {8'h40, 8'h3F};
            162 : data_word <= {8'h40, 8'h20};
            163 : data_word <= {8'h40, 8'h20};
            164 : data_word <= {8'h40, 8'h00};
            165 : data_word <= {8'h40, 8'h00};
            166 : data_word <= {8'h40, 8'h00};
            167 : data_word <= {8'h40, 8'h1F};
            168 : data_word <= {8'h40, 8'h20};
            169 : data_word <= {8'h40, 8'h20};
            170 : data_word <= {8'h40, 8'h20};
            171 : data_word <= {8'h40, 8'h20};
            172 : data_word <= {8'h40, 8'h1F};
            173 : data_word <= {8'h40, 8'h00};
            174 : data_word <= {8'h40, 8'h00};
            175 : data_word <= {8'h40, 8'h00};
            176 : data_word <= {8'h40, 8'h00};
            177 : data_word <= {8'h40, 8'h00};
            178 : data_word <= {8'h40, 8'h00};
            179 : data_word <= {8'h40, 8'h00};
            180 : data_word <= {8'h40, 8'h00};
            181 : data_word <= {8'h40, 8'h00};
            182 : data_word <= {8'h40, 8'h00};
            183 : data_word <= {8'h40, 8'h03};
            184 : data_word <= {8'h40, 8'h3E};
            185 : data_word <= {8'h40, 8'h01};
            186 : data_word <= {8'h40, 8'h3E};
            187 : data_word <= {8'h40, 8'h03};
            188 : data_word <= {8'h40, 8'h00};
            189 : data_word <= {8'h40, 8'h00};
            190 : data_word <= {8'h40, 8'h00};
            191 : data_word <= {8'h40, 8'h1F};
            192 : data_word <= {8'h40, 8'h20};
            193 : data_word <= {8'h40, 8'h20};
            194 : data_word <= {8'h40, 8'h20};
            195 : data_word <= {8'h40, 8'h20};
            196 : data_word <= {8'h40, 8'h1F};
            197 : data_word <= {8'h40, 8'h00};
            198 : data_word <= {8'h40, 8'h20};
            199 : data_word <= {8'h40, 8'h20};
            200 : data_word <= {8'h40, 8'h3F};
            201 : data_word <= {8'h40, 8'h21};
            202 : data_word <= {8'h40, 8'h20};
            203 : data_word <= {8'h40, 8'h00};
            204 : data_word <= {8'h40, 8'h01};
            205 : data_word <= {8'h40, 8'h00};
            206 : data_word <= {8'h40, 8'h00};
            207 : data_word <= {8'h40, 8'h20};
            208 : data_word <= {8'h40, 8'h20};
            209 : data_word <= {8'h40, 8'h3F};
            210 : data_word <= {8'h40, 8'h20};
            211 : data_word <= {8'h40, 8'h20};
            212 : data_word <= {8'h40, 8'h00};
            213 : data_word <= {8'h40, 8'h00};
            214 : data_word <= {8'h40, 8'h00};
            215 : data_word <= {8'h40, 8'h1F};
            216 : data_word <= {8'h40, 8'h20};
            217 : data_word <= {8'h40, 8'h20};
            218 : data_word <= {8'h40, 8'h20};
            219 : data_word <= {8'h40, 8'h10};
            220 : data_word <= {8'h40, 8'h3F};
            221 : data_word <= {8'h40, 8'h20};


            default:data_word <= {8'h40 ,8'h00};
        endcase
    end
end


assign word_addr = init_done ? data_word[15:8]:init_word[15:8];
assign wdata     = init_done ? data_word[7 :0]:init_word[7 :0];
assign exec = exec_reg;


endmodule

