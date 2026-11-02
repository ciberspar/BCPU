#include "lettuce_asm.h"

#include <ctype.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>

static int parse_register(const char *text, uint8_t *reg) {
    if (!text || !reg || toupper((unsigned char)text[0]) != 'R')
        return 0;

    char *end;
    long value = strtol(text + 1, &end, 10);

    if (*end != '\0' || value < 0 || value > 15)
        return 0;

    *reg = (uint8_t)value;
    return 1;
}

static int parse_immediate(const char *text, int32_t *value) {
    if (!text || !value)
        return 0;

    char *end;
    long parsed = strtol(text, &end, 0);

    if (*end != '\0' || parsed < -131072 || parsed > 131071)
        return 0;

    *value = (int32_t)parsed;
    return 1;
}

int parse_instruction(const char *line, uint32_t *instruction) {
    if (!line || !instruction)
        return 0;

    char buffer[256];

    if (strlen(line) >= sizeof(buffer))
        return 0;

    strcpy(buffer, line);

    char *comment = strchr(buffer, ';');
    if (comment)
        *comment = '\0';

    char *tokens[5];
    int count = 0;

    char *token = strtok(buffer, " \t,\r\n");

    while (token && count < 5) {
        tokens[count++] = token;
        token = strtok(NULL, " \t,\r\n");
    }

    if (token)
        return 0;

    if (count == 0)
        return 2;

    if (!strcasecmp(tokens[0], "NOP") && count == 1) {
        *instruction = encode_r(LETTUCE_OP_NOP, 0, 0, 0);
        return 1;
    }

    if (!strcasecmp(tokens[0], "HALT") && count == 1) {
        *instruction = encode_r(LETTUCE_OP_HALT, 0, 0, 0);
        return 1;
    }

    uint8_t rd, ra, rb;
    int32_t immediate;

    if (!strcasecmp(tokens[0], "ADD") ||
        !strcasecmp(tokens[0], "SUB") ||
        !strcasecmp(tokens[0], "MUL")) {

        if (count != 4 ||
            !parse_register(tokens[1], &rd) ||
            !parse_register(tokens[2], &ra) ||
            !parse_register(tokens[3], &rb))
            return 0;

        uint8_t opcode =
            !strcasecmp(tokens[0], "ADD") ? LETTUCE_OP_ADD :
            !strcasecmp(tokens[0], "SUB") ? LETTUCE_OP_SUB :
                                             LETTUCE_OP_MUL;

        *instruction = encode_r(opcode, rd, ra, rb);
        return 1;
    }

    if (!strcasecmp(tokens[0], "ADDI")) {
        if (count != 4 ||
            !parse_register(tokens[1], &rd) ||
            !parse_register(tokens[2], &ra) ||
            !parse_immediate(tokens[3], &immediate))
            return 0;

        *instruction = encode_i(
            LETTUCE_OP_ADDI, rd, ra, immediate
        );

        return 1;
    }

    return 0;
}