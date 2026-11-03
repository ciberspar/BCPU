
/*
 * BCPU Tomato G1
 * Lettuce32 Software Emulator
 *
 * Version: 0.1
 * Architecture: Lettuce32
 *
 * Initial instruction-set emulator.
 */

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define REGISTER_COUNT 16
#define MEMORY_SIZE (1024 * 1024)
#define MAX_STEPS 1000000

/* Lettuce32 opcodes */

enum {
    OP_NOP   = 0,
    OP_ADD   = 1,
    OP_SUB   = 2,
    OP_MUL   = 3,
    OP_AND   = 5,
    OP_OR    = 6,
    OP_XOR   = 7,
    OP_NOT   = 8,
    OP_SHL   = 9,
    OP_SHR   = 10,
    OP_SAR   = 11,
    OP_ADDI  = 12,
    OP_ANDI  = 13,
    OP_ORI   = 14,
    OP_XORI  = 15,
    OP_LDW   = 17,
    OP_STW   = 18,
    OP_BEQ   = 23,
    OP_BNE   = 24,
    OP_BLT   = 25,
    OP_BGE   = 26,
    OP_HALT  = 31
};

/* CPU state */

typedef struct {
    uint32_t registers[REGISTER_COUNT];
    uint32_t pc;
    uint8_t memory[MEMORY_SIZE];
    uint64_t cycles;
    int halted;
    int error;
} LettuceCPU;

/* Sign extension */

static int32_t sign_extend_18(uint32_t value) {
    value &= 0x3FFFFu;

    if (value & 0x20000u)
        value |= 0xFFFC0000u;

    return (int32_t)value;
}

/* Memory access: little-endian */

static uint32_t memory_read32(
    LettuceCPU *cpu,
    uint32_t address
) {
    if (address > MEMORY_SIZE - 4) {
        cpu->error = 1;
        return 0;
    }

    return
        (uint32_t)cpu->memory[address] |
        ((uint32_t)cpu->memory[address + 1] << 8) |
        ((uint32_t)cpu->memory[address + 2] << 16) |
        ((uint32_t)cpu->memory[address + 3] << 24);
}

static void memory_write32(
    LettuceCPU *cpu,
    uint32_t address,
    uint32_t value
) {
    if (address > MEMORY_SIZE - 4) {
        cpu->error = 1;
        return;
    }

    cpu->memory[address]     = (uint8_t)value;
    cpu->memory[address + 1] = (uint8_t)(value >> 8);
    cpu->memory[address + 2] = (uint8_t)(value >> 16);
    cpu->memory[address + 3] = (uint8_t)(value >> 24);
}

/* CPU initialization */

static void cpu_init(LettuceCPU *cpu) {
    memset(cpu, 0, sizeof(*cpu));
}

/* Instruction execution */

static void cpu_step(LettuceCPU *cpu) {
    if (cpu->halted || cpu->error)
        return;

    if (cpu->pc > MEMORY_SIZE - 4) {
        cpu->error = 1;
        return;
    }

    uint32_t instruction =
        memory_read32(cpu, cpu->pc);

    if (cpu->error)
        return;

    cpu->pc += 4;
    cpu->cycles++;

    uint32_t opcode = instruction >> 26;
    uint32_t rd = (instruction >> 22) & 0xF;
    uint32_t ra = (instruction >> 18) & 0xF;
    uint32_t rb = (instruction >> 14) & 0xF;

    uint32_t immediate = instruction & 0x3FFFFu;

    int32_t signed_imm = sign_extend_18(immediate);

    uint32_t a = cpu->registers[ra];
    uint32_t b = cpu->registers[rb];

    uint32_t result = 0;
    uint32_t address = 0;

    switch (opcode) {

        case OP_NOP:
            break;

        case OP_ADD:
            result = a + b;
            cpu->registers[rd] = result;
            break;

        case OP_SUB:
            result = a - b;
            cpu->registers[rd] = result;
            break;

        case OP_MUL:
            result = a * b;
            cpu->registers[rd] = result;
            break;

        case OP_AND:
            cpu->registers[rd] = a & b;
            break;

        case OP_OR:
            cpu->registers[rd] = a | b;
            break;

        case OP_XOR:
            cpu->registers[rd] = a ^ b;
            break;

        case OP_NOT:
            cpu->registers[rd] = ~a;
            break;

        case OP_SHL:
            cpu->registers[rd] = a << (b & 31);
            break;

        case OP_SHR:
            cpu->registers[rd] = a >> (b & 31);
            break;

        case OP_SAR:
            cpu->registers[rd] =
                (uint32_t)((int32_t)a >> (b & 31));
            break;

        case OP_ADDI:
            cpu->registers[rd] = a + (uint32_t)signed_imm;
            break;

        case OP_ANDI:
            cpu->registers[rd] = a & immediate;
            break;

        case OP_ORI:
            cpu->registers[rd] = a | immediate;
            break;

        case OP_XORI:
            cpu->registers[rd] = a ^ immediate;
            break;

        case OP_LDW:
            address = a + (uint32_t)signed_imm;
            cpu->registers[rd] =
                memory_read32(cpu, address);
            break;

        case OP_STW:
            address = a + (uint32_t)signed_imm;
            memory_write32(
                cpu,
                address,
                cpu->registers[rd]
            );
            break;

        case OP_BEQ:
            if (a == b)
                cpu->pc += (uint32_t)(signed_imm * 4);
            break;

        case OP_BNE:
            if (a != b)
                cpu->pc += (uint32_t)(signed_imm * 4);
            break;

        case OP_BLT:
            if ((int32_t)a < (int32_t)b)
                cpu->pc += (uint32_t)(signed_imm * 4);
            break;

        case OP_BGE:
            if ((int32_t)a >= (int32_t)b)
                cpu->pc += (uint32_t)(signed_imm * 4);
            break;

        case OP_HALT:
            cpu->halted = 1;
            break;

        default:
            fprintf(
                stderr,
                "Lettuce32: unsupported opcode %u at PC 0x%08X\n",
                opcode,
                cpu->pc - 4
            );
            cpu->error = 1;
            break;
    }

    /* R0 is always zero. */
    cpu->registers[0] = 0;
}

/* Run CPU */

static void cpu_run(LettuceCPU *cpu) {
    while (!cpu->halted &&
           !cpu->error &&
           cpu->cycles < MAX_STEPS) {
        cpu_step(cpu);
    }

    if (cpu->cycles >= MAX_STEPS &&
        !cpu->halted &&
        !cpu->error) {
        fprintf(stderr, "Lettuce32: cycle limit reached\n");
        cpu->error = 1;
    }
}

/* Demonstration program */

static void load_demo_program(LettuceCPU *cpu) {
    /*
     * The demo will be added after the assembler
     * and instruction encoder are defined.
     */
    (void)cpu;
}

/* Main */

int main(void) {
    LettuceCPU cpu;

    cpu_init(&cpu);
    load_demo_program(&cpu);

    printf("BCPU Tomato G1 - Lettuce32 Emulator\n");
    printf("Memory: %u bytes\n", MEMORY_SIZE);

    cpu_run(&cpu);

    printf("Cycles: %llu\n",
           (unsigned long long)cpu.cycles);

    if (cpu.halted)
        printf("CPU halted successfully.\n");

    if (cpu.error)
        printf("CPU stopped because of an execution error.\n");

    printf("\nRegisters:\n");

    for (int i = 0; i < REGISTER_COUNT; i++) {
        printf(
            "R%-2d = 0x%08X\n",
            i,
            cpu.registers[i]
        );
    }

    return cpu.error ? EXIT_FAILURE : EXIT_SUCCESS;
}
