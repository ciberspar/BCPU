#include "lettuce_emulator.h"

#include <stdint.h>
#include <string.h>

#define MEMORY_SIZE LETTUCE_MEMORY_SIZE
#define REGISTER_COUNT LETTUCE_REGISTER_COUNT

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

static int memory_read32(
LettuceCPU *cpu,
uint32_t address,
uint32_t *value
) {
if (cpu == NULL || value == NULL ||
(address & 3u) != 0 ||
address > MEMORY_SIZE - 4u) {
if (cpu != NULL) {
cpu->error = 1;
}
return 0;
}

*value =
    (uint32_t)cpu->memory[address] |
    ((uint32_t)cpu->memory[address + 1] << 8) |
    ((uint32_t)cpu->memory[address + 2] << 16) |
    ((uint32_t)cpu->memory[address + 3] << 24);
return 1;

}

static int memory_write32(
LettuceCPU *cpu,
uint32_t address,
uint32_t value
) {
if (cpu == NULL ||
(address & 3u) != 0 ||
address > MEMORY_SIZE - 4u) {
if (cpu != NULL) {
cpu->error = 1;
}
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
int is_branch;
if (cpu == NULL || cpu->halted || cpu->error) {
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
is_branch =
    opcode == OP_BEQ ||
    opcode == OP_BNE ||
    opcode == OP_BLT ||
    opcode == OP_BGE;
// Branch format:
// RD = first source register
// RA = second source register
// IMM = signed 18-bit displacement
if (is_branch) {
    a = cpu->registers[rd];
    b = cpu->registers[ra];
} else {
    a = cpu->registers[ra];
    b = cpu->registers[rb];
}
next_pc = cpu->pc + 4u;
switch (opcode) {
    case OP_NOP:
        break;
    case OP_ADD:
        cpu->registers[rd] = a + b;
        break;
    case OP_SUB:
        cpu->registers[rd] = a - b;
        break;
    case OP_MUL:
        cpu->registers[rd] = a * b;
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

/* API pública */

int lettuce_cpu_init(LettuceCPU *cpu) {
if (cpu == NULL) {
return LETTUCE_CPU_ERROR;
}

cpu_init(cpu);
return LETTUCE_CPU_OK;

}

int lettuce_cpu_step(LettuceCPU *cpu) {
if (cpu == NULL) {
return LETTUCE_CPU_ERROR;
}

if (cpu->error) {
    return LETTUCE_CPU_ERROR;
}
if (cpu->halted) {
    return LETTUCE_CPU_HALTED;
}
if (!cpu_step(cpu)) {
    return LETTUCE_CPU_ERROR;
}
return cpu->halted
    ? LETTUCE_CPU_HALTED
    : LETTUCE_CPU_OK;

}

int lettuce_cpu_run(
LettuceCPU *cpu,
uint64_t max_steps
) {
uint64_t steps = 0;

if (cpu == NULL) {
    return LETTUCE_CPU_ERROR;
}
if (cpu->error) {
    return LETTUCE_CPU_ERROR;
}
if (cpu->halted) {
    return LETTUCE_CPU_HALTED;
}
if (max_steps == 0) {
    max_steps = MAX_STEPS;
}
while (!cpu->halted && !cpu->error) {
    if (steps >= max_steps) {
        return LETTUCE_CPU_STEP_LIMIT;
    }
    if (!cpu_step(cpu)) {
        return LETTUCE_CPU_ERROR;
    }
    steps++;
}
return cpu->error
    ? LETTUCE_CPU_ERROR
    : LETTUCE_CPU_HALTED;

}

int lettuce_cpu_is_halted(const LettuceCPU *cpu) {
return cpu != NULL && cpu->halted;
}

int lettuce_cpu_has_error(const LettuceCPU *cpu) {
return cpu == NULL || cpu->error;
}

/* Compatibilidad con los tests anteriores. */

static int cpu_run(LettuceCPU *cpu) {
return lettuce_cpu_run(cpu, MAX_STEPS)
== LETTUCE_CPU_HALTED;
}

#ifndef LETTUCE_EMULATOR_NO_MAIN

#include <stdio.h>

int main(void) {
LettuceCPU cpu;

if (lettuce_cpu_init(&cpu) != LETTUCE_CPU_OK) {
    return 1;
}
printf("BCPU LETTUCE32 EMULATOR\n");
printf("Memory: %u bytes\n", MEMORY_SIZE);
printf("Registers: %u\n", REGISTER_COUNT);
printf("Maximum steps: %u\n", MAX_STEPS);
printf("Emulator initialized successfully.\n");
printf("Waiting for a Lettuce32 program.\n");
return 0;

}

#endif