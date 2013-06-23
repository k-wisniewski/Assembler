OPTIONS?=-DBASIC
sse: OPTIONS = -DSSE
NASM=nasm

all: src/life.o asm/make_simulation.o
	gcc -L/usr/lib -o bin/life src/life.o asm/make_simulation.o

sse: src/life.o asm/make_simulation_sse.o
	gcc -L/usr/lib -o bin/life_sse src/life.o asm/make_simulation_sse.o

run: all
	bin/life

src/life.o: src/life.c
	gcc $(OPTIONS) -g -c src/life.c -o src/life.o

asm/make_simulation.o: asm/make_simulation.asm
	$(NASM) -g -f elf64 asm/make_simulation.asm -o asm/make_simulation.o

asm/make_simulation_sse.o: asm/make_simulation_sse.asm
	$(NASM) -g -f elf64 asm/make_simulation_sse.asm -o asm/make_simulation_sse.o

clean:
	find . -type f -name "*.o" -exec rm -f {} \;
	find . -type f -name "life" -exec rm -f {} \;
	find . -type f -name "life_sse" -exec rm -f {} \;
