module aram (
    input clk   ,
    input rst_n ,
    input wire we_i,                   // write enable
    input wire[15:0] addr_i,    // addr
    input wire[31:0] data_i,
    output reg[31:0] data_o         // read data

);

reg [31:0] _ram[0:1023];

// write
always @(posedge clk ) begin
    if(we_i) begin
        _ram[addr_i[31:0]] = data_i;
    end
end

// read
always @(*) begin
    if(!rst_n)begin
        data_o = 16'd0;
    end
    else begin
        data_o = _ram[addr_i[15:0]];
    end
end

reg [9:0] j;

reg [31:0] wave;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        wave <= 16'd0;
        j<=10'd0;
    end
    else begin
        wave <= _ram[j][31:0];
        j<=j+1;
    end
end

endmodule
