
`timescale 1ns/1ps

module lettuce_mmu_tb;

    reg clk;
    reg reset;

    reg req_valid;
    reg [31:0] virtual_address;

    reg access_read;
    reg access_write;
    reg access_execute;

    reg map_enable;
    reg [31:0] virtual_base;
    reg [32:0] virtual_limit;
    reg [33:0] physical_base;

    reg permission_read;
    reg permission_write;
    reg permission_execute;

    wire resp_valid;
    wire [33:0] physical_address;
    wire fault;
    wire [2:0] fault_code;

    integer tests;
    integer failed;

    localparam FAULT_NONE       = 3'd0;
    localparam FAULT_UNMAPPED   = 3'd1;
    localparam FAULT_PERMISSION = 3'd2;
    localparam FAULT_OVERFLOW   = 3'd3;
    localparam FAULT_ACCESS     = 3'd4;

    lettuce_mmu dut (
        .clk(clk),
        .reset(reset),

        .req_valid(req_valid),
        .virtual_address(virtual_address),

        .access_read(access_read),
        .access_write(access_write),
        .access_execute(access_execute),

        .map_enable(map_enable),
        .virtual_base(virtual_base),
        .virtual_limit(virtual_limit),
        .physical_base(physical_base),

        .permission_read(permission_read),
        .permission_write(permission_write),
        .permission_execute(permission_execute),

        .resp_valid(resp_valid),
        .physical_address(physical_address),
        .fault(fault),
        .fault_code(fault_code)
    );

    initial begin
        clk = 0;
        reset = 0;

        req_valid = 0;
        virtual_address = 0;

        access_read = 0;
        access_write = 0;
        access_execute = 0;

        map_enable = 1;
        virtual_base = 32'h00001000;
        virtual_limit = 33'h00002000;
        physical_base = 34'h00010000;

        permission_read = 1;
        permission_write = 1;
        permission_execute = 1;

        tests = 0;
        failed = 0;

        $display("--------------------------------");
        $display("LETTUCE MMU TESTS");
        $display("--------------------------------");

        // Test 1: Valid read.
        req_valid = 1;
        virtual_address = 32'h00001020;
        access_read = 1;
        #10;

        check_result(
            "Valid read",
            1, 0, FAULT_NONE, 34'h00010020
        );

        // Test 2: Valid write.
        access_read = 0;
        access_write = 1;
        virtual_address = 32'h00001100;
        #10;

        check_result(
            "Valid write",
            1, 0, FAULT_NONE, 34'h00010100
        );

        // Test 3: Valid execute.
        access_write = 0;
        access_execute = 1;
        virtual_address = 32'h00001200;
        #10;

        check_result(
            "Valid execute",
            1, 0, FAULT_NONE, 34'h00010200
        );

        // Test 4: Address below mapping.
        access_execute = 0;
        access_read = 1;
        virtual_address = 32'h00000FFF;
        #10;

        check_result(
            "Address below mapping",
            1, 1, FAULT_UNMAPPED, 34'b0
        );

        // Test 5: Address at exclusive limit.
        virtual_address = 32'h00002000;
        #10;

        check_result(
            "Address at exclusive limit",
            1, 1, FAULT_UNMAPPED, 34'b0
        );

        // Test 6: Read permission denied.
        virtual_address = 32'h00001020;
        permission_read = 0;
        #10;

        check_result(
            "Read permission denied",
            1, 1, FAULT_PERMISSION, 34'b0
        );

        // Test 7: Write permission denied.
        permission_read = 1;
        access_read = 0;
        access_write = 1;
        permission_write = 0;
        #10;

        check_result(
            "Write permission denied",
            1, 1, FAULT_PERMISSION, 34'b0
        );

        // Test 8: Execute permission denied.
        access_write = 0;
        access_execute = 1;
        permission_write = 1;
        permission_execute = 0;
        #10;

        check_result(
            "Execute permission denied",
            1, 1, FAULT_PERMISSION, 34'b0
        );

        // Test 9: No access type selected.
        access_execute = 0;
        permission_execute = 1;
        #10;

        check_result(
            "No access type selected",
            1, 1, FAULT_ACCESS, 34'b0
        );

        // Test 10: Multiple access types selected.
        access_read = 1;
        access_execute = 1;
        #10;

        check_result(
            "Multiple access types",
            1, 1, FAULT_ACCESS, 34'b0
        );

        // Test 11: Mapping disabled.
        access_read = 1;
        access_execute = 0;
        map_enable = 0;
        #10;

        check_result(
            "Mapping disabled",
            1, 1, FAULT_UNMAPPED, 34'b0
        );

        // Test 12: Physical address overflow.
        map_enable = 1;
        physical_base = 34'h3FFFFFFF0;
        virtual_address = 32'h00001020;
        #10;

        check_result(
            "Physical address overflow",
            1, 1, FAULT_OVERFLOW, 34'b0
        );

        // Test 13: Request idle.
        req_valid = 0;
        #10;

        check_result(
            "Request idle",
            0, 0, FAULT_NONE, 34'b0
        );

        // Test 14: Last valid address in mapping.
        req_valid = 1;
        physical_base = 34'h00010000;
        virtual_address = 32'h00001FFF;
        access_read = 1;
        access_execute = 0;
        #10;

        check_result(
            "Last address in mapping",
            1, 0, FAULT_NONE, 34'h00010FFF
        );

        $display("--------------------------------");
        $display("TESTS: %0d", tests);
        $display("FAILED: %0d", failed);

        if (failed == 0) begin
            $display("ALL LETTUCE MMU TESTS PASSED!");
        end
        else begin
            $display("LETTUCE MMU TESTS FAILED!");
        end

        $finish;
    end

    task check_result;
        input [255:0] test_name;
        input expected_valid;
        input expected_fault;
        input [2:0] expected_code;
        input [33:0] expected_address;

        begin
            tests = tests + 1;

            if (
                resp_valid !== expected_valid ||
                fault !== expected_fault ||
                fault_code !== expected_code ||
                physical_address !== expected_address
            ) begin
                failed = failed + 1;

                $display(
                    "FAIL: %0s | valid=%b fault=%b code=%d address=%h",
                    test_name,
                    resp_valid,
                    fault,
                    fault_code,
                    physical_address
                );
            end
            else begin
                $display("PASS: %0s", test_name);
            end
        end
    endtask

endmodule
