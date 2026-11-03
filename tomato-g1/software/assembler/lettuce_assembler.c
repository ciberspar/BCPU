#include "lettuce_assembler.h"

#include <ctype.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef enum {
    TYPE_NONE,
    TYPE_RRR,
    TYPE_NOT,
    TYPE_RRI,
    TYPE_MEMORY
} InstructionType;

typedef struct {
    const char *name;
    uint32_t opcode;
    InstructionType type;
} Instruction;

static const Instruction instruction_set[] = {
    {"NOP",  0,  TYPE_NONE},
    {"ADD",  1,  TYPE_RRR},
    {"SUB",  2,  TYPE_RRR},
    {"MUL",  3,  TYPE_RRR},
    {"AND",  5,  TYPE_RRR},
    {"OR",   6,  TYPE_RRR},
    {"XOR",  7,  TYPE_RRR},
    {"NOT",  8,  TYPE_NOT},
    {"SHL",  9,  TYPE_RRR},
    {"SHR",  10, TYPE_RRR},
    {"SAR",  11, TYPE_RRR},
    {"ADDI", 12, TYPE_RRI},
    {"ANDI", 13, TYPE_RRI},
    {"ORI",  14, TYPE_RRI},
    {"XORI", 15, TYPE_RRI},
    {"LDW",  17, TYPE_MEMORY},
    {"STW",  18, TYPE_MEMORY},
    {"HALT", 31, TYPE_NONE}
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

static void uppercase(char *text) {
    while (*text != '\0') {
        *text = (char)toupper((unsigned char)*text);
        text++;
    }
}

static int parse_register(
    const char *text,
    unsigned int *reg
) {
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

    if (errno != 0 ||
        end == text + 1 ||
        *end != '\0') {
        return 0;
    }

    if (value < 0 || value >= LETTUCE_REGISTER_COUNT) {
        return 0;
    }

    *reg = (unsigned int)value;

    return 1;
}

static int parse_immediate(
    const char *text,
    int *value
) {
    if (text == NULL || value == NULL || *text == '\0') {
        return 0;
    }

    errno = 0;

    char *end = NULL;

    long parsed = strtol(text, &end, 0);

    if (errno != 0 ||
        end == text ||
        *end != '\0') {
        return 0;
    }

    if (parsed < LETTUCE_IMMEDIATE_MIN ||
        parsed > LETTUCE_IMMEDIATE_MAX) {
        return 0;
    }

    *value = (int)parsed;

    return 1;
}

static const Instruction *find_instruction(
    const char *name
) {
    size_t count =
        sizeof(instruction_set) / sizeof(instruction_set[0]);

    for (size_t i = 0; i < count; i++) {
        if (strcmp(name, instruction_set[i].name) == 0) {
            return &instruction_set[i];
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

        if (*operand == '\0' || count >= maximum) {
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
        set_error(
            error_buffer,
            error_buffer_size,
            "Invalid input"
        );

        return LETTUCE_ASM_ERROR;
    }

    char line[256];

    size_t length = strlen(source);

    if (length >= sizeof(line)) {
        set_error(
            error_buffer,
            error_buffer_size,
            "Instruction line too long"
        );

        return LETTUCE_ASM_ERROR;
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

    char *operand_text = NULL;

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

        return LETTUCE_ASM_ERROR;
    }

    char *operands[4];

    int operand_count = 0;

    if (operand_text != NULL && *operand_text != '\0') {
        operand_count = split_operands(
            operand_text,
            operands,
            4
        );

        if (operand_count < 0) {
            set_error(
                error_buffer,
                error_buffer_size,
                "Invalid operand list"
            );

            return LETTUCE_ASM_ERROR;
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

                return LETTUCE_ASM_ERROR;
            }
            break;

        case TYPE_RRR:
            if (operand_count != 3) {
                set_error(
                    error_buffer,
                    error_buffer_size,
                    "Expected RD, RA, RB"
                );

                return LETTUCE_ASM_ERROR;
            }

            if (!parse_register(operands[0], &rd) ||
                !parse_register(operands[1], &ra) ||
                !parse_register(operands[2], &rb)) {
                set_error(
                    error_buffer,
                    error_buffer_size,
                    "Invalid register. Use R0 through R15"
                );

                return LETTUCE_ASM_ERROR;
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
                    "Expected RD, RA"
                );

                return LETTUCE_ASM_ERROR;
            }

            if (!parse_register(operands[0], &rd) ||
                !parse_register(operands[1], &ra)) {
                set_error(
                    error_buffer,
                    error_buffer_size,
                    "Invalid register"
                );

                return LETTUCE_ASM_ERROR;
            }

            encoded |= rd << 22;
            encoded |= ra << 18;
            break;

        case TYPE_RRI:
            if (operand_count != 3) {
                set_error(
                    error_buffer,
                    error_buffer_size,
                    "Expected RD, RA, IMMEDIATE"
                );

                return LETTUCE_ASM_ERROR;
            }

            if (!parse_register(operands[0], &rd) ||
                !parse_register(operands[1], &ra)) {
                set_error(
                    error_buffer,
                    error_buffer_size,
                    "Invalid register"
                );

                return LETTUCE_ASM_ERROR;
            }

            if (!parse_immediate(operands[2], &immediate)) {
                set_error(
                    error_buffer,
                    error_buffer_size,
                    "Immediate outside signed 18-bit range"
                );

                return LETTUCE_ASM_ERROR;
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
                    "Expected REGISTER, BASE, OFFSET"
                );

                return LETTUCE_ASM_ERROR;
            }

            if (!parse_register(operands[0], &rd) ||
                !parse_register(operands[1], &ra)) {
                set_error(
                    error_buffer,
                    error_buffer_size,
                    "Invalid memory register"
                );

                return LETTUCE_ASM_ERROR;
            }

            if (!parse_immediate(operands[2], &immediate)) {
                set_error(
                    error_buffer,
                    error_buffer_size,
                    "Invalid memory offset"
                );

                return LETTUCE_ASM_ERROR;
            }

            encoded |= rd << 22;
            encoded |= ra << 18;
            encoded |= (uint32_t)immediate & 0x3FFFF;
            break;
    }

    *instruction = encoded;

    if (error_buffer != NULL && error_buffer_size > 0) {
        error_buffer[0] = '\0';
    }

    return LETTUCE_ASM_OK;
}

#ifndef LETTUCE_ASSEMBLER_NO_MAIN

int main(void) {
    char line[256];
    char error[128];

    unsigned long line_number = 0;

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

        if (result != LETTUCE_ASM_OK) {
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

    if (ferror(stdin)) {
        fprintf(stderr, "Input reading error\n");
        return 1;
    }

    return 0;
}

#endif