module top (
    input clk,
    input rst_n,
    input  [3:0] key,
    output [3:0] led
);

reg [31:0] cnt0, cnt1;

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

wire key0_valid = cnt0 == 32'd20_000_000;

reg led0;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        led0 <= 1'd0;
    end
    else if(key0_short) begin
        led0 <= ~led0;
    end
end

reg led1;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        led1 <= 1'd0;
    end
    else if(key0_long) begin
        led1 <= ~led1;
    end
end

assign led[0] = led0;
assign led[1] = led1;

// assign led = key;

endmodule

