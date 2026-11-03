
# Lettuce32 ISA Specification
## BCPU Tomato G1

**Version:** 0.1  
**Architecture:** Lettuce32  
**Word size:** 32 bits  
**Instruction size:** 32 bits  
**Register count:** 16 general-purpose registers  
**Register width:** 32 bits  
**Endianness:** Not formally specified yet

---

## 1. General architecture

Lettuce32 is the instruction set architecture used by BCPU Tomato G1.

The architecture uses:
- 32-bit data words.
- 32-bit instructions.
- 16 general-purpose registers.
- A 32-bit program counter (PC).
- A shared memory bus for instruction fetching and data access.
- A P-Core and an E-Core.

Register R0 is permanently zero.

## 2. Instruction format

Every instruction is 32 bits long.

### General fields

| Bits | Width | Field |
|---|---:|---|
| 31–26 | 6 | Opcode |
| 25–22 | 4 | RD |
| 21–18 | 4 | RA |
| 17–14 | 4 | RB |
| 17–0 | 18 | Immediate |

The immediate field overlaps the RB field. Its interpretation depends on the instruction.

### Register format

Used by arithmetic and logical instructions.

- RD: destination register.
- RA: first source register.
- RB: second source register.

### Immediate format

Used by immediate arithmetic, loads, stores and branches.

- RD: destination or store-data register.
- RA: base or first source register.
- Immediate: signed or unsigned 18-bit value, depending on the instruction.

## 3. Register set

| Register | Description |
|---|---|
| R0 | Constant zero |
| R1–R15 | General-purpose registers |

All registers are 32 bits wide.

Writes to R0 must not change its value.

## 4. Opcode table

| Opcode | Instruction | Status |
|---:|---|---|
| 0 | NOP | Implemented |
| 1 | ADD | Implemented |
| 2 | SUB | Implemented |
| 3 | MUL | Implemented |
| 4 | DIVU | Planned |
| 5 | AND | Implemented |
| 6 | OR | Implemented |
| 7 | XOR | Implemented |
| 8 | NOT | Implemented |
| 9 | SHL | Implemented |
| 10 | SHR | Implemented |
| 11 | SAR | Implemented |
| 12 | ADDI | Implemented |
| 13 | ANDI | Implemented |
| 14 | ORI | Implemented |
| 15 | XORI | Implemented |
| 16 | LUI | Planned |
| 17 | LDW | Implemented |
| 18 | STW | Implemented |
| 19 | LDBU | Planned |
| 20 | STB | Planned |
| 21 | LDHU | Planned |
| 22 | STH | Planned |
| 23 | BEQ | Implemented |
| 24 | BNE | Implemented |
| 25 | BLT | Implemented |
| 26 | BGE | Implemented |
| 27 | JAL | Planned |
| 28 | JALR | Planned |
| 29 | RET | Planned |
| 30 | SYSCALL | Planned |
| 31 | HALT | Implemented |

"Planned" means an opcode is declared in the control-unit source but is not yet implemented by the current processor cores.

## 5. Arithmetic instructions

### ADD

RD = RA + RB

### SUB

RD = RA - RB

### MUL

RD = RA * RB

P-Core uses combinational multiplication.

E-Core uses iterative multiplication.

### AND

RD = RA AND RB

### OR

RD = RA OR RB

### XOR

RD = RA XOR RB

### NOT

RD = NOT RA

### SHL

RD = RA shifted left by RB[4:0].

### SHR

RD = RA shifted right logically by RB[4:0].

### SAR

RD = RA shifted right arithmetically by RB[4:0].

## 6. Immediate instructions

### ADDI

RD = RA + sign_extend(IMMEDIATE)

### ANDI

RD = RA AND zero_extend(IMMEDIATE)

### ORI

RD = RA OR zero_extend(IMMEDIATE)

### XORI

RD = RA XOR zero_extend(IMMEDIATE)

The immediate field is 18 bits wide.

## 7. Memory instructions

### LDW

Loads a 32-bit word from memory.

Effective address:

RA + sign_extend(IMMEDIATE)

Result is written to RD.

### STW

Stores the contents of RD into memory.

Effective address:

RA + sign_extend(IMMEDIATE)

Store data:

RD

Memory alignment and byte ordering still need a formal specification.

## 8. Branch instructions

Branch offsets are signed 18-bit values.

The processor increments PC by 4 when fetching an instruction.

The current branch implementation calculates:

PC = PC + (sign_extend(IMMEDIATE) << 2)

### BEQ

Branch if RA == RB.

### BNE

Branch if RA != RB.

### BLT

Branch if signed(RA) < signed(RB).

### BGE

Branch if signed(RA) >= signed(RB).

## 9. Processor control instructions

### NOP

Performs no operation.

### HALT

Stops the processor.

The current implementation remains in the halted state until reset.

## 10. Memory interface

The current processor interface includes:

- mem_read
- mem_write
- mem_address
- mem_write_data
- mem_read_data
- mem_ready

Instruction fetches and data accesses share the same memory interface.

The scheduler arbitrates access between P-Core and E-Core.

## 11. P-Core and E-Core compatibility

Both cores are intended to execute the same Lettuce32 instruction set.

Current differences:

- P-Core performs multiplication combinationally.
- E-Core performs multiplication iteratively.
- Both use 32-bit registers and a 32-bit PC.

The current RTL does not yet implement all declared opcodes.

## 12. Features still required

Before running a full operating system or porting DOOM, Lettuce32 needs additional architectural features:

- A complete and tested instruction decoder.
- Unsigned division.
- Full jump and return instructions.
- Byte and halfword memory operations.
- Interrupt handling.
- Exception handling.
- Privileged execution modes.
- Memory protection.
- A defined system-call interface.
- A documented application binary interface (ABI).
- A compiler and assembler.
- A boot and executable file format.

## 13. DOOM compatibility target

The initial DOOM port will target:

- Lettuce32.
- 32-bit execution.
- A compatible runtime and memory allocator.
- A framebuffer interface.
- Keyboard input.
- Timer support.
- A compatible C toolchain.

DOOM compatibility is a development target, not a currently supported feature.

---

**End of Lettuce32 ISA Specification v0.1**
