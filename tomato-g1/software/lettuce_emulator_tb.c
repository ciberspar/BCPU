
#include <stdio.h>
#include <stdint.h>

#include "lettuce_emulator.h"

static unsigned passed = 0;
static unsigned failed = 0;

static void check(const char *name, int condition) {
    if (condition) {
        printf("[PASS] %s\n", name);
        passed++;
    } else {
        printf("[FAIL] %s\n", name);
        failed++;
    }
}

static uint32_t encode_rrr(
    uint32_t opcode,
    uint32_t rd,
    uint32_t ra,
    uint32_t rb
) {
    return (opcode << 26) |
           ((rd & 0xFu) << 22) |
           ((ra & 0xFu) << 18) |
           ((rb & 0xFu) << 14);
}

static uint32_t encode_not(uint32_t rd, uint32_t ra) {
    return (8u << 26) |
           ((rd & 0xFu) << 22) |
           ((ra & 0xFu) << 18);
}

static uint32_t encode_rri(
    uint32_t opcode,
    uint32_t rd,
    uint32_t ra,
    int32_t immediate
) {
    return (opcode << 26) |
           ((rd & 0xFu) << 22) |
           ((ra & 0xFu) << 18) |
           ((uint32_t)immediate & 0x3FFFFu);
}

static uint32_t encode_memory(
    uint32_t opcode,
    uint32_t reg,
    uint32_t base,
    int32_t offset
) {
    return (opcode << 26) |
           ((reg & 0xFu) << 22) |
           ((base & 0xFu) << 18) |
           ((uint32_t)offset & 0x3FFFFu);
}

static void write_instruction(
    LettuceCPU *cpu,
    uint32_t address,
    uint32_t instruction
) {
    cpu->memory[address] = (uint8_t)instruction;
    cpu->memory[address + 1] = (uint8_t)(instruction >> 8);
    cpu->memory[address + 2] = (uint8_t)(instruction >> 16);
    cpu->memory[address + 3] = (uint8_t)(instruction >> 24);
}

static void test_alu(void) {
    LettuceCPU cpu;

    lettuce_cpu_init(&cpu);

    cpu.registers[1] = 20;
    cpu.registers[2] = 5;

    write_instruction(&cpu, 0, encode_rrr(1, 3, 1, 2));
    check("ADD executes", lettuce_cpu_step(&cpu) == LETTUCE_CPU_OK);
    check("ADD result", cpu.registers[3] == 25);

    lettuce_cpu_init(&cpu);
    cpu.registers[1] = 20;
    cpu.registers[2] = 5;
    write_instruction(&cpu, 0, encode_rrr(2, 3, 1, 2));
    lettuce_cpu_step(&cpu);
    check("SUB result", cpu.registers[3] == 15);

    lettuce_cpu_init(&cpu);
    cpu.registers[1] = 7;
    cpu.registers[2] = 6;
    write_instruction(&cpu, 0, encode_rrr(3, 3, 1, 2));
    lettuce_cpu_step(&cpu);
    check("MUL result", cpu.registers[3] == 42);

    lettuce_cpu_init(&cpu);
    cpu.registers[1] = 0xF0u;
    cpu.registers[2] = 0x0Fu;
    write_instruction(&cpu, 0, encode_rrr(5, 3, 1, 2));
    lettuce_cpu_step(&cpu);
    check("AND result", cpu.registers[3] == 0);

    lettuce_cpu_init(&cpu);
    cpu.registers[1] = 0xF0u;
    cpu.registers[2] = 0x0Fu;
    write_instruction(&cpu, 0, encode_rrr(6, 3, 1, 2));
    lettuce_cpu_step(&cpu);
    check("OR result", cpu.registers[3] == 0xFFu);

    lettuce_cpu_init(&cpu);
    cpu.registers[1] = 0xAAu;
    cpu.registers[2] = 0x0Fu;
    write_instruction(&cpu, 0, encode_rrr(7, 3, 1, 2));
    lettuce_cpu_step(&cpu);
    check("XOR result", cpu.registers[3] == 0xA5u);

    lettuce_cpu_init(&cpu);
    cpu.registers[1] = 0x0000000Fu;
    write_instruction(&cpu, 0, encode_not(3, 1));
    lettuce_cpu_step(&cpu);
    check("NOT result", cpu.registers[3] == 0xFFFFFFF0u);

    lettuce_cpu_init(&cpu);
    cpu.registers[1] = 3;
    cpu.registers[2] = 2;
    write_instruction(&cpu, 0, encode_rrr(9, 3, 1, 2));
    lettuce_cpu_step(&cpu);
    check("SHL result", cpu.registers[3] == 12);

    lettuce_cpu_init(&cpu);
    cpu.registers[1] = 32;
    cpu.registers[2] = 2;
    write_instruction(&cpu, 0, encode_rrr(10, 3, 1, 2));
    lettuce_cpu_step(&cpu);
    check("SHR result", cpu.registers[3] == 8);

    lettuce_cpu_init(&cpu);
    cpu.registers[1] = 0xFFFFFFF0u;
    cpu.registers[2] = 2;
    write_instruction(&cpu, 0, encode_rrr(11, 3, 1, 2));
    lettuce_cpu_step(&cpu);
    check("SAR result", cpu.registers[3] == 0xFFFFFFFCu);
}

static void test_immediate(void) {
    LettuceCPU cpu;

    lettuce_cpu_init(&cpu);
    cpu.registers[1] = 10;
    write_instruction(&cpu, 0, encode_rri(12, 2, 1, 7));
    lettuce_cpu_step(&cpu);
    check("ADDI positive immediate", cpu.registers[2] == 17);

    lettuce_cpu_init(&cpu);
    cpu.registers[1] = 10;
    write_instruction(&cpu, 0, encode_rri(12, 2, 1, -3));
    lettuce_cpu_step(&cpu);
    check("ADDI negative immediate", cpu.registers[2] == 7);

    lettuce_cpu_init(&cpu);
    cpu.registers[1] = 0xFFu;
    write_instruction(&cpu, 0, encode_rri(13, 2, 1, 0x0F));
    lettuce_cpu_step(&cpu);
    check("ANDI result", cpu.registers[2] == 0x0Fu);

    lettuce_cpu_init(&cpu);
    cpu.registers[1] = 0xF0u;
    write_instruction(&cpu, 0, encode_rri(14, 2, 1, 0x0F));
    lettuce_cpu_step(&cpu);
    check("ORI result", cpu.registers[2] == 0xFFu);

    lettuce_cpu_init(&cpu);
    cpu.registers[1] = 0xFFu;
    write_instruction(&cpu, 0, encode_rri(15, 2, 1, 0x0F));
    lettuce_cpu_step(&cpu);
    check("XORI result", cpu.registers[2] == 0xF0u);
}

static void test_memory(void) {
    LettuceCPU cpu;

    lettuce_cpu_init(&cpu);

    cpu.registers[1] = 256;
    cpu.registers[2] = 0x12345678u;

    write_instruction(&cpu, 0, encode_memory(18, 2, 1, 4));
    write_instruction(&cpu, 4, encode_memory(17, 3, 1, 4));

    check(
        "STW executes",
        lettuce_cpu_step(&cpu) == LETTUCE_CPU_OK
    );

    check(
        "STW writes memory",
        cpu.memory[260] == 0x78 &&
        cpu.memory[261] == 0x56 &&
        cpu.memory[262] == 0x34 &&
        cpu.memory[263] == 0x12
    );

    check(
        "LDW executes",
        lettuce_cpu_step(&cpu) == LETTUCE_CPU_OK
    );

    check(
        "LDW reads correct value",
        cpu.registers[3] == 0x12345678u
    );

    lettuce_cpu_init(&cpu);
    cpu.registers[1] = 257;
    write_instruction(&cpu, 0, encode_memory(17, 2, 1, 0));

    check(
        "Unaligned memory access rejected",
        lettuce_cpu_step(&cpu) == LETTUCE_CPU_ERROR
    );

    check(
        "Memory error recorded",
        lettuce_cpu_has_error(&cpu)
    );

    lettuce_cpu_init(&cpu);
    cpu.registers[1] = LETTUCE_MEMORY_SIZE - 4u;
    write_instruction(&cpu, 0, encode_memory(17, 2, 1, 4));

    check(
        "Out-of-range memory access rejected",
        lettuce_cpu_step(&cpu) == LETTUCE_CPU_ERROR
    );
}

static void test_cpu_control(void) {
    LettuceCPU cpu;

    check(
        "CPU initialization",
        lettuce_cpu_init(&cpu) == LETTUCE_CPU_OK
    );

    check("Initial PC is zero", cpu.pc == 0);
    check("Initial cycles are zero", cpu.cycles == 0);
    check("R0 starts at zero", cpu.registers[0] == 0);

    cpu.registers[1] = 5;
    write_instruction(&cpu, 0, encode_rri(12, 2, 1, 3));
    write_instruction(&cpu, 4, 31u << 26);

    check(
        "ADDI executes",
        lettuce_cpu_step(&cpu) == LETTUCE_CPU_OK
    );

    check("ADDI calculates correctly", cpu.registers[2] == 8);
    check("PC advances four bytes", cpu.pc == 4);
    check("Cycle counter increments", cpu.cycles == 1);

    check(
        "HALT executes",
        lettuce_cpu_step(&cpu) == LETTUCE_CPU_HALTED
    );

    check("CPU reports halted", lettuce_cpu_is_halted(&cpu));

    check(
        "CPU stays halted",
        lettuce_cpu_step(&cpu) == LETTUCE_CPU_HALTED &&
        cpu.cycles == 2
    );

    lettuce_cpu_init(&cpu);
    write_instruction(&cpu, 0, encode_rri(12, 0, 0, 99));
    lettuce_cpu_step(&cpu);
    check("R0 remains hardwired to zero", cpu.registers[0] == 0);

    lettuce_cpu_init(&cpu);
    write_instruction(&cpu, 0, 0u);
    write_instruction(&cpu, 4, 0u);

    check(
        "Execution step limit",
        lettuce_cpu_run(&cpu, 1) == LETTUCE_CPU_STEP_LIMIT
    );

    check(
        "Step limit preserves state",
        cpu.cycles == 1 && cpu.pc == 4
    );

    lettuce_cpu_init(&cpu);
    cpu.pc = LETTUCE_MEMORY_SIZE;

    check(
        "Invalid instruction address detected",
        lettuce_cpu_step(&cpu) == LETTUCE_CPU_ERROR
    );

    check("CPU records execution error", lettuce_cpu_has_error(&cpu));

    lettuce_cpu_init(&cpu);
    write_instruction(&cpu, 0, 63u << 26);

    check(
        "Unknown opcode rejected",
        lettuce_cpu_step(&cpu) == LETTUCE_CPU_ERROR
    );

    check(
        "Null CPU rejected",
        lettuce_cpu_init(NULL) == LETTUCE_CPU_ERROR
    );
}

int main(void) {
    printf("BCPU TOMATO G1 - LETTUCE32 EMULATOR TESTS\n\n");

    test_alu();
    test_immediate();
    test_memory();
    test_cpu_control();

    printf("\n================================\n");
    printf("LETTUCE EMULATOR TEST RESULTS\n");
    printf("Passed: %u\n", passed);
    printf("Failed: %u\n", failed);
    printf("================================\n");

    return failed == 0 ? 0 : 1;
}
