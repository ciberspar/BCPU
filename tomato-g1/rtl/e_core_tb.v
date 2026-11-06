
`timescale 1ns/1ps

module e_core_tb;

    reg clk;
    reg reset;

    wire mem_read;
    wire mem_write;
    wire [31:0] mem_address;
    wire [31:0] mem_write_data;

    reg [31:0] mem_read_data;
    reg mem_ready;

    wire halted;
    wire [31:0] debug_pc;

    reg [31:0] memory [0:255];

    integer i;
    integer timeout;
    integer passed;
    integer failed;

    localparam OP_MUL  = 6'd3;
    localparam OP_ADDI = 6'd12;
    localparam OP_LDW  = 6'd17;
    localparam OP_STW  = 6'd18;
    localparam OP_BEQ  = 6'd23;
    localparam OP_BNE  = 6'd24;
    localparam OP_BLT  = 6'd25;
    localparam OP_BGE  = 6'd26;
    localparam OP_HALT = 6'd31;

    tomato_e_core dut (
        .clk(clk),
        .reset(reset),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_address(mem_address),
        .mem_write_data(mem_write_data),
        .mem_read_data(mem_read_data),
        .mem_ready(mem_ready),
        .halted(halted),
        .debug_pc(debug_pc)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    function [31:0] encode_i;
        input [5:0] opcode;
        input [3:0] rd;
        input [3:0] ra;
        input [17:0] immediate;
        begin
            encode_i = {
                opcode,
                rd,
                ra,
                immediate
            };
        end
    endfunction

    function [31:0] encode_r;
        input [5:0] opcode;
        input [3:0] rd;
        input [3:0] ra;
        input [3:0] rb;
        begin
            encode_r = {
                opcode,
                rd,
                ra,
                rb,
                14'b0
            };
        end
    endfunction

    // Simulated memory
    always @(posedge clk) begin
        if (reset) begin
            mem_ready <= 1'b0;
        end
        else begin
            mem_ready <= 1'b0;

            if (mem_read) begin
                mem_read_data <= memory[mem_address[9:2]];
                mem_ready <= 1'b1;
            end

            if (mem_write) begin
                memory[mem_address[9:2]] <= mem_write_data;
                mem_ready <= 1'b1;
            end
        end
    end

    task check;
        input condition;
        input [255:0] test_name;
        begin
            if (condition === 1'b1) begin
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

        reset = 1'b1;
        mem_read_data = 32'b0;
        mem_ready = 1'b0;

        passed = 0;
        failed = 0;
        timeout = 0;

        for (i = 0; i < 256; i = i + 1)
            memory[i] = 32'b0;

        // =================================
        // PROGRAM
        // =================================

        // R1 = 5
        memory[0] = encode_i(
            OP_ADDI, 4'd1, 4'd0, 18'd5
        );

        // R2 = 12
        memory[1] = encode_i(
            OP_ADDI, 4'd2, 4'd0, 18'd12
        );

        // R3 = R1 * R2 = 60
        memory[2] = encode_r(
            OP_MUL, 4'd3, 4'd1, 4'd2
        );

        // Store R2 at address 128 (memory[32])
        memory[3] = encode_i(
            OP_STW, 4'd2, 4'd0, 18'd128
        );

        // Load address 128 into R4
        memory[4] = encode_i(
            OP_LDW, 4'd4, 4'd0, 18'd128
        );

        // BEQ R1, R1, +1
        memory[5] = encode_i(
            OP_BEQ, 4'd1, 4'd1, 18'd1
        );

        memory[6] = encode_i(
            OP_ADDI, 4'd5, 4'd0, 18'd99
        );

        // BNE R1, R2, +1
        memory[7] = encode_i(
            OP_BNE, 4'd1, 4'd2, 18'd1
        );

        memory[8] = encode_i(
            OP_ADDI, 4'd6, 4'd0, 18'd99
        );

        // BLT R1, R2, +1
        memory[9] = encode_i(
            OP_BLT, 4'd1, 4'd2, 18'd1
        );

        memory[10] = encode_i(
            OP_ADDI, 4'd7, 4'd0, 18'd99
        );

        // BGE R2, R1, +1
        memory[11] = encode_i(
            OP_BGE, 4'd2, 4'd1, 18'd1
        );

        memory[12] = encode_i(
            OP_ADDI, 4'd8, 4'd0, 18'd99
        );

        // BNE R1, R1, +1 (not taken)
        memory[13] = encode_i(
            OP_BNE, 4'd1, 4'd1, 18'd1
        );

        // R9 = 7
        memory[14] = encode_i(
            OP_ADDI, 4'd9, 4'd0, 18'd7
        );

        // BGE R1, R2, +1 (not taken)
        memory[15] = encode_i(
            OP_BGE, 4'd1, 4'd2, 18'd1
        );

        // R10 = 8
        memory[16] = encode_i(
            OP_ADDI, 4'd10, 4'd0, 18'd8
        );

        // HALT
        memory[17] = {
            OP_HALT,
            26'b0
        };

        // =================================
        // RESET RELEASE
        // =================================

        #20;
        @(negedge clk);
        reset = 1'b0;

        $display("================================");
        $display(" BCPU TOMATO G1");
        $display(" E-CORE EXTENDED TESTS");
        $display("================================");

        while (!halted && timeout < 1000) begin
            @(negedge clk);
            timeout = timeout + 1;
        end

        #1;

        // =================================
        // ARITHMETIC
        // =================================

        check(
            dut.registers.registers[1] === 32'd5,
            "ADDI R1"
        );

        check(
            dut.registers.registers[2] === 32'd12,
            "ADDI R2"
        );

        check(
            dut.registers.registers[3] === 32'd60,
            "ITERATIVE MULTIPLICATION"
        );

        // =================================
        // MEMORY
        // =================================

        check(
            memory[32] === 32'd12,
            "STW MEMORY WRITE"
        );

        check(
            dut.registers.registers[4] === 32'd12,
            "LDW MEMORY READ"
        );

        // =================================
        // BRANCHES
        // =================================

        check(
            dut.registers.registers[5] === 32'd0,
            "BEQ TAKEN"
        );

        check(
            dut.registers.registers[6] === 32'd0,
            "BNE TAKEN"
        );

        check(
            dut.registers.registers[7] === 32'd0,
            "BLT TAKEN"
        );

        check(
            dut.registers.registers[8] === 32'd0,
            "BGE TAKEN"
        );

        check(
            dut.registers.registers[9] === 32'd7,
            "BNE NOT TAKEN"
        );

        check(
            dut.registers.registers[10] === 32'd8,
            "BGE NOT TAKEN"
        );

        // =================================
        // PROCESSOR STATUS
        // =================================

        check(
            dut.registers.registers[0] === 32'd0,
            "REGISTER R0"
        );

        check(
            halted === 1'b1,
            "HALT"
        );

        check(
            debug_pc === 32'd72,
            "PROGRAM COUNTER"
        );

        // =================================
        // FINAL REPORT
        // =================================

        $display("--------------------------------");
        $display("PASSED: %0d", passed);
        $display("FAILED: %0d", failed);
        $display("CYCLES: %0d", timeout);
        $display("--------------------------------");

        if (failed == 0 && halted) begin
            $display("ALL E-CORE EXTENDED TESTS PASSED!");
            $finish;
        end
        else begin
            $display("E-CORE EXTENDED TESTS FAILED!");
            $fatal(1, "E-Core verification failed");
        end

    end

    initial begin
        #15000;
        if (!halted) begin
            $display("ERROR: E-CORE TIMEOUT");
            $fatal(1, "E-Core did not halt");
        end
    end

endmodule
