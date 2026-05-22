`timescale 1ns / 1ps

module sccontroller(
    input wire [5:0] opcode,
    input wire [5:0] funct,
    input wire eq_flag,
    output reg reg_we,
    output reg mem_we,
    output reg [3:0] alu_op,
    output reg alu_src_imm,
    output reg imm_zero_ext,
    output reg [1:0] reg_dst_sel,
    output reg [1:0] pc_sel,
    output reg [1:0] wb_sel
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

    localparam REGDST_RT = 2'd0;
    localparam REGDST_RD = 2'd1;
    localparam REGDST_RA = 2'd2;

    localparam PC_PLUS4  = 2'd0;
    localparam PC_BRANCH = 2'd1;
    localparam PC_JUMP   = 2'd2;
    localparam PC_RS     = 2'd3;

    localparam WB_ALU = 2'd0;
    localparam WB_MEM = 2'd1;
    localparam WB_PC4 = 2'd2;
    localparam WB_LUI = 2'd3;

    always @(*) begin
        reg_we = 1'b0;
        mem_we = 1'b0;
        alu_op = ALU_ADD;
        alu_src_imm = 1'b0;
        imm_zero_ext = 1'b0;
        reg_dst_sel = REGDST_RT;
        pc_sel = PC_PLUS4;
        wb_sel = WB_ALU;

        case (opcode)
            6'b000000: begin
                reg_dst_sel = REGDST_RD;
                case (funct)
                    6'h20, 6'h21: reg_we = 1'b1;
                    6'h22, 6'h23: begin reg_we = 1'b1; alu_op = ALU_SUB; end
                    6'h24: begin reg_we = 1'b1; alu_op = ALU_AND; end
                    6'h25: begin reg_we = 1'b1; alu_op = ALU_OR; end
                    6'h26: begin reg_we = 1'b1; alu_op = ALU_XOR; end
                    6'h27: begin reg_we = 1'b1; alu_op = ALU_NOR; end
                    6'h2A: begin reg_we = 1'b1; alu_op = ALU_SLT; end
                    6'h2B: begin reg_we = 1'b1; alu_op = ALU_SLTU; end
                    6'h00: begin reg_we = 1'b1; alu_op = ALU_SLL; end
                    6'h02: begin reg_we = 1'b1; alu_op = ALU_SRL; end
                    6'h03: begin reg_we = 1'b1; alu_op = ALU_SRA; end
                    6'h04: begin reg_we = 1'b1; alu_op = ALU_SLLV; end
                    6'h06: begin reg_we = 1'b1; alu_op = ALU_SRLV; end
                    6'h07: begin reg_we = 1'b1; alu_op = ALU_SRAV; end
                    6'h08: begin reg_dst_sel = REGDST_RT; pc_sel = PC_RS; end
                    default: begin reg_dst_sel = REGDST_RT; end
                endcase
            end
            6'h08, 6'h09: begin reg_we = 1'b1; alu_src_imm = 1'b1; end
            6'h0C: begin reg_we = 1'b1; alu_src_imm = 1'b1; imm_zero_ext = 1'b1; alu_op = ALU_AND; end
            6'h0D: begin reg_we = 1'b1; alu_src_imm = 1'b1; imm_zero_ext = 1'b1; alu_op = ALU_OR; end
            6'h0E: begin reg_we = 1'b1; alu_src_imm = 1'b1; imm_zero_ext = 1'b1; alu_op = ALU_XOR; end
            6'h0F: begin reg_we = 1'b1; wb_sel = WB_LUI; end
            6'h0A: begin reg_we = 1'b1; alu_src_imm = 1'b1; alu_op = ALU_SLT; end
            6'h0B: begin reg_we = 1'b1; alu_src_imm = 1'b1; alu_op = ALU_SLTU; end
            6'h04: begin if (eq_flag) pc_sel = PC_BRANCH; end
            6'h05: begin if (!eq_flag) pc_sel = PC_BRANCH; end
            6'h23: begin reg_we = 1'b1; alu_src_imm = 1'b1; wb_sel = WB_MEM; end
            6'h2B: begin mem_we = 1'b1; alu_src_imm = 1'b1; end
            6'h02: begin pc_sel = PC_JUMP; end
            6'h03: begin reg_we = 1'b1; reg_dst_sel = REGDST_RA; wb_sel = WB_PC4; pc_sel = PC_JUMP; end
            default: begin end
        endcase
    end
endmodule
