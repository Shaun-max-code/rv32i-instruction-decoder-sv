// Code your design here
module rv32i_decoder_imm_gen (
    input  logic [31:0] instr,
    output logic [4:0]  rs1,
    output logic [4:0]  rs2,
    output logic [4:0]  rd,
    output logic [31:0] imm_out,
    output logic        reg_write,
    output logic        alu_src,
    output logic        mem_read,
    output logic        mem_write,
    output logic        branch,
    output logic        jump,
    output logic [1:0]  result_src,
    output logic [3:0]  alu_ctrl,
    output logic        illegal_instr
);

    logic [6:0] opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;

    assign opcode = instr[6:0];
    assign rd     = instr[11:7];
    assign funct3 = instr[14:12];
    assign rs1    = instr[19:15];
    assign rs2    = instr[24:20];
    assign funct7 = instr[31:25];

    localparam [6:0] OP_R_TYPE = 7'b0110011;
    localparam [6:0] OP_I_ALU  = 7'b0010011;
    localparam [6:0] OP_LOAD   = 7'b0000011;
    localparam [6:0] OP_STORE  = 7'b0100011;
    localparam [6:0] OP_BRANCH = 7'b1100011;
    localparam [6:0] OP_JAL    = 7'b1101111;
    localparam [6:0] OP_JALR   = 7'b1100111;
    localparam [6:0] OP_LUI    = 7'b0110111;
    localparam [6:0] OP_AUIPC  = 7'b0010111;

    localparam [3:0] ALU_ADD  = 4'b0000;
    localparam [3:0] ALU_SUB  = 4'b0001;
    localparam [3:0] ALU_SLL  = 4'b0010;
    localparam [3:0] ALU_SLT  = 4'b0011;
    localparam [3:0] ALU_SLTU = 4'b0100;
    localparam [3:0] ALU_XOR  = 4'b0101;
    localparam [3:0] ALU_SRL  = 4'b0110;
    localparam [3:0] ALU_SRA  = 4'b0111;
    localparam [3:0] ALU_OR   = 4'b1000;
    localparam [3:0] ALU_AND  = 4'b1001;

    typedef enum logic [2:0] {
        IMM_I, IMM_S, IMM_B, IMM_U, IMM_J, IMM_NONE
    } imm_type_t;

    imm_type_t imm_sel;
    logic [1:0] alu_op;

    always_comb begin
        reg_write     = 1'b0;
        alu_src       = 1'b0;
        mem_read      = 1'b0;
        mem_write     = 1'b0;
        branch        = 1'b0;
        jump          = 1'b0;
        result_src    = 2'b00;
        alu_op        = 2'b00;
        imm_sel       = IMM_NONE;
        illegal_instr = 1'b0;

        case (opcode)
            OP_R_TYPE: begin reg_write = 1'b1; alu_op = 2'b10; end
            OP_I_ALU:  begin reg_write = 1'b1; alu_src = 1'b1; alu_op = 2'b10; imm_sel = IMM_I; end
            OP_LOAD:   begin reg_write = 1'b1; alu_src = 1'b1; mem_read = 1'b1; result_src = 2'b01; imm_sel = IMM_I; end
            OP_STORE:  begin alu_src = 1'b1; mem_write = 1'b1; imm_sel = IMM_S; end
            OP_BRANCH: begin branch = 1'b1; alu_op = 2'b01; imm_sel = IMM_B; end
            OP_JAL:    begin reg_write = 1'b1; jump = 1'b1; result_src = 2'b10; imm_sel = IMM_J; end
            OP_JALR:   begin reg_write = 1'b1; alu_src = 1'b1; jump = 1'b1; result_src = 2'b10; imm_sel = IMM_I; end
            OP_LUI:    begin reg_write = 1'b1; result_src = 2'b11; imm_sel = IMM_U; end
            OP_AUIPC:  begin reg_write = 1'b1; alu_src = 1'b1; imm_sel = IMM_U; end
            default:   begin illegal_instr = 1'b1; end
        endcase
    end

    always_comb begin
        case (imm_sel)
            IMM_I: imm_out = {{20{instr[31]}}, instr[31:20]};
            IMM_S: imm_out = {{20{instr[31]}}, instr[31:25], instr[11:7]};
            IMM_B: imm_out = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
            IMM_U: imm_out = {instr[31:12], 12'b0};
            IMM_J: imm_out = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
            default: imm_out = 32'b0;
        endcase
    end

    always_comb begin
        alu_ctrl = ALU_ADD;
        case (alu_op)
            2'b00: alu_ctrl = ALU_ADD;
            2'b01: alu_ctrl = ALU_SUB;
            2'b10: begin
                case (funct3)
                    3'b000: alu_ctrl = (opcode == OP_R_TYPE && funct7[5]) ? ALU_SUB : ALU_ADD;
                    3'b001: alu_ctrl = ALU_SLL;
                    3'b010: alu_ctrl = ALU_SLT;
                    3'b011: alu_ctrl = ALU_SLTU;
                    3'b100: alu_ctrl = ALU_XOR;
                    3'b101: alu_ctrl = funct7[5] ? ALU_SRA : ALU_SRL;
                    3'b110: alu_ctrl = ALU_OR;
                    3'b111: alu_ctrl = ALU_AND;
                    default: alu_ctrl = ALU_ADD;
                endcase
            end
            default: alu_ctrl = ALU_ADD;
        endcase
    end

endmodule
