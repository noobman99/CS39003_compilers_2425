.SUFFIXES:

.PHONY: run clean

run: a.out

a.out: y.tab.c lex.yy.c polyutils.c
	gcc y.tab.c lex.yy.c polyutils.c

y.tab.c: poly.y
	yacc -d poly.y

lex.yy.c: poly.l
	lex poly.l

clean:
	rm -f y.tab.c y.tab.h lex.yy.c a.out