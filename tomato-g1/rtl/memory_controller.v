
module tomato_memory_controller (
    input  wire        clk,
    input  wire        reset,

    // Solicitud del procesador
    input  wire        mem_read,
    input  wire        mem_write,
    input  wire [31:0] mem_address,
    input  wire [31:0] mem_write_data,
    output reg  [31:0] mem_read_data,
    output reg         mem_ready,

    // Interfaz hacia el sistema de memoria
    output reg         ram_read,
    output reg         ram_write,
    output reg  [31:0] ram_address,
    output reg  [31:0] ram_write_data,
    input  wire [31:0] ram_read_data,
    input  wire        ram_ready
);

    localparam IDLE  = 2'd0;
    localparam READ  = 2'd1;
    localparam WRITE = 2'd2;

    reg [1:0] state;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state          <= IDLE;
            mem_read_data  <= 32'b0;
            mem_ready      <= 1'b0;
            ram_read       <= 1'b0;
            ram_write      <= 1'b0;
            ram_address    <= 32'b0;
            ram_write_data <= 32'b0;
        end else begin
            mem_ready <= 1'b0;
            ram_read  <= 1'b0;
            ram_write <= 1'b0;

            case (state)
                IDLE: begin
                    if (mem_read) begin
                        ram_address <= mem_address;
                        ram_read    <= 1'b1;
                        state       <= READ;
                    end else if (mem_write) begin
                        ram_address    <= mem_address;
                        ram_write_data <= mem_write_data;
                        ram_write      <= 1'b1;
                        state          <= WRITE;
                    end
                end

                READ: begin
                    if (ram_ready) begin
                        mem_read_data <= ram_read_data;
                        mem_ready     <= 1'b1;
                        state         <= IDLE;
                    end
                end

                WRITE: begin
                    if (ram_ready) begin
                        mem_ready <= 1'b1;
                        state     <= IDLE;
                    end
                end

                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
