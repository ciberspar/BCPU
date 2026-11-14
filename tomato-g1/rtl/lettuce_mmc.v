
`timescale 1ns/1ps

module lettuce_mmu (
    input wire clk,
    input wire reset,

    input wire req_valid,
    input wire [31:0] virtual_address,

    input wire access_read,
    input wire access_write,
    input wire access_execute,

    input wire map_enable,
    input wire [31:0] virtual_base,
    input wire [32:0] virtual_limit,
    input wire [33:0] physical_base,

    input wire permission_read,
    input wire permission_write,
    input wire permission_execute,

    output reg resp_valid,
    output reg [33:0] physical_address,
    output reg fault,
    output reg [2:0] fault_code
);

    localparam FAULT_NONE       = 3'd0;
    localparam FAULT_UNMAPPED   = 3'd1;
    localparam FAULT_PERMISSION = 3'd2;
    localparam FAULT_OVERFLOW   = 3'd3;
    localparam FAULT_ACCESS     = 3'd4;

    reg [32:0] virtual_offset;
    reg [34:0] physical_result;

    always @(*) begin
        resp_valid = 1'b0;
        physical_address = 34'b0;
        fault = 1'b0;
        fault_code = FAULT_NONE;

        virtual_offset = 33'b0;
        physical_result = 35'b0;

        if (req_valid) begin
            resp_valid = 1'b1;

            // Exactly one access type must be selected.
            if (!(
                (access_read && !access_write && !access_execute) ||
                (!access_read && access_write && !access_execute) ||
                (!access_read && !access_write && access_execute)
            )) begin
                fault = 1'b1;
                fault_code = FAULT_ACCESS;
            end

            // Check whether the virtual address is mapped.
            else if (
                !map_enable ||
                ({1'b0, virtual_address} < {1'b0, virtual_base}) ||
                ({1'b0, virtual_address} >= virtual_limit)
            ) begin
                fault = 1'b1;
                fault_code = FAULT_UNMAPPED;
            end

            // Check access permissions.
            else if (
                (access_read && !permission_read) ||
                (access_write && !permission_write) ||
                (access_execute && !permission_execute)
            ) begin
                fault = 1'b1;
                fault_code = FAULT_PERMISSION;
            end

            else begin
                // Calculate virtual offset.
                virtual_offset =
                    {1'b0, virtual_address} -
                    {1'b0, virtual_base};

                // Translate to a 34-bit physical address.
                physical_result =
                    {1'b0, physical_base} +
                    {2'b00, virtual_offset};

                // Detect overflow beyond 34 physical bits.
                if (physical_result[34]) begin
                    fault = 1'b1;
                    fault_code = FAULT_OVERFLOW;
                end
                else begin
                    physical_address = physical_result[33:0];
                end
            end
        end
    end

endmodule
