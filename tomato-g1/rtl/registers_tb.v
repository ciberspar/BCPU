`timescale 1ns/1ps

module registers_tb;

    reg clk;
    reg reset;
    reg write_enable;

    reg [3:0] read_addr_a;
    reg [3:0] read_addr_b;
    reg [3:0] write_addr;

    reg [31:0] write_data;

    wire [31:0] read_data_a;
    wire [31:0] read_data_b;

    integer passed;
    integer failed;

    tomato_registers dut (
        .clk(clk),
        .reset(reset),
        .write_enable(write_enable),
        .read_addr_a(read_addr_a),
        .read_addr_b(read_addr_b),
        .write_addr(write_addr),
        .write_data(write_data),
        .read_data_a(read_data_a),
        .read_data_b(read_data_b)
    );

    always #5 clk = ~clk;

    task check;
        input [127:0] test_name;
        input [31:0] actual;
        input [31:0] expected;

        begin
            if (actual === expected) begin
                $display("PASS: %0s", test_name);
                passed = passed + 1;
            end
            else begin
                $display("FAIL: %0s", test_name);
                $display("Expected: %h", expected);
                $display("Got:      %h", actual);
                failed = failed + 1;
            end
        end
    endtask

    task write_register;
        input [3:0] address;
        input [31:0] data;

        begin
            @(negedge clk);
            write_enable = 1'b1;
            write_addr = address;
            write_data = data;

            @(posedge clk);
            #1;

            write_enable = 1'b0;
        end
    endtask

    initial begin
        clk = 0;
        reset = 1;
        write_enable = 0;

        read_addr_a = 0;
        read_addr_b = 0;
        write_addr = 0;
        write_data = 0;

        passed = 0;
        failed = 0;

        $display("================================");
        $display(" BCPU TOMATO G1");
        $display(" REGISTERS TESTBENCH");
        $display("================================");

        #12;
        reset = 0;

        // Test R0
        read_addr_a = 0;
        #1;
        check("R0 ALWAYS ZERO", read_data_a, 32'd0);

        // Test writing R1
        write_register(4'd1, 32'h12345678);
        read_addr_a = 1;
        #1;
        check("WRITE R1", read_data_a, 32'h12345678);

        // Test writing R2
        write_register(4'd2, 32'hABCDEF01);
        read_addr_a = 2;
        #1;
        check("WRITE R2", read_data_a, 32'hABCDEF01);

        // Test second read port
        read_addr_a = 1;
        read_addr_b = 2;
        #1;
        check("READ PORT A", read_data_a, 32'h12345678);
        check("READ PORT B", read_data_b, 32'hABCDEF01);

        // Test that R0 cannot be modified
        write_register(4'd0, 32'hFFFFFFFF);
        read_addr_a = 0;
        #1;
        check("R0 CANNOT BE MODIFIED", read_data_a, 32'd0);

        // Test asynchronous reset
        reset = 1;
        #1;

        read_addr_a = 1;
        read_addr_b = 2;
        #1;

        check("RESET R1", read_data_a, 32'd0);
        check("RESET R2", read_data_b, 32'd0);

        reset = 0;

        $display("================================");
        $display("PASSED: %0d", passed);
        $display("FAILED: %0d", failed);
        $display("================================");

        if (failed != 0)
            $fatal(1, "REGISTERS TESTS FAILED!");

        $display("ALL REGISTERS TESTS PASSED!");

        $finish;
    end

endmodule