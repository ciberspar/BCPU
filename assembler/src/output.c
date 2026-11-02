#include "lettuce_asm.h"

int write_binary(FILE *file, uint32_t instruction) {
    if (!file)
        return 0;

    for (int i = 0; i < 4; i++) {
        uint8_t byte = (uint8_t)(instruction >> (i * 8));

        if (fputc(byte, file) == EOF)
            return 0;
    }

    return 1;
}