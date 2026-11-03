#ifndef LETTUCE_PROGRAM_LOADER_H
#define LETTUCE_PROGRAM_LOADER_H

#include <stddef.h>
#include <stdint.h>

#include "program_format.h"

#define LETTUCE_LOADER_OK 0
#define LETTUCE_LOADER_ERROR (-1)

#define LETTUCE_LOADER_INVALID_MAGIC (-2)
#define LETTUCE_LOADER_INVALID_VERSION (-3)
#define LETTUCE_LOADER_INVALID_SIZE (-4)
#define LETTUCE_LOADER_INVALID_ENTRY (-5)
#define LETTUCE_LOADER_MEMORY_OVERFLOW (-6)

typedef struct {
    uint32_t entry_point;
    uint32_t code_size;
    uint32_t instruction_count;
} LettuceLoadedProgram;

int lettuce_program_validate(
    const uint8_t *data,
    size_t data_size,
    size_t memory_size,
    LettuceLoadedProgram *program
);

int lettuce_program_load(
    const uint8_t *data,
    size_t data_size,
    uint8_t *memory,
    size_t memory_size,
    LettuceLoadedProgram *program
);

#endif