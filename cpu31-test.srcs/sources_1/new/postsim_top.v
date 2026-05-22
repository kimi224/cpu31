`timescale 1ns / 1ps

module postsim_top #(
    parameter IO_SWITCH_DATA = 32'h00000000
)(
    input wire clk_in,
    input wire reset,
    output wire [31:0] pc,
    output wire [31:0] inst,
    output wire [31:0] mem0,
    output wire [31:0] mem1
);
    wire mem_we;
    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire [31:0] mem_rdata;

    sccpu sccpu (
        .clk_in(clk_in),
        .reset(reset),
        .clk_en(1'b1),
        .pc(pc),
        .inst(inst),
        .mem_rdata(mem_rdata),
        .mem_we(mem_we),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata)
    );

    scinstmem imem (
        .addr(pc),
        .inst(inst)
    );

    scdatamem_postsim #(
        .DEPTH(64),
        .ENABLE_IO(0)
    ) dmem (
        .clk(clk_in),
        .mem_we(mem_we),
        .addr(mem_addr),
        .wdata(mem_wdata),
        .io_switch_data(IO_SWITCH_DATA),
        .rdata(mem_rdata),
        .word0(mem0),
        .word1(mem1)
    );
endmodule
