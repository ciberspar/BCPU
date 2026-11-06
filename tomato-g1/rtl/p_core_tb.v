
`timescale 1ns/1ps

module p_core_tb;

    reg clk;
    reg reset;

    wire mem_read;
    wire mem_write;
    wire [31:0] mem_address;
    wire [31:0] mem_write_data;

    reg [31:0] mem_read_data;
    reg mem_ready;

    wire halted;
    wire faulted;
    wire [31:0] debug_pc;

    reg [31:0] memory [0:255];

    integer i;
    integer timeout;
    integer passed;
    integer failed;

    localparam OP_ADDI = 6'd12;
    localparam OP_LDW  = 6'd17;
    localparam OP_STW  = 6'd18;
    localparam OP_HALT = 6'd31;

    tomato_p_core dut (
        .clk(clk),
        .reset(reset),

        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_address(mem_address),
        .mem_write_data(mem_write_data),
        .mem_read_data(mem_read_data),
        .mem_ready(mem_ready),

        .halted(halted),
        .faulted(faulted),
        .debug_pc(debug_pc)
    );

    // Clock generator
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

    // Simulated memory
    always @(posedge clk) begin
        if (reset) begin
            mem_ready <= 1'b0;
        end
        else begin
            mem_ready <= 1'b0;

            if (mem_read && !mem_write) begin
                mem_read_data <= memory[mem_address[9:2]];
                mem_ready <= 1'b1;
            end

            if (mem_write && !mem_read) begin
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

        // Initialize RAM
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

        // Store R2 at address 128 (memory[32])
        memory[2] = encode_i(
            OP_STW, 4'd2, 4'd0, 18'd128
        );

        // Load address 128 into R3
        memory[3] = encode_i(
            OP_LDW, 4'd3, 4'd0, 18'd128
        );

        // HALT
        memory[4] = {
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
        $display(" P-CORE TESTBENCH");
        $display("================================");

        while (!halted && !faulted && timeout < 500) begin
            @(negedge clk);
            timeout = timeout + 1;
        end

        #1;

        // =================================
        // REGISTER TESTS
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
            dut.registers.registers[3] === 32'd12,
            "LDW R3"
        );

        check(
            dut.registers.registers[0] === 32'd0,
            "REGISTER R0"
        );

        // =================================
        // MEMORY TESTS
        // =================================

        check(
            memory[32] === 32'd12,
            "STW MEMORY WRITE"
        );

        // =================================
        // PROCESSOR STATUS
        // =================================

        check(
            halted === 1'b1,
            "HALT"
        );

        check(
            faulted === 1'b0,
            "NO EXECUTION FAULT"
        );

        check(
            debug_pc === 32'd20,
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

        if (failed == 0 && halted && !faulted) begin
            $display("ALL P-CORE TESTS PASSED!");
            $finish;
        end
        else begin
            $display("P-CORE TESTS FAILED!");
            $fatal(1, "P-Core verification failed");
        end
    end

    initial begin
        #10000;
        if (!halted && !faulted) begin
            $display("ERROR: P-CORE TIMEOUT");
            $fatal(1, "P-Core did not halt");
        end
    end

endmodule
