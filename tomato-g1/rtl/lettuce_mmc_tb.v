
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

    integer passed;
    integer failed;

    lettuce_mmu uut (
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

    always #5 clk = ~clk;

    task check_result;
        input [8*40-1:0] test_name;
        input expected_fault;
        input [2:0] expected_code;
        begin
            #2;

            if (fault === expected_fault &&
                fault_code === expected_code) begin
                $display("[PASS] %0s", test_name);
                passed = passed + 1;
            end else begin
                $display("[FAIL] %0s", test_name);
                $display("       fault esperado=%b recibido=%b",
                         expected_fault, fault);
                $display("       code esperado=%d recibido=%d",
                         expected_code, fault_code);
                failed = failed + 1;
            end
        end
    endtask

    initial begin
        clk = 0;
        reset = 1;

        req_valid = 0;
        virtual_address = 0;

        access_read = 0;
        access_write = 0;
        access_execute = 0;

        map_enable = 1;
        virtual_base = 32'h00001000;
        virtual_limit = 33'h000002000;
        physical_base = 34'h000010000;

        permission_read = 1;
        permission_write = 1;
        permission_execute = 1;

        passed = 0;
        failed = 0;

        #10;
        reset = 0;

        // 1. Lectura válida
        req_valid = 1;
        virtual_address = 32'h00001020;
        access_read = 1;
        access_write = 0;
        access_execute = 0;

        check_result("Lectura valida", 0, 0);

        if (physical_address !== 34'h000010020) begin
            $display("[FAIL] Direccion fisica incorrecta");
            failed = failed + 1;
        end else begin
            $display("[PASS] Traduccion de direccion");
            passed = passed + 1;
        end

        // 2. Escritura válida
        access_read = 0;
        access_write = 1;

        check_result("Escritura valida", 0, 0);

        // 3. Ejecución válida
        access_write = 0;
        access_execute = 1;

        check_result("Ejecucion valida", 0, 0);

        // 4. Dirección fuera de la región
        access_execute = 0;
        access_read = 1;
        virtual_address = 32'h00002000;

        check_result("Direccion no mapeada", 1, 1);

        // 5. Permiso de escritura denegado
        virtual_address = 32'h00001020;
        access_read = 0;
        access_write = 1;
        permission_write = 0;

        check_result("Permiso de escritura denegado", 1, 2);

        // 6. Permiso de ejecución denegado
        permission_write = 1;
        permission_execute = 0;
        access_write = 0;
        access_execute = 1;

        check_result("Permiso de ejecucion denegado", 1, 2);

        // 7. Acceso inválido: dos tipos simultáneos
        permission_execute = 1;
        access_read = 1;
        access_execute = 1;

        check_result("Combinacion de acceso invalida", 1, 4);

        // 8. Mapeo desactivado
        access_read = 1;
        access_execute = 0;
        map_enable = 0;

        check_result("Mapeo desactivado", 1, 1);

        // 9. Desbordamiento de dirección física
        map_enable = 1;
        physical_base = 34'h3FFFFFFF0;
        virtual_address = 32'h00001020;

        check_result("Desbordamiento fisico", 1, 3);

        // Resultado final
        $display("");
        $display("================================");
        $display(" LETTUCE MMU TEST RESULTS");
        $display("================================");
        $display("Passed: %0d", passed);
        $display("Failed: %0d", failed);

        if (failed == 0)
            $display("ALL LETTUCE MMU TESTS PASSED!");
        else
            $display("LETUCCE MMU TESTS FAILED!");

        $finish;
    end

endmodule
