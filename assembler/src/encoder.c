#include "lettuce_asm.h"

uint32_t encode_r(uint8_t opcode, uint8_t rd,
                  uint8_t ra, uint8_t rb) {
    return ((uint32_t)(opcode & 0x3F) << 26) |
           ((uint32_t)(rd & 0x0F) << 22) |
           ((uint32_t)(ra & 0x0F) << 18) |
           ((uint32_t)(rb & 0x0F) << 14);
}

uint32_t encode_i(uint8_t opcode, uint8_t rd,
                  uint8_t ra, int32_t immediate) {
    return ((uint32_t)(opcode & 0x3F) << 26) |
           ((uint32_t)(rd & 0x0F) << 22) |
           ((uint32_t)(ra & 0x0F) << 18) |
           ((uint32_t)immediate & 0x3FFFF);
}