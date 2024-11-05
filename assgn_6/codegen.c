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
            printf("%d: ST %s, R%d\n", assmeblyIns++, sym->name, reg);
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

void addSymbol(int reg, Symbol *sym)
{
    Symtab *temp = registers[reg].symbols;

    if (sym->reg != -1)
    {
        removeSymbol(sym);
    }

    if (temp == NULL)
    {
        registers[reg].symbols = (Symtab *)malloc(sizeof(Symtab));
        registers[reg].symbols->head = sym;
        sym->reg = reg;
        registers[reg].symbols->next = NULL;
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

    temp->next = (Symtab *)malloc(sizeof(Symtab));
    temp->next->head = sym;
    sym->reg = reg;
    temp->next->next = NULL;
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
        Reg reg = registers[sym->reg];
        Symtab *temp = reg.symbols;
        if (temp->next == NULL || isRes == 0)
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
                printf("%d: LD R%d, %s\n", assmeblyIns++, i, sym->name);
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
        printf("%d: LD R%d, %s\n", assmeblyIns++, min_reg, sym->name);
    }
    addSymbol(min_reg, sym);

    return min_reg;
}

void generateTargetCode()
{
    int block = 1;
    for (int i = 1; i < nextInstruction; i++)
    {
        if (Leaders[i] != 0)
        {
            printf("\nBlock %d\n", block++);
        }

        if (strcmp(Q[i].op, "=") == 0)
        {
            Symbol *arg1 = lookup(Q[i].arg1, 0, 0);
            Symbol *result = lookup(Q[i].result, 0, 0);
            if (arg1->isConst)
            {
                int result_reg = getReg(result, 1);
                printf("%d: LDI R%d %s\n", assmeblyIns++, result_reg, Q[i].arg1);
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
            printf("%d: JMP %s\n", assmeblyIns++, Q[i].result);
        }
        else if (strcmp(Q[i].op, "ff") == 0)
        {
            // Read arg1, operation, arg2 from Q[i].arg1
            char *arg1, *operation, *arg2;
            sscanf(Q[i].arg1, "%m[^ ] %m[^ ] %m[^\n]", &arg1, &operation, &arg2);
            Symbol *arg1_sym = lookup(arg1, 0, 0);
            char *arg1_name = (char *)malloc(10);
            if (arg1_sym->isConst)
            {
                strcpy(arg1_name, arg1);
            }
            else
            {
                int arg1_reg = getReg(arg1_sym, 0);
                sprintf(arg1_name, "R%d", arg1_reg);
            }
            Symbol *arg2_sym = lookup(arg2, 0, 0);
            char *arg2_name = (char *)malloc(10);
            if (arg2_sym->isConst)
            {
                strcpy(arg2_name, arg2);
            }
            else
            {
                int arg2_reg = getReg(arg2_sym, 0);
                sprintf(arg2_name, "R%d", arg2_reg);
            }

            freeRegs();
            if (strcmp(operation, "=") == 0)
            {
                printf("%d: JNE %s %s %s\n", assmeblyIns++, arg1_name, arg2_name, Q[i].result);
            }
            else if (strcmp(operation, "/=") == 0)
            {
                printf("%d: JEQ %s %s %s\n", assmeblyIns++, arg1_name, arg2_name, Q[i].result);
            }
            else if (strcmp(operation, "<") == 0)
            {
                printf("%d: JGE %s %s %s\n", assmeblyIns++, arg1_name, arg2_name, Q[i].result);
            }
            else if (strcmp(operation, ">") == 0)
            {
                printf("%d: JLE %s %s %s\n", assmeblyIns++, arg1_name, arg2_name, Q[i].result);
            }
            else if (strcmp(operation, "<=") == 0)
            {
                printf("%d: JGT %s %s %s\n", assmeblyIns++, arg1_name, arg2_name, Q[i].result);
            }
            else if (strcmp(operation, ">=") == 0)
            {
                printf("%d: JLT %s %s %s\n", assmeblyIns++, arg1_name, arg2_name, Q[i].result);
            }

            if (Leaders[i + 1] != 0)
            {
                freeRegs();
            }
        }
        else
        {
            Symbol *arg1 = lookup(Q[i].arg1, 0, 0);
            char *arg1_name = (char *)malloc(10);
            if (arg1->isConst)
            {
                strcpy(arg1_name, Q[i].arg1);
            }
            else
            {
                int arg1_reg = getReg(arg1, 0);
                sprintf(arg1_name, "R%d", arg1_reg);
            }
            Symbol *arg2 = lookup(Q[i].arg2, 0, 0);
            char *arg2_name = (char *)malloc(10);
            if (arg2->isConst)
            {
                strcpy(arg2_name, Q[i].arg2);
            }
            else
            {
                int arg2_reg = getReg(arg2, 0);
                sprintf(arg2_name, "R%d", arg2_reg);
            }
            Symbol *result = lookup(Q[i].result, 1, 0);
            int result_reg = getReg(result, 1);

            char operation = Q[i].op[0];

            switch (operation)
            {
            case '+':
                printf("%d: ADD R%d %s %s\n", assmeblyIns++, result_reg, arg1_name, arg2_name);
                break;
            case '-':
                printf("%d: SUB R%d %s %s\n", assmeblyIns++, result_reg, arg1_name, arg2_name);
                break;
            case '*':
                printf("%d: MUL R%d %s %s\n", assmeblyIns++, result_reg, arg1_name, arg2_name);
                break;
            case '/':
                printf("%d: DIV R%d %s %s\n", assmeblyIns++, result_reg, arg1_name, arg2_name);
                break;
            case '%':
                printf("%d: MOD R%d %s %s\n", assmeblyIns++, result_reg, arg1_name, arg2_name);
                break;
            }

            free(arg1_name);
            free(arg2_name);

            if (Leaders[i + 1] != 0)
            {
                freeRegs();
            }
        }

        Q[i].assemblyIns = assmeblyIns - 1;
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
    return 0;
}

void yyerror(char *s)
{
    fprintf(stderr, "%s\n", s);
}