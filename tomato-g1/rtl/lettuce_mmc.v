
`timescale 1ns/1ps

module lettuce_mmu (
    input wire clk,
    input wire reset,

    // Virtual memory request
    input wire req_valid,
    input wire [31:0] virtual_address,

    // Access type
    input wire access_read,
    input wire access_write,
    input wire access_execute,

    // Region configuration
    input wire map_enable,
    input wire [31:0] virtual_base,
    input wire [32:0] virtual_limit,
    input wire [33:0] physical_base,

    // Permissions
    input wire permission_read,
    input wire permission_write,
    input wire permission_execute,

    // Translation response
    output reg resp_valid,
    output reg [33:0] physical_address,
    output reg fault,
    output reg [2:0] fault_code
);

    // Fault codes
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

            // Reject invalid access combinations.
            if ((access_read + access_write +
                 access_execute) != 1) begin

                fault = 1'b1;
                fault_code = FAULT_ACCESS;

            end

            // Check whether the mapping exists.
            else if (!map_enable ||
                     ({1'b0, virtual_address} < 
                      {1'b0, virtual_base}) ||
                     ({1'b0, virtual_address} >=
                      virtual_limit)) begin

                fault = 1'b1;
                fault_code = FAULT_UNMAPPED;

            end

            // Check access permissions.
            else if ((access_read && !permission_read) ||
                     (access_write && !permission_write) ||
                     (access_execute && !permission_execute)) begin

                fault = 1'b1;
                fault_code = FAULT_PERMISSION;

            end

            else begin
                virtual_offset =
                    {1'b0, virtual_address} -
                    {1'b0, virtual_base};

                physical_result =
                    {1'b0, physical_base} +
                    {2'b00, virtual_offset};

                // Physical addresses must fit in 34 bits.
                if (physical_result[34] ||
                    physical_result[33:0] < physical_base) begin

                    fault = 1'b1;
                    fault_code = FAULT_OVERFLOW;

                end
                else begin
                    physical_address =
                        physical_result[33:0];
                end
            end
        end
    end

endmodule
