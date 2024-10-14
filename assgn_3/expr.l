%{
#include "y.tab.h"
#include<string.h>
void yyerror(char* s);
int yylex();
%}

letter [a-zA-Z_]
digit [0-9]
nz_digit [1-9]
identifier {letter}({letter}|{digit})*
constant ([+-]?{nz_digit}{digit}*)|0
ws [ \t\n]

%%
"+" return PLUS;
"-" return MINUS;
"**" return DUBSTAR;
"*" return STAR;
"/" return DIV;
"%" return MOD;
"set" return SET;
"(" return LP;
")" return RP;
{identifier} { yylval.id = strdup(yytext); return ID; }
{constant} { yylval.num = strdup(yytext); return NUM; }
{ws} {;}
. { yyerror("Unexpected Character."); }
%%

int yywrap() {
    return 1;
}
