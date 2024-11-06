.SUFFIXES:

.PHONY: run all clean fullclean

all: y.tab.c lex.yy.c codegen.c
	gcc lex.yy.c y.tab.c codegen.c -o codegen

y.tab.c: prog.y
	yacc -d prog.y

lex.yy.c: prog.l
	lex prog.l

run: all
	./codegen < sample.txt
	echo "Assembly code is in target_code.txt, intermediate instructions are in intermediate_instructions.txt"

clean:
	rm -f lex.yy.c y.tab.c y.tab.h codegen

fullclean: clean
	rm -f intermediate_instructions.txt target_code.txt