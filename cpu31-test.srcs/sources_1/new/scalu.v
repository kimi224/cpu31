`timescale 1ns / 1ps

module scalu(
    input wire [31:0] src_a,
    input wire [31:0] src_b,
    input wire [4:0] shamt,
    input wire [3:0] alu_op,
    output reg [31:0] result,
    output wire eq_flag
);
    localparam ALU_ADD  = 4'd0;
    localparam ALU_SUB  = 4'd1;
    localparam ALU_AND  = 4'd2;
    localparam ALU_OR   = 4'd3;
    localparam ALU_XOR  = 4'd4;
    localparam ALU_NOR  = 4'd5;
    localparam ALU_SLT  = 4'd6;
    localparam ALU_SLTU = 4'd7;
    localparam ALU_SLL  = 4'd8;
    localparam ALU_SRL  = 4'd9;
    localparam ALU_SRA  = 4'd10;
    localparam ALU_SLLV = 4'd11;
    localparam ALU_SRLV = 4'd12;
    localparam ALU_SRAV = 4'd13;

    assign eq_flag = (src_a == src_b);

    always @(*) begin
        case (alu_op)
            ALU_ADD:  result = src_a + src_b;
            ALU_SUB:  result = src_a - src_b;
            ALU_AND:  result = src_a & src_b;
            ALU_OR:   result = src_a | src_b;
            ALU_XOR:  result = src_a ^ src_b;
            ALU_NOR:  result = ~(src_a | src_b);
            ALU_SLT:  result = ($signed(src_a) < $signed(src_b)) ? 32'h00000001 : 32'h00000000;
            ALU_SLTU: result = (src_a < src_b) ? 32'h00000001 : 32'h00000000;
            ALU_SLL:  result = src_b << shamt;
            ALU_SRL:  result = src_b >> shamt;
            ALU_SRA:  result = $signed(src_b) >>> shamt;
            ALU_SLLV: result = src_b << src_a[4:0];
            ALU_SRLV: result = src_b >> src_a[4:0];
            ALU_SRAV: result = $signed(src_b) >>> src_a[4:0];
            default:  result = 32'h00000000;
        endcase
    end
endmodule
