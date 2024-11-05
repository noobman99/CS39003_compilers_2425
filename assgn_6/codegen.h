#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int yylex();
void yyerror(char *s);

#define MAX_QUADS 1000
#define MAX_REG 20

typedef struct
{
    char op[10];
    char arg1[40];
    char arg2[40];
    char result[40];
    int assemblyIns;
} Quad;

typedef struct symbol
{
    char name[40];
    int reg;
    int isTemp;
    int isConst;
    int offset;
    int isMemsync;
    struct symbol *next;
} Symbol;

void emit(char *op, char *arg1, char *arg2, char *result);
void backpatch(int instructionNumber, int target);
void inialize_leaders();
void printQuads();

void markLeader(int ind);

Symbol *genTemp();
Symbol *lookup(char *name, int isTemp, int isConst);
