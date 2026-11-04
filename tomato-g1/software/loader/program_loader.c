
#include "program_loader.h"

#include <limits.h>
#include <string.h>

static uint32_t read_u32_le(const uint8_t *data)
{
    return ((uint32_t)data[0]) |
           ((uint32_t)data[1] << 8) |
           ((uint32_t)data[2] << 16) |
           ((uint32_t)data[3] << 24);
}

int lettuce_program_validate(
    const uint8_t *data,
    size_t data_size,
    size_t memory_size,
    LettuceLoadedProgram *program
)
{
    uint32_t magic;
    uint32_t version;
    uint32_t entry_point;
    uint32_t code_size;
    uint32_t flags;

    if (!data || !program)
        return LETTUCE_LOADER_ERROR;

    if (data_size < LETTUCE_PROGRAM_HEADER_SIZE)
        return LETTUCE_LOADER_INVALID_SIZE;

    magic = read_u32_le(data);
    version = read_u32_le(data + 4);
    entry_point = read_u32_le(data + 8);
    code_size = read_u32_le(data + 12);
    flags = read_u32_le(data + 16);

    if (magic != LETTUCE_PROGRAM_MAGIC)
        return LETTUCE_LOADER_INVALID_MAGIC;

    if (version != LETTUCE_PROGRAM_VERSION)
        return LETTUCE_LOADER_INVALID_VERSION;

    if (flags != LETTUCE_PROGRAM_FLAG_NONE)
        return LETTUCE_LOADER_ERROR;

    if (code_size == 0 || code_size % 4 != 0)
        return LETTUCE_LOADER_INVALID_SIZE;

    if ((size_t)code_size > SIZE_MAX - LETTUCE_PROGRAM_HEADER_SIZE)
        return LETTUCE_LOADER_INVALID_SIZE;

    if (data_size != LETTUCE_PROGRAM_HEADER_SIZE + (size_t)code_size)
        return LETTUCE_LOADER_INVALID_SIZE;

    if (entry_point % 4 != 0 || entry_point >= code_size)
        return LETTUCE_LOADER_INVALID_ENTRY;

    if ((size_t)code_size > memory_size)
        return LETTUCE_LOADER_MEMORY_OVERFLOW;

    program->entry_point = entry_point;
    program->code_size = code_size;
    program->instruction_count = code_size / 4;

    return LETTUCE_LOADER_OK;
}

int lettuce_program_load(
    const uint8_t *data,
    size_t data_size,
    uint8_t *memory,
    size_t memory_size,
    LettuceLoadedProgram *program
)
{
    int result;

    if (!memory)
        return LETTUCE_LOADER_ERROR;

    result = lettuce_program_validate(
        data,
        data_size,
        memory_size,
        program
    );

    if (result != LETTUCE_LOADER_OK)
        return result;

    memcpy(
        memory,
        data + LETTUCE_PROGRAM_HEADER_SIZE,
        program->code_size
    );

    return LETTUCE_LOADER_OK;
}
