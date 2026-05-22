`timescale 1ns / 1ps

module scinstmem(
    input wire [31:0] addr,
    output wire [31:0] inst
);
    wire [10:0] word_addr;

    assign word_addr = addr[12:2];

    imem imem (
        .a(word_addr),
        .spo(inst)
    );
endmodule
