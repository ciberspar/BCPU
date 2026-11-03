#include "lettuce_assembler.h"

#include <ctype.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifndef LETTUCE_ASSEMBLER_NO_MAIN
#define LETTUCE_ASSEMBLER_HAS_MAIN
#endif

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
#define OP_HALT  31

#define MAX_OPERANDS 4
#define IMMEDIATE_MIN (-131072)
#define IMMEDIATE_MAX 131071

typedef struct {
    const char *name;
    unsigned int opcode;
    int type;
} Instruction;

enum {
    TYPE_NONE,
    TYPE_RRR,
    TYPE_RRI,
    TYPE_MEMORY,
    TYPE_NOT
};

static const Instruction instructions[] = {
    {"NOP",  OP_NOP,  TYPE_NONE},
    {"HALT", OP_HALT, TYPE_NONE},

    {"ADD",  OP_ADD,  TYPE_RRR},
    {"SUB",  OP_SUB,  TYPE_RRR},
    {"MUL",  OP_MUL,  TYPE_RRR},
    {"AND",  OP_AND,  TYPE_RRR},
    {"OR",   OP_OR,   TYPE_RRR},
    {"XOR",  OP_XOR,  TYPE_RRR},
    {"SHL",  OP_SHL,  TYPE_RRR},
    {"SHR",  OP_SHR,  TYPE_RRR},
    {"SAR",  OP_SAR,  TYPE_RRR},

    {"NOT",  OP_NOT,  TYPE_NOT},

    {"ADDI", OP_ADDI, TYPE_RRI},
    {"ANDI", OP_ANDI, TYPE_RRI},
    {"ORI",  OP_ORI,  TYPE_RRI},
    {"XORI", OP_XORI, TYPE_RRI},

    {"LDW",  OP_LDW,  TYPE_MEMORY},
    {"STW",  OP_STW,  TYPE_MEMORY}
};

static void set_error(
    char *buffer,
    size_t size,
    const char *message
) {
    if (buffer != NULL && size > 0) {
        snprintf(buffer, size, "%s", message);
    }
}

static void uppercase(char *text) {
    while (*text != '\0') {
        *text = (char)toupper((unsigned char)*text);
        text++;
    }
}

static char *trim(char *text) {
    while (isspace((unsigned char)*text)) {
        text++;
    }

    char *end = text + strlen(text);

    while (end > text && isspace((unsigned char)end[-1])) {
        end--;
    }

    *end = '\0';
    return text;
}

static int parse_register(const char *text, unsigned int *reg) {
    if (text == NULL || reg == NULL) {
        return 0;
    }

    if (toupper((unsigned char)text[0]) != 'R') {
        return 0;
    }

    if (text[1] == '\0') {
        return 0;
    }

    errno = 0;

    char *end = NULL;
    long value = strtol(text + 1, &end, 10);

    if (errno != 0 || end == text + 1 || *end != '\0') {
        return 0;
    }

    if (value < 0 || value > 15) {
        return 0;
    }

    *reg = (unsigned int)value;
    return 1;
}

static int parse_immediate(const char *text, int *value) {
    if (text == NULL || value == NULL || *text == '\0') {
        return 0;
    }

    errno = 0;

    char *end = NULL;
    long parsed = strtol(text, &end, 0);

    if (errno != 0 || end == text || *end != '\0') {
        return 0;
    }

    if (parsed < IMMEDIATE_MIN || parsed > IMMEDIATE_MAX) {
        return 0;
    }

    *value = (int)parsed;
    return 1;
}

static const Instruction *find_instruction(const char *name) {
    size_t count = sizeof(instructions) / sizeof(instructions[0]);

    for (size_t i = 0; i < count; i++) {
        if (strcmp(name, instructions[i].name) == 0) {
            return &instructions[i];
        }
    }

    return NULL;
}

static int split_operands(
    char *text,
    char *operands[],
    int maximum
) {
    int count = 0;
    char *start = text;

    while (1) {
        char *comma = strchr(start, ',');

        if (comma != NULL) {
            *comma = '\0';
        }

        char *operand = trim(start);

        if (*operand == '\0') {
            return -1;
        }

        if (count >= maximum) {
            return -1;
        }

        operands[count++] = operand;

        if (comma == NULL) {
            break;
        }

        start = comma + 1;
    }

    return count;
}

int lettuce_assemble_line(
    const char *source,
    uint32_t *instruction,
    char *error_buffer,
    size_t error_buffer_size
) {
    if (source == NULL || instruction == NULL) {
        set_error(error_buffer, error_buffer_size, "Invalid input");
        return -1;
    }

    char line[256];

    size_t length = strlen(source);

    if (length >= sizeof(line)) {
        set_error(error_buffer, error_buffer_size, "Line too long");
        return -1;
    }

    memcpy(line, source, length + 1);

    char *comment = strpbrk(line, "#;");

    if (comment != NULL) {
        *comment = '\0';
    }

    char *content = trim(line);

    if (*content == '\0') {
        return LETTUCE_ASM_EMPTY;
    }

    char *separator = content;

    while (*separator != '\0' &&
           !isspace((unsigned char)*separator)) {
        separator++;
    }

    char *operand_text = separator;

    if (*separator != '\0') {
        *separator = '\0';
        operand_text = trim(separator + 1);
    }

    uppercase(content);

    const Instruction *info = find_instruction(content);

    if (info == NULL) {
        set_error(
            error_buffer,
            error_buffer_size,
            "Unknown or unsupported instruction"
        );
        return -1;
    }

    char *operands[MAX_OPERANDS];
    int operand_count = 0;

    if (*operand_text != '\0') {
        operand_count = split_operands(
            operand_text,
            operands,
            MAX_OPERANDS
        );

        if (operand_count < 0) {
            set_error(
                error_buffer,
                error_buffer_size,
                "Invalid operand list"
            );
            return -1;
        }
    }

    unsigned int rd = 0;
    unsigned int ra = 0;
    unsigned int rb = 0;
    int immediate = 0;

    uint32_t encoded = info->opcode << 26;

    switch (info->type) {
        case TYPE_NONE:
            if (operand_count != 0) {
                set_error(
                    error_buffer,
                    error_buffer_size,
                    "Instruction takes no operands"
                );
                return -1;
            }
            break;

        case TYPE_RRR:
            if (operand_count != 3) {
                set_error(
                    error_buffer,
                    error_buffer_size,
                    "Expected: RD, RA, RB"
                );
                return -1;
            }

            if (!parse_register(operands[0], &rd) ||
                !parse_register(operands[1], &ra) ||
                !parse_register(operands[2], &rb)) {
                set_error(
                    error_buffer,
                    error_buffer_size,
                    "Invalid register. Use R0 through R15"
                );
                return -1;
            }

            encoded |= rd << 22;
            encoded |= ra << 18;
            encoded |= rb << 14;
            break;

        case TYPE_NOT:
            if (operand_count != 2) {
                set_error(
                    error_buffer,
                    error_buffer_size,
                    "Expected: RD, RA"
                );
                return -1;
            }

            if (!parse_register(operands[0], &rd) ||
                !parse_register(operands[1], &ra)) {
                set_error(
                    error_buffer,
                    error_buffer_size,
                    "Invalid register. Use R0 through R15"
                );
                return -1;
            }

            encoded |= rd << 22;
            encoded |= ra << 18;
            break;

        case TYPE_RRI:
            if (operand_count != 3) {
                set_error(
                    error_buffer,
                    error_buffer_size,
                    "Expected: RD, RA, IMMEDIATE"
                );
                return -1;
            }

            if (!parse_register(operands[0], &rd) ||
                !parse_register(operands[1], &ra)) {
                set_error(
                    error_buffer,
                    error_buffer_size,
                    "Invalid register. Use R0 through R15"
                );
                return -1;
            }

            if (!parse_immediate(operands[2], &immediate)) {
                set_error(
                    error_buffer,
                    error_buffer_size,
                    "Immediate outside signed 18-bit range"
                );
                return -1;
            }

            encoded |= rd << 22;
            encoded |= ra << 18;
            encoded |= (uint32_t)immediate & 0x3FFFF;
            break;

        case TYPE_MEMORY:
            if (operand_count != 3) {
                set_error(
                    error_buffer,
                    error_buffer_size,
                    "Expected: REGISTER, BASE, OFFSET"
                );
                return -1;
            }

            if (!parse_register(operands[0], &rd) ||
                !parse_register(operands[1], &ra)) {
                set_error(
                    error_buffer,
                    error_buffer_size,
                    "Invalid register. Use R0 through R15"
                );
                return -1;
            }

            if (!parse_immediate(operands[2], &immediate)) {
                set_error(
                    error_buffer,
                    error_buffer_size,
                    "Invalid memory offset"
                );
                return -1;
            }

            encoded |= rd << 22;
            encoded |= ra << 18;
            encoded |= (uint32_t)immediate & 0x3FFFF;
            break;

        default:
            set_error(
                error_buffer,
                error_buffer_size,
                "Internal assembler error"
            );
            return -1;
    }

    *instruction = encoded;

    if (error_buffer != NULL && error_buffer_size > 0) {
        error_buffer[0] = '\0';
    }

    return 0;
}

#ifdef LETTUCE_ASSEMBLER_HAS_MAIN

int main(void) {
    char line[256];
    char error[128];

    unsigned long line_number = 0;

    printf("BCPU LETTUCE32 ASSEMBLER\n");
    printf("Enter instructions. Press Ctrl+D to finish.\n\n");

    while (fgets(line, sizeof(line), stdin) != NULL) {
        line_number++;

        uint32_t machine_code = 0;

        int result = lettuce_assemble_line(
            line,
            &machine_code,
            error,
            sizeof(error)
        );

        if (result == LETTUCE_ASM_EMPTY) {
            continue;
        }

        if (result != 0) {
            fprintf(
                stderr,
                "Line %lu: %s\n",
                line_number,
                error
            );
            return 1;
        }

        printf("%08X\n", machine_code);
    }

    return 0;
}

#endif