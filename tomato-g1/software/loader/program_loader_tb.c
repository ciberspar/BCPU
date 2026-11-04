
#include <stdio.h>
#include <stdint.h>
#include <string.h>

#include "program_loader.h"

#define TEST_MEMORY_SIZE 256

static int passed = 0;
static int failed = 0;

static void check(const char *name, int condition)
{
    if (condition) {
        printf("PASS: %s\n", name);
        passed++;
    } else {
        printf("FAIL: %s\n", name);
        failed++;
    }
}

static void write_u32_le(uint8_t *data, uint32_t value)
{
    data[0] = (uint8_t)value;
    data[1] = (uint8_t)(value >> 8);
    data[2] = (uint8_t)(value >> 16);
    data[3] = (uint8_t)(value >> 24);
}

static void create_program(uint8_t *data)
{
    memset(data, 0, 28);

    write_u32_le(data, LETTUCE_PROGRAM_MAGIC);
    write_u32_le(data + 4, LETTUCE_PROGRAM_VERSION);
    write_u32_le(data + 8, 0);
    write_u32_le(data + 12, 8);
    write_u32_le(data + 16, LETTUCE_PROGRAM_FLAG_NONE);

    /* Programa de prueba: NOP y HALT */
    write_u32_le(data + 20, 0x00000000);
    write_u32_le(data + 24, 0x7C000000);
}

int main(void)
{
    uint8_t data[28];
    uint8_t memory[TEST_MEMORY_SIZE];
    LettuceLoadedProgram program;

    printf("LETTUCE32 PROGRAM LOADER TESTS\n");

    create_program(data);
    memset(memory, 0xAA, sizeof(memory));

    check(
        "Valid program accepted",
        lettuce_program_validate(
            data, sizeof(data), sizeof(memory), &program
        ) == LETTUCE_LOADER_OK
    );

    check(
        "Entry point",
        program.entry_point == 0
    );

    check(
        "Code size",
        program.code_size == 8
    );

    check(
        "Instruction count",
        program.instruction_count == 2
    );

    check(
        "Program loaded",
        lettuce_program_load(
            data, sizeof(data), memory, sizeof(memory), &program
        ) == LETTUCE_LOADER_OK
    );

    check(
        "First instruction copied",
        memory[0] == 0x00 &&
        memory[1] == 0x00 &&
        memory[2] == 0x00 &&
        memory[3] == 0x00
    );

    check(
        "Second instruction copied",
        memory[4] == 0x00 &&
        memory[5] == 0x00 &&
        memory[6] == 0x00 &&
        memory[7] == 0x7C
    );

    check(
        "Memory after program unchanged",
        memory[8] == 0xAA
    );

    data[0] ^= 0xFF;

    check(
        "Invalid magic rejected",
        lettuce_program_validate(
            data, sizeof(data), sizeof(memory), &program
        ) == LETTUCE_LOADER_INVALID_MAGIC
    );

    create_program(data);
    write_u32_le(data + 4, 99);

    check(
        "Invalid version rejected",
        lettuce_program_validate(
            data, sizeof(data), sizeof(memory), &program
        ) == LETTUCE_LOADER_INVALID_VERSION
    );

    create_program(data);
    write_u32_le(data + 12, 0);

    check(
        "Empty program rejected",
        lettuce_program_validate(
            data, sizeof(data), sizeof(memory), &program
        ) == LETTUCE_LOADER_INVALID_SIZE
    );

    create_program(data);
    write_u32_le(data + 12, 7);

    check(
        "Unaligned code size rejected",
        lettuce_program_validate(
            data, sizeof(data), sizeof(memory), &program
        ) == LETTUCE_LOADER_INVALID_SIZE
    );

    create_program(data);
    write_u32_le(data + 8, 2);

    check(
        "Unaligned entry rejected",
        lettuce_program_validate(
            data, sizeof(data), sizeof(memory), &program
        ) == LETTUCE_LOADER_INVALID_ENTRY
    );

    create_program(data);
    write_u32_le(data + 8, 8);

    check(
        "Entry outside code rejected",
        lettuce_program_validate(
            data, sizeof(data), sizeof(memory), &program
        ) == LETTUCE_LOADER_INVALID_ENTRY
    );

    create_program(data);

    check(
        "Truncated program rejected",
        lettuce_program_validate(
            data, sizeof(data) - 1, sizeof(memory), &program
        ) == LETTUCE_LOADER_INVALID_SIZE
    );

    check(
        "Memory overflow rejected",
        lettuce_program_validate(
            data, sizeof(data), 4, &program
        ) == LETTUCE_LOADER_MEMORY_OVERFLOW
    );

    check(
        "Null input rejected",
        lettuce_program_validate(
            NULL, sizeof(data), sizeof(memory), &program
        ) == LETTUCE_LOADER_ERROR
    );

    check(
        "Null memory rejected",
        lettuce_program_load(
            data, sizeof(data), NULL, sizeof(memory), &program
        ) == LETTUCE_LOADER_ERROR
    );

    printf("\nPASSED: %d\n", passed);
    printf("FAILED: %d\n", failed);

    if (failed == 0) {
        printf("ALL PROGRAM LOADER TESTS PASSED!\n");
        return 0;
    }

    return 1;
}
