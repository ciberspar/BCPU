
# BCPU Tests

This directory contains architecture verification tests.

## Test categories

- Instruction decoding
- Arithmetic operations
- Logical operations
- Register behavior
- Memory access
- Branch execution
- Exception handling
- Processor reset
- Program execution

## Test targets

- Lettuce32
- Lettuce32E
- Lettuce64

## Requirements

Every implemented instruction must have:

1. An encoding test.
2. An execution test.
3. An expected result.
4. An invalid-input test where applicable.

No processor implementation is considered verified
without passing its architecture tests.
