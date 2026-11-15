
#include <stdint.h>
#include <stddef.h>

#define CALCULATOR_RAM_CAPACITY 256

typedef struct {
    int32_t first;
    int32_t second;
    int32_t result;
    uint32_t operation;
    uint32_t valid;
} CalculatorRecord;

/*
 * RAM result storage.
 * This is a software-side model of the record layout.
 * The real hardware address will be assigned by the
 * Lettuce32 linker/loader.
 */
static CalculatorRecord calculator_ram[CALCULATOR_RAM_CAPACITY];

static uint32_t record_count = 0;

enum {
    CALC_ADD = 1,
    CALC_SUB = 2,
    CALC_MUL = 3,
    CALC_DIV = 4
};

int calculator_execute(
    int32_t first,
    int32_t second,
    uint32_t operation,
    int32_t *result
) {
    if (result == NULL)
        return -1;

    switch (operation) {
        case CALC_ADD:
            *result = first + second;
            return 0;

        case CALC_SUB:
            *result = first - second;
            return 0;

        case CALC_MUL:
            *result = first * second;
            return 0;

        case CALC_DIV:
            if (second == 0)
                return -2;

            *result = first / second;
            return 0;

        default:
            return -3;
    }
}

int calculator_save_ram(
    int32_t first,
    int32_t second,
    uint32_t operation,
    int32_t result
) {
    if (record_count >= CALCULATOR_RAM_CAPACITY)
        return -1;

    calculator_ram[record_count].first = first;
    calculator_ram[record_count].second = second;
    calculator_ram[record_count].operation = operation;
    calculator_ram[record_count].result = result;
    calculator_ram[record_count].valid = 1;

    record_count++;

    return 0;
}

const CalculatorRecord *calculator_get_record(uint32_t index) {
    if (index >= record_count)
        return NULL;

    return &calculator_ram[index];
}

uint32_t calculator_get_record_count(void) {
    return record_count;
}

int calculator_run(
    int32_t first,
    int32_t second,
    uint32_t operation,
    int32_t *result
) {
    int status = calculator_execute(
        first,
        second,
        operation,
        result
    );

    if (status != 0)
        return status;

    return calculator_save_ram(
        first,
        second,
        operation,
        *result
    );
}
