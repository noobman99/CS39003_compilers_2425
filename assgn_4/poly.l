%{
#include <stdio.h>
#include "y.tab.h"
void yyerror(char* s);
int yylex();
%}

nonsingulardigit [2-9]
newline \n
ws [ \t]

%%
"+" return PLUS;
"-" return MINUS;
"x" return XSYM;
"^" return EXP;
"0" return ZERO;
"1" return ONE;


{nonsingulardigit} { yylval.num = *yytext - '0'; return D; }
{ws} {;}
{newline} {;}
. { printf("Unexpected Character.\n"); }
%%

int yywrap() {
    return 1;
}