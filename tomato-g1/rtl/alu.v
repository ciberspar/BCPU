
module tomato_alu (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [3:0]  operation,
    output reg  [31:0] result,
    output wire        zero
);

    localparam OP_ADD = 4'd0;
    localparam OP_SUB = 4'd1;
    localparam OP_AND = 4'd2;
    localparam OP_OR  = 4'd3;
    localparam OP_XOR = 4'd4;
    localparam OP_NOT = 4'd5;
    localparam OP_SHL = 4'd6;
    localparam OP_SHR = 4'd7;
    localparam OP_SAR = 4'd8;
    localparam OP_MUL = 4'd9;

    always @(*) begin
        result = 32'b0;

        case (operation)
            OP_ADD: result = a + b;
            OP_SUB: result = a - b;
            OP_AND: result = a & b;
            OP_OR:  result = a | b;
            OP_XOR: result = a ^ b;
            OP_NOT: result = ~a;
            OP_SHL: result = a << b[4:0];
            OP_SHR: result = a >> b[4:0];
            OP_SAR: result = $signed(a) >>> b[4:0];
            OP_MUL: result = a * b;

            default: result = 32'b0;
        endcase
    end

    assign zero = (result == 32'b0);

endmodule
