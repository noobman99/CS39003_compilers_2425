.SUFFIXES:

.PHONY: run all clean

all: y.tab.c lex.yy.c intcodegen.c
	gcc -o icgen y.tab.c lex.yy.c intcodegen.c

y.tab.c: expr.y
	yacc -d expr.y

lex.yy.c: expr.l
	lex expr.l

run: all
	./icgen < sample.txt 
	gcc -o ic intcode.c
	./ic > output.txt
	echo "Output of ic is in output.txt"

clean:
	rm -f y.tab.c y.tab.h lex.yy.c intcode.c icgen ic output.txt
