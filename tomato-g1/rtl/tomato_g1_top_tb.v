
`timescale 1ns/1ps

module tomato_g1_top_tb;

    reg clk = 0;
    reg reset = 1;

    wire mem_read;
    wire mem_execute;
    wire mem_write;
    wire [31:0] mem_address;
    wire [31:0] mem_write_data;

    reg [31:0] mem_read_data = 0;
    reg mem_ready = 0;

    wire p_halted;
    wire e_halted;
    wire p_faulted;
    wire e_faulted;

    wire [31:0] p_debug_pc;
    wire [31:0] e_debug_pc;

    wire scheduler_busy;
    wire scheduler_active_core;

    reg [31:0] memory [0:63];

    integer i;
    integer cycles;
    integer passed = 0;
    integer failed = 0;
    integer instruction_fetches = 0;
    integer data_reads = 0;

    // Detectar el inicio de cada transaccion
    reg previous_mem_read = 0;

    always #5 clk = ~clk;

    tomato_g1_top dut (
        .clk(clk),
        .reset(reset),

        .mem_read(mem_read),
        .mem_execute(mem_execute),
        .mem_write(mem_write),
        .mem_address(mem_address),
        .mem_write_data(mem_write_data),
        .mem_read_data(mem_read_data),
        .mem_ready(mem_ready),

        .p_halted(p_halted),
        .e_halted(e_halted),
        .p_faulted(p_faulted),
        .e_faulted(e_faulted),

        .p_debug_pc(p_debug_pc),
        .e_debug_pc(e_debug_pc),

        .scheduler_busy(scheduler_busy),
        .scheduler_active_core(scheduler_active_core)
    );

    // Memoria sincronica de prueba
    always @(posedge clk) begin
        mem_ready <= 1'b0;

        if (mem_read && !mem_write) begin
            mem_read_data <= memory[mem_address[7:2]];
            mem_ready <= 1'b1;
        end
        else if (mem_write && !mem_read) begin
            memory[mem_address[7:2]] <= mem_write_data;
            mem_ready <= 1'b1;
        end
    end

    // Contar una sola vez por transaccion
    always @(posedge clk) begin
        if (reset) begin
            instruction_fetches <= 0;
            data_reads <= 0;
            previous_mem_read <= 1'b0;
        end
        else begin
            if (mem_read && !previous_mem_read && !mem_write) begin
                if (mem_execute)
                    instruction_fetches <= instruction_fetches + 1;
                else
                    data_reads <= data_reads + 1;
            end

            previous_mem_read <= mem_read;
        end
    end

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

    initial begin
        $display("================================");
        $display(" BCPU TOMATO G1 SYSTEM TEST");
        $display("================================");

        for (i = 0; i < 64; i = i + 1)
            memory[i] = 32'h00000000;

        // HALT para ambos nucleos
        memory[0] = 32'h7C000000;

        repeat (4) @(negedge clk);
        reset = 0;

        cycles = 0;

        while ((!p_halted || !e_halted) &&
               (!p_faulted && !e_faulted) &&
               cycles < 100) begin

            @(negedge clk);
            #1;

            cycles = cycles + 1;

            if (mem_read && mem_write) begin
                $display("FAIL: Read and write active together");
                failed = failed + 1;
            end
        end

        // Estado P-Core
        check(p_halted, "P-CORE FETCHED HALT");
        check(!p_faulted, "P-CORE HAS NO FAULT");

        // Estado E-Core
        check(e_halted, "E-CORE FETCHED HALT");
        check(!e_faulted, "E-CORE HAS NO FAULT");

        // Contadores de programa
        check(
            p_debug_pc == 32'd4,
            "P-CORE PROGRAM COUNTER"
        );

        check(
            e_debug_pc == 32'd4,
            "E-CORE PROGRAM COUNTER"
        );

        // Seguridad del bus
        check(
            !(mem_read && mem_write),
            "MEMORY READ/WRITE NEVER ACTIVE TOGETHER"
        );

        // Busqueda de instrucciones
        check(
            instruction_fetches == 2,
            "TWO INSTRUCTION FETCHES ON SHARED BUS"
        );

        // Lecturas normales
        check(
            data_reads == 0,
            "NO NORMAL DATA READS"
        );

        // Señal execute
        check(
            mem_execute === 1'b0,
            "EXECUTE SIGNAL INACTIVE WHEN IDLE"
        );

        // Scheduler
        check(
            !scheduler_busy,
            "SCHEDULER IDLE AFTER BOTH CORES HALT"
        );

        // Resultado final
        $display("--------------------------------");
        $display("INSTRUCTION FETCHES: %0d", instruction_fetches);
        $display("DATA READS: %0d", data_reads);
        $display("CYCLES: %0d", cycles);
        $display("PASSED: %0d", passed);
        $display("FAILED: %0d", failed);
        $display("--------------------------------");

        if (failed == 0) begin
            $display("ALL TOMATO G1 SYSTEM TESTS PASSED!");
            $finish;
        end
        else begin
            $display("TOMATO G1 SYSTEM TESTS FAILED!");
            $fatal(1, "System verification failed");
        end
    end

    initial begin
        #5000;
        if (failed == 0 &&
            (!p_halted || !e_halted)) begin
            $display("ERROR: SYSTEM TEST TIMEOUT");
            $fatal(1, "System test timed out");
        end
    end

endmodule
