# Lettuce ASM 0.1

The official experimental assembler for the BCPU Lettuce architecture.

## Features

- Lettuce32 instruction encoding
- 16 general-purpose registers
- R-format instructions
- I-format instructions
- Little-endian binary output
- Assembly error reporting

## Supported instructions

| Instruction | Description |
|---|---|
| NOP | No operation |
| ADD | Register addition |
| SUB | Register subtraction |
| MUL | Register multiplication |
| ADDI | Immediate addition |
| HALT | Stop execution |

## Build

```bash
make