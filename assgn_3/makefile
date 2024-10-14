all: y.tab.c lex.yy.c
	gcc lex.yy.c y.tab.c main.c

y.tab.c: expr.y
	yacc -d expr.y

lex.yy.c: expr.l
	lex expr.l

run:
	./a.out < sample.txt

clean:
	rm -f ./*.out
	rm y.tab.*
	rm lex.yy.c