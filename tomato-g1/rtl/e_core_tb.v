
`timescale 1ns/1ps

module e_core_tb;

    reg clk;
    reg reset;

    wire mem_read;
    wire mem_write;
    wire [31:0] mem_address;
    wire [31:0] mem_write_data;

    reg [31:0] mem_read_data;
    reg mem_ready;

    wire halted;
    wire [31:0] debug_pc;

    reg [31:0] memory [0:255];

    integer i;
    integer timeout;

    localparam OP_ADDI = 6'd12;
    localparam OP_MUL  = 6'd3;
    localparam OP_HALT = 6'd31;

    tomato_e_core dut (
        .clk(clk),
        .reset(reset),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_address(mem_address),
        .mem_write_data(mem_write_data),
        .mem_read_data(mem_read_data),
        .mem_ready(mem_ready),
        .halted(halted),
        .debug_pc(debug_pc)
    );

    // Clock
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // Immediate instruction encoder
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

    // Register instruction encoder
    function [31:0] encode_r;
        input [5:0] opcode;
        input [3:0] rd;
        input [3:0] ra;
        input [3:0] rb;
        begin
            encode_r = {
                opcode,
                rd,
                ra,
                rb,
                14'b0
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

            if (mem_read) begin
                mem_read_data <= memory[mem_address[9:2]];
                mem_ready <= 1'b1;
            end

            if (mem_write) begin
                memory[mem_address[9:2]] <= mem_write_data;
                mem_ready <= 1'b1;
            end
        end
    end

    // Main tests
    initial begin

        reset = 1'b1;
        mem_read_data = 32'b0;
        mem_ready = 1'b0;

        for (i = 0; i < 256; i = i + 1)
            memory[i] = 32'b0;

        // Program

        // R1 = 5
        memory[0] = encode_i(
            OP_ADDI, 4'd1, 4'd0, 18'd5
        );

        // R2 = 12
        memory[1] = encode_i(
            OP_ADDI, 4'd2, 4'd0, 18'd12
        );

        // R3 = R1 * R2
        memory[2] = encode_r(
            OP_MUL, 4'd3, 4'd1, 4'd2
        );

        // HALT
        memory[3] = {
            OP_HALT,
            26'b0
        };

        #20;
        @(negedge clk);
        reset = 1'b0;

        $display("================================");
        $display(" BCPU TOMATO G1");
        $display(" E-CORE TESTBENCH");
        $display("================================");

        timeout = 0;

        while (!halted && timeout < 300) begin
            @(negedge clk);
            timeout = timeout + 1;
        end

        #1;

        // Test ADDI
        if (dut.registers.registers[1] !== 32'd5) begin
            $display("FAIL: ADDI R1");
            $finish;
        end

        // Test second ADDI
        if (dut.registers.registers[2] !== 32'd12) begin
            $display("FAIL: ADDI R2");
            $finish;
        end

        // Test iterative multiplication
        if (dut.registers.registers[3] !== 32'd60) begin
            $display("FAIL: MULTIPLICATION");
            $display("Expected: 60");
            $display("Received: %d",
                dut.registers.registers[3]);
            $finish;
        end

        // Test R0
        if (dut.registers.registers[0] !== 32'd0) begin
            $display("FAIL: R0");
            $finish;
        end

        // Test HALT
        if (!halted) begin
            $display("FAIL: HALT");
            $finish;
        end

        $display("PASS: ADDI R1");
        $display("PASS: ADDI R2");
        $display("PASS: ITERATIVE MUL");
        $display("PASS: R0");
        $display("PASS: HALT");

        $display("--------------------------------");
        $display("PASSED: 5");
        $display("FAILED: 0");
        $display("--------------------------------");
        $display("ALL E-CORE TESTS PASSED!");

        $finish;

    end

endmodule
