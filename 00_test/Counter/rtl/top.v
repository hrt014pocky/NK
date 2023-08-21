module top (
    input clk,
    input rst_n,
    output [7:0] segment,
    output [3:0] segsel,
    output led4,
    output led5,
    output led6,
    output led7,
    output ledr,
    output ledg,
    output ledb
);

wire cnt_add;
wire cnt_end;

reg [31:0] cnt;


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
assign cnt_end = cnt_add && (cnt == 32'd50_000_000);

reg [3:0] seg_reg;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        seg_reg <= 4'b0111;
    end
    else begin
        if(cnt_end) begin
            seg_reg <= {seg_reg[2:0], seg_reg[3]};
        end
   end
end


assign ledr = 1'd0;
assign ledg = 1'd0;
assign ledb = 1'd0;

assign led4 = 1'd0;
assign led5 = 1'd1;
assign led6 = 1'd0;
assign led7 = 1'd1;

assign segsel = seg_reg;
assign segment = 8'h3f;

endmodule

