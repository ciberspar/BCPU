# Lettuce32 ISA

Version: 0.1-draft

Target processor: BCPU Tomato.

## Basic properties

- Word size: 32 bits.
- General-purpose registers: 16.
- Instruction encoding: fixed 32-bit instructions (initial proposal).
- Endianness: little-endian (initial proposal).

## Register proposal

| Register | Purpose |
|---|---|
| R0 | Zero register |
| R1-R12 | General-purpose |
| R13 | Stack pointer |
| R14 | Link register |
| R15 | Program counter |

## Instruction categories

- Arithmetic.
- Logic.
- Memory access.
- Branches.
- Comparisons.
- System control.

## Initial instruction proposal

- ADD
- SUB
- MUL
- DIV
- AND
- OR
- XOR
- NOT
- LOAD
- STORE
- JMP
- BEQ
- BNE
- CALL
- RET
- HALT

Instruction encodings and exact semantics are not finalized.