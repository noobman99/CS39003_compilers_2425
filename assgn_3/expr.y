%{
#include<stdio.h>
#include<stdlib.h>
#include<string.h>

int yylex();
void yyerror(char* s);

struct _symbol {
    int type;
    char* token;
    int val;
    struct _symbol* next;
};
typedef struct _symbol* symbol;

symbol newsymbol(int type, char* token);
symbol addtosymboltable(int type, char* token);
int getsymbolvalue(char* token);
void setsymbolvalue(char* token, int val);

struct _treenode {
    int type;
    struct _treenode* left;
    struct _treenode* right;
    symbol sym;
};
typedef struct _treenode* treenode;

treenode newtreenode(int type);
void addleaf(treenode node, symbol sym);
void addchild(treenode node, treenode child);
int evaltree(treenode node);

%}

%union {char* num; char* id; int op; struct _treenode* node; }
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

STMT : SETSTMT { ; }
            | EXPRSTMT { ; }
            ;

SETSTMT : LP SET ID NUM RP { addtosymboltable(ID, $3); 
                             symbol tmp = addtosymboltable(NUM, $4); 
                             setsymbolvalue($3, tmp->val);
                             free($3);
                             free($4);
                           }
            | LP SET ID ID RP { addtosymboltable(ID, $3); 
                                int tmp = getsymbolvalue($4); 
                                setsymbolvalue($3, tmp); 
                                free($3);
                                free($4);
                              }
            | LP SET ID EXPR RP { addtosymboltable(ID, $3); 
                                  int tmp = evaltree($4); 
                                  setsymbolvalue($3, tmp); 
                                  free($3);
                                }
            ;

EXPRSTMT : EXPR { int eval = evaltree($1); 
                  printf("Standalone expression evaluates to %d\n", eval); 
                  $$ = eval; 
                }
            ;

EXPR : LP OP ARG ARG RP { treenode temp = newtreenode($2); 
                          addchild(temp, $3); 
                          addchild(temp, $4); 
                          $$ = temp; 
                        }
            ;

OP : PLUS { $$ = PLUS; }
            | MINUS { $$ = MINUS; }
            | DUBSTAR { $$ = DUBSTAR; }
            | STAR { $$ = STAR; }
            | DIV { $$ = DIV; }
            | MOD { $$ = MOD; }
            ;

ARG : ID { treenode temp = newtreenode(ID); 
           addleaf(temp, addtosymboltable(ID, $1)); 
           free($1);
           $$ = temp; 
         }
            | EXPR { $$ = $1; }
            | NUM { treenode temp = newtreenode(NUM); 
                    addleaf(temp, addtosymboltable(NUM, $1)); 
                    free($1);
                    $$ = temp; 
                  }
            ;
%%
