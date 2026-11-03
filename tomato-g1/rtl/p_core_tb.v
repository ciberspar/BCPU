
`timescale 1ns/1ps

module p_core_tb;

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

    // Simulated RAM
    reg [31:0] memory [0:255];

    integer i;
    integer timeout;

    localparam OP_ADDI = 6'd12;
    localparam OP_LDW  = 6'd17;
    localparam OP_STW  = 6'd18;
    localparam OP_HALT = 6'd31;

    // Processor
    tomato_p_core dut (
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

    // Clock generator
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // I-format instruction encoder
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

    // Memory model
    // One-cycle response to each request
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

    // Main test
    initial begin

        reset = 1'b1;
        mem_read_data = 32'b0;
        mem_ready = 1'b0;

        // Initialize RAM
        for (i = 0; i < 256; i = i + 1)
            memory[i] = 32'b0;

        // Program

        // 0: R1 = 5
        memory[0] = encode_i(
            OP_ADDI, 4'd1, 4'd0, 18'd5
        );

        // 1: R2 = 12
        memory[1] = encode_i(
            OP_ADDI, 4'd2, 4'd0, 18'd12
        );

        // 2: Memory[64] = R2
        memory[2] = encode_i(
            OP_STW, 4'd2, 4'd0, 18'd64
        );

        // 3: R3 = Memory[64]
        memory[3] = encode_i(
            OP_LDW, 4'd3, 4'd0, 18'd64
        );

        // 4: HALT
        memory[4] = {
            OP_HALT,
            26'b0
        };

        // Release reset
        #20;
        @(negedge clk);
        reset = 1'b0;

        $display("================================");
        $display(" BCPU TOMATO G1");
        $display(" P-CORE TESTBENCH");
        $display("================================");

        // Wait for processor to halt
        timeout = 0;

        while (!halted && timeout < 200) begin
            @(negedge clk);
            timeout = timeout + 1;
        end

        // Allow final signals to settle
        #1;

        // Test HALT
        if (!halted) begin
            $display("FAIL: HALT");
            $finish;
        end

        // Test R1
        if (dut.registers.registers[1] !== 32'd5) begin
            $display("FAIL: R1");
            $finish;
        end

        // Test R2
        if (dut.registers.registers[2] !== 32'd12) begin
            $display("FAIL: R2");
            $finish;
        end

        // Test STW
        if (memory[16] !== 32'd12) begin
            $display("FAIL: STW");
            $finish;
        end

        // Test LDW
        if (dut.registers.registers[3] !== 32'd12) begin
            $display("FAIL: LDW");
            $finish;
        end

        // Test R0
        if (dut.registers.registers[0] !== 32'd0) begin
            $display("FAIL: R0");
            $finish;
        end

        // All tests passed
        $display("PASS: ADDI R1");
        $display("PASS: ADDI R2");
        $display("PASS: STW");
        $display("PASS: LDW");
        $display("PASS: HALT");
        $display("PASS: R0");

        $display("================================");
        $display("ALL P-CORE TESTS PASSED!");
        $display("================================");

        $finish;

    end

endmodule
