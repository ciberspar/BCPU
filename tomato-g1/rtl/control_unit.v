
module tomato_control_unit (
    input  wire [5:0] opcode,

    output reg reg_write,
    output reg alu_src_imm,
    output reg mem_read,
    output reg mem_write,
    output reg mem_to_reg,
    output reg branch,
    output reg jump,
    output reg alu_enable,
    output reg [3:0] alu_operation,
    output reg halt
);

    // ALU operations
    localparam ALU_ADD = 4'd0;
    localparam ALU_SUB = 4'd1;
    localparam ALU_AND = 4'd2;
    localparam ALU_OR  = 4'd3;
    localparam ALU_XOR = 4'd4;
    localparam ALU_NOT = 4'd5;
    localparam ALU_SHL = 4'd6;
    localparam ALU_SHR = 4'd7;
    localparam ALU_SAR = 4'd8;
    localparam ALU_MUL = 4'd9;

    // Lettuce opcodes
    localparam OP_NOP    = 6'd0;
    localparam OP_ADD    = 6'd1;
    localparam OP_SUB    = 6'd2;
    localparam OP_MUL    = 6'd3;
    localparam OP_DIVU   = 6'd4;
    localparam OP_AND    = 6'd5;
    localparam OP_OR     = 6'd6;
    localparam OP_XOR    = 6'd7;
    localparam OP_NOT    = 6'd8;
    localparam OP_SHL    = 6'd9;
    localparam OP_SHR    = 6'd10;
    localparam OP_SAR    = 6'd11;
    localparam OP_ADDI   = 6'd12;
    localparam OP_ANDI   = 6'd13;
    localparam OP_ORI    = 6'd14;
    localparam OP_XORI   = 6'd15;
    localparam OP_LUI    = 6'd16;
    localparam OP_LDW    = 6'd17;
    localparam OP_STW    = 6'd18;
    localparam OP_LDBU   = 6'd19;
    localparam OP_STB    = 6'd20;
    localparam OP_LDHU   = 6'd21;
    localparam OP_STH    = 6'd22;
    localparam OP_BEQ    = 6'd23;
    localparam OP_BNE    = 6'd24;
    localparam OP_BLT    = 6'd25;
    localparam OP_BGE    = 6'd26;
    localparam OP_JAL    = 6'd27;
    localparam OP_JALR   = 6'd28;
    localparam OP_RET    = 6'd29;
    localparam OP_SYSCALL = 6'd30;
    localparam OP_HALT   = 6'd31;

    always @(*) begin
        // Default signals
        reg_write     = 1'b0;
        alu_src_imm   = 1'b0;
        mem_read      = 1'b0;
        mem_write     = 1'b0;
        mem_to_reg    = 1'b0;
        branch        = 1'b0;
        jump          = 1'b0;
        alu_enable    = 1'b0;
        alu_operation = ALU_ADD;
        halt          = 1'b0;

        case (opcode)

            OP_NOP: begin
            end

            OP_ADD: begin
                reg_write = 1'b1;
                alu_enable = 1'b1;
                alu_operation = ALU_ADD;
            end

            OP_SUB: begin
                reg_write = 1'b1;
                alu_enable = 1'b1;
                alu_operation = ALU_SUB;
            end

            OP_MUL: begin
                reg_write = 1'b1;
                alu_enable = 1'b1;
                alu_operation = ALU_MUL;
            end

            OP_AND: begin
                reg_write = 1'b1;
                alu_enable = 1'b1;
                alu_operation = ALU_AND;
            end

            OP_OR: begin
                reg_write = 1'b1;
                alu_enable = 1'b1;
                alu_operation = ALU_OR;
            end

            OP_XOR: begin
                reg_write = 1'b1;
                alu_enable = 1'b1;
                alu_operation = ALU_XOR;
            end

            OP_NOT: begin
                reg_write = 1'b1;
                alu_enable = 1'b1;
                alu_operation = ALU_NOT;
            end

            OP_SHL: begin
                reg_write = 1'b1;
                alu_enable = 1'b1;
                alu_operation = ALU_SHL;
            end

            OP_SHR: begin
                reg_write = 1'b1;
                alu_enable = 1'b1;
                alu_operation = ALU_SHR;
            end

            OP_SAR: begin
                reg_write = 1'b1;
                alu_enable = 1'b1;
                alu_operation = ALU_SAR;
            end

            OP_ADDI: begin
                reg_write = 1'b1;
                alu_src_imm = 1'b1;
                alu_enable = 1'b1;
                alu_operation = ALU_ADD;
            end

            OP_ANDI: begin
                reg_write = 1'b1;
                alu_src_imm = 1'b1;
                alu_enable = 1'b1;
                alu_operation = ALU_AND;
            end

            OP_ORI: begin
                reg_write = 1'b1;
                alu_src_imm = 1'b1;
                alu_enable = 1'b1;
                alu_operation = ALU_OR;
            end

            OP_XORI: begin
                reg_write = 1'b1;
                alu_src_imm = 1'b1;
                alu_enable = 1'b1;
                alu_operation = ALU_XOR;
            end

            OP_LDW, OP_LDBU, OP_LDHU: begin
                reg_write = 1'b1;
                alu_src_imm = 1'b1;
                alu_enable = 1'b1;
                mem_read = 1'b1;
                mem_to_reg = 1'b1;
                alu_operation = ALU_ADD;
            end

            OP_STW, OP_STB, OP_STH: begin
                alu_src_imm = 1'b1;
                alu_enable = 1'b1;
                mem_write = 1'b1;
                alu_operation = ALU_ADD;
            end

            OP_BEQ, OP_BNE, OP_BLT, OP_BGE: begin
                branch = 1'b1;
                alu_enable = 1'b1;
                alu_operation = ALU_SUB;
            end

            OP_JAL, OP_JALR, OP_RET: begin
                jump = 1'b1;
                reg_write = (opcode == OP_JAL || opcode == OP_JALR);
            end

            OP_LUI: begin
                reg_write = 1'b1;
            end

            OP_DIVU: begin
                reg_write = 1'b1;
                alu_enable = 1'b1;
            end

            OP_SYSCALL: begin
                halt = 1'b0;
            end

            OP_HALT: begin
                halt = 1'b1;
            end

            default: begin
                // Unknown instruction: no operation
            end

        endcase
    end

endmodule
