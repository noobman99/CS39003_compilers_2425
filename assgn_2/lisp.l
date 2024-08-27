%{
#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#define EXPR_BEGIN 1
#define EXPR_END 2
#define VARIABLE 3
#define CONSTANT 4
#define OPERATION 5
#define ERROR 6
%}

%%
\( return (EXPR_BEGIN);
\) return (EXPR_END);
-?[0-9]+ return (CONSTANT);
[a-zA-Z_][a-zA-Z0-9_]* return (VARIABLE);
[+\-/%*] return (OPERATION);
[\n\t ] ;
. return (ERROR);
%%

int yywrap(void) {
    return 1;
}