
/*
 * BCPU Tomato G1
 * Lettuce32 Emulator Testbench
 *
 * Version: 0.1
 */

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Include emulator implementation. */
#include "lettuce_emulator.c"

static int passed = 0;
static int failed = 0;

static void check(
    const char *name,
    int condition
) {
    if (condition) {
        printf("PASS: %s\n", name);
        passed++;
    } else {
        printf("FAIL: %s\n", name);
        failed++;
    }
}

/* Encode a register instruction. */
static uint32_t encode_rrr(
    uint32_t opcode,
    uint32_t rd,
    uint32_t ra,
    uint32_t rb
) {
    return
        ((opcode & 0x3F) << 26) |
        ((rd & 0xF) << 22) |
        ((ra & 0xF) << 18) |
        ((rb & 0xF) << 14);
}

/* Encode an immediate instruction. */
static uint32_t encode_imm(
    uint32_t opcode,
    uint32_t rd,
    uint32_t ra,
    uint32_t immediate
) {
    return
        ((opcode & 0x3F) << 26) |
        ((rd & 0xF) << 22) |
        ((ra & 0xF) << 18) |
        (immediate & 0x3FFFF);
}

/* Write an instruction into program memory. */
static void put_instruction(
    LettuceCPU *cpu,
    uint32_t address,
    uint32_t instruction
) {
    memory_write32(cpu, address, instruction);
}

/* Test arithmetic instructions. */
static void test_arithmetic(void) {
    LettuceCPU cpu;
    cpu_init(&cpu);

    cpu.registers[1] = 10;
    cpu.registers[2] = 5;

    put_instruction(
        &cpu, 0,
        encode_rrr(OP_ADD, 3, 1, 2)
    );

    put_instruction(
        &cpu, 4,
        encode_rrr(OP_SUB, 4, 1, 2)
    );

    put_instruction(
        &cpu, 8,
        encode_rrr(OP_MUL, 5, 1, 2)
    );

    put_instruction(
        &cpu, 12,
        OP_HALT << 26
    );

    cpu_run(&cpu);

    check("ADD", cpu.registers[3] == 15);
    check("SUB", cpu.registers[4] == 5);
    check("MUL", cpu.registers[5] == 50);
    check("Arithmetic program HALT", cpu.halted);
}

/* Test immediate instructions. */
static void test_immediate(void) {
    LettuceCPU cpu;
    cpu_init(&cpu);

    cpu.registers[1] = 20;

    put_instruction(
        &cpu, 0,
        encode_imm(OP_ADDI, 2, 1, 7)
    );

    put_instruction(
        &cpu, 4,
        encode_imm(OP_ANDI, 3, 1, 15)
    );

    put_instruction(
        &cpu, 8,
        encode_imm(OP_ORI, 4, 1, 3)
    );

    put_instruction(
        &cpu, 12,
        encode_imm(OP_XORI, 5, 1, 7)
    );

    put_instruction(
        &cpu, 16,
        OP_HALT << 26
    );

    cpu_run(&cpu);

    check("ADDI", cpu.registers[2] == 27);
    check("ANDI", cpu.registers[3] == 4);
    check("ORI", cpu.registers[4] == 23);
    check("XORI", cpu.registers[5] == 19);
}

/* Test logical instructions. */
static void test_logic(void) {
    LettuceCPU cpu;
    cpu_init(&cpu);

    cpu.registers[1] = 0xF0;
    cpu.registers[2] = 0x0F;

    put_instruction(&cpu, 0,
        encode_rrr(OP_AND, 3, 1, 2));

    put_instruction(&cpu, 4,
        encode_rrr(OP_OR, 4, 1, 2));

    put_instruction(&cpu, 8,
        encode_rrr(OP_XOR, 5, 1, 2));

    put_instruction(&cpu, 12,
        encode_rrr(OP_NOT, 6, 1, 2));

    put_instruction(&cpu, 16, OP_HALT << 26);

    cpu_run(&cpu);

    check("AND", cpu.registers[3] == 0);
    check("OR", cpu.registers[4] == 0xFF);
    check("XOR", cpu.registers[5] == 0xFF);
    check("NOT", cpu.registers[6] == ~0xF0u);
}

/* Test shifts. */
static void test_shifts(void) {
    LettuceCPU cpu;
    cpu_init(&cpu);

    cpu.registers[1] = 8;
    cpu.registers[2] = 1;

    put_instruction(&cpu, 0,
        encode_rrr(OP_SHL, 3, 1, 2));

    put_instruction(&cpu, 4,
        encode_rrr(OP_SHR, 4, 1, 2));

    put_instruction(&cpu, 8, OP_HALT << 26);

    cpu_run(&cpu);

    check("SHL", cpu.registers[3] == 16);
    check("SHR", cpu.registers[4] == 4);
}

/* Test memory operations. */
static void test_memory(void) {
    LettuceCPU cpu;
    cpu_init(&cpu);

    cpu.registers[1] = 128;
    cpu.registers[2] = 0x12345678;

    put_instruction(
        &cpu, 0,
        encode_imm(OP_STW, 2, 1, 0)
    );

    put_instruction(
        &cpu, 4,
        encode_imm(OP_LDW, 3, 1, 0)
    );

    put_instruction(
        &cpu, 8,
        OP_HALT << 26
    );

    cpu_run(&cpu);

    check(
        "STW and LDW",
        cpu.registers[3] == 0x12345678
    );

    check(
        "Memory little-endian",
        cpu.memory[128] == 0x78 &&
        cpu.memory[129] == 0x56 &&
        cpu.memory[130] == 0x34 &&
        cpu.memory[131] == 0x12
    );
}

/* Test R0. */
static void test_zero_register(void) {
    LettuceCPU cpu;
    cpu_init(&cpu);

    cpu.registers[1] = 99;

    put_instruction(
        &cpu, 0,
        encode_rrr(OP_ADD, 0, 1, 1)
    );

    put_instruction(&cpu, 4, OP_HALT << 26);

    cpu_run(&cpu);

    check("R0 remains zero", cpu.registers[0] == 0);
}

/* Test signed immediate. */
static void test_negative_immediate(void) {
    LettuceCPU cpu;
    cpu_init(&cpu);

    cpu.registers[1] = 10;

    put_instruction(
        &cpu, 0,
        encode_imm(OP_ADDI, 2, 1, 0x3FFFF)
    );

    put_instruction(&cpu, 4, OP_HALT << 26);

    cpu_run(&cpu);

    check("Negative immediate", cpu.registers[2] == 9);
}

/* Test invalid opcode. */
static void test_invalid_opcode(void) {
    LettuceCPU cpu;
    cpu_init(&cpu);

    put_instruction(&cpu, 0, 63u << 26);

    cpu_run(&cpu);

    check("Invalid opcode detected", cpu.error);
}

/* Main test runner. */
int main(void) {
    printf("\n");
    printf("====================================\n");
    printf(" BCPU TOMATO G1 - LETTUCE32 TESTS\n");
    printf("====================================\n\n");

    test_arithmetic();
    test_immediate();
    test_logic();
    test_shifts();
    test_memory();
    test_zero_register();
    test_negative_immediate();
    test_invalid_opcode();

    printf("\n====================================\n");
    printf("PASSED: %d\n", passed);
    printf("FAILED: %d\n", failed);
    printf("====================================\n");

    if (failed == 0) {
        printf("ALL LETTUCE32 TESTS PASSED!\n");
        return EXIT_SUCCESS;
    }

    printf("LETTUCE32 TESTS FAILED!\n");
    return EXIT_FAILURE;
}
