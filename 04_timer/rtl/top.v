`include "define.v"

module top (
    input clk,
    input rst_n,
    input  [3:0] key,
    output [7:0] segment,
    output [3:0] segsel
);

reg [31:0] cntsel;
wire cntsel_add;
wire cntsel_end;

reg [31:0] cnt1;
wire cnt1_add;
wire cnt1_end;

reg [7:0] cnt100ms;
wire cnt100ms_add;
wire cnt100ms_end;

reg [7:0] cnt1s;
wire cnt1s_add;
wire cnt1s_end;

reg [7:0] cnt10s;
wire cnt10s_add;
wire cnt10s_end;

reg [15:0] cntmin;
wire cntmin_add;
wire cntmin_end;

reg [3:0] sel_index;
wire sel_index_add;
wire sel_index_end;

reg [31:0] cnt0;
reg [3:0] key1, key2;

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
    if(!rst_n) begin
        cnt0 <= 0;
    end
    else if(key2[0])
        cnt0 <= cnt0 + 1'd1;
    else
        cnt0 <= 0;
end

reg key0_short, key0_long;
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

reg [7:0] disp;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        disp  <= `DISPCODE_4;
    end
    else begin
        case (sel_index)
            0: begin
                disp <= cnt100ms;
            end
            1: begin
                disp <= cnt1s;
            end
            2: begin
                disp <= cnt10s;
            end
            3: begin
                disp <= cntmin;
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
            0: begin
                seg_data_next = `DISPCODE_0;
            end
            1: begin
                seg_data_next = `DISPCODE_1;
            end
            2: begin
                seg_data_next = `DISPCODE_2;
            end
            3: begin
                seg_data_next = `DISPCODE_3;
            end
            4: begin
                seg_data_next = `DISPCODE_4;
            end
            5: begin
                seg_data_next = `DISPCODE_5;
            end
            6: begin
                seg_data_next = `DISPCODE_6;
            end
            7: begin
                seg_data_next = `DISPCODE_7;
            end
            8: begin
                seg_data_next = `DISPCODE_8;
            end
            9: begin
                seg_data_next = `DISPCODE_9;
            end
            default: 
                seg_data_next = `DISPCODE_NULL;
        endcase
        if((sel_index == 1) || (sel_index == 3)) begin
            seg_data_next = seg_data_next & `DISPCODE_DOT;
        end
    end
end


assign segment = ~(seg_data);

reg start;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        start <= 1'd0;
    end
    else begin
        if(key0_short)
            start <= ~start;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cnt1 <= 0;
    end
    else if(cnt1_add) begin
        if(cnt1_end)
            cnt1 <= 0;
        else
            cnt1 <= cnt1 + 1'd1;
   end
end

assign cnt1_add = start;
assign cnt1_end = (cnt1_add && cnt1 == 32'd10_000_000 - 1) || key0_long;


always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cnt100ms <= 0;
    end
    else if(cnt100ms_add) begin
        if(cnt100ms_end)
            cnt100ms <= 0;
        else
            cnt100ms <= cnt100ms + 1'd1;
   end
end

assign cnt100ms_add = cnt1_end;
assign cnt100ms_end = (cnt100ms_add && cnt100ms == 8'd10 - 1) || key0_long;


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

assign cnt1s_add = cnt100ms_end;
assign cnt1s_end = (cnt1s_add && cnt1s == 8'd10 - 1) || key0_long;


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
assign cnt10s_end = (cnt10s_add && cnt10s == 8'd6 - 1) || key0_long;


always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cntmin <= 0;
    end
    else if(cntmin_add) begin
        if(cntmin_end)
            cntmin <= 0;
        else
            cntmin <= cntmin + 1'd1;
   end
end

assign cntmin_add = cnt10s_end;
assign cntmin_end = (cntmin_add && cntmin == 16'd10 - 1) || key0_long;



endmodule


