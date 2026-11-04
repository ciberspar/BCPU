#include "lettuce_runtime.h"

#include <string.h>

int lettuce_runtime_init(
    LettuceRuntime *runtime,
    uint64_t max_cycles
) {
    if (runtime == NULL) {
        return LETTUCE_RUNTIME_ERROR;
    }

    memset(runtime, 0, sizeof(LettuceRuntime));

    runtime->max_cycles = (max_cycles == 0)
        ? LETTUCE_RUNTIME_DEFAULT_MAX_CYCLES
        : max_cycles;

    return LETTUCE_RUNTIME_OK;
}

int lettuce_runtime_load(
    LettuceRuntime *runtime,
    const uint8_t *program_data,
    size_t program_size,
    uint8_t *memory,
    size_t memory_size
) {
    LettuceLoadedProgram loaded;

    if (runtime == NULL ||
        program_data == NULL ||
        memory == NULL ||
        program_size == 0 ||
        memory_size == 0 ||
        runtime->max_cycles == 0) {
        return LETTUCE_RUNTIME_INVALID_PROGRAM;
    }

    if (runtime->execution_started) {
        return LETTUCE_RUNTIME_EXECUTION_ERROR;
    }

    if (lettuce_program_load(
            program_data,
            program_size,
            memory,
            memory_size,
            &loaded
        ) != LETTUCE_LOADER_OK) {
        return LETTUCE_RUNTIME_INVALID_PROGRAM;
    }

    runtime->entry_point = loaded.entry_point;
    runtime->code_size = loaded.code_size;
    runtime->instruction_count = loaded.instruction_count;

    runtime->program_loaded = 1;
    runtime->execution_started = 0;
    runtime->execution_finished = 0;

    return LETTUCE_RUNTIME_OK;
}

int lettuce_runtime_mark_started(
    LettuceRuntime *runtime
) {
    if (runtime == NULL) {
        return LETTUCE_RUNTIME_ERROR;
    }

    if (!runtime->program_loaded ||
        runtime->execution_started ||
        runtime->execution_finished) {
        return LETTUCE_RUNTIME_EXECUTION_ERROR;
    }

    runtime->execution_started = 1;

    return LETTUCE_RUNTIME_OK;
}

int lettuce_runtime_mark_finished(
    LettuceRuntime *runtime
) {
    if (runtime == NULL) {
        return LETTUCE_RUNTIME_ERROR;
    }

    if (!runtime->program_loaded ||
        !runtime->execution_started ||
        runtime->execution_finished) {
        return LETTUCE_RUNTIME_EXECUTION_ERROR;
    }

    runtime->execution_finished = 1;

    return LETTUCE_RUNTIME_OK;
}