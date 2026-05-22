`timescale 1ns / 1ps

module regfile(
    input wire clk,
    input wire reset,
    input wire clk_en,
    input wire we,
    input wire [4:0] waddr,
    input wire [31:0] wdata,
    input wire [4:0] raddr1,
    input wire [4:0] raddr2,
    output wire [31:0] rdata1,
    output wire [31:0] rdata2
);
    reg [31:0] array_reg [31:0];
    integer i;

    initial begin
        for (i = 0; i < 32; i = i + 1) begin
            array_reg[i] = 32'h00000000;
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < 32; i = i + 1) begin
                array_reg[i] <= 32'h00000000;
            end
        end else if (clk_en && we && (waddr != 5'd0)) begin
            array_reg[waddr] <= wdata;
        end
    end

    assign rdata1 = (raddr1 == 5'd0) ? 32'h00000000 : array_reg[raddr1];
    assign rdata2 = (raddr2 == 5'd0) ? 32'h00000000 : array_reg[raddr2];
endmodule
