#ifndef LETTUCE_ASM_H
#define LETTUCE_ASM_H

#include <stdint.h>
#include <stdio.h>

typedef enum {
    LETTUCE_OP_NOP  = 0,
    LETTUCE_OP_ADD  = 1,
    LETTUCE_OP_SUB  = 2,
    LETTUCE_OP_MUL  = 3,
    LETTUCE_OP_ADDI = 12,
    LETTUCE_OP_HALT = 31
} LettuceOpcode;

uint32_t encode_r(uint8_t opcode, uint8_t rd,
                  uint8_t ra, uint8_t rb);

uint32_t encode_i(uint8_t opcode, uint8_t rd,
                  uint8_t ra, int32_t immediate);

int parse_instruction(const char *line, uint32_t *instruction);
int write_binary(FILE *file, uint32_t instruction);

#endif