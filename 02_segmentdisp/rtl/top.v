`include "define.v"

module top (
    input clk,
    input rst_n,
    output [7:0] segment,
    output [3:0] segsel
);



wire cnt_add;
wire cnt_end;
wire cntment_add;
wire cntment_end;

reg [31:0] cnt;
reg [31:0] cntment;
reg [7: 0] dispTable [0:15];


always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cnt <= 0;
    end
    else if(cnt_add) begin
        if(cnt_end)
            cnt<= 0;
        else
            cnt <= cnt + 1'd1;
   end
end

assign cnt_add = 1'd1;
assign cnt_end = cnt_add && (cnt == 32'd100_000_000);

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cntment <= 0;
    end
    else if(cntment_add) begin
        if(cntment_end)
            cntment<= 0;
        else
            cntment <= cntment + 1'd1;
   end
end

assign cntment_add = cnt_end;
assign cntment_end = cntment_add && cntment == 8'd16 - 1;


reg [3:0] sel_reg;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        sel_reg <= 4'b0111;
    end
    else begin
        if(cnt_end) begin
            sel_reg <= {sel_reg[0], sel_reg[3:1]};
        end
   end
end

assign segsel = sel_reg;
assign segment = ~dispTable[cntment];


always @(*) begin
    dispTable[0] = `DISPCODE_0;
    dispTable[1] = `DISPCODE_1;
    dispTable[2] = `DISPCODE_2;
    dispTable[3] = `DISPCODE_3;
    dispTable[4] = `DISPCODE_4;
    dispTable[5] = `DISPCODE_5;
    dispTable[6] = `DISPCODE_6;
    dispTable[7] = `DISPCODE_7;
    dispTable[8] = `DISPCODE_8;
    dispTable[9] = `DISPCODE_9;
    dispTable[10] = `DISPCODE_A;
    dispTable[11] = `DISPCODE_b;
    dispTable[12] = `DISPCODE_C;
    dispTable[13] = `DISPCODE_d;
    dispTable[14] = `DISPCODE_E;
    dispTable[15] = `DISPCODE_F;
end
    
endmodule


