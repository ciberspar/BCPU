
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MEMORY_SIZE (1024u * 1024u)
#define REGISTER_COUNT 16
#define MAX_STEPS 1000000u

#define OP_NOP   0
#define OP_ADD   1
#define OP_SUB   2
#define OP_MUL   3
#define OP_AND   5
#define OP_OR    6
#define OP_XOR   7
#define OP_NOT   8
#define OP_SHL   9
#define OP_SHR   10
#define OP_SAR   11
#define OP_ADDI  12
#define OP_ANDI  13
#define OP_ORI   14
#define OP_XORI  15
#define OP_LDW   17
#define OP_STW   18
#define OP_BEQ   23
#define OP_BNE   24
#define OP_BLT   25
#define OP_BGE   26
#define OP_HALT  31

typedef struct {
    uint32_t registers[REGISTER_COUNT];
    uint32_t pc;
    uint8_t memory[MEMORY_SIZE];
    uint64_t cycles;
    int halted;
    int error;
} LettuceCPU;

static int32_t sign_extend_18(uint32_t value) {
    value &= 0x3FFFFu;

    if (value & 0x20000u) {
        value |= 0xFFFC0000u;
    }

    return (int32_t)value;
}

static void cpu_init(LettuceCPU *cpu) {
    memset(cpu, 0, sizeof(*cpu));
}

static int memory_read32(LettuceCPU *cpu,
                         uint32_t address,
                         uint32_t *value) {
    if ((address & 3u) != 0 ||
        address > MEMORY_SIZE - 4u) {
        cpu->error = 1;
        return 0;
    }

    *value =
        (uint32_t)cpu->memory[address] |
        ((uint32_t)cpu->memory[address + 1] << 8) |
        ((uint32_t)cpu->memory[address + 2] << 16) |
        ((uint32_t)cpu->memory[address + 3] << 24);

    return 1;
}

static int memory_write32(LettuceCPU *cpu,
                          uint32_t address,
                          uint32_t value) {
    if ((address & 3u) != 0 ||
        address > MEMORY_SIZE - 4u) {
        cpu->error = 1;
        return 0;
    }

    cpu->memory[address] = (uint8_t)value;
    cpu->memory[address + 1] = (uint8_t)(value >> 8);
    cpu->memory[address + 2] = (uint8_t)(value >> 16);
    cpu->memory[address + 3] = (uint8_t)(value >> 24);

    return 1;
}

static int cpu_step(LettuceCPU *cpu) {
    uint32_t instruction;
    uint32_t opcode;
    uint32_t rd;
    uint32_t ra;
    uint32_t rb;
    uint32_t immediate;

    uint32_t a;
    uint32_t b;
    uint32_t result = 0;
    uint32_t next_pc;

    if (cpu->halted || cpu->error) {
        return 0;
    }

    if ((cpu->pc & 3u) != 0 ||
        cpu->pc > MEMORY_SIZE - 4u) {
        cpu->error = 1;
        return 0;
    }

    if (!memory_read32(cpu, cpu->pc, &instruction)) {
        return 0;
    }

    opcode = instruction >> 26;
    rd = (instruction >> 22) & 0xF;
    ra = (instruction >> 18) & 0xF;
    rb = (instruction >> 14) & 0xF;
    immediate = instruction & 0x3FFFFu;

    a = cpu->registers[ra];
    b = cpu->registers[rb];

    next_pc = cpu->pc + 4u;

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
            cpu->registers[rd] = a << (b & 31u);
            break;

        case OP_SHR:
            cpu->registers[rd] = a >> (b & 31u);
            break;

        case OP_SAR: {
            uint32_t shift = b & 31u;

            if (shift == 0) {
                result = a;
            } else if (a & 0x80000000u) {
                result = (a >> shift) |
                         (~0u << (32u - shift));
            } else {
                result = a >> shift;
            }

            cpu->registers[rd] = result;
            break;
        }

        case OP_ADDI:
            cpu->registers[rd] =
                a + (uint32_t)sign_extend_18(immediate);
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

        case OP_LDW: {
            uint32_t address =
                a + (uint32_t)sign_extend_18(immediate);

            if (!memory_read32(cpu, address, &result)) {
                return 0;
            }

            cpu->registers[rd] = result;
            break;
        }

        case OP_STW: {
            uint32_t address =
                a + (uint32_t)sign_extend_18(immediate);

            if (!memory_write32(
                    cpu,
                    address,
                    cpu->registers[rd])) {
                return 0;
            }

            break;
        }

        case OP_BEQ:
            if (a == b) {
                next_pc +=
                    (uint32_t)(sign_extend_18(immediate) * 4);
            }
            break;

        case OP_BNE:
            if (a != b) {
                next_pc +=
                    (uint32_t)(sign_extend_18(immediate) * 4);
            }
            break;

        case OP_BLT:
            if ((int32_t)a < (int32_t)b) {
                next_pc +=
                    (uint32_t)(sign_extend_18(immediate) * 4);
            }
            break;

        case OP_BGE:
            if ((int32_t)a >= (int32_t)b) {
                next_pc +=
                    (uint32_t)(sign_extend_18(immediate) * 4);
            }
            break;

        case OP_HALT:
            cpu->halted = 1;
            break;

        default:
            cpu->error = 1;
            return 0;
    }

    cpu->pc = next_pc;
    cpu->registers[0] = 0;
    cpu->cycles++;

    return 1;
}

static int cpu_run(LettuceCPU *cpu) {
    uint64_t steps = 0;

    while (!cpu->halted && !cpu->error) {
        if (steps >= MAX_STEPS) {
            cpu->error = 1;
            break;
        }

        if (!cpu_step(cpu)) {
            break;
        }

        steps++;
    }

    return cpu->halted && !cpu->error;
}

#ifndef LETTUCE_EMULATOR_NO_MAIN

int main(void) {
    LettuceCPU cpu;

    cpu_init(&cpu);

    printf("BCPU LETTUCE32 EMULATOR\n");
    printf("Memory: %u bytes\n", MEMORY_SIZE);
    printf("Registers: %d\n", REGISTER_COUNT);
    printf("Maximum steps: %u\n", MAX_STEPS);
    printf("Emulator initialized successfully.\n");
    printf("Waiting for a Lettuce32 program.\n");

    return 0;
}

#endif
