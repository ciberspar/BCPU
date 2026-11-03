
`timescale 1ns/1ps

module control_unit_tb;

    reg [5:0] opcode;

    wire reg_write;
    wire alu_src_imm;
    wire mem_read;
    wire mem_write;
    wire mem_to_reg;
    wire branch;
    wire jump;
    wire alu_enable;
    wire [3:0] alu_operation;
    wire halt;

    integer passed;
    integer failed;

    localparam OP_NOP  = 6'd0;
    localparam OP_ADD  = 6'd1;
    localparam OP_SUB  = 6'd2;
    localparam OP_MUL  = 6'd3;
    localparam OP_ADDI = 6'd12;
    localparam OP_LDW  = 6'd17;
    localparam OP_STW  = 6'd18;
    localparam OP_BEQ  = 6'd23;
    localparam OP_BNE  = 6'd24;
    localparam OP_HALT = 6'd31;

    localparam ALU_ADD = 4'd0;
    localparam ALU_SUB = 4'd1;
    localparam ALU_MUL = 4'd9;

    tomato_control_unit dut (
        .opcode(opcode),
        .reg_write(reg_write),
        .alu_src_imm(alu_src_imm),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_to_reg(mem_to_reg),
        .branch(branch),
        .jump(jump),
        .alu_enable(alu_enable),
        .alu_operation(alu_operation),
        .halt(halt)
    );

    task check;
        input [127:0] test_name;
        input expected_reg_write;
        input expected_alu_src_imm;
        input expected_mem_read;
        input expected_mem_write;
        input expected_mem_to_reg;
        input expected_branch;
        input expected_jump;
        input expected_alu_enable;
        input [3:0] expected_alu_operation;
        input expected_halt;

        begin
            #1;

            if (
                reg_write === expected_reg_write &&
                alu_src_imm === expected_alu_src_imm &&
                mem_read === expected_mem_read &&
                mem_write === expected_mem_write &&
                mem_to_reg === expected_mem_to_reg &&
                branch === expected_branch &&
                jump === expected_jump &&
                alu_enable === expected_alu_enable &&
                alu_operation === expected_alu_operation &&
                halt === expected_halt
            ) begin
                $display("PASS: %0s", test_name);
                passed = passed + 1;
            end
            else begin
                $display("FAIL: %0s", test_name);
                failed = failed + 1;
            end
        end
    endtask

    initial begin
        passed = 0;
        failed = 0;
        opcode = OP_NOP;

        $display("================================");
        $display(" BCPU TOMATO G1");
        $display(" CONTROL UNIT TESTBENCH");
        $display("================================");

        opcode = OP_NOP;
        check("NOP", 0,0,0,0,0,0,0,0,ALU_ADD,0);

        opcode = OP_ADD;
        check("ADD", 1,0,0,0,0,0,0,1,ALU_ADD,0);

        opcode = OP_SUB;
        check("SUB", 1,0,0,0,0,0,0,1,ALU_SUB,0);

        opcode = OP_MUL;
        check("MUL", 1,0,0,0,0,0,0,1,ALU_MUL,0);

        opcode = OP_ADDI;
        check("ADDI", 1,1,0,0,0,0,0,1,ALU_ADD,0);

        opcode = OP_LDW;
        check("LDW", 1,1,1,0,1,0,0,1,ALU_ADD,0);

        opcode = OP_STW;
        check("STW", 0,1,0,1,0,0,0,1,ALU_ADD,0);

        opcode = OP_BEQ;
        check("BEQ", 0,0,0,0,0,1,0,1,ALU_SUB,0);

        opcode = OP_BNE;
        check("BNE", 0,0,0,0,0,1,0,1,ALU_SUB,0);

        opcode = OP_HALT;
        check("HALT", 0,0,0,0,0,0,0,0,ALU_ADD,1);

        $display("================================");
        $display("PASSED: %0d", passed);
        $display("FAILED: %0d", failed);
        $display("================================");

        if (failed != 0)
            $fatal(1, "CONTROL UNIT TESTS FAILED!");

        $display("ALL CONTROL UNIT TESTS PASSED!");

        $finish;
    end

endmodule
