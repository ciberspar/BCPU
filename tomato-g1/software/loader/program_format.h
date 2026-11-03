#ifndef LETTUCE_PROGRAM_FORMAT_H
#define LETTUCE_PROGRAM_FORMAT_H

#include <stdint.h>

#define LETTUCE_PROGRAM_MAGIC 0x4C545033u
#define LETTUCE_PROGRAM_VERSION 1u

#define LETTUCE_PROGRAM_HEADER_SIZE 20u

#define LETTUCE_PROGRAM_FLAG_NONE 0u

typedef struct {
    uint32_t magic;
    uint32_t version;
    uint32_t entry_point;
    uint32_t code_size;
    uint32_t flags;
} LettuceProgramHeader;

#endif