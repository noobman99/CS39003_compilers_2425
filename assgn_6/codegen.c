#include "codegen.h"
#include "y.tab.h"

typedef struct symtab
{
    Symbol *head;
    struct symtab *next;
} Symtab;

typedef struct reg
{
    Symtab *symbols;
} Reg;

Quad Q[MAX_QUADS];
int Leaders[MAX_QUADS];
Reg registers[MAX_REG];
Symbol *SymbolTable;
int offset;
int tempIndex;
int nextInstruction;
int assmeblyIns;

Quad ASSEMBLY_CODE[MAX_QUADS];

int totReg;

extern int yyparse();

/* Symbol Table functions */

Symbol *newSymbol(char *name, int isTemp, int isConst)
{
    Symbol *new = (Symbol *)malloc(sizeof(Symbol));
    strcpy(new->name, name);
    new->reg = -1;
    new->isTemp = isTemp;
    new->isConst = isConst;
    if (isTemp == 0 && isConst == 0)
    {
        new->offset = offset;
        offset += 4;
    }
    else
    {
        new->offset = -1;
    }
    new->isMemsync = 1;
    new->next = NULL;
    return new;
}

Symbol *genTemp()
{
    char *tempName = (char *)malloc(20);
    sprintf(tempName, "$%d", tempIndex++);
    Symbol *temp = newSymbol(tempName, 1, 0);
    if (SymbolTable == NULL)
    {
        SymbolTable = temp;
        return temp;
    }
    Symbol *prev = SymbolTable;
    while (prev->next != NULL)
    {
        prev = prev->next;
    }
    prev->next = temp;
    return temp;
}

Symbol *lookup(char *name, int isTemp, int isConst)
{
    if (SymbolTable == NULL)
    {
        SymbolTable = newSymbol(name, isTemp, isConst);
        return SymbolTable;
    }

    Symbol *temp = SymbolTable;
    Symbol *prev = NULL;
    while (temp != NULL)
    {
        if (strcmp(temp->name, name) == 0)
        {
            return temp;
        }
        prev = temp;
        temp = temp->next;
    }

    Symbol *new = newSymbol(name, isTemp, isConst);
    prev->next = new;
    return new;
}

/* Quad functions */

void emit(char *op, char *arg1, char *arg2, char *result)
{
    strcpy(Q[nextInstruction].op, op);
    strcpy(Q[nextInstruction].arg1, arg1);
    strcpy(Q[nextInstruction].arg2, arg2);
    strcpy(Q[nextInstruction].result, result);
    nextInstruction++;
}

void emitAssembly(char *op, char *arg1, char *arg2, char *result)
{
    strcpy(ASSEMBLY_CODE[assmeblyIns].op, op);
    strcpy(ASSEMBLY_CODE[assmeblyIns].arg1, arg1);
    strcpy(ASSEMBLY_CODE[assmeblyIns].arg2, arg2);
    strcpy(ASSEMBLY_CODE[assmeblyIns].result, result);
    assmeblyIns++;
}

void backpatch(int instructionNumber, int target)
{
    if (strcmp(Q[instructionNumber].op, "ff") == 0 || strcmp(Q[instructionNumber].op, "gt") == 0)
    {
        char *gotoInstruction = (char *)malloc(20);
        sprintf(gotoInstruction, "%d", target);
        strcpy(Q[instructionNumber].result, gotoInstruction);
        free(gotoInstruction);
    }
}

void inialize_leaders()
{
    for (int i = 0; i < MAX_QUADS; i++)
    {
        Leaders[i] = 0;
    }
    Leaders[1] = 1;
}

void printQuads()
{
    int block = 1;
    for (int i = 1; i < nextInstruction; i++)
    {
        if (Leaders[i] != 0)
        {
            if (i != 1)
                printf("\n");
            printf("Block %d\n", block++);
        }

        if (strcmp(Q[i].op, "=") == 0)
        {
            printf("%d : %s = %s \n", i, Q[i].result, Q[i].arg1);
            continue;
        }
        else if (strcmp(Q[i].op, "gt") == 0)
        {
            printf("%d : goto %s \n", i, Q[i].result);
            continue;
        }
        else if (strcmp(Q[i].op, "ff") == 0)
        {
            printf("%d : iffalse %s goto %s \n", i, Q[i].arg1, Q[i].result);
            continue;
        }
        printf("%d : %s = %s %s %s \n", i, Q[i].result, Q[i].arg1, Q[i].op, Q[i].arg2);
    }
}

/* Register functions */

void spill(int reg, int forced)
{
    Symtab *temp = registers[reg].symbols;
    Symtab *prev = NULL;
    while (temp != NULL)
    {
        Symbol *sym = temp->head;
        if (sym->isMemsync == 0 && (forced == 1 || sym->isTemp == 0))
        {
            char *tmp = (char *)malloc(10);
            sprintf(tmp, "R%d", reg);
            emitAssembly("ST", sym->name, tmp, "");
            free(tmp);
        }
        sym->reg = -1;
        sym->isMemsync = 1;
        prev = temp;
        temp = temp->next;
        free(prev);
    }
    registers[reg].symbols = NULL;
}

void removeSymbol(Symbol *sym)
{
    Symtab *temp = registers[sym->reg].symbols;
    if (temp->head == sym)
    {
        registers[sym->reg].symbols = temp->next;
        free(temp);
        return;
    }
    Symtab *prev = NULL;
    while (temp != NULL)
    {
        if (temp->head == sym)
        {
            prev->next = temp->next;
            free(temp);
            return;
        }
        prev = temp;
        temp = temp->next;
    }
}

Symtab *newSymbolWrap(Symbol *sym)
{
    Symtab *tmp = (Symtab *)malloc(sizeof(Symtab));
    tmp->head = sym;
    tmp->next = NULL;

    return tmp;
}

void addSymbol(int reg, Symbol *sym)
{
    Symtab *temp = registers[reg].symbols;

    if (sym->reg != -1)
    {
        removeSymbol(sym);
    }

    if (temp == NULL)
    {
        registers[reg].symbols = newSymbolWrap(sym);
        sym->reg = reg;
        return;
    }

    if (temp->head == sym)
    {
        return;
    }

    while (temp->next != NULL)
    {
        temp = temp->next;
        if (temp->head == sym)
        {
            return;
        }
    }

    temp->next = newSymbolWrap(sym);
    sym->reg = reg;
}

void freeRegs()
{
    for (int i = 0; i < totReg; i++)
    {
        spill(i, 0);
    }
}

int getReg(Symbol *sym, int isRes)
{
    if (sym->reg != -1)
    {
        if (registers[sym->reg].symbols->next == NULL || isRes == 0)
        {
            if (isRes == 1)
            {
                sym->isMemsync = 0;
            }
            return sym->reg;
        }
    }

    for (int i = 0; i < totReg; i++)
    {
        if (registers[i].symbols == NULL)
        {
            if (isRes == 1)
            {
                sym->isMemsync = 0;
            }
            else
            {
                char *tmp = (char *)malloc(10);
                sprintf(tmp, "R%d", i);
                emitAssembly("LD", tmp, sym->name, "");
                free(tmp);
            }
            addSymbol(i, sym);
            return i;
        }
    }

    int min_score = 1000000, min_reg = -1;
    for (int i = 0; i < totReg; i++)
    {
        int score = 0;
        Symtab *temp = registers[i].symbols;
        while (temp != NULL)
        {
            if (temp->head->isMemsync == 0)
            {
                score++;
            }
            // if the symbol is a temporary variable, give it a higher score, so that it is not spilled first
            if (temp->head->isTemp)
            {
                score += 10;
            }
            temp = temp->next;
        }
        if (score < min_score)
        {
            min_score = score;
            min_reg = i;
        }
    }

    spill(min_reg, 1);

    if (isRes == 1)
    {
        sym->isMemsync = 0;
    }
    else
    {
        char *tmp = (char *)malloc(10);
        sprintf(tmp, "R%d", min_reg);
        emitAssembly("LD", tmp, sym->name, "");
        free(tmp);
    }
    addSymbol(min_reg, sym);

    return min_reg;
}

char *getName(char *sym_name)
{
    Symbol *sym = lookup(sym_name, 0, 0);
    char *arg1_name = (char *)malloc(10);
    if (sym->isConst)
    {
        strcpy(arg1_name, sym_name);
    }
    else
    {
        int arg1_reg = getReg(sym, 0);
        sprintf(arg1_name, "R%d", arg1_reg);
    }

    return arg1_name;
}

void generateTargetCode()
{
    int block = 1;
    for (int i = 1; i < nextInstruction; i++)
    {
        if (strcmp(Q[i].op, "=") == 0)
        {
            Symbol *arg1 = lookup(Q[i].arg1, 0, 0);
            Symbol *result = lookup(Q[i].result, 0, 0);
            if (arg1->isConst)
            {
                int result_reg = getReg(result, 1);
                char *tmp = (char *)malloc(10);
                sprintf(tmp, "R%d", result_reg);
                emitAssembly("LDI", tmp, Q[i].arg1, "");
                free(tmp);
            }
            else
            {
                int arg_reg = getReg(arg1, 0);
                addSymbol(arg_reg, result);
                result->isMemsync = 0;
            }

            if (Leaders[i + 1] != 0)
            {
                freeRegs();
            }
        }
        else if (strcmp(Q[i].op, "gt") == 0)
        {
            freeRegs();
            emitAssembly("JMP", "", "", Q[i].result);
        }
        else if (strcmp(Q[i].op, "ff") == 0)
        {
            // Read arg1, operation, arg2 from Q[i].arg1
            char *arg1, *operation, *arg2;
            sscanf(Q[i].arg1, "%m[^ ] %m[^ ] %m[^\n]", &arg1, &operation, &arg2);

            char *arg1_name = getName(arg1);
            char *arg2_name = getName(arg2);

            freeRegs();

            char opr[5];

            if (strcmp(operation, "=") == 0)
            {
                strcpy(opr, "JNE");
            }
            else if (strcmp(operation, "/=") == 0)
            {
                strcpy(opr, "JEQ");
            }
            else if (strcmp(operation, "<") == 0)
            {
                strcpy(opr, "JGE");
            }
            else if (strcmp(operation, ">") == 0)
            {
                strcpy(opr, "JLE");
            }
            else if (strcmp(operation, "<=") == 0)
            {
                strcpy(opr, "JGT");
            }
            else if (strcmp(operation, ">=") == 0)
            {
                strcpy(opr, "JLT");
            }

            emitAssembly(opr, arg1_name, arg2_name, Q[i].result);

            free(arg1_name);
            free(arg2_name);
        }
        else
        {
            char *arg1_name = getName(Q[i].arg1);
            char *arg2_name = getName(Q[i].arg2);

            Symbol *result = lookup(Q[i].result, 1, 0);
            int result_reg = getReg(result, 1);

            char operation = Q[i].op[0];
            char opr[5];

            switch (operation)
            {
            case '+':
                strcpy(opr, "ADD");
                break;
            case '-':
                strcpy(opr, "SUB");
                break;
            case '*':
                strcpy(opr, "MUL");
                break;
            case '/':
                strcpy(opr, "DIV");
                break;
            case '%':
                strcpy(opr, "MOD");
                break;
            }

            char *tmp = (char *)malloc(10);
            sprintf(tmp, "R%d", result_reg);

            emitAssembly(opr, arg1_name, arg2_name, tmp);

            free(arg1_name);
            free(arg2_name);
            free(tmp);

            if (Leaders[i + 1] != 0)
            {
                freeRegs();
            }
        }

        Q[i].assemblyIns = assmeblyIns - 1;
    }
}

void printAssembly()
{
    for (int i = 1; i < assmeblyIns; i++)
    {
        printf("%d: %s %s %s %s\n", i, ASSEMBLY_CODE[i].op, ASSEMBLY_CODE[i].arg1, ASSEMBLY_CODE[i].arg2, ASSEMBLY_CODE[i].result);
    }
}

int main(int argc, char **argv)
{
    if (argc > 1)
    {
        // set totReg to the value of the first argument
        totReg = atoi(argv[1]);
    }
    else
    {
        // set totReg to 5 if no argument is provided
        totReg = 5;
    }
    setbuf(stdout, NULL);
    SymbolTable = NULL;
    tempIndex = 1;
    assmeblyIns = 1;
    nextInstruction = 1;
    inialize_leaders();
    yyparse();
    printQuads();
    printf("\n\n\n\n\n\n");
    generateTargetCode();
    printAssembly();
    return 0;
}

void yyerror(char *s)
{
    fprintf(stderr, "%s\n", s);
}