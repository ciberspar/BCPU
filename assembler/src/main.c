#include "lettuce_asm.h"

#include <stdio.h>

#define MAX_INSTRUCTIONS 4096

int main(int argc, char **argv) {
    if (argc != 3) {
        fprintf(stderr,
                "Usage: lettuce-asm input.asm output.bin\n");
        return 1;
    }

    FILE *input = fopen(argv[1], "r");

    if (!input) {
        perror("Input");
        return 1;
    }

    FILE *output = fopen(argv[2], "wb");

    if (!output) {
        perror("Output");
        fclose(input);
        return 1;
    }

    char line[256];
    unsigned int line_number = 0;
    unsigned int instruction_count = 0;
    int status = 0;

    while (fgets(line, sizeof(line), input)) {
        line_number++;

        uint32_t instruction;

        int result = parse_instruction(line, &instruction);

        if (result == 2)
            continue;

        if (result == 0) {
            fprintf(stderr,
                    "Assembly error at line %u\n",
                    line_number);
            status = 1;
            break;
        }

        if (instruction_count >= MAX_INSTRUCTIONS) {
            fprintf(stderr, "Program too large\n");
            status = 1;
            break;
        }

        if (!write_binary(output, instruction)) {
            fprintf(stderr, "Binary write error\n");
            status = 1;
            break;
        }

        instruction_count++;
    }

    if (ferror(input))
        status = 1;

    if (fclose(input) != 0)
        status = 1;

    if (fclose(output) != 0)
        status = 1;

    if (status)
        return 1;

    printf("Lettuce ASM: %u instructions assembled.\n",
           instruction_count);

    return 0;
}