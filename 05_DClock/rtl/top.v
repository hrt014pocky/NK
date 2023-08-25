`include "define.v"

module top (
    input clk,
    input rst_n,
    input  [3:0] key,
    output [7:0] segment,
    output [3:0] segsel
);

reg timeset;
reg flash0;
reg flash1;
reg flash2;
reg flash3;
reg [7:0] set_swift;

reg [31:0] cntflash;
wire cntflash_add;
wire cntflash_end;

reg [31:0] cntsel;
wire cntsel_add;
wire cntsel_end;

reg [3:0] sel_index;
wire sel_index_add;
wire sel_index_end;

reg [31:0] cnt0 ,cnt1 ;
reg [3:0] key1, key2;
reg key0_short, key0_long;
reg key1_short, key1_long;

reg [31:0] cntclock;
wire cntclock_add;
wire cntclock_end;

reg [7:0] cnt1s;
wire cnt1s_add;
wire cnt1s_end;

reg [7:0] cnt10s;
wire cnt10s_add;
wire cnt10s_end;

reg [7:0] cnt1min;
wire cnt1min_add;
wire cnt1min_end;

reg [7:0] cnt10min;
wire cnt10min_add;
wire cnt10min_end;

reg [7:0] cnt1h;
wire cnt1h_add;
wire cnt1h_end;

reg [7:0] cnt10h;
wire cnt10h_add;
wire cnt10h_end;

//-------------------------------------------------------------------
// 数码管扫描
//-------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cntsel <= 0;
    end
    else if(cntsel_add) begin
        if(cntsel_end)
            cntsel <= 0;
        else
            cntsel <= cntsel + 1'd1;
   end
end

assign cntsel_add = 1'd1;
assign cntsel_end = cntsel_add && cntsel == 31'd20_000_0 - 1;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        sel_index <= 0;
    end
    else if(sel_index_add) begin
        if(sel_index_end)
            sel_index <= 0;
        else
            sel_index <= sel_index + 1'd1;
   end
end

assign sel_index_add = cntsel_end;
assign sel_index_end = sel_index_add && sel_index == 3'd4 - 1;


assign segsel = ~(4'b0001 << sel_index);

//-------------------------------------------------------------------
// 数码管显示
//-------------------------------------------------------------------
reg [7:0] disp;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        disp  <= `DISPCODE_4;
    end
    else begin
        case (sel_index)
            0: begin
                if(flash0) 
                    disp <= 10;
                else
                    disp <= cnt1min;
            end
            1: begin
                if(flash1) 
                    disp <= 10;
                else
                    disp <= cnt10min;
            end
            2: begin
                if(flash2) 
                    disp <= 10;
                else
                    disp <= cnt1h;
            end
            3: begin
                if(flash3) 
                    disp <= 10;
                else
                    disp <= cnt10h;
            end
            default: ;
        endcase
    end
end

reg [7:0] seg_data, seg_data_next;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        seg_data <= `DISPCODE_NULL;
    end
    else begin
        seg_data <= seg_data_next;
    end
end

always @(*) begin
    if(!rst_n) begin
        seg_data_next = `DISPCODE_NULL;
    end
    else begin
        case (disp)
            0: seg_data_next = `DISPCODE_0;
            1: seg_data_next = `DISPCODE_1;
            2: seg_data_next = `DISPCODE_2;
            3: seg_data_next = `DISPCODE_3;
            4: seg_data_next = `DISPCODE_4;
            5: seg_data_next = `DISPCODE_5;
            6: seg_data_next = `DISPCODE_6;
            7: seg_data_next = `DISPCODE_7;
            8: seg_data_next = `DISPCODE_8;
            9: seg_data_next = `DISPCODE_9;
            10: seg_data_next = `DISPCODE_NULL;
            default: 
                seg_data_next = `DISPCODE_NULL;
        endcase
        if((sel_index == 2)) begin
            seg_data_next = seg_data_next & `DISPCODE_DOT;
        end
    end
end

assign segment = ~(seg_data);

//-------------------------------------------------------------------
// 数码管闪烁 设置分秒选择
//-------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cntflash <= 0;
    end
    else if(cntflash_add) begin
        if(cntflash_end)
            cntflash <= 0;
        else
            cntflash <= cntflash + 1'd1;
   end
end

assign cntflash_add = 1'd1;
assign cntflash_end = cntflash_add && cntflash == 32'd30_000_000;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        timeset <= 1'd0;
    end
    else begin
        if(!timeset && key0_long) begin
            timeset <= 1'd1;
        end
        else if(timeset && key0_long) begin
            timeset <= 1'd0;
        end
        else begin
            timeset <= timeset;
        end
    end
end

wire shift_add, shift_end;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        set_swift <= 0;
    end
    else if(shift_add) begin
        if(shift_end)
            set_swift <= 0;
        else
            set_swift <= set_swift + 1'd1;
   end
   else if(shift_end) 
        set_swift <= 0;
end

assign shift_add = timeset && key0_short;
assign shift_end = !timeset || (shift_add && set_swift == 8'd4 - 1);


always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        flash0 <= 1'd0;
        flash1 <= 1'd0;
        flash2 <= 1'd0;
        flash3 <= 1'd0;
    end
    else begin
        if(timeset && cntflash_end) begin
            case (set_swift)
                0: begin 
                    flash0 <= ~flash0;
                    flash1 <= 1'd0;
                    flash2 <= 1'd0;
                    flash3 <= 1'd0;
                end
                1: begin 
                    flash0 <= 1'd0;
                    flash1 <= ~flash1;
                    flash2 <= 1'd0;
                    flash3 <= 1'd0;
                end
                2: begin 
                    flash0 <= 1'd0;
                    flash1 <= 1'd0;
                    flash2 <= ~flash2;
                    flash3 <= 1'd0;
                end
                3: begin 
                    flash0 <= 1'd0;
                    flash1 <= 1'd0;
                    flash2 <= 1'd0;
                    flash3 <= ~flash3;
                end
                default: begin
                    flash0 <= 1'd0;
                    flash1 <= 1'd0;
                    flash2 <= 1'd0;
                    flash3 <= 1'd0;
                end
            endcase
        end
        else if(timeset) begin
            flash0 <= flash0;
            flash1 <= flash1;
            flash2 <= flash2;
            flash3 <= flash3;
        end
        else begin
            flash0 <= 1'd0;
            flash1 <= 1'd0;
            flash2 <= 1'd0;
            flash3 <= 1'd0;
        end
    end
end



//-------------------------------------------------------------------
// 按键
//-------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        key1 <= 4'b0000;
        key2 <= 4'b0000;
    end
    else begin
        key1 <= key;
        key2 <= key1;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
        cnt0 <= 0;
    else if(key2[0])
        cnt0 <= cnt0 + 1'd1;
    else 
        cnt0 <= 0;
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) 
        cnt1 <= 0;
    else if(key2[1])
        cnt1 <= cnt1 + 1'd1;
    else 
        cnt1 <= 0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        key0_short <= 1'd0;
        key0_long  <= 1'd0;
    end
    else if(!key2[0]) begin
        if((cnt0 > 32'd2_000_000) && (cnt0 < 32'd50_000_000)) begin
            key0_short <= 1'd1;
        end
        else if(cnt0 >= 32'd50_000_000) begin
            key0_long <= 1'd1;
        end
        else begin
            key0_short <= 1'd0;
            key0_long  <= 1'd0;
        end
    end
    else begin
        key0_short <= 1'd0;
        key0_long  <= 1'd0;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        key1_short <= 1'd0;
        key1_long  <= 1'd0;
    end
    else if(!key2[1]) begin
        if((cnt1 > 32'd2_000_000) && (cnt1 < 32'd50_000_000)) begin
            key1_short <= 1'd1;
        end
        else if(cnt1 >= 32'd50_000_000) begin
            key1_long <= 1'd1;
        end
        else begin
            key1_short <= 1'd0;
            key1_long  <= 1'd0;
        end
    end
    else begin
        key1_short <= 1'd0;
        key1_long  <= 1'd0;
    end
end


//-------------------------------------------------------------------
// 时钟，秒
//-------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cntclock <= 0;
    end
    else if(cntclock_add) begin
        if(cntclock_end)
            cntclock <= 0;
        else
            cntclock <= cntclock + 1'd1;
   end
end

assign cntclock_add = !timeset;
assign cntclock_end = cntclock_add && cntclock == 32'd100_000_000 - 1;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cnt1s <= 0;
    end
    else if(cnt1s_add) begin
        if(cnt1s_end)
            cnt1s <= 0;
        else
            cnt1s <= cnt1s + 1'd1;
   end
end

assign cnt1s_add = cntclock_end;
assign cnt1s_end = cnt1s_add && cnt1s == 8'd10 - 1;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cnt10s <= 0;
    end
    else if(cnt10s_add) begin
        if(cnt10s_end)
            cnt10s <= 0;
        else
            cnt10s <= cnt10s + 1'd1;
   end
end

assign cnt10s_add = cnt1s_end;
assign cnt10s_end = cnt10s_add && cnt10s == 8'd6 - 1;

//-------------------------------------------------------------------
// 时钟，分
//-------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cnt1min <= 0;
    end
    else if(cnt1min_add) begin
        if(cnt1min_end)
            cnt1min <= 0;
        else
            cnt1min <= cnt1min + 1'd1;
   end
end

assign cnt1min_add = cnt10s_end || (key1_short && set_swift == 0);
assign cnt1min_end = cnt1min_add && cnt1min == 8'd10 - 1;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cnt10min <= 0;
    end
    else if(cnt10min_add) begin
        if(cnt10min_end)
            cnt10min <= 0;
        else
            cnt10min <= cnt10min + 1'd1;
   end
end

assign cnt10min_add = (!timeset && cnt1min_end) || (key1_short && set_swift == 1);
assign cnt10min_end = cnt10min_add && cnt10min == 8'd6 - 1;

//-------------------------------------------------------------------
// 时钟，小时
//-------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cnt1h <= 0;
    end
    else if(cnt1h_add) begin
        if(cnt1h_end)
            cnt1h <= 0;
        else
            cnt1h <= cnt1h + 1'd1;
   end
end

assign cnt1h_add = (!timeset && cnt10min_end) || (key1_short && set_swift == 2);
assign cnt1h_end = (cnt1h_add && cnt1h == 8'd10 - 1) || (cnt1h_add && (cnt1h == 8'd4 - 1) && (cnt10h == 2));

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cnt10h <= 0;
    end
    else if(cnt10h_add) begin
        if(cnt10h_end)
            cnt10h <= 0;
        else
            cnt10h <= cnt10h + 1'd1;
   end
end

assign cnt10h_add = cnt1h_end;
assign cnt10h_end = (cnt10h_add && (cnt1h == 8'd4 - 1) && (cnt10h == 2)) || (cnt10h_add && cnt10h == 3);


endmodule

