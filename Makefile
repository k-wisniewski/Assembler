NASM=/usr/local/Cellar/nasm/2.10.07/bin/nasm

all: src/life.o asm/make_simulation.o
	gcc -L/usr/lib -o bin/life src/life.o asm/make_simulation.o

run: all
	bin/life

src/life.o: src/life.c
	gcc -g -G -c src/life.c -o src/life.o

asm/make_simulation.o: asm/make_simulation.asm
	$(NASM) -g -f macho64 asm/make_simulation.asm -o asm/make_simulation.o

clean:
	find . -type f -name "*.o" -exec rm -f {} \;
	rm bin/life
