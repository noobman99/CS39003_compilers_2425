#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include "y.tab.h"
#include<setjmp.h>

void yyerror(char* s);
extern int yyparse();

struct _symbol {
    int type;
    char* token;
    int val;
    struct _symbol* next;
};
typedef struct _symbol* symbol;

struct _treenode {
    int type; // stores if its ID, NUM, TYPE of OPERATION
    struct _treenode* left;
    struct _treenode* right;
    symbol sym;
};
typedef struct _treenode* treenode;

// global variable symboltable
symbol symboltable;

// auxilary function to calculate power without mathlib.
int n_pow(int base, int power) {
    int res = 1;
    while (power > 0) {
        res *= base;
        power--;
    }
    return res;
}

symbol newsymbol(int type, char* token) {
    symbol sym = (symbol) malloc(sizeof(struct _symbol));
    sym->type = type;
    sym->token = strdup(token);
    sym->next = NULL;
    sym->val = 0;
    return sym;
}

symbol addtosymboltable(int type, char* token) {
    symbol temp = symboltable, prev;
    while (temp != NULL) {
        if (!strcmp(temp->token, token)) {
            return temp;
        }
        prev = temp;
        temp = temp->next;
    }

    if (symboltable) {
        prev->next = newsymbol(type, token);
        temp = prev->next;
    } else {
        symboltable = newsymbol(type, token);
        temp = symboltable;
    }

    // auto assign value if it is a number
    if (type == NUM) {
        temp->val = atoi(token);
    }

    return temp;
}

void setsymbolvalue(char* token, int val) {
    symbol temp = symboltable;
    while(temp != NULL) {
        if (!strcmp(temp->token, token)) {
            printf("Variable %s has been set to %d\n", token, val);
            temp->val = val;
            return;
        }
        temp = temp->next;
    }

    yyerror("Required symbol not found");
}

int getsymbolvalue(char* token) {
    symbol temp = symboltable;
    while(temp != NULL) {
        if (!strcmp(temp->token, token)) {
            return temp->val;
        }
        temp = temp->next;
    }

    yyerror("Required symbol not found");
}

void freesymboltable() {
    symbol curr = symboltable, next;
    while (curr != NULL)
    {
        next = curr->next;
        free(curr->token);
        free(curr);
        curr = next;
    }    
}

treenode newtreenode(int type) {
    treenode node = (treenode) malloc(sizeof(struct _treenode));
    node->type = type;
    node->left = NULL;
    node->right = NULL;
    node->sym = NULL;
    return node;
}

void addleaf(treenode node, symbol sym) {
    node->sym = sym;
}

void addchild(treenode node, treenode child) {
    if (node->left) {
        node->right = child;
    } else {
        node->left = child;
    }
}


int evaltree(treenode node) {
    if (node->type == ID || node->type == NUM) {
        int temp = node->sym->val;
        free(node);
        return temp;
    }

    // case where not a leaf node
    int l = 0, r = 0;
    if (node->left) {
        l = evaltree(node->left);
    } 
    if (node->right) {
        r = evaltree(node->right);
    }

    int opr = node->type;
    free(node);

    // type has what type of operation as well.
    switch (opr)
    {
    case PLUS:
        return l + r;
    case MINUS:
        return l - r;
    case STAR:
        return l * r;
    case DIV:
        if (r == 0) {
            yyerror("Divided by 0!");
        }
        return l / r;
    case MOD:
        if (r == 0) {
            yyerror("Mod by 0!");
        }
        if (r < 0) {
            yyerror("Mod by negative number!");
        }
        return l % r;
    case DUBSTAR:
        if (l == 0 && r == 0) {
            yyerror("0^0 form invalid!");
        }
        if (r < 0) {
            yyerror("Negative power not allowed!");
        }
        return n_pow(l, r);
    default:
        break;
    }
}

static jmp_buf buf;

int main() {
    symboltable = NULL;
    if (!setjmp(buf)) {
        yyparse();
    } else {
        printf("Ending parser because of error.");
    }
    freesymboltable();
}

void yyerror(char *s) {
    fprintf(stderr, "Error: %s\n", s);
    longjmp(buf, 1);
}