all:
	yacc -d expr.y
	lex expr.l
	gcc lex.yy.c y.tab.c codegen.c -o codegen

run: all
	./codegen < sample.txt

clean:
	rm -f lex.yy.c y.tab.c y.tab.h codegen