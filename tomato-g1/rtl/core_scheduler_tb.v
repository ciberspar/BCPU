
`timescale 1ns/1ps

module core_scheduler_tb;

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

    task complete_transaction;
        input expected_core;
        input [31:0] expected_address;
        input [31:0] expected_data;
        input expected_write;
        input [31:0] returned_data;

        begin
            wait (mem_read || mem_write);
            #1;

            if (busy &&
                active_core == expected_core &&
                mem_address == expected_address &&
                mem_write_data == expected_data &&
                mem_write == expected_write &&
                mem_read == !expected_write) begin
                $display("PASS: Correct bus owner and transaction");
                passed = passed + 1;
            end else begin
                $display("FAIL: Incorrect bus transaction");
                failed = failed + 1;
            end

            repeat (2) @(negedge clk);

            mem_read_data = returned_data;
            mem_ready = 1;

            @(negedge clk);
            #1;

            if (expected_core == 1'b0) begin
                if (p_mem_ready && !e_mem_ready &&
                    p_mem_read_data == returned_data) begin
                    $display("PASS: P-Core receives memory response");
                    passed = passed + 1;
                end else begin
                    $display("FAIL: P-Core response routing");
                    failed = failed + 1;
                end
            end else begin
                if (e_mem_ready && !p_mem_ready &&
                    e_mem_read_data == returned_data) begin
                    $display("PASS: E-Core receives memory response");
                    passed = passed + 1;
                end else begin
                    $display("FAIL: E-Core response routing");
                    failed = failed + 1;
                end
            end

            mem_ready = 0;
        end
    endtask

    initial begin
        $display("================================");
        $display(" BCPU TOMATO CORE SCHEDULER TEST");
        $display("================================");

        repeat (3) @(negedge clk);
        reset = 0;

        // Both cores request memory simultaneously.
        p_mem_read = 1;
        p_mem_address = 32'h00001000;

        e_mem_write = 1;
        e_mem_address = 32'h00002000;
        e_mem_write_data = 32'h12345678;

        // P-Core should receive the first grant.
        complete_transaction(
            1'b0,
            32'h00001000,
            32'h00000000,
            1'b0,
            32'hAABBCCDD
        );

        p_mem_read = 0;

        // E-Core should receive the next grant.
        complete_transaction(
            1'b1,
            32'h00002000,
            32'h12345678,
            1'b1,
            32'h00000000
        );

        e_mem_write = 0;

        repeat (3) @(negedge clk);

        if (!busy && !mem_read && !mem_write) begin
            $display("PASS: Scheduler returns to idle");
            passed = passed + 1;
        end else begin
            $display("FAIL: Scheduler did not return to idle");
            failed = failed + 1;
        end

        $display("--------------------------------");
        $display("PASSED: %0d", passed);
        $display("FAILED: %0d", failed);

        if (failed == 0)
            $display("ALL CORE SCHEDULER TESTS PASSED!");
        else
            $display("CORE SCHEDULER TESTS FAILED!");

        $finish;
    end

    initial begin
        #2000;
        $display("ERROR: TEST TIMEOUT");
        $finish;
    end

endmodule
