#ifndef LETTUCE_RUNTIME_H
#define LETTUCE_RUNTIME_H

#include <stddef.h>
#include <stdint.h>

#include "../loader/program_loader.h"

#define LETTUCE_RUNTIME_OK 0
#define LETTUCE_RUNTIME_ERROR (-1)
#define LETTUCE_RUNTIME_INVALID_PROGRAM (-2)
#define LETTUCE_RUNTIME_EXECUTION_ERROR (-3)

#define LETTUCE_RUNTIME_DEFAULT_MAX_CYCLES 1000000u

typedef struct {
    uint32_t entry_point;
    uint32_t code_size;
    uint32_t instruction_count;
    uint64_t max_cycles;
    uint8_t program_loaded;
    uint8_t execution_started;
    uint8_t execution_finished;
} LettuceRuntime;

int lettuce_runtime_init(
    LettuceRuntime *runtime,
    uint64_t max_cycles
);

int lettuce_runtime_load(
    LettuceRuntime *runtime,
    const uint8_t *program_data,
    size_t program_size,
    uint8_t *memory,
    size_t memory_size
);

int lettuce_runtime_mark_started(
    LettuceRuntime *runtime
);

int lettuce_runtime_mark_finished(
    LettuceRuntime *runtime
);

#endif