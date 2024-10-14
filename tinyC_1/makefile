run: a.out
	./a.out < ass3_22CS30041_22CS30045_test.c

lexfile:
	flex ass3_22CS30041_22CS30045.l

a.out: lexfile
	gcc lex.yy.c ass3_22CS30041_22CS30045.c

clean:
	rm -f ./a.out ./lex.yy.c