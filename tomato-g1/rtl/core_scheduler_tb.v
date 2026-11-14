
`timescale 1ns/1ps

module core_scheduler_tb;

    reg clk = 0;
    reg reset = 1;

    // P-Core
    reg p_mem_read = 0;
    reg p_mem_execute = 0;
    reg p_mem_write = 0;
    reg [31:0] p_mem_address = 0;
    reg [31:0] p_mem_write_data = 0;
    wire [31:0] p_mem_read_data;
    wire p_mem_ready;

    // E-Core
    reg e_mem_read = 0;
    reg e_mem_execute = 0;
    reg e_mem_write = 0;
    reg [31:0] e_mem_address = 0;
    reg [31:0] e_mem_write_data = 0;
    wire [31:0] e_mem_read_data;
    wire e_mem_ready;

    // External memory bus
    wire mem_read;
    wire mem_execute;
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
        .p_mem_execute(p_mem_execute),
        .p_mem_write(p_mem_write),
        .p_mem_address(p_mem_address),
        .p_mem_write_data(p_mem_write_data),
        .p_mem_read_data(p_mem_read_data),
        .p_mem_ready(p_mem_ready),

        .e_mem_read(e_mem_read),
        .e_mem_execute(e_mem_execute),
        .e_mem_write(e_mem_write),
        .e_mem_address(e_mem_address),
        .e_mem_write_data(e_mem_write_data),
        .e_mem_read_data(e_mem_read_data),
        .e_mem_ready(e_mem_ready),

        .mem_read(mem_read),
        .mem_execute(mem_execute),
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

    task complete_transaction;
        input expected_core;
        input [31:0] expected_address;
        input [31:0] expected_data;
        input expected_read;
        input expected_execute;
        input expected_write;
        input [31:0] returned_data;

        begin
            wait (mem_read || mem_write);
            #1;

            check(
                busy &&
                active_core == expected_core,
                "CORRECT TRANSACTION OWNER"
            );

            check(
                mem_address == expected_address,
                "CORRECT MEMORY ADDRESS"
            );

            check(
                mem_read == expected_read &&
                mem_write == expected_write,
                "CORRECT READ/WRITE CONTROL"
            );

            check(
                mem_execute == expected_execute,
                "EXECUTE SIGNAL ROUTING"
            );

            if (expected_write) begin
                check(
                    mem_write_data == expected_data,
                    "CORRECT WRITE DATA"
                );
            end

            repeat (2) @(negedge clk);

            mem_read_data = returned_data;
            mem_ready = 1'b1;

            @(negedge clk);
            #1;

            if (expected_core == 1'b0) begin
                check(
                    p_mem_ready && !e_mem_ready,
                    "RESPONSE ROUTED TO P-CORE"
                );

                check(
                    p_mem_read_data == returned_data,
                    "P-CORE RECEIVES CORRECT DATA"
                );
            end
            else begin
                check(
                    e_mem_ready && !p_mem_ready,
                    "RESPONSE ROUTED TO E-CORE"
                );

                check(
                    e_mem_read_data == returned_data,
                    "E-CORE RECEIVES CORRECT DATA"
                );
            end

            mem_ready = 1'b0;
        end
    endtask

    initial begin
        $display("================================");
        $display(" BCPU TOMATO G1");
        $display(" CORE SCHEDULER TEST");
        $display("================================");

        repeat (3) @(negedge clk);
        reset = 1'b0;

        // TEST 1:
        // Both cores request memory simultaneously.
        // P-Core requests an instruction fetch.

        p_mem_read = 1'b1;
        p_mem_execute = 1'b1;
        p_mem_address = 32'h00001000;

        // E-Core requests a write.
        e_mem_write = 1'b1;
        e_mem_execute = 1'b0;
        e_mem_address = 32'h00002000;
        e_mem_write_data = 32'h12345678;

        // P-Core should receive the first grant.
        complete_transaction(
            1'b0,
            32'h00001000,
            32'h00000000,
            1'b1,
            1'b1,
            1'b0,
            32'hAABBCCDD
        );

        p_mem_read = 1'b0;
        p_mem_execute = 1'b0;

        // TEST 2:
        // E-Core should receive the pending write.

        complete_transaction(
            1'b1,
            32'h00002000,
            32'h12345678,
            1'b0,
            1'b0,
            1'b1,
            32'h00000000
        );

        e_mem_write = 1'b0;

        // TEST 3:
        // P-Core performs a normal data read.
        // Execute must remain inactive.

        p_mem_read = 1'b1;
        p_mem_execute = 1'b0;
        p_mem_address = 32'h00003000;

        complete_transaction(
            1'b0,
            32'h00003000,
            32'h00000000,
            1'b1,
            1'b0,
            1'b0,
            32'hCAFEBABE
        );

        p_mem_read = 1'b0;

        repeat (3) @(negedge clk);

        check(
            !busy && !mem_read && !mem_write &&
            !mem_execute,
            "SCHEDULER RETURNS TO IDLE"
        );

        $display("--------------------------------");
        $display("PASSED: %0d", passed);
        $display("FAILED: %0d", failed);
        $display("--------------------------------");

        if (failed == 0) begin
            $display("ALL CORE SCHEDULER TESTS PASSED!");
            $finish;
        end
        else begin
            $display("CORE SCHEDULER TESTS FAILED!");
            $fatal(1, "Scheduler verification failed");
        end
    end

    initial begin
        #2000;
        $display("ERROR: TEST TIMEOUT");
        $fatal(1, "Scheduler test timed out");
    end

endmodule
