%{
#include "y.tab.h"
#include <string.h>
void yyerror(const char *s);
%}

letter [a-zA-Z_]
digit [0-9]
nz_digit [1-9]
identifier {letter}({letter}|{digit})*
constant [+-]?(({nz_digit}{digit}*)|0)
ws [ \t\n]

%%
{ws}              ; // Ignore whitespace
"set"                { return SET; }
"when"               { return WHEN; }
"loop while"        { return WHILE; }
{constant}               { yylval.str = strdup(yytext); return NUMB; }
{identifier} { yylval.str = strdup(yytext); return IDEN; }
"("                  { return LP; }
")"                  { return RP; }
"+"                  { yylval.str = "+"; return PLUS; }
"-"                  { yylval.str = "-"; return MINUS; }
"*"                  { yylval.str = "*"; return MUL; }
"/"                  { yylval.str = "/"; return DIV; }
"%"                  { yylval.str = "%"; return REM; }
"="                  { yylval.str = "=="; return EQ; }
"<"                  { yylval.str = "<"; return LT; }
">"                  { yylval.str = ">"; return GT; }
"<="                 { yylval.str = "<="; return LE; }
">="                 { yylval.str = ">="; return GE; }
"/="                 { yylval.str = "!="; return NE; }
.                    { yyerror("Invalid Character"); }

%%

int yywrap() {
    return 1;
}