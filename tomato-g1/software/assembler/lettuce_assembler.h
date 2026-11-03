#ifndef LETTUCE_ASSEMBLER_H
#define LETTUCE_ASSEMBLER_H

#include <stddef.h>
#include <stdint.h>

#define LETTUCE_ASM_EMPTY 2

int lettuce_assemble_line(
    const char *source,
    uint32_t *instruction,
    char *error_buffer,
    size_t error_buffer_size
);

#endif