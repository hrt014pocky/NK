module key (
    input clk,
    input rst_n,
    input key,
    output reg key_short,
    output reg key_long
);

reg key_reg;
reg [31:0] cnt0;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        key_reg <= 1'd1;
    else 
        key_reg <= key;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cnt0 <= 0;
    end
    else if(!key_reg)
        cnt0 <= cnt0 + 1'd1;
    else
        cnt0 <= 0;
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        key_short <= 1'd0;
        key_long  <= 1'd0;
    end
    else if(key_reg) begin
        if((cnt0 > 32'd50_000) && (cnt0 < 32'd20_000_000)) begin
            key_short <= 1'd1;
        end
        else if(cnt0 >= 32'd20_000_000) begin
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







endmodule