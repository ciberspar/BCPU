
#ifndef LETTUCE_EMULATOR_H
#define LETTUCE_EMULATOR_H

#include <stddef.h>
#include <stdint.h>

/* BCPU Tomato G1 - Lettuce32 */

#define LETTUCE_MEMORY_SIZE (1024u * 1024u)
#define LETTUCE_REGISTER_COUNT 16u

#define LETTUCE_CPU_OK 0
#define LETTUCE_CPU_ERROR (-1)
#define LETTUCE_CPU_HALTED 1
#define LETTUCE_CPU_STEP_LIMIT (-2)

typedef struct {
    uint32_t registers[LETTUCE_REGISTER_COUNT];

    uint32_t pc;

    uint8_t memory[LETTUCE_MEMORY_SIZE];

    uint64_t cycles;

    int halted;
    int error;

} LettuceCPU;

/* Inicialización del procesador virtual. */
int lettuce_cpu_init(LettuceCPU *cpu);

/* Ejecuta una instrucción. */
int lettuce_cpu_step(LettuceCPU *cpu);

/* Ejecuta instrucciones hasta HALT, error o límite. */
int lettuce_cpu_run(
    LettuceCPU *cpu,
    uint64_t max_steps
);

/* Consulta el estado del procesador. */
int lettuce_cpu_is_halted(const LettuceCPU *cpu);
int lettuce_cpu_has_error(const LettuceCPU *cpu);

#endif
