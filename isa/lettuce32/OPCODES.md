Lettuce32 Opcode Table

Version: 0.2-draft
Target: BCPU Tomato G1
Status: Compatibility audit

1. Implemented instructions

These opcodes are currently implemented in the assembler, emulator, P-Core and E-Core.

Opcode	Hex	Instruction	Format
0	0x00	NOP	R
1	0x01	ADD	R
2	0x02	SUB	R
3	0x03	MUL	R
5	0x05	AND	R
6	0x06	OR	R
7	0x07	XOR	R
8	0x08	NOT	R
9	0x09	SHL	R
10	0x0A	SHR	R
11	0x0B	SAR	R
12	0x0C	ADDI	I
13	0x0D	ANDI	I
14	0x0E	ORI	I
15	0x0F	XORI	I
17	0x11	LDW	I
18	0x12	STW	I
23	0x17	BEQ	B
24	0x18	BNE	B
25	0x19	BLT	B
26	0x1A	BGE	B
31	0x1F	HALT	R

2. Reserved opcodes

These opcode values are not implemented in Lettuce32 0.2.

Opcode	Hex	Planned instruction
4	0x04	DIVU
16	0x10	LUI
19	0x13	LDBU
20	0x14	STB
21	0x15	LDHU
22	0x16	STH
27	0x1B	JAL
28	0x1C	JALR
29	0x1D	RET
30	0x1E	SYSCALL

Reserved opcodes must not be used by Lettuce32 0.2 programs.

Their future implementation requires updates to the ISA specification, assembler, emulator, P-Core, E-Core and automated tests.

3. Encoding formats

All instructions are 32 bits long.

* R: register-based instruction.
* I: immediate-based instruction.
* B: branch instruction.

The exact bit layouts and operand semantics are defined in ISA.md.

4. Compatibility requirements

An instruction is considered implemented only when its behavior is consistent across:

* Lettuce32 Assembler
* Lettuce32 Emulator
* BCPU Tomato G1 P-Core
* BCPU Tomato G1 E-Core

Assembler support alone does not establish processor compatibility.

5. Release status

Lettuce32 0.2 remains a compatibility-audit draft.

The opcode table must not be considered frozen until all defined instructions pass automated tests and the processor components demonstrate consistent architectural behavior.