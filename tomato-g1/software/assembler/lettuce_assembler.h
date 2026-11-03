#ifndef LETTUCE_ASSEMBLER_H
#define LETTUCE_ASSEMBLER_H

#include <stddef.h>
#include <stdint.h>

#define LETTUCE_ASM_EMPTY 2
#define LETTUCE_ASM_OK 0
#define LETTUCE_ASM_ERROR (-1)

#define LETTUCE_REGISTER_COUNT 16
#define LETTUCE_IMMEDIATE_MIN (-131072)
#define LETTUCE_IMMEDIATE_MAX 131071

int lettuce_assemble_line(
    const char *source,
    uint32_t *instruction,
    char *error_buffer,
    size_t error_buffer_size
);

#endif