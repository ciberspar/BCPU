
`timescale 1ns/1ps

module tomato_g1_top_tb;

    reg clk = 0;
    reg reset = 1;

    wire mem_read;
    wire mem_write;
    wire [31:0] mem_address;
    wire [31:0] mem_write_data;

    reg [31:0] mem_read_data = 0;
    reg mem_ready = 0;

    wire p_halted;
    wire e_halted;
    wire p_faulted;
    wire e_faulted;

    wire [31:0] p_debug_pc;
    wire [31:0] e_debug_pc;

    wire scheduler_busy;
    wire scheduler_active_core;

    reg [31:0] memory [0:63];

    integer i;
    integer cycles;
    integer passed = 0;
    integer failed = 0;

    always #5 clk = ~clk;

    tomato_g1_top dut (
        .clk(clk),
        .reset(reset),

        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_address(mem_address),
        .mem_write_data(mem_write_data),
        .mem_read_data(mem_read_data),
        .mem_ready(mem_ready),

        .p_halted(p_halted),
        .e_halted(e_halted),
        .p_faulted(p_faulted),
        .e_faulted(e_faulted),

        .p_debug_pc(p_debug_pc),
        .e_debug_pc(e_debug_pc),

        .scheduler_busy(scheduler_busy),
        .scheduler_active_core(scheduler_active_core)
    );

    // Simple synchronous memory model
    always @(posedge clk) begin
        mem_ready <= 1'b0;

        if (mem_read && !mem_write) begin
            mem_read_data <= memory[mem_address[7:2]];
            mem_ready <= 1'b1;
        end
        else if (mem_write && !mem_read) begin
            memory[mem_address[7:2]] <= mem_write_data;
            mem_ready <= 1'b1;
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
        $display("================================");
        $display(" BCPU TOMATO G1 SYSTEM TEST");
        $display("================================");

        for (i = 0; i < 64; i = i + 1)
            memory[i] = 32'h00000000;

        // HALT instruction at address zero
        memory[0] = 32'h7C000000;

        repeat (4) @(negedge clk);
        reset = 0;

        cycles = 0;

        while ((!p_halted || !e_halted) &&
               (!p_faulted && !e_faulted) &&
               cycles < 100) begin

            @(negedge clk);
            #1;

            cycles = cycles + 1;

            if (mem_read && mem_write) begin
                $display("FAIL: Read and write active together");
                failed = failed + 1;
            end
        end

        // P-Core status
        check(p_halted, "P-Core fetched HALT");
        check(!p_faulted, "P-Core has no fault");

        // E-Core status
        check(e_halted, "E-Core fetched HALT");
        check(!e_faulted, "E-Core has no fault");

        // Program counters
        check(
            p_debug_pc == 32'd4,
            "P-Core program counter"
        );

        check(
            e_debug_pc == 32'd4,
            "E-Core program counter"
        );

        // Bus safety
        check(
            !(mem_read && mem_write),
            "Memory read/write are never active together"
        );

        // Scheduler status
        check(
            !scheduler_busy,
            "Scheduler is idle after both cores halt"
        );

        $display("--------------------------------");
        $display("Cycles: %0d", cycles);
        $display("PASSED: %0d", passed);
        $display("FAILED: %0d", failed);

        if (failed == 0) begin
            $display("ALL TOMATO G1 SYSTEM TESTS PASSED!");
            $finish;
        end
        else begin
            $display("TOMATO G1 SYSTEM TESTS FAILED!");
            $fatal(1, "System verification failed");
        end
    end

    initial begin
        #5000;
        if (failed == 0 &&
            (!p_halted || !e_halted)) begin
            $display("ERROR: SYSTEM TEST TIMEOUT");
            $fatal(1, "System test timed out");
        end
    end

endmodule
