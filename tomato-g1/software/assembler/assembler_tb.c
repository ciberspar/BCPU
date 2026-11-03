#define LETTUCE_ASSEMBLER_NO_MAIN
#include "lettuce_assembler.c"

#include <stdio.h>
#include <stdint.h>
#include <string.h>

static int passed = 0;
static int failed = 0;

static void check(
    const char *name,
    const char *source,
    uint32_t expected
) {
    uint32_t result = 0;
    char error[128];

    int status = lettuce_assemble_line(
        source,
        &result,
        error,
        sizeof(error)
    );

    if (status == 0 && result == expected) {
        printf("PASS: %s\n", name);
        passed++;
    } else {
        printf("FAIL: %s\n", name);
        printf("  Expected: %08X\n", expected);
        printf("  Received: %08X\n", result);

        if (status != 0) {
            printf("  Error: %s\n", error);
        }

        failed++;
    }
}

static void check_error(
    const char *name,
    const char *source
) {
    uint32_t result = 0;
    char error[128];

    int status = lettuce_assemble_line(
        source,
        &result,
        error,
        sizeof(error)
    );

    if (status == -1) {
        printf("PASS: %s\n", name);
        passed++;
    } else {
        printf("FAIL: %s\n", name);
        failed++;
    }
}

static void check_empty(
    const char *name,
    const char *source
) {
    uint32_t result = 0;
    char error[128];

    int status = lettuce_assemble_line(
        source,
        &result,
        error,
        sizeof(error)
    );

    if (status == LETTUCE_ASM_EMPTY) {
        printf("PASS: %s\n", name);
        passed++;
    } else {
        printf("FAIL: %s\n", name);
        failed++;
    }
}

int main(void) {
    printf("BCPU LETTUCE32 ASSEMBLER TESTS\n\n");

    check("NOP", "NOP", 0x00000000);
    check("HALT", "HALT", 0x7C000000);

    check("ADD", "ADD R3, R1, R2", 0x04C48000);
    check("SUB", "SUB R2, R1, R2", 0x08848000);
    check("MUL", "MUL R3, R1, R2", 0x0CC48000);

    check("AND", "AND R3, R1, R2", 0x14C48000);
    check("OR", "OR R3, R1, R2", 0x18C48000);
    check("XOR", "XOR R3, R1, R2", 0x1CC48000);

    check("NOT", "NOT R2, R1", 0x20840000);

    check("SHL", "SHL R3, R1, R2", 0x24C48000);
    check("SHR", "SHR R3, R1, R2", 0x28C48000);
    check("SAR", "SAR R3, R1, R2", 0x2CC48000);

    check("ADDI", "ADDI R1, R0, 10", 0x3040000A);
    check("ADDI negative", "ADDI R2, R1, -1", 0x3087FFFF);

    check("ANDI", "ANDI R3, R1, 15", 0x34C4000F);
    check("ORI", "ORI R3, R1, 15", 0x38C4000F);
    check("XORI", "XORI R3, R1, 15", 0x3CC4000F);

    check("LDW", "LDW R3, R1, 4", 0x44C40004);
    check("STW", "STW R2, R1, 0", 0x48840000);

    check(
        "Lowercase accepted",
        "addi r1, r0, 10",
        0x3040000A
    );

    check_empty("Comment ignored", "# this is a comment");
    check_empty("Empty line ignored", "   ");

    check_error("R16 rejected", "ADD R16, R1, R2");
    check_error("Invalid register rejected", "ADD RX, R1, R2");
    check_error("Immediate overflow rejected", "ADDI R1, R0, 200000");
    check_error("Missing operand rejected", "ADD R1, R2");
    check_error("Unknown opcode rejected", "DIVU R1, R2, R3");

    check_error("Branch not yet supported", "BEQ R1, R2, 4");

    printf("\nPASSED: %d\n", passed);
    printf("FAILED: %d\n", failed);

    if (failed == 0) {
        printf("\nALL LETTUCE32 ASSEMBLER TESTS PASSED!\n");
        return 0;
    }

    printf("\nLET TUCE32 ASSEMBLER TESTS FAILED!\n");
    return 1;
}