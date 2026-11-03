CC = gcc

CFLAGS = -std=c11 -Wall -Wextra -Werror -O2
INCLUDES = -Iinclude

TARGET = build/lettuce-asm

SOURCES = \
	src/main.c \
	src/parser.c \
	src/encoder.c \
	src/output.c

all: $(TARGET)

$(TARGET): $(SOURCES) include/lettuce_asm.h
	mkdir -p build
	$(CC) $(CFLAGS) $(INCLUDES) $(SOURCES) -o $(TARGET)

clean:
	rm -rf build

.PHONY: all clean