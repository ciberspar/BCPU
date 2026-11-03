
`timescale 1ns/1ps

module core_scheduler_fairness_tb;

    reg clk = 0;
    reg reset = 1;

    reg p_mem_read = 0;
    reg p_mem_write = 0;
    reg [31:0] p_mem_address = 0;
    reg [31:0] p_mem_write_data = 0;
    wire [31:0] p_mem_read_data;
    wire p_mem_ready;

    reg e_mem_read = 0;
    reg e_mem_write = 0;
    reg [31:0] e_mem_address = 0;
    reg [31:0] e_mem_write_data = 0;
    wire [31:0] e_mem_read_data;
    wire e_mem_ready;

    wire mem_read;
    wire mem_write;
    wire [31:0] mem_address;
    wire [31:0] mem_write_data;

    reg [31:0] mem_read_data = 0;
    reg mem_ready = 0;

    wire busy;
    wire active_core;

    integer passed = 0;
    integer failed = 0;
    integer i;

    always #5 clk = ~clk;

    tomato_core_scheduler dut (
        .clk(clk),
        .reset(reset),

        .p_mem_read(p_mem_read),
        .p_mem_write(p_mem_write),
        .p_mem_address(p_mem_address),
        .p_mem_write_data(p_mem_write_data),
        .p_mem_read_data(p_mem_read_data),
        .p_mem_ready(p_mem_ready),

        .e_mem_read(e_mem_read),
        .e_mem_write(e_mem_write),
        .e_mem_address(e_mem_address),
        .e_mem_write_data(e_mem_write_data),
        .e_mem_read_data(e_mem_read_data),
        .e_mem_ready(e_mem_ready),

        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_address(mem_address),
        .mem_write_data(mem_write_data),
        .mem_read_data(mem_read_data),
        .mem_ready(mem_ready),

        .busy(busy),
        .active_core(active_core)
    );

    task check;
        input condition;
        input [8*100-1:0] message;
        begin
            if (condition) begin
                $display("PASS: %0s", message);
                passed = passed + 1;
            end else begin
                $display("FAIL: %0s", message);
                failed = failed + 1;
            end
        end
    endtask

    task verify_transaction;
        input expected_core;
        input [31:0] expected_address;
        input [31:0] response_data;

        integer timeout_count;
        reg found;

        begin
            timeout_count = 0;
            found = 0;

            while (!found && timeout_count < 30) begin
                @(negedge clk);
                #1;

                if (mem_read || mem_write)
                    found = 1;

                timeout_count = timeout_count + 1;
            end

            check(found, "Memory transaction appears");

            if (found) begin
                check(busy, "Scheduler is busy");

                check(active_core == expected_core,
                      "Correct core receives its turn");

                check(mem_read && !mem_write,
                      "Transaction is a memory read");

                check(mem_address == expected_address,
                      "Correct core memory address");

                mem_read_data = response_data;
                mem_ready = 1;

                @(negedge clk);
                #1;

                if (expected_core == 1'b0) begin
                    check(p_mem_ready && !e_mem_ready,
                          "Response routed only to P-Core");

                    check(p_mem_read_data == response_data,
                          "P-Core receives correct data");
                end else begin
                    check(e_mem_ready && !p_mem_ready,
                          "Response routed only to E-Core");

                    check(e_mem_read_data == response_data,
                          "E-Core receives correct data");
                end

                mem_ready = 0;
            end
        end
    endtask

    initial begin
        $display("========================================");
        $display(" BCPU TOMATO G1 FAIRNESS TEST");
        $display("========================================");

        repeat (3) @(negedge clk);
        reset = 0;

        // Both cores continuously request memory.
        @(negedge clk);

        p_mem_read = 1;
        p_mem_address = 32'h00001000;

        e_mem_read = 1;
        e_mem_address = 32'h00002000;

        // Expected round-robin sequence:
        // P, E, P, E, P, E.

        for (i = 0; i < 6; i = i + 1) begin
            if ((i % 2) == 0) begin
                verify_transaction(
                    1'b0,
                    32'h00001000,
                    32'hA0000000 + i
                );
            end else begin
                verify_transaction(
                    1'b1,
                    32'h00002000,
                    32'hB0000000 + i
                );
            end
        end

        $display("----------------------------------------");
        $display("ROUND-ROBIN TURNS CHECKED: 6");
        $display("PASSED: %0d", passed);
        $display("FAILED: %0d", failed);

        if (failed == 0)
            $display("ALL FAIRNESS TESTS PASSED!");
        else
            $display("FAIRNESS TESTS FAILED!");

        $finish;
    end

    initial begin
        #5000;
        $display("ERROR: FAIRNESS TEST TIMEOUT");
        $fatal(1, "Fairness test timed out");
    end

endmodule
