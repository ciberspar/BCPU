
module tomato_io_controller (
    input  wire        clk,
    input  wire        reset,

    // Bus de entrada y salida
    input  wire        io_write,
    input  wire        io_read,
    input  wire [3:0]  io_address,
    input  wire [31:0] io_write_data,
    output reg  [31:0] io_read_data,
    output wire        io_ready,

    // Pines GPIO externos
    input  wire [31:0] gpio_in,
    output reg  [31:0] gpio_out,
    output reg  [31:0] gpio_oe
);

    localparam ADDR_GPIO_OUT = 4'h0;
    localparam ADDR_GPIO_OE  = 4'h4;
    localparam ADDR_GPIO_IN  = 4'h8;

    assign io_ready = 1'b1;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            gpio_out <= 32'b0;
            gpio_oe  <= 32'b0;
        end else if (io_write) begin
            case (io_address)
                ADDR_GPIO_OUT:
                    gpio_out <= io_write_data;

                ADDR_GPIO_OE:
                    gpio_oe <= io_write_data;

                default: begin
                    gpio_out <= gpio_out;
                    gpio_oe  <= gpio_oe;
                end
            endcase
        end
    end

    always @(*) begin
        io_read_data = 32'b0;

        if (io_read) begin
            case (io_address)
                ADDR_GPIO_OUT:
                    io_read_data = gpio_out;

                ADDR_GPIO_OE:
                    io_read_data = gpio_oe;

                ADDR_GPIO_IN:
                    io_read_data = gpio_in;

                default:
                    io_read_data = 32'b0;
            endcase
        end
    end

endmodule
