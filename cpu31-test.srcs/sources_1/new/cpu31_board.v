`timescale 1ns / 1ps

module cpu31_board #(
    parameter IO_SWITCH_DATA = 32'h00008000,
    parameter CPU_STEP_DIVISOR = 26'd50000000
)(
    input wire clk_in,
    input wire reset,
    output wire [31:0] display_data
);
    reg [25:0] step_counter;
    reg cpu_clk_en;
    wire [31:0] inst;
    wire [31:0] pc;
    wire mem_we;
    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire [31:0] mem_rdata;
    wire [31:0] word0;
    wire [31:0] word1;

    always @(posedge clk_in) begin
        if (reset) begin
            step_counter <= 26'd0;
            cpu_clk_en <= 1'b0;
        end else if (step_counter == (CPU_STEP_DIVISOR - 1'b1)) begin
            step_counter <= 26'd0;
            cpu_clk_en <= 1'b1;
        end else begin
            step_counter <= step_counter + 1'b1;
            cpu_clk_en <= 1'b0;
        end
    end

    sccpu sccpu (
        .clk_in(clk_in),
        .reset(reset),
        .clk_en(cpu_clk_en),
        .pc(pc),
        .inst(inst),
        .mem_rdata(mem_rdata),
        .mem_we(mem_we),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata)
    );

    scinstmem_board imem (
        .addr(pc),
        .inst(inst)
    );

    scdatamem #(
        .IO_SWITCH_ADDR(32'h10010010)
    ) dmem (
        .clk(clk_in),
        .mem_we(cpu_clk_en && mem_we),
        .addr(mem_addr),
        .wdata(mem_wdata),
        .io_switch_data(IO_SWITCH_DATA),
        .rdata(mem_rdata),
        .word0(word0),
        .word1(word1)
    );

    assign display_data = inst;
endmodule
