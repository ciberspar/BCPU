`timescale 1ns/1ps

module alu_tb;

    reg [31:0] a;
    reg [31:0] b;
    reg [3:0] operation;

    wire [31:0] result;
    wire zero;

    integer passed;
    integer failed;

    localparam OP_ADD = 4'd0;
    localparam OP_SUB = 4'd1;
    localparam OP_AND = 4'd2;
    localparam OP_OR  = 4'd3;
    localparam OP_XOR = 4'd4;
    localparam OP_NOT = 4'd5;
    localparam OP_SHL = 4'd6;
    localparam OP_SHR = 4'd7;
    localparam OP_SAR = 4'd8;
    localparam OP_MUL = 4'd9;

    tomato_alu dut (
        .a(a),
        .b(b),
        .operation(operation),
        .result(result),
        .zero(zero)
    );

    task check;
        input [127:0] test_name;
        input [3:0] op;
        input [31:0] input_a;
        input [31:0] input_b;
        input [31:0] expected;

        begin
            operation = op;
            a = input_a;
            b = input_b;

            #5;

            if (result === expected) begin
                $display("PASS: %0s", test_name);
                passed = passed + 1;
            end
            else begin
                $display("FAIL: %0s", test_name);
                $display("Expected: %h", expected);
                $display("Got:      %h", result);
                failed = failed + 1;
            end
        end
    endtask

    initial begin
        passed = 0;
        failed = 0;

        a = 0;
        b = 0;
        operation = 0;

        $display("================================");
        $display(" BCPU TOMATO G1");
        $display(" ALU TESTBENCH");
        $display("================================");

        check("ADD", OP_ADD, 32'd10, 32'd7, 32'd17);
        check("SUB", OP_SUB, 32'd10, 32'd7, 32'd3);
        check("AND", OP_AND, 32'hF0F0, 32'h0FF0, 32'h00F0);
        check("OR", OP_OR, 32'hF000, 32'h00F0, 32'hF0F0);
        check("XOR", OP_XOR, 32'hAAAA, 32'hFFFF, 32'h5555);
        check("NOT", OP_NOT, 32'h0000000F, 32'd0, 32'hFFFFFFF0);
        check("SHL", OP_SHL, 32'd1, 32'd4, 32'd16);
        check("SHR", OP_SHR, 32'h00000080, 32'd2, 32'h00000020);
        check("SAR", OP_SAR, 32'h80000000, 32'd4, 32'hF8000000);
        check("MUL", OP_MUL, 32'd12, 32'd7, 32'd84);

        operation = OP_ADD;
        a = 32'd5;
        b = 32'hFFFFFFFB;
        #5;

        if (zero === 1'b1) begin
            $display("PASS: ZERO FLAG");
            passed = passed + 1;
        end
        else begin
            $display("FAIL: ZERO FLAG");
            failed = failed + 1;
        end

        $display("================================");
        $display("PASSED: %0d", passed);
        $display("FAILED: %0d", failed);
        $display("================================");

        if (failed != 0)
            $fatal(1, "ALU TESTS FAILED!");

        $display("ALL ALU TESTS PASSED!");
        $finish;
    end

endmodule