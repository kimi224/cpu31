`timescale 1ns / 1ps

module test(
    input wire clk_in,
    input wire reset,
    output wire [7:0] o_seg,
    output wire [7:0] o_sel
);
    wire [31:0] display_data;

    cpu31_board cpu_board (
        .clk_in(clk_in),
        .reset(reset),
        .display_data(display_data)
    );

    seg7x16 seg7x16_ref (
        .clk(clk_in),
        .reset(reset),
        .cs(1'b1),
        .i_data(display_data),
        .o_seg(o_seg),
        .o_sel(o_sel)
    );
endmodule
