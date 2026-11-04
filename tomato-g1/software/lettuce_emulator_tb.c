
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

static uint32_t encode_addi(
    uint32_t rd,
    uint32_t ra,
    int32_t immediate
) {
    return (12u << 26) |
           ((rd & 0xFu) << 22) |
           ((ra & 0xFu) << 18) |
           ((uint32_t)immediate & 0x3FFFFu);
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

int main(void) {
    LettuceCPU cpu;

    check(
        "CPU initialization",
        lettuce_cpu_init(&cpu) == LETTUCE_CPU_OK
    );

    check(
        "Initial PC is zero",
        cpu.pc == 0
    );

    check(
        "Initial cycle counter is zero",
        cpu.cycles == 0
    );

    check(
        "Register zero starts at zero",
        cpu.registers[0] == 0
    );

    /* ADDI R2, R1, 3 */
    cpu.registers[1] = 5;
    write_instruction(
        &cpu,
        0,
        encode_addi(2, 1, 3)
    );

    /* HALT */
    write_instruction(
        &cpu,
        4,
        31u << 26
    );

    check(
        "Execute ADDI instruction",
        lettuce_cpu_step(&cpu) == LETTUCE_CPU_OK
    );

    check(
        "ADDI calculates correct result",
        cpu.registers[2] == 8
    );

    check(
        "PC advances by four bytes",
        cpu.pc == 4
    );

    check(
        "Cycle counter increments",
        cpu.cycles == 1
    );

    check(
        "Execute HALT instruction",
        lettuce_cpu_step(&cpu) == LETTUCE_CPU_HALTED
    );

    check(
        "CPU reports halted state",
        lettuce_cpu_is_halted(&cpu)
    );

    check(
        "CPU does not execute after HALT",
        lettuce_cpu_step(&cpu) == LETTUCE_CPU_HALTED &&
        cpu.cycles == 2
    );

    /* Test de límite de ejecución. */
    lettuce_cpu_init(&cpu);

    write_instruction(&cpu, 0, 0u);
    write_instruction(&cpu, 4, 0u);
    write_instruction(&cpu, 8, 0u);

    check(
        "Execution step limit",
        lettuce_cpu_run(&cpu, 1) == LETTUCE_CPU_STEP_LIMIT
    );

    check(
        "Step limit preserves CPU state",
        cpu.cycles == 1 && cpu.pc == 4
    );

    /* Test de dirección de instrucción inválida. */
    lettuce_cpu_init(&cpu);
    cpu.pc = LETTUCE_MEMORY_SIZE;

    check(
        "Invalid instruction address detected",
        lettuce_cpu_step(&cpu) == LETTUCE_CPU_ERROR
    );

    check(
        "CPU records execution error",
        lettuce_cpu_has_error(&cpu)
    );

    check(
        "Null CPU rejected",
        lettuce_cpu_init(NULL) == LETTUCE_CPU_ERROR
    );

    printf("\n================================\n");
    printf("LETTUCE EMULATOR TEST RESULTS\n");
    printf("Passed: %u\n", passed);
    printf("Failed: %u\n", failed);
    printf("================================\n");

    return failed == 0 ? 0 : 1;
}
