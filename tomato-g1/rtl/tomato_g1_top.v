
`timescale 1ns/1ps

module tomato_g1_top (
    input wire clk,
    input wire reset,

    // External memory interface
    output wire mem_read,
    output wire mem_write,
    output wire [31:0] mem_address,
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

    // P-Core bus
    wire p_mem_read;
    wire p_mem_write;
    wire [31:0] p_mem_address;
    wire [31:0] p_mem_write_data;
    wire [31:0] p_mem_read_data;
    wire p_mem_ready;

    // E-Core bus
    wire e_mem_read;
    wire e_mem_write;
    wire [31:0] e_mem_address;
    wire [31:0] e_mem_write_data;
    wire [31:0] e_mem_read_data;
    wire e_mem_ready;

    // P-Core instance
    tomato_p_core p_core (
        .clk(clk),
        .reset(reset),

        .mem_read(p_mem_read),
        .mem_write(p_mem_write),
        .mem_address(p_mem_address),
        .mem_write_data(p_mem_write_data),
        .mem_read_data(p_mem_read_data),
        .mem_ready(p_mem_ready),

        .halted(p_halted),
        .faulted(p_faulted),
        .debug_pc(p_debug_pc)
    );

    // E-Core instance
    tomato_e_core e_core (
        .clk(clk),
        .reset(reset),

        .mem_read(e_mem_read),
        .mem_write(e_mem_write),
        .mem_address(e_mem_address),
        .mem_write_data(e_mem_write_data),
        .mem_read_data(e_mem_read_data),
        .mem_ready(e_mem_ready),

        .halted(e_halted),
        .faulted(e_faulted),
        .debug_pc(e_debug_pc)
    );

    // Shared memory scheduler
    tomato_core_scheduler scheduler (
        .clk(clk),
        .reset(reset),

        // P-Core
        .p_mem_read(p_mem_read),
        .p_mem_write(p_mem_write),
        .p_mem_address(p_mem_address),
        .p_mem_write_data(p_mem_write_data),
        .p_mem_read_data(p_mem_read_data),
        .p_mem_ready(p_mem_ready),

        // E-Core
        .e_mem_read(e_mem_read),
        .e_mem_write(e_mem_write),
        .e_mem_address(e_mem_address),
        .e_mem_write_data(e_mem_write_data),
        .e_mem_read_data(e_mem_read_data),
        .e_mem_ready(e_mem_ready),

        // External memory
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_address(mem_address),
        .mem_write_data(mem_write_data),
        .mem_read_data(mem_read_data),
        .mem_ready(mem_ready),

        // Status
        .busy(scheduler_busy),
        .active_core(scheduler_active_core)
    );

endmodule
