main: compile test

compile:
	lex tinyC_22CS30041_22CS30045.l
	yacc -d tinyC_22CS30041_22CS30045.y
	g++ lex.yy.c y.tab.c tinyC_22CS30041_22CS30045_translator.cxx

test:
	for i in 1 2 3 4 5 ; do \
		echo "Testing test_$$i.c"; \
		./a.out < test_files/tinyC_22CS30041_22CS30045_test_$$i.c > output_files/tinyC_22CS30041_22CS30045_quads_$$i.out ; \
	done

clean:
	rm -f a.out lex.yy.c y.tab.c y.tab.h