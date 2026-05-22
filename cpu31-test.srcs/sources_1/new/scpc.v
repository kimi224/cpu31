`timescale 1ns / 1ps

module scpc #(
    parameter PC_RESET = 32'h00400000
)(
    input wire clk,
    input wire reset,
    input wire clk_en,
    input wire [31:0] next_pc,
    output reg [31:0] pc
);
    initial begin
        pc = PC_RESET;
    end

    always @(posedge clk) begin
        if (reset) begin
            pc <= PC_RESET;
        end else if (clk_en) begin
            pc <= next_pc;
        end
    end
endmodule
