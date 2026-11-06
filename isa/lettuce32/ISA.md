# Lettuce32 ISA Specification

Version: 0.2-draft
Target: BCPU Tomato G1
Status: Compatibility audit

## 1. Architecture

- Architecture name: Lettuce32
- Word size: 32 bits
- Address size: 32 bits
- Instruction size: 32 bits
- Instruction alignment: 4 bytes
- Endianness: little-endian
- General-purpose registers: 16
- Register width: 32 bits
- Register R0: constant zero

## 2. Registers

| Register | Definition |
|---|---|
| R0 | Constant zero |
| R1-R15 | General-purpose registers |

Writes to R0 are discarded.
Reads from R0 always return zero.

The program counter is an internal processor register.
It is not exposed as R15.

## 3. Instruction encoding

Every instruction occupies exactly 32 bits.

### 3.1 R-format

| Bits | Width | Field |
|---|---:|---|
| 31-26 | 6 | Opcode |
| 25-22 | 4 | RD |
| 21-18 | 4 | RA |
| 17-14 | 4 | RB |
| 13-0 | 14 | Reserved |

Reserved bits must be zero.

### 3.2 I-format

| Bits | Width | Field |
|---|---:|---|
| 31-26 | 6 | Opcode |
| 25-22 | 4 | RD |
| 21-18 | 4 | RA |
| 17-0 | 18 | Immediate |

Signed immediate range:

- Minimum: -131072
- Maximum: 131071

### 3.3 B-format

B-format uses the I-format bit layout.

- RD: first comparison register
- RA: second comparison register
- Immediate: signed 18-bit displacement

Branch displacement is measured in instructions.
The target is calculated relative to the next instruction:

PC = PC + 4 + (sign_extend(immediate) * 4)

## 4. Instruction set

### 4.1 Arithmetic

| Opcode | Instruction | Operation |
|---:|---|---|
| 1 | ADD | RD = RA + RB |
| 2 | SUB | RD = RA - RB |
| 3 | MUL | RD = RA * RB |
| 12 | ADDI | RD = RA + sign_extend(imm) |

Arithmetic results are 32-bit values.
Overflow wraps modulo 2^32.

### 4.2 Logical operations

| Opcode | Instruction | Operation |
|---:|---|---|
| 5 | AND | RD = RA & RB |
| 6 | OR | RD = RA \| RB |
| 7 | XOR | RD = RA ^ RB |
| 8 | NOT | RD = ~RA |
| 13 | ANDI | RD = RA & zero_extend(imm) |
| 14 | ORI | RD = RA \| zero_extend(imm) |
| 15 | XORI | RD = RA ^ zero_extend(imm) |

### 4.3 Shift operations

| Opcode | Instruction | Operation |
|---:|---|---|
| 9 | SHL | Logical left shift |
| 10 | SHR | Logical right shift |
| 11 | SAR | Arithmetic right shift |

The shift amount is RB[4:0].

### 4.4 Memory operations

| Opcode | Instruction | Operation |
|---:|---|---|
| 17 | LDW | RD = memory32[RA + sign_extend(imm)] |
| 18 | STW | memory32[RA + sign_extend(imm)] = RD |

Memory is little-endian.

Word accesses require 4-byte alignment.

### 4.5 Branch operations

| Opcode | Instruction | Condition |
|---:|---|---|
| 23 | BEQ | RA == RD |
| 24 | BNE | RA != RD |
| 25 | BLT | signed(RD) < signed(RA) |
| 26 | BGE | signed(RD) >= signed(RA) |

A branch is taken when its condition is true.

### 4.6 Processor control

| Opcode | Instruction | Operation |
|---:|---|---|
| 0 | NOP | No operation |
| 31 | HALT | Stop execution |

## 5. Reserved opcodes

The following opcodes are reserved in this version:

4, 16, 19, 20, 21, 22, 27, 28, 29, 30.

Reserved opcodes must not be used by Lettuce32 programs.

Future versions may assign these values after implementation
and compatibility testing.

## 6. Compatibility requirements

The following components must implement identical instruction
semantics:

- Lettuce32 P-Core
- Lettuce32 E-Core
- Lettuce32 Emulator
- Lettuce32 Assembler
- Lettuce32 Runtime

An instruction is not considered supported merely because
the assembler can encode it.

## 7. Verification requirements

Before Lettuce32 can be declared stable:

- Every defined instruction must have automated tests.
- P-Core and E-Core must produce equivalent architectural results.
- Emulator results must match the hardware model.
- Invalid instructions must have defined behavior.
- Memory alignment behavior must be consistent.
- Branch offsets must be tested in both directions.
- R0 must remain zero under all circumstances.
- Reset behavior must be verified.
- Integrated execution must be tested with real instruction sequences.

## 8. Release status

Lettuce32 0.2 is a compatibility-audit draft.

It is not yet a frozen ISA release.

A stable release requires passing the complete verification suite.