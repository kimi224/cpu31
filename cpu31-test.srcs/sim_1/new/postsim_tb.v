`timescale 1ns / 1ps

module postsim_tb;

    reg clk_in;
    reg reset;
    wire [31:0] pc;
    wire [31:0] inst;
    wire [31:0] mem0;
    wire [31:0] mem1;
    reg [31:0] cnt;

    integer outfile;

    postsim_top uut (
        .clk_in(clk_in),
        .reset(reset),
        .pc(pc),
        .inst(inst),
        .mem0(mem0),
        .mem1(mem1)
    );

    initial begin
        outfile = $fopen("D:/computer_composition/cpu31-test/tmp/postsim_result.txt", "w");
        clk_in = 1'b0;
        reset = 1'b1;
        cnt = 32'h00000000;
        #120;
        reset = 1'b0;
    end

    always #50 clk_in = ~clk_in;

    always @(posedge clk_in) begin
        #1;
        cnt <= cnt + 1'b1;
        if (pc <= 32'h00400278) begin
            $fdisplay(outfile, "pc: %h", pc);
            $fdisplay(outfile, "instr: %h", inst);
            $fdisplay(outfile, "mem0: %h", mem0);
            $fdisplay(outfile, "mem1: %h", mem1);
        end else if (cnt > 32'd1000) begin
            $fdisplay(outfile, "timeout pc: %h", pc);
            $fclose(outfile);
            $finish;
        end else begin
            $fclose(outfile);
            $finish;
        end
    end
endmodule
