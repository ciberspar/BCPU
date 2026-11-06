
module tomato_p_core (
    input  wire        clk,
    input  wire        reset,

    // Bus compartido de instrucciones y datos
    output wire        mem_read,
    output wire        mem_write,
    output wire [31:0] mem_address,
    output wire [31:0] mem_write_data,
    input  wire [31:0] mem_read_data,
    input  wire        mem_ready,

    // Estado del procesador
    output wire        halted,
    output wire        faulted,
    output wire [31:0] debug_pc
);

// Lettuce32 opcodes
localparam OP_NOP  = 6'd0;
localparam OP_ADD  = 6'd1;
localparam OP_SUB  = 6'd2;
localparam OP_MUL  = 6'd3;
localparam OP_AND  = 6'd5;
localparam OP_OR   = 6'd6;
localparam OP_XOR  = 6'd7;
localparam OP_NOT  = 6'd8;
localparam OP_SHL  = 6'd9;
localparam OP_SHR  = 6'd10;
localparam OP_SAR  = 6'd11;
localparam OP_ADDI = 6'd12;
localparam OP_ANDI = 6'd13;
localparam OP_ORI  = 6'd14;
localparam OP_XORI = 6'd15;
localparam OP_LDW  = 6'd17;
localparam OP_STW  = 6'd18;
localparam OP_BEQ  = 6'd23;
localparam OP_BNE  = 6'd24;
localparam OP_BLT  = 6'd25;
localparam OP_BGE  = 6'd26;
localparam OP_HALT = 6'd31;

// ALU operations
localparam ALU_ADD = 4'd0;
localparam ALU_SUB = 4'd1;
localparam ALU_AND = 4'd2;
localparam ALU_OR  = 4'd3;
localparam ALU_XOR = 4'd4;
localparam ALU_NOT = 4'd5;
localparam ALU_SHL = 4'd6;
localparam ALU_SHR = 4'd7;
localparam ALU_SAR = 4'd8;
localparam ALU_MUL = 4'd9;

// Processor states
localparam FETCH_REQ  = 4'd0;
localparam FETCH_WAIT = 4'd1;
localparam DECODE     = 4'd2;
localparam LOAD_REQ   = 4'd3;
localparam LOAD_WAIT  = 4'd4;
localparam STORE_REQ  = 4'd5;
localparam STORE_WAIT = 4'd6;
localparam WRITEBACK  = 4'd7;
localparam HALTED     = 4'd8;
localparam FAULTED    = 4'd9;

reg [3:0] state;
reg [31:0] pc;
reg [31:0] instruction;
reg [31:0] effective_address;
reg [31:0] store_value;
reg [3:0] destination;
reg [31:0] writeback_value;

// Instruction fields
wire [5:0] opcode = instruction[31:26];
wire [3:0] rd = instruction[25:22];
wire [3:0] ra = instruction[21:18];
wire [3:0] rb = instruction[17:14];
wire [17:0] immediate = instruction[17:0];

wire [31:0] signed_immediate =
    {{14{immediate[17]}}, immediate};

wire [31:0] unsigned_immediate =
    {14'b0, immediate};

// Branch instructions use RD and RA as source registers.
wire is_branch =
    (opcode == OP_BEQ) ||
    (opcode == OP_BNE) ||
    (opcode == OP_BLT) ||
    (opcode == OP_BGE);

// Register file
wire [31:0] register_a;
wire [31:0] register_b;

wire [3:0] read_address_a;
wire [3:0] read_address_b;

assign read_address_a =
    is_branch ? rd : ra;

assign read_address_b =
    is_branch ? ra :
    (opcode == OP_STW) ? rd : rb;

wire register_write_enable;

tomato_registers registers (
    .clk(clk),
    .reset(reset),
    .write_enable(register_write_enable),
    .read_addr_a(read_address_a),
    .read_addr_b(read_address_b),
    .write_addr(destination),
    .write_data(writeback_value),
    .read_data_a(register_a),
    .read_data_b(register_b)
);

assign register_write_enable =
    (state == WRITEBACK);

// ALU
reg [3:0] alu_operation;
reg [31:0] alu_a;
reg [31:0] alu_b;

wire [31:0] alu_result;
wire alu_zero;

tomato_alu alu (
    .a(alu_a),
    .b(alu_b),
    .operation(alu_operation),
    .result(alu_result),
    .zero(alu_zero)
);

// ALU input selection
always @(*) begin
    alu_a = register_a;
    alu_b = register_b;
    alu_operation = ALU_ADD;

    case (opcode)
        OP_ADD: alu_operation = ALU_ADD;
        OP_SUB: alu_operation = ALU_SUB;
        OP_MUL: alu_operation = ALU_MUL;
        OP_AND: alu_operation = ALU_AND;
        OP_OR:  alu_operation = ALU_OR;
        OP_XOR: alu_operation = ALU_XOR;
        OP_NOT: alu_operation = ALU_NOT;
        OP_SHL: alu_operation = ALU_SHL;
        OP_SHR: alu_operation = ALU_SHR;
        OP_SAR: alu_operation = ALU_SAR;

        OP_ADDI: begin
            alu_operation = ALU_ADD;
            alu_b = signed_immediate;
        end

        OP_ANDI: begin
            alu_operation = ALU_AND;
            alu_b = unsigned_immediate;
        end

        OP_ORI: begin
            alu_operation = ALU_OR;
            alu_b = unsigned_immediate;
        end

        OP_XORI: begin
            alu_operation = ALU_XOR;
            alu_b = unsigned_immediate;
        end

        OP_LDW, OP_STW: begin
            alu_operation = ALU_ADD;
            alu_b = signed_immediate;
        end

        default: begin
            alu_operation = ALU_ADD;
        end
    endcase
end

// Memory interface
assign mem_read =
    (state == FETCH_REQ) ||
    (state == LOAD_REQ);

assign mem_write =
    (state == STORE_REQ);

assign mem_address =
    (state == FETCH_REQ) ? pc :
    effective_address;

assign mem_write_data = store_value;

// Processor status
assign halted = (state == HALTED);
assign faulted = (state == FAULTED);
assign debug_pc = pc;

// Main processor controller
always @(posedge clk or posedge reset) begin
    if (reset) begin
        state             <= FETCH_REQ;
        pc                <= 32'b0;
        instruction       <= 32'b0;
        effective_address <= 32'b0;
        store_value       <= 32'b0;
        destination       <= 4'b0;
        writeback_value   <= 32'b0;
    end
    else begin
        case (state)

            FETCH_REQ: begin
                state <= FETCH_WAIT;
            end

            FETCH_WAIT: begin
                if (mem_ready) begin
                    instruction <= mem_read_data;
                    pc <= pc + 32'd4;
                    state <= DECODE;
                end
            end

            DECODE: begin
                case (opcode)

                    OP_NOP: begin
                        state <= FETCH_REQ;
                    end

                    OP_HALT: begin
                        state <= HALTED;
                    end

                    // Register arithmetic
                    OP_ADD, OP_SUB, OP_MUL,
                    OP_AND, OP_OR, OP_XOR,
                    OP_NOT, OP_SHL, OP_SHR,
                    OP_SAR: begin
                        destination <= rd;
                        writeback_value <= alu_result;
                        state <= WRITEBACK;
                    end

                    // Immediate arithmetic
                    OP_ADDI, OP_ANDI,
                    OP_ORI, OP_XORI: begin
                        destination <= rd;
                        writeback_value <= alu_result;
                        state <= WRITEBACK;
                    end

                    // Load word
                    OP_LDW: begin
                        if (alu_result[1:0] != 2'b00) begin
                            state <= FAULTED;
                        end
                        else begin
                            effective_address <= alu_result;
                            destination <= rd;
                            state <= LOAD_REQ;
                        end
                    end

                    // Store word
                    OP_STW: begin
                        if (alu_result[1:0] != 2'b00) begin
                            state <= FAULTED;
                        end
                        else begin
                            effective_address <= alu_result;
                            store_value <= register_b;
                            state <= STORE_REQ;
                        end
                    end

                    // Branch if equal
                    OP_BEQ: begin
                        if (register_a == register_b)
                            pc <= pc +
                                (signed_immediate << 2);

                        state <= FETCH_REQ;
                    end

                    // Branch if not equal
                    OP_BNE: begin
                        if (register_a != register_b)
                            pc <= pc +
                                (signed_immediate << 2);

                        state <= FETCH_REQ;
                    end

                    // Branch if less than
                    OP_BLT: begin
                        if ($signed(register_a) <
                            $signed(register_b))
                            pc <= pc +
                                (signed_immediate << 2);

                        state <= FETCH_REQ;
                    end

                    // Branch if greater or equal
                    OP_BGE: begin
                        if ($signed(register_a) >=
                            $signed(register_b))
                            pc <= pc +
                                (signed_immediate << 2);

                        state <= FETCH_REQ;
                    end

                    // Any unsupported opcode is a fault.
                    default: begin
                        state <= FAULTED;
                    end
                endcase
            end

            LOAD_REQ: begin
                state <= LOAD_WAIT;
            end

            LOAD_WAIT: begin
                if (mem_ready) begin
                    writeback_value <= mem_read_data;
                    state <= WRITEBACK;
                end
            end

            STORE_REQ: begin
                state <= STORE_WAIT;
            end

            STORE_WAIT: begin
                if (mem_ready)
                    state <= FETCH_REQ;
            end

            WRITEBACK: begin
                state <= FETCH_REQ;
            end

            HALTED: begin
                state <= HALTED;
            end

            FAULTED: begin
                state <= FAULTED;
            end

            default: begin
                state <= FAULTED;
            end
        endcase
    end
end

endmodule
