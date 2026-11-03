
`timescale 1ns/1ps

module tomato_core_scheduler (
    input wire clk,
    input wire reset,

    // P-Core interface
    input wire p_mem_read,
    input wire p_mem_write,
    input wire [31:0] p_mem_address,
    input wire [31:0] p_mem_write_data,
    output reg [31:0] p_mem_read_data,
    output reg p_mem_ready,

    // E-Core interface
    input wire e_mem_read,
    input wire e_mem_write,
    input wire [31:0] e_mem_address,
    input wire [31:0] e_mem_write_data,
    output reg [31:0] e_mem_read_data,
    output reg e_mem_ready,

    // External memory bus
    output reg mem_read,
    output reg mem_write,
    output reg [31:0] mem_address,
    output reg [31:0] mem_write_data,
    input wire [31:0] mem_read_data,
    input wire mem_ready,

    output wire busy,
    output wire active_core
);

    localparam CORE_P = 1'b0;
    localparam CORE_E = 1'b1;

    reg transaction_active;
    reg transaction_owner;
    reg last_grant;

    reg grant_valid;
    reg grant_owner;

    reg saved_read;
    reg saved_write;
    reg [31:0] saved_address;
    reg [31:0] saved_write_data;

    assign busy = transaction_active;
    assign active_core = transaction_owner;

    // Round-robin arbitration
    always @(*) begin
        grant_valid = 1'b0;
        grant_owner = last_grant;

        if (!transaction_active) begin
            if (last_grant == CORE_P) begin
                if (e_mem_read || e_mem_write) begin
                    grant_valid = 1'b1;
                    grant_owner = CORE_E;
                end else if (p_mem_read || p_mem_write) begin
                    grant_valid = 1'b1;
                    grant_owner = CORE_P;
                end
            end else begin
                if (p_mem_read || p_mem_write) begin
                    grant_valid = 1'b1;
                    grant_owner = CORE_P;
                end else if (e_mem_read || e_mem_write) begin
                    grant_valid = 1'b1;
                    grant_owner = CORE_E;
                end
            end
        end
    end

    // Capture and complete memory transactions
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            transaction_active <= 1'b0;
            transaction_owner <= CORE_P;
            last_grant <= CORE_E;

            saved_read <= 1'b0;
            saved_write <= 1'b0;
            saved_address <= 32'b0;
            saved_write_data <= 32'b0;

            p_mem_read_data <= 32'b0;
            e_mem_read_data <= 32'b0;
            p_mem_ready <= 1'b0;
            e_mem_ready <= 1'b0;
        end else begin
            p_mem_ready <= 1'b0;
            e_mem_ready <= 1'b0;

            if (!transaction_active && grant_valid) begin
                transaction_active <= 1'b1;
                transaction_owner <= grant_owner;
                last_grant <= grant_owner;

                if (grant_owner == CORE_P) begin
                    saved_read <= p_mem_read;
                    saved_write <= p_mem_write;
                    saved_address <= p_mem_address;
                    saved_write_data <= p_mem_write_data;
                end else begin
                    saved_read <= e_mem_read;
                    saved_write <= e_mem_write;
                    saved_address <= e_mem_address;
                    saved_write_data <= e_mem_write_data;
                end
            end

            if (transaction_active && mem_ready) begin
                transaction_active <= 1'b0;

                if (transaction_owner == CORE_P) begin
                    p_mem_read_data <= mem_read_data;
                    p_mem_ready <= 1'b1;
                end else begin
                    e_mem_read_data <= mem_read_data;
                    e_mem_ready <= 1'b1;
                end
            end
        end
    end

    // External bus
    always @(*) begin
        mem_read = 1'b0;
        mem_write = 1'b0;
        mem_address = 32'b0;
        mem_write_data = 32'b0;

        if (transaction_active) begin
            mem_read = saved_read;
            mem_write = saved_write;
            mem_address = saved_address;
            mem_write_data = saved_write_data;
        end
    end

endmodule
