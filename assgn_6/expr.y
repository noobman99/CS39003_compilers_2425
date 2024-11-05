%{
#include "codegen.h"

extern Quad Q[MAX_QUADS];
extern int Leaders[MAX_QUADS];
extern int tempIndex;
extern int nextInstruction;

%}

%union {
    int num;
    char *str;
    struct symbol *sym;
}

// Define terminals
%token <str> IDEN NUMB
%token SET WHEN WHILE LP RP
%token <str> EQ LT GT PLUS MINUS DIV MUL REM LE GE NE

// Define non-terminals
%type LIST STMT ASGN COND LOOP
%type <num> BOOL M
%type <str> RELN OPER
%type <sym> ATOM EXPR

%%
LIST: STMT
    | STMT LIST;

STMT: ASGN
    | COND
    | LOOP;

ASGN: LP SET IDEN ATOM RP {
        Symbol* var = lookup($3, 0, 0); // Lookup variable
        emit("=", $4->name, "", var->name); // Generate assignment quad
    };

COND: LP WHEN M BOOL M LIST RP {
        backpatch($4, nextInstruction); // Backpatch false label
        Leaders[nextInstruction] = 1; // Mark end of condition as leader
    };

LOOP: LP WHILE M BOOL M LIST RP {
        backpatch($4, nextInstruction + 1); // Backpatch loop false label
        char *tempVar = (char*)malloc(20);
        sprintf(tempVar, "%d", $3);
        emit("gt", "", "", tempVar); // Generate goto quad
        free(tempVar);
        Leaders[nextInstruction] = 1; // Mark loop end as leader
    };

M: {
        Leaders[nextInstruction] = 1; // Mark loop start as leader
        $$ = nextInstruction; // Return current instruction number for backpatching
    };

ATOM: IDEN { $$ = lookup($1, 0, 0); }
    | NUMB { $$ = lookup($1, 0, 1); }
    | EXPR;

EXPR: LP OPER ATOM ATOM RP {
        Symbol *tempVar = genTemp(); // Create temporary variable
        emit($2, $3->name, $4->name, tempVar->name); // Generate operation quad
        $$ = tempVar; // Return temporary variable as result of expression
    };

BOOL: LP RELN ATOM ATOM RP {
        char *comparison = (char*)malloc(40);
        sprintf(comparison, "%s %s %s", $3->name, $2, $4->name); // Create comparison string for backpatching

        $$ = nextInstruction;

        emit("ff", comparison, "", ""); // Generate iffalse quad

        free(comparison);
    };

RELN: EQ | NE | LT | GT | LE | GE;

OPER: PLUS | MINUS | DIV | MUL | REM;

%%
