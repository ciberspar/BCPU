
`timescale 1ns/1ps

module core_scheduler_contention_tb;

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
    integer timeout_count;

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

    task run_transaction;
        input expected_core;
        input expected_write;
        input [31:0] expected_address;
        input [31:0] expected_write_data;
        input [31:0] response_data;

        reg found;

        begin
            found = 0;
            timeout_count = 0;

            while (!found && timeout_count < 30) begin
                @(negedge clk);
                #1;

                if (mem_read || mem_write)
                    found = 1;

                timeout_count = timeout_count + 1;
            end

            check(found, "Transaction appears on memory bus");

            if (found) begin
                check(busy, "Scheduler reports busy");

                check(
                    active_core == expected_core,
                    "Correct core owns the bus"
                );

                check(
                    mem_address == expected_address,
                    "Correct transaction address"
                );

                check(
                    mem_write == expected_write &&
                    mem_read == !expected_write,
                    "Correct read/write operation"
                );

                if (expected_write) begin
                    check(
                        mem_write_data == expected_write_data,
                        "Correct write data"
                    );
                end

                mem_read_data = response_data;
                mem_ready = 1;

                @(negedge clk);
                #1;

                if (expected_core == 1'b0) begin
                    check(
                        p_mem_ready && !e_mem_ready,
                        "Response routed only to P-Core"
                    );

                    check(
                        p_mem_read_data == response_data,
                        "P-Core receives correct response data"
                    );
                end else begin
                    check(
                        e_mem_ready && !p_mem_ready,
                        "Response routed only to E-Core"
                    );

                    check(
                        e_mem_read_data == response_data,
                        "E-Core receives correct response data"
                    );
                end

                mem_ready = 0;
            end
        end
    endtask

    initial begin
        $display("========================================");
        $display(" BCPU TOMATO G1 CONTENTION TEST");
        $display("========================================");

        repeat (3) @(negedge clk);
        reset = 0;

        // First, give the bus to P-Core.
        @(negedge clk);

        p_mem_read = 1;
        p_mem_address = 32'h00001000;

        run_transaction(
            1'b0,
            1'b0,
            32'h00001000,
            32'h00000000,
            32'h11112222
        );

        p_mem_read = 0;

        // Now both cores request memory simultaneously.
        // Since P-Core had the previous grant,
        // E-Core must receive the next grant.
        @(negedge clk);

        p_mem_read = 1;
        p_mem_address = 32'h00003000;

        e_mem_write = 1;
        e_mem_address = 32'h00002000;
        e_mem_write_data = 32'hAABBCCDD;

        // E-Core must be served first.
        run_transaction(
            1'b1,
            1'b1,
            32'h00002000,
            32'hAABBCCDD,
            32'h33334444
        );

        e_mem_write = 0;

        // P-Core request must still be waiting.
        run_transaction(
            1'b0,
            1'b0,
            32'h00003000,
            32'h00000000,
            32'h55556666
        );

        p_mem_read = 0;

        repeat (3) @(negedge clk);
        #1;

        check(!busy, "Scheduler returns to idle");

        check(
            !mem_read && !mem_write,
            "External memory bus becomes inactive"
        );

        check(
            !p_mem_ready && !e_mem_ready,
            "No response signal remains active"
        );

        $display("----------------------------------------");
        $display("PASSED: %0d", passed);
        $display("FAILED: %0d", failed);

        if (failed == 0)
            $display("ALL CONTENTION TESTS PASSED!");
        else
            $display("CONTENTION TESTS FAILED!");

        $finish;
    end

    initial begin
        #5000;
        $display("ERROR: CONTENTION TEST TIMEOUT");
        $display("FAILED: %0d", failed + 1);
        $finish;
    end

endmodule
