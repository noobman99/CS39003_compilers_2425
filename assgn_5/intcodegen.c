#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "y.tab.h"

void yyerror(char *s);
extern int yyparse();

// Structure Definitions
struct _symboltablenode
{
    char *name;
    int offset;
    struct _symboltablenode *next;
};
typedef struct _symboltablenode *symboltablenode;

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

// Global Variables
int MEMIDX = 0;
int REGIDX = 2;
int TEMPVAR = 0;
int R0OCCUPIED = 0;
symboltablenode SYMBOLTABLE = NULL;
FILE *outputfile;

// Function Declarations

// Symbol Table Functions
int addtosymboltable(char *name)
{
    if (SYMBOLTABLE == NULL)
    {
        SYMBOLTABLE = (symboltablenode)malloc(sizeof(struct _symboltablenode));
        SYMBOLTABLE->name = strdup(name);
        SYMBOLTABLE->next = NULL;
        SYMBOLTABLE->offset = MEMIDX;
    }
    else
    {
        symboltablenode temp = SYMBOLTABLE;
        symboltablenode par;
        while (temp != NULL)
        {
            if (strcmp(temp->name, name) == 0)
            {
                return temp->offset;
            }
            par = temp;
            temp = temp->next;
        }
        par->next = (symboltablenode)malloc(sizeof(struct _symboltablenode));
        par->next->name = strdup(name);
        par->next->next = NULL;
        par->next->offset = MEMIDX;
    }

    return MEMIDX++;
}

int getfromsymboltable(char *name)
{
    symboltablenode temp = SYMBOLTABLE;
    while (temp != NULL)
    {
        if (strcmp(temp->name, name) == 0)
        {
            return temp->offset;
        }
        temp = temp->next;
    }
    return -1;
}

void freesymboltable()
{
    symboltablenode temp = SYMBOLTABLE;
    symboltablenode par;
    while (temp != NULL)
    {
        par = temp;
        temp = temp->next;
        free(par->name);
        free(par);
    }
}

// Temporary Variable Functions
tempaddr gettemp()
{
    if (REGIDX > 11)
    {
        char *tmp = (char *)malloc(sizeof(char) * 10);
        sprintf(tmp, "$%d", TEMPVAR++);
        int offset = addtosymboltable(tmp);
        tempaddr addr = {offset, 1};
        // fprintf(outputfile, "// Reached end of registers. address - %d\n", offset);
        return addr;
    }
    else
    {
        tempaddr addr = {REGIDX, 0};
        REGIDX++;
        return addr;
    }
}

// Parse Node Functions
parsenode createparsenode(int addr, int type)
{
    // TYPE 0 = REG, TYPE 1 = MEM, TYPE 2 = IMM
    parsenode node = (parsenode)malloc(sizeof(struct _parsenode));
    node->addr = addr;
    node->type = type;
    return node;
}

// Code Generation Functions
int loadfrommem(int idx)
{
    if (R0OCCUPIED)
    {
        fprintf(outputfile, "   R[1] = MEM[%d];\n", idx);
        return 1;
    }
    else
    {
        fprintf(outputfile, "   R[0] = MEM[%d];\n", idx);
        R0OCCUPIED = 1;
        return 0;
    }
}

void printexpression(parsenode node)
{
    if (node->type == 0)
    {
        fprintf(outputfile, "   eprn(R, %d);\n", node->addr);
    }
    else if (node->type == 1)
    {
        fprintf(outputfile, "   R[0] = MEM[%d];\n", node->addr);
        fprintf(outputfile, "   eprn(R, 0);\n");
    }
    else
    {
        fprintf(outputfile, "   R[2] = %d;\n", node->addr);
        fprintf(outputfile, "   eprn(R, 2);\n");
    }
}

char *getterm(parsenode node)
{
    char *term = (char *)malloc(10 * sizeof(char));
    switch (node->type)
    {
    case 0:
        sprintf(term, "R[%d]", node->addr);
        break;
    case 1:
        sprintf(term, "R[%d]", loadfrommem(node->addr));
        break;
    case 2:
        sprintf(term, "%d", node->addr);
        break;
    default:
        break;
    }
    return term;
}

// State Management Functions
void setreg(int reg)
{
    REGIDX = reg;
}
void resetreg()
{
    REGIDX = 2;
}
void clearR0()
{
    R0OCCUPIED = 0;
}

int main()
{
    outputfile = fopen("intcode.c", "w");
    fprintf(outputfile, "#include <stdio.h>\n#include <stdlib.h>\n#include \"aux.c\"\n\nint main ( )\n{\n   int R[12];\n   int MEM[65536];\n\n");
    yyparse();
    fprintf(outputfile, "\n   exit(0);\n}");
    fclose(outputfile);
    freesymboltable();
}

void yyerror(char *s)
{
    fprintf(stderr, "Error: %s\n", s);
}