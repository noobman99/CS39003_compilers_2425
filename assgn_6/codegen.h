#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int yylex();
void yyerror(char *s);

#define MAX_QUADS 1000
#define MAX_REG 20
#define MAX_VARIABLE_NAME 20

// Assumption -- All variables names are less than 20 characters
typedef struct
{
    char op[5];
    char arg1[2 * MAX_VARIABLE_NAME + 10];
    char arg2[MAX_VARIABLE_NAME + 1];
    char result[MAX_VARIABLE_NAME + 1];
    int altIns;
} Quad;

typedef struct symbol
{
    char name[MAX_VARIABLE_NAME + 1];
    int reg;
    int isTemp;
    int isConst;
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
