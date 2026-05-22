`timescale 1ns / 1ps

module sccpu(
    input wire clk_in,
    input wire reset,
    input wire clk_en,
    output wire [31:0] pc,
    input wire [31:0] inst,
    input wire [31:0] mem_rdata,
    output wire mem_we,
    output wire [31:0] mem_addr,
    output wire [31:0] mem_wdata
);
    localparam PC_RESET = 32'h00400000;
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

    wire [31:0] pc_plus4;
    wire [31:0] next_pc;
    wire [5:0] opcode;
    wire [4:0] rs;
    wire [4:0] rt;
    wire [4:0] rd;
    wire [4:0] shamt;
    wire [5:0] funct;
    wire [15:0] imm16;
    wire [25:0] imm26;
    wire [31:0] rs_data;
    wire [31:0] rt_data;
    wire [31:0] sign_ext_imm;
    wire [31:0] zero_ext_imm;
    wire [31:0] imm_ext;
    wire [31:0] branch_target;
    wire [31:0] jump_target;
    wire [31:0] alu_src_b;
    wire [31:0] alu_result;
    wire reg_we;
    wire mem_we_ctrl;
    wire eq_flag;
    wire [3:0] alu_op;
    wire alu_src_imm;
    wire imm_zero_ext;
    wire [1:0] reg_dst_sel;
    wire [1:0] pc_sel;
    wire [1:0] wb_sel;
    reg [4:0] reg_waddr;
    reg [31:0] reg_wdata;

    scpc #(
        .PC_RESET(PC_RESET)
    ) pc_reg_ref (
        .clk(clk_in),
        .reset(reset),
        .clk_en(clk_en),
        .next_pc(next_pc),
        .pc(pc)
    );

    regfile cpu_ref (
        .clk(clk_in),
        .reset(reset),
        .clk_en(clk_en),
        .we(reg_we),
        .waddr(reg_waddr),
        .wdata(reg_wdata),
        .raddr1(rs),
        .raddr2(rt),
        .rdata1(rs_data),
        .rdata2(rt_data)
    );

    sccontroller control_ref (
        .opcode(opcode),
        .funct(funct),
        .eq_flag(eq_flag),
        .reg_we(reg_we),
        .mem_we(mem_we_ctrl),
        .alu_op(alu_op),
        .alu_src_imm(alu_src_imm),
        .imm_zero_ext(imm_zero_ext),
        .reg_dst_sel(reg_dst_sel),
        .pc_sel(pc_sel),
        .wb_sel(wb_sel)
    );

    scalu alu_ref (
        .src_a(rs_data),
        .src_b(alu_src_b),
        .shamt(shamt),
        .alu_op(alu_op),
        .result(alu_result),
        .eq_flag(eq_flag)
    );

    assign opcode = inst[31:26];
    assign rs = inst[25:21];
    assign rt = inst[20:16];
    assign rd = inst[15:11];
    assign shamt = inst[10:6];
    assign funct = inst[5:0];
    assign imm16 = inst[15:0];
    assign imm26 = inst[25:0];

    assign sign_ext_imm = {{16{imm16[15]}}, imm16};
    assign zero_ext_imm = {16'h0000, imm16};
    assign imm_ext = imm_zero_ext ? zero_ext_imm : sign_ext_imm;
    assign pc_plus4 = pc + 32'h00000004;
    assign branch_target = pc_plus4 + (sign_ext_imm << 2);
    assign jump_target = {pc_plus4[31:28], imm26, 2'b00};
    assign alu_src_b = alu_src_imm ? imm_ext : rt_data;

    always @(*) begin
        case (reg_dst_sel)
            REGDST_RD: reg_waddr = rd;
            REGDST_RA: reg_waddr = 5'd31;
            default:   reg_waddr = rt;
        endcase
    end

    always @(*) begin
        case (wb_sel)
            WB_MEM: reg_wdata = mem_rdata;
            WB_PC4: reg_wdata = pc_plus4;
            WB_LUI: reg_wdata = {imm16, 16'h0000};
            default: reg_wdata = alu_result;
        endcase
    end

    assign next_pc = (pc_sel == PC_BRANCH) ? branch_target :
                     (pc_sel == PC_JUMP)   ? jump_target :
                     (pc_sel == PC_RS)     ? rs_data :
                                             pc_plus4;

    assign mem_we = mem_we_ctrl;
    assign mem_addr = alu_result;
    assign mem_wdata = rt_data;
endmodule
