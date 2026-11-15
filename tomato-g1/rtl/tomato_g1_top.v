
`timescale 1ns/1ps

module tomato_g1_top (
    input wire clk,
    input wire reset,

    // External physical RAM interface
    output wire mem_read,
    output wire mem_execute,
    output wire mem_write,
    output wire [33:0] mem_address,
    output wire [31:0] mem_write_data,
    input wire [31:0] mem_read_data,
    input wire mem_ready,

    // Processor status
    output wire p_halted,
    output wire e_halted,
    output wire p_faulted,
    output wire e_faulted,

    output wire [31:0] p_debug_pc,
    output wire [31:0] e_debug_pc,

    // Scheduler status
    output wire scheduler_busy,
    output wire scheduler_active_core
);

    // P-Core virtual memory interface
    wire p_mem_read;
    wire p_mem_execute;
    wire p_mem_write;
    wire [31:0] p_mem_address;
    wire [31:0] p_mem_write_data;
    wire [31:0] p_mem_read_data;
    wire p_mem_ready;
    wire p_mem_fault;

    // E-Core virtual memory interface
    wire e_mem_read;
    wire e_mem_execute;
    wire e_mem_write;
    wire [31:0] e_mem_address;
    wire [31:0] e_mem_write_data;
    wire [31:0] e_mem_read_data;
    wire e_mem_ready;
    wire e_mem_fault;

    // Scheduler virtual memory bus
    wire virtual_read;
    wire virtual_execute;
    wire virtual_write;
    wire [31:0] virtual_address;
    wire [31:0] virtual_write_data;
    wire [31:0] virtual_read_data;
    wire virtual_ready;
    wire virtual_fault;

    // MMU status
    wire [2:0] mmu_fault_code;

    // Physical memory subsystem signals
    wire physical_read;
    wire physical_write;
    wire [33:0] physical_address;
    wire [31:0] physical_write_data;

    // ------------------------------------------------
    // P-CORE
    // ------------------------------------------------

    tomato_p_core p_core (
        .clk(clk),
        .reset(reset),

        .mem_read(p_mem_read),
        .mem_execute(p_mem_execute),
        .mem_write(p_mem_write),
        .mem_address(p_mem_address),
        .mem_write_data(p_mem_write_data),
        .mem_read_data(p_mem_read_data),
        .mem_ready(p_mem_ready),
        .mem_fault(p_mem_fault),

        .halted(p_halted),
        .faulted(p_faulted),
        .debug_pc(p_debug_pc)
    );

    // ------------------------------------------------
    // E-CORE
    // ------------------------------------------------

    tomato_e_core e_core (
        .clk(clk),
        .reset(reset),

        .mem_read(e_mem_read),
        .mem_execute(e_mem_execute),
        .mem_write(e_mem_write),
        .mem_address(e_mem_address),
        .mem_write_data(e_mem_write_data),
        .mem_read_data(e_mem_read_data),
        .mem_ready(e_mem_ready),
        .mem_fault(e_mem_fault),

        .halted(e_halted),
        .faulted(e_faulted),
        .debug_pc(e_debug_pc)
    );

    // ------------------------------------------------
    // SHARED CORE SCHEDULER
    // ------------------------------------------------

    tomato_core_scheduler scheduler (
        .clk(clk),
        .reset(reset),

        // P-Core
        .p_mem_read(p_mem_read),
        .p_mem_execute(p_mem_execute),
        .p_mem_write(p_mem_write),
        .p_mem_address(p_mem_address),
        .p_mem_write_data(p_mem_write_data),
        .p_mem_read_data(p_mem_read_data),
        .p_mem_ready(p_mem_ready),
        .p_mem_fault(p_mem_fault),

        // E-Core
        .e_mem_read(e_mem_read),
        .e_mem_execute(e_mem_execute),
        .e_mem_write(e_mem_write),
        .e_mem_address(e_mem_address),
        .e_mem_write_data(e_mem_write_data),
        .e_mem_read_data(e_mem_read_data),
        .e_mem_ready(e_mem_ready),
        .e_mem_fault(e_mem_fault),

        // Virtual memory bus
        .mem_read(virtual_read),
        .mem_execute(virtual_execute),
        .mem_write(virtual_write),
        .mem_address(virtual_address),
        .mem_write_data(virtual_write_data),
        .mem_read_data(virtual_read_data),
        .mem_ready(virtual_ready),
        .mem_fault(virtual_fault),

        // Status
        .busy(scheduler_busy),
        .active_core(scheduler_active_core)
    );

    // ------------------------------------------------
    // TOMATO G1 MEMORY SUBSYSTEM + LETTUCE MMU
    // ------------------------------------------------

    tomato_g1_memory_subsystem memory_subsystem (
        .clk(clk),
        .reset(reset),

        .mem_read(virtual_read),
        .mem_execute(virtual_execute),
        .mem_write(virtual_write),
        .virtual_address(virtual_address),
        .mem_write_data(virtual_write_data),

        .mem_read_data(virtual_read_data),
        .mem_ready(virtual_ready),
        .mem_fault(virtual_fault),

        // Initial identity mapping for bring-up.
        .map_enable(1'b1),
        .virtual_base(32'h00000000),
        .virtual_limit(33'h100000000),
        .physical_base(34'h000000000),

        // Initial test permissions.
        .permission_read(1'b1),
        .permission_write(1'b1),
        .permission_execute(1'b1),

        .mmu_fault_code(mmu_fault_code),

        // Physical RAM bus
        .ram_read(physical_read),
        .ram_write(physical_write),
        .ram_address(physical_address),
        .ram_write_data(physical_write_data),
        .ram_read_data(mem_read_data),
        .ram_ready(mem_ready)
    );

    // ------------------------------------------------
    // EXTERNAL PHYSICAL RAM CONNECTION
    // ------------------------------------------------

    assign mem_read = physical_read;
    assign mem_write = physical_write;
    assign mem_address = physical_address;
    assign mem_write_data = physical_write_data;

    // Execute is a logical attribute of the active
    // virtual request, not a physical RAM operation.
    assign mem_execute = virtual_execute;

endmodule
