
`timescale 1ns/1ps

module memory_controller_tb;

    reg clk;
    reg reset;

    reg mem_read;
    reg mem_write;
    reg [31:0] mem_address;
    reg [31:0] mem_write_data;

    wire [31:0] mem_read_data;
    wire mem_ready;

    wire ram_read;
    wire ram_write;
    wire [31:0] ram_address;
    wire [31:0] ram_write_data;

    reg [31:0] ram_read_data;
    reg ram_ready;

    integer passed;
    integer failed;

    tomato_memory_controller dut (
        .clk(clk),
        .reset(reset),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_address(mem_address),
        .mem_write_data(mem_write_data),
        .mem_read_data(mem_read_data),
        .mem_ready(mem_ready),
        .ram_read(ram_read),
        .ram_write(ram_write),
        .ram_address(ram_address),
        .ram_write_data(ram_write_data),
        .ram_read_data(ram_read_data),
        .ram_ready(ram_ready)
    );

    always #5 clk = ~clk;

    task check;
        input condition;
        input [8*50-1:0] message;
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

    initial begin
        clk = 0;
        reset = 1;

        mem_read = 0;
        mem_write = 0;
        mem_address = 0;
        mem_write_data = 0;

        ram_read_data = 0;
        ram_ready = 0;

        passed = 0;
        failed = 0;

        // RESET
        repeat (2) @(posedge clk);
        #1;

        check(mem_ready == 0, "RESET MEM READY");
        check(ram_read == 0, "RESET RAM READ");
        check(ram_write == 0, "RESET RAM WRITE");
        check(mem_read_data == 0, "RESET READ DATA");

        @(negedge clk);
        reset = 0;

        // READ REQUEST
        mem_address = 32'h00001000;
        mem_read = 1;

        @(posedge clk);
        #1;

        check(ram_read == 1, "READ REQUEST");
        check(ram_address == 32'h00001000, "READ ADDRESS");
        check(ram_write == 0, "READ DOES NOT WRITE");

        @(negedge clk);
        mem_read = 0;

        // READ RESPONSE
        ram_read_data = 32'h12345678;
        ram_ready = 1;

        @(posedge clk);
        #1;

        check(mem_ready == 1, "READ COMPLETED");
        check(mem_read_data == 32'h12345678, "READ DATA");

        @(negedge clk);
        ram_ready = 0;

        // WRITE REQUEST
        mem_address = 32'h00002000;
        mem_write_data = 32'hAABBCCDD;
        mem_write = 1;

        @(posedge clk);
        #1;

        check(ram_write == 1, "WRITE REQUEST");
        check(ram_address == 32'h00002000, "WRITE ADDRESS");
        check(ram_write_data == 32'hAABBCCDD, "WRITE DATA");
        check(ram_read == 0, "WRITE DOES NOT READ");

        @(negedge clk);
        mem_write = 0;

        // WRITE RESPONSE
        ram_ready = 1;

        @(posedge clk);
        #1;

        check(mem_ready == 1, "WRITE COMPLETED");

        @(negedge clk);
        ram_ready = 0;

        // SIMULTANEOUS REQUEST PRIORITY
        mem_address = 32'h00003000;
        mem_read = 1;
        mem_write = 1;

        @(posedge clk);
        #1;

        check(ram_read == 1, "READ HAS PRIORITY");
        check(ram_write == 0, "WRITE WAITING");

        @(negedge clk);
        mem_read = 0;
        mem_write = 0;

        ram_ready = 1;
        ram_read_data = 32'hCAFEBABE;

        @(posedge clk);
        #1;

        check(mem_read_data == 32'hCAFEBABE, "PRIORITY READ DATA");

        @(negedge clk);
        ram_ready = 0;

        // RESULTS
        $display("--------------------------------");
        $display("PASSED: %0d", passed);
        $display("FAILED: %0d", failed);
        $display("--------------------------------");

        if (failed == 0)
            $display("ALL MEMORY CONTROLLER TESTS PASSED!");
        else
            $display("MEMORY CONTROLLER TESTS FAILED!");

        $finish;
    end

endmodule
