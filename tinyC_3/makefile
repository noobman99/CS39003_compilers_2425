main:
	lex tinyC_22CS30041_22CS30045.l
	yacc -d tinyC_22CS30041_22CS30045.y
	g++ lex.yy.c y.tab.c tinyC_22CS30041_22CS30045_translator.cxx

test:
	./a.out < input.c

clean:
	rm -f a.out lex.yy.c y.tab.c y.tab.h