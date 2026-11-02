
# Lettuce32 Opcode Table

Version: 0.1-draft

| Opcode | Hex | Instruction | Format |
|---|---:|---|---|
| 0 | 0x00 | NOP | R |
| 1 | 0x01 | ADD | R |
| 2 | 0x02 | SUB | R |
| 3 | 0x03 | MUL | R |
| 4 | 0x04 | DIVU | R |
| 5 | 0x05 | AND | R |
| 6 | 0x06 | OR | R |
| 7 | 0x07 | XOR | R |
| 8 | 0x08 | NOT | R |
| 9 | 0x09 | SHL | R |
| 10 | 0x0A | SHR | R |
| 11 | 0x0B | SAR | R |
| 12 | 0x0C | ADDI | I |
| 13 | 0x0D | ANDI | I |
| 14 | 0x0E | ORI | I |
| 15 | 0x0F | XORI | I |
| 16 | 0x10 | LUI | I |
| 17 | 0x11 | LDW | I |
| 18 | 0x12 | STW | I |
| 19 | 0x13 | LDBU | I |
| 20 | 0x14 | STB | I |
| 21 | 0x15 | LDHU | I |
| 22 | 0x16 | STH | I |
| 23 | 0x17 | BEQ | B |
| 24 | 0x18 | BNE | B |
| 25 | 0x19 | BLT | B |
| 26 | 0x1A | BGE | B |
| 27 | 0x1B | JAL | I |
| 28 | 0x1C | JALR | I |
| 29 | 0x1D | RET | R |
| 30 | 0x1E | SYSCALL | R |
| 31 | 0x1F | HALT | R |

Unused opcodes are reserved for future extensions.

This table is provisional until the ISA is formally frozen.
