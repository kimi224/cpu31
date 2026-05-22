`timescale 1ns / 1ps

module scdatamem #(
    parameter DEPTH = 1024,
    parameter BASE_ADDR = 32'h10010000,
    parameter IO_SWITCH_ADDR = BASE_ADDR + 32'h00010000
)(
    input wire clk,
    input wire mem_we,
    input wire [31:0] addr,
    input wire [31:0] wdata,
    input wire [31:0] io_switch_data,
    output wire [31:0] rdata,
    output wire [31:0] word0,
    output wire [31:0] word1
);
    function integer clog2;
        input integer value;
        integer temp;
        begin
            temp = value - 1;
            clog2 = 0;
            while (temp > 0) begin
                temp = temp >> 1;
                clog2 = clog2 + 1;
            end
        end
    endfunction

    localparam ADDR_W = clog2(DEPTH);
    (* ram_style = "distributed" *) reg [31:0] ram [0:DEPTH-1];
    reg [31:0] word0_reg;
    reg [31:0] word1_reg;
    integer i;
    wire [ADDR_W-1:0] word_index;
    wire ram_sel;
    wire io_sel;

    initial begin
        for (i = 0; i < DEPTH; i = i + 1) begin
            ram[i] = 32'h00000000;
        end
        word0_reg = 32'h00000000;
        word1_reg = 32'h00000000;
    end

    assign word_index = addr[ADDR_W+1:2];
    assign ram_sel = (addr[31:ADDR_W+2] == BASE_ADDR[31:ADDR_W+2]);
    assign io_sel = (addr == IO_SWITCH_ADDR);

    always @(posedge clk) begin
        if (mem_we && ram_sel && !io_sel) begin
            ram[word_index] <= wdata;
            if (word_index == {ADDR_W{1'b0}}) begin
                word0_reg <= wdata;
            end
            if (word_index == {{(ADDR_W-1){1'b0}}, 1'b1}) begin
                word1_reg <= wdata;
            end
        end
    end

    assign rdata = io_sel ? io_switch_data :
                   (ram_sel ? ram[word_index] : 32'h00000000);
    assign word0 = word0_reg;
    assign word1 = word1_reg;
endmodule
