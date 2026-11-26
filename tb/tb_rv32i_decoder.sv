`timescale 1ns/1ps

module tb_rv32i_decoder;

    logic [31:0] instr;
    logic [4:0]  rs1, rs2, rd;
    logic [31:0] imm_out;
    logic        reg_write, alu_src, mem_read, mem_write, branch, jump;
    logic [1:0]  result_src;
    logic [3:0]  alu_ctrl;
    logic        illegal_instr;

    int pass_count = 0;
    int fail_count = 0;

    rv32i_decoder_imm_gen dut (.*);

    task check_instr(
        input string       name,
        input logic [31:0] test_instr,
        input logic [4:0]  exp_rs1,
        input logic [4:0]  exp_rs2,
        input logic [4:0]  exp_rd,
        input logic [31:0] exp_imm,
        input logic        exp_reg_write,
        input logic        exp_alu_src,
        input logic        exp_mem_read,
        input logic        exp_mem_write,
        input logic        exp_branch,
        input logic        exp_jump,
        input logic [3:0]  exp_alu_ctrl,
        input logic        exp_illegal
    );
        instr = test_instr;
        #10;
        if (rs1 === exp_rs1 && rs2 === exp_rs2 && rd === exp_rd &&
            imm_out === exp_imm && reg_write === exp_reg_write &&
            alu_src === exp_alu_src && mem_read === exp_mem_read &&
            mem_write === exp_mem_write && branch === exp_branch &&
            jump === exp_jump && alu_ctrl === exp_alu_ctrl &&
            illegal_instr === exp_illegal) begin
            $display("[PASS] %-12s | Instr: %h | Imm: %h | ALU_Ctrl: %b", name, instr, imm_out, alu_ctrl);
            pass_count++;
        end else begin
            $error("[FAIL] %-12s | Instr: %h", name, instr);
            fail_count++;
        end
    endtask

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_rv32i_decoder);

        check_instr("SUB (R)", 32'h407302B3, 5'd6, 5'd7, 5'd5, 32'h0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 4'b0001, 1'b0);
        check_instr("ADDI (I)", 32'hFF058513, 5'd11, 5'd16, 5'd10, 32'hFFFFFFF0, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 4'b0000, 1'b0);
        check_instr("SRAI (I)", 32'h40425193, 5'd4, 5'd4, 5'd3, 32'h00000404, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 4'b0111, 1'b0);
        check_instr("LW (I)", 32'h00C12403, 5'd2, 5'd12, 5'd8, 32'h0000000C, 1'b1, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 4'b0000, 1'b0);
        check_instr("SW (S)", 32'hFE912C23, 5'd2, 5'd9, 5'd24, 32'hFFFFFFF8, 1'b0, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 4'b0000, 1'b0);
        check_instr("BEQ (B)", 32'hFE208EE3, 5'd1, 5'd2, 5'd29, 32'hFFFFFFFC, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 4'b0001, 1'b0);
        check_instr("LUI (U)", 32'h12345637, 5'd5, 5'd3, 5'd12, 32'h12345000, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 4'b0000, 1'b0);
        check_instr("JAL (J)", 32'h010000EF, 5'd0, 5'd16, 5'd1, 32'h00000010, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 4'b0000, 1'b0);
        check_instr("ILLEGAL", 32'hFFFFFFFF, 5'd31, 5'd31, 5'd31, 32'h0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 4'b0000, 1'b1);

        #10;
        $display("Simulation Summary: %0d PASSED, %0d FAILED", pass_count, fail_count);
        $finish;
    end

endmodule
