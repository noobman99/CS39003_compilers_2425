run: compile
	./a.out < input_22CS30041_22CS30045.c > output_22CS30041_22CS30045.txt

compile:
	yacc -d tinyC_22CS30041_22CS30045.y
	lex tinyC_22CS30041_22CS30045.l
	gcc lex.yy.c y.tab.c tinyC_22CS30041_22CS30045.c

clean:
	rm -f ./*.out
	rm y.tab.*
	rm lex.yy.c