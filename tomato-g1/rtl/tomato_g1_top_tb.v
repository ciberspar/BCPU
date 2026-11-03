
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

    // Tomato G1 complete system
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

    initial begin
        $display("================================");
        $display(" BCPU TOMATO G1 SYSTEM TEST");
        $display("================================");

        // Initialize memory
        for (i = 0; i < 64; i = i + 1)
            memory[i] = 32'h00000000;

        // HALT instruction at address zero
        memory[0] = 32'h7C000000;

        // Reset system
        repeat (4) @(negedge clk);
        reset = 0;

        // Wait for both processors to halt
        cycles = 0;

        while ((!p_halted || !e_halted) && cycles < 100) begin
            @(negedge clk);
            #1;

            cycles = cycles + 1;

            if (mem_read && mem_write) begin
                $display("FAIL: Read and write active together");
                failed = failed + 1;
            end
        end

        // Check P-Core
        if (p_halted) begin
            $display("PASS: P-Core fetched HALT and stopped");
            passed = passed + 1;
        end
        else begin
            $display("FAIL: P-Core did not halt");
            failed = failed + 1;
        end

        // Check E-Core
        if (e_halted) begin
            $display("PASS: E-Core fetched HALT and stopped");
            passed = passed + 1;
        end
        else begin
            $display("FAIL: E-Core did not halt");
            failed = failed + 1;
        end

        // Check program counters
        if (p_debug_pc == 32'd4) begin
            $display("PASS: P-Core program counter");
            passed = passed + 1;
        end
        else begin
            $display("FAIL: P-Core PC = %h", p_debug_pc);
            failed = failed + 1;
        end

        if (e_debug_pc == 32'd4) begin
            $display("PASS: E-Core program counter");
            passed = passed + 1;
        end
        else begin
            $display("FAIL: E-Core PC = %h", e_debug_pc);
            failed = failed + 1;
        end

        $display("--------------------------------");
        $display("Cycles: %0d", cycles);
        $display("PASSED: %0d", passed);
        $display("FAILED: %0d", failed);

        if (failed == 0) begin
            $display("ALL TOMATO G1 SYSTEM TESTS PASSED!");
        end
        else begin
            $display("TOMATO G1 SYSTEM TESTS FAILED!");
        end

        $finish;
    end

    // Simulation timeout
    initial begin
        #5000;
        $display("ERROR: SYSTEM TEST TIMEOUT");
        $finish;
    end

endmodule
