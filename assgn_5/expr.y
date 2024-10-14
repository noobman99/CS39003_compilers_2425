%{
#include<stdio.h>
#include<stdlib.h>
#include<string.h>

int yylex();
void yyerror(char* s);

extern FILE* outputfile;

struct _symboltablenode
{
    char *name;
    int offset;
    struct _symboltablenode *next;
};
typedef struct _symboltablenode* symboltablenode;

struct _parsenode
{
    int addr;
    int type;
};

typedef struct _parsenode *parsenode;

typedef struct
{
    int addr;
    int ismem;
} tempaddr;

int addtosymboltable(char *name);
int getfromsymboltable(char *name);
tempaddr gettemp();
void resetreg();
void setreg(int reg);
parsenode createparsenode(int addr, int type);
int loadfrommem(int idx);
void clearR0();
void printexpression(parsenode node);
char *getterm(parsenode node);

%}

%union {int num; char* id; int op; struct _parsenode* node; }
%token <num> NUM
%token <id> ID
%token PLUS
%token MINUS
%token DUBSTAR
%token STAR
%token DIV
%token MOD
%token LP
%token RP
%token SET
%type PROGRAM
%type STMT
%type SETSTMT
%type <op> EXPRSTMT
%type <node> EXPR
%type <op> OP
%type <node> ARG
%start PROGRAM

%%

PROGRAM : STMT PROGRAM { ; }
            | STMT { ; }
            ;

STMT : SETSTMT { resetreg(); }
            | EXPRSTMT { resetreg(); }
            ;

SETSTMT : LP SET ID NUM RP { 
                             fprintf(outputfile, "   MEM[%d] = %d;\n", addtosymboltable($3), $4);
                             fprintf(outputfile, "   mprn(MEM, %d);\n", getfromsymboltable($3));
                             free($3);
                           }
            | LP SET ID ID RP { 
                                fprintf(outputfile, "   R[0] = MEM[%d];\n", addtosymboltable($4));
                                fprintf(outputfile, "   MEM[%d] = R[0];\n", addtosymboltable($3));
                                fprintf(outputfile, "   mprn(MEM, %d);\n", getfromsymboltable($3));
                                free($3);
                                free($4);
                              }
            | LP SET ID EXPR RP { if ($4->type == 0) {
                                    fprintf(outputfile, "   MEM[%d] = R[%d];\n", addtosymboltable($3), $4->addr);
                                  } else if ($4->type == 1) {
                                    fprintf(outputfile, "   MEM[%d] = MEM[%d];\n", addtosymboltable($3), $4->addr);
                                  } else {
                                    fprintf(outputfile, "   MEM[%d] = %d;\n", addtosymboltable($3), $4->addr);
                                  }
                                  fprintf(outputfile, "   mprn(MEM, %d);\n", getfromsymboltable($3));
                                  free($3);
                                  free($4);
                                }
            ;

EXPRSTMT : EXPR { printexpression($1); free($1); }
            ;

EXPR : LP OP ARG ARG RP { int addr = -1, type = 0;

                          if ($3->type == 0 && $3->addr > 1) {
                            addr = $3->addr;
                            if (addr < 11) {
                                setreg(addr + 1);
                            }
                          } else if ($4->type == 0 && $4->addr > 1) {
                            addr = $4->addr;
                            if (addr < 11) {
                                setreg(addr + 1);
                            }
                          } else {
                            tempaddr tmp = gettemp();
                            addr = tmp.addr;
                            type = tmp.ismem;
                          }

                          $$ = createparsenode(addr, type);
                          if (type == 1) {
                            addr = 0;
                          }

                          char *term1 = getterm($3);
                          char *term2 = getterm($4);
                          
                          char symbols[5] = {'+', '-', '*', '/', '%'};
                          if ($2 == -1) {
                            fprintf(outputfile, "   R[%d] = pwr(%s, %s);\n", addr, term1, term2);
                          } else {
                            fprintf(outputfile, "   R[%d] = %s %c %s;\n", addr, term1, symbols[$2], term2);
                          }

                          if (type == 1) {
                            fprintf(outputfile, "   MEM[%d] = R[0];\n", $$->addr);
                          }

                          clearR0();
                          free($3);
                          free($4);
                          free(term1);
                          free(term2);
                        }
            ;

OP : PLUS { $$ = 0; }
            | MINUS { $$ = 1; }
            | DUBSTAR { $$ = -1; }
            | STAR { $$ = 2; }
            | DIV { $$ = 3; }
            | MOD { $$ = 4; }
            ;

ARG : ID { int addr = getfromsymboltable($1);
           $$ = createparsenode(addr, 1);
           free($1);
         }
            | EXPR { $$ = $1; }
            | NUM { $$ = createparsenode($1, 2); }
            ;
%%
