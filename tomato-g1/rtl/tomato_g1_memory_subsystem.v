
`timescale 1ns/1ps

module tomato_g1_memory_subsystem (
    input wire clk,
    input wire reset,

    // Virtual bus from the core scheduler
    input wire mem_read,
    input wire mem_execute,
    input wire mem_write,
    input wire [31:0] virtual_address,
    input wire [31:0] mem_write_data,

    output wire [31:0] mem_read_data,
    output wire mem_ready,
    output wire mem_fault,

    // MMU mapping configuration
    input wire map_enable,
    input wire [31:0] virtual_base,
    input wire [32:0] virtual_limit,
    input wire [33:0] physical_base,

    input wire permission_read,
    input wire permission_write,
    input wire permission_execute,

    // Fault reporting
    output wire [2:0] mmu_fault_code,

    // Physical RAM interface
    output wire ram_read,
    output wire ram_write,
    output wire [33:0] ram_address,
    output wire [31:0] ram_write_data,
    input wire [31:0] ram_read_data,
    input wire ram_ready
);

    wire request_valid;
    wire mmu_resp_valid;
    wire [33:0] physical_address;

    wire controller_read;
    wire controller_write;
    wire controller_ready;

    wire [31:0] controller_read_data;

    wire access_read;
    wire access_write;
    wire access_execute;

    assign request_valid = mem_read || mem_write;

    assign access_execute = mem_execute;
    assign access_write = mem_write;
    assign access_read = mem_read && !mem_execute;

    // Virtual address translation and permission checking
    lettuce_mmu mmu (
        .clk(clk),
        .reset(reset),

        .req_valid(request_valid),
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

        .resp_valid(mmu_resp_valid),
        .physical_address(physical_address),
        .fault(mem_fault),
        .fault_code(mmu_fault_code)
    );

    // Never send an invalid translation to physical memory.
    assign controller_read =
        request_valid &&
        mmu_resp_valid &&
        !mem_fault &&
        mem_read;

    assign controller_write =
        request_valid &&
        mmu_resp_valid &&
        !mem_fault &&
        mem_write;

    // Normal completion and translation faults are separate signals.
    assign mem_ready = controller_ready;
    assign mem_read_data = controller_read_data;

    // Physical memory controller
    tomato_memory_controller memory_controller (
        .clk(clk),
        .reset(reset),

        .mem_read(controller_read),
        .mem_write(controller_write),
        .mem_address(physical_address),
        .mem_write_data(mem_write_data),

        .mem_read_data(controller_read_data),
        .mem_ready(controller_ready),

        .ram_read(ram_read),
        .ram_write(ram_write),
        .ram_address(ram_address),
        .ram_write_data(ram_write_data),

        .ram_read_data(ram_read_data),
        .ram_ready(ram_ready)
    );

endmodule
