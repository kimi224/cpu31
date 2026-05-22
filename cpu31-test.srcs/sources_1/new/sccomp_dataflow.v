`timescale 1ns / 1ps

module sccomp_dataflow #(
    parameter IO_SWITCH_DATA = 32'h00000000
)(
    input wire clk_in,
    input wire reset,
    output wire [31:0] inst,
    output wire [31:0] pc
);
    wire mem_we;
    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire [31:0] mem_rdata;
    wire [31:0] word0;
    wire [31:0] word1;
    wire [31:0] core_pc;
    wire [31:0] fetched_inst;

    sccpu sccpu (
        .clk_in(clk_in),
        .reset(reset),
        .clk_en(1'b1),
        .pc(core_pc),
        .inst(fetched_inst),
        .mem_rdata(mem_rdata),
        .mem_we(mem_we),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata)
    );

    scinstmem imem (
        .addr(core_pc),
        .inst(fetched_inst)
    );

    scdatamem dmem (
        .clk(clk_in),
        .mem_we(mem_we),
        .addr(mem_addr),
        .wdata(mem_wdata),
        .io_switch_data(IO_SWITCH_DATA),
        .rdata(mem_rdata),
        .word0(word0),
        .word1(word1)
    );

    assign pc = core_pc;
    assign inst = fetched_inst;
endmodule
