%{
#include "y.tab.h"
#include <string.h>

%}

%%
[ \t\n]+              ; // Ignore whitespace
"set"                { return SET; }
"when"               { return WHEN; }
"loop while"        { return WHILE; }
[0-9]+               { yylval.str = strdup(yytext); return NUMB; }
[a-zA-Z_][a-zA-Z0-9_]* { yylval.str = strdup(yytext); return IDEN; }
"("                  { return LP; }
")"                  { return RP; }
"+"                  { yylval.str = "+"; return PLUS; }
"-"                  { yylval.str = "-"; return MINUS; }
"*"                  { yylval.str = "*"; return MUL; }
"/"                  { yylval.str = "/"; return DIV; }
"%"                  { yylval.str = "%"; return REM; }
"="                  { yylval.str = "="; return EQ; }
"<"                  { yylval.str = "<"; return LT; }
">"                  { yylval.str = ">"; return GT; }
"<="                 { yylval.str = "<="; return LE; }
">="                 { yylval.str = ">="; return GE; }
"/="                 { yylval.str = "/="; return NE; }
.                    { /* ignore other characters */ }

%%

int yywrap() {
    return 1;
}