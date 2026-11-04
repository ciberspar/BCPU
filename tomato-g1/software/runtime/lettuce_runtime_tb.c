
#include <stdio.h>
#include <stdint.h>
#include <string.h>

#include "lettuce_runtime.h"

#define TEST_MEMORY_SIZE 1024u
#define TEST_PROGRAM_SIZE 24u

static unsigned tests_passed = 0;
static unsigned tests_failed = 0;

static void check(const char *name, int condition) {
    if (condition) {
        printf("[PASS] %s\n", name);
        tests_passed++;
    } else {
        printf("[FAIL] %s\n", name);
        tests_failed++;
    }
}

static void write_u32_le(
    uint8_t *buffer,
    unsigned offset,
    uint32_t value
) {
    buffer[offset] = (uint8_t)value;
    buffer[offset + 1] = (uint8_t)(value >> 8);
    buffer[offset + 2] = (uint8_t)(value >> 16);
    buffer[offset + 3] = (uint8_t)(value >> 24);
}

static void create_test_program(uint8_t *data) {
    memset(data, 0, TEST_PROGRAM_SIZE);

    write_u32_le(data, 0, LETTUCE_PROGRAM_MAGIC);
    write_u32_le(data, 4, LETTUCE_PROGRAM_VERSION);
    write_u32_le(data, 8, 0);
    write_u32_le(data, 12, 4);
    write_u32_le(data, 16, LETTUCE_PROGRAM_FLAG_NONE);

    /* Una instrucción HALT de prueba. */
    write_u32_le(data, 20, 0x7C000000u);
}

int main(void) {
    LettuceRuntime runtime;
    uint8_t memory[TEST_MEMORY_SIZE];
    uint8_t program[TEST_PROGRAM_SIZE];

    memset(memory, 0, sizeof(memory));
    create_test_program(program);

    check(
        "Runtime initialization",
        lettuce_runtime_init(&runtime, 1000) == LETTUCE_RUNTIME_OK
    );

    check(
        "Custom cycle limit",
        runtime.max_cycles == 1000
    );

    check(
        "Program loading",
        lettuce_runtime_load(
            &runtime,
            program,
            sizeof(program),
            memory,
            sizeof(memory)
        ) == LETTUCE_RUNTIME_OK
    );

    check(
        "Program loaded state",
        runtime.program_loaded == 1
    );

    check(
        "Entry point",
        runtime.entry_point == 0
    );

    check(
        "Code size",
        runtime.code_size == 4
    );

    check(
        "Instruction count",
        runtime.instruction_count == 1
    );

    check(
        "Program copied to memory",
        memory[20] == program[20] &&
        memory[21] == program[21] &&
        memory[22] == program[22] &&
        memory[23] == program[23]
    );

    check(
        "Execution start",
        lettuce_runtime_mark_started(&runtime) == LETTUCE_RUNTIME_OK
    );

    check(
        "Execution started state",
        runtime.execution_started == 1
    );

    check(
        "Duplicate start rejected",
        lettuce_runtime_mark_started(&runtime) ==
        LETTUCE_RUNTIME_EXECUTION_ERROR
    );

    check(
        "Execution finish",
        lettuce_runtime_mark_finished(&runtime) == LETTUCE_RUNTIME_OK
    );

    check(
        "Execution finished state",
        runtime.execution_finished == 1
    );

    check(
        "Duplicate finish rejected",
        lettuce_runtime_mark_finished(&runtime) ==
        LETTUCE_RUNTIME_EXECUTION_ERROR
    );

    check(
        "Restart rejected",
        lettuce_runtime_mark_started(&runtime) ==
        LETTUCE_RUNTIME_EXECUTION_ERROR
    );

    check(
        "Null initialization rejected",
        lettuce_runtime_init(NULL, 100) == LETTUCE_RUNTIME_ERROR
    );

    check(
        "Null runtime rejected during loading",
        lettuce_runtime_load(
            NULL,
            program,
            sizeof(program),
            memory,
            sizeof(memory)
        ) == LETTUCE_RUNTIME_INVALID_PROGRAM
    );

    printf("\n================================\n");
    printf("LETTUCE RUNTIME TEST RESULTS\n");
    printf("Passed: %u\n", tests_passed);
    printf("Failed: %u\n", tests_failed);
    printf("================================\n");

    return tests_failed == 0 ? 0 : 1;
}
