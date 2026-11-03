
module tomato_registers (
    input  wire        clk,
    input  wire        reset,
    input  wire        write_enable,

    input  wire [3:0]  read_addr_a,
    input  wire [3:0]  read_addr_b,
    input  wire [3:0]  write_addr,

    input  wire [31:0] write_data,

    output wire [31:0] read_data_a,
    output wire [31:0] read_data_b
);

    reg [31:0] registers [0:15];

    integer i;

    // Reset registers
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 16; i = i + 1)
                registers[i] <= 32'b0;
        end
        else if (write_enable && write_addr != 4'd0) begin
            registers[write_addr] <= write_data;
        end
    end

    // Register R0 is always zero
    assign read_data_a =
        (read_addr_a == 4'd0) ? 32'b0 :
        registers[read_addr_a];

    assign read_data_b =
        (read_addr_b == 4'd0) ? 32'b0 :
        registers[read_addr_b];

endmodule
