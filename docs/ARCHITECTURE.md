# Lettuce Architecture

Version: 0.1-draft

Lettuce is the original instruction set architecture
family used by BCPU processors.

## Architecture family

### Lettuce32

- 32-bit architecture.
- Basic instruction set.
- Designed for low-resource systems.
- Used by BCPU Tomato.

### Lettuce32E

- 32-bit architecture.
- Enhanced instruction set.
- Intended to extend Lettuce32.
- Used by BCPU Water.

The E means Enhanced.

### Lettuce64

- 64-bit architecture.
- Extended registers and addressing.
- Designed for advanced computing.
- Used by BCPU Agata.

## Design goals

- Simple instruction decoding.
- Efficient execution.
- Memory protection.
- Interrupt support.
- Atomic operations.
- Future SIMD extensions.
- Virtualization support.

## Compatibility

Compatibility between Lettuce32, Lettuce32E
and Lettuce64 must be formally specified.

## Status

This document describes design goals.
It does not represent a completed processor.