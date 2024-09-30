%{
#include <stdio.h>
#include <stdlib.h>
int yylex();
void yyerror(char* s);

struct nodechild;

struct _node
{
    int type;
    int inh;
    int val;
    int nchildren;
    struct _nodechild *children;
};

struct _nodechild
{
    struct _node *node;
    struct _nodechild *next;
};

typedef struct _node *node;
typedef struct _nodechild *nodechild;

node newNode(int type);
void addChild(node parent, node child);

node root;

%}

%union {int num; char* id; struct _node* node;}
%token PLUS MINUS EXP ZERO ONE XSYM
%token <num> D
// defining tokens for non terminal symbols
%token  SS TT PP XX NN MM
%type <node> S T P X N M
%start S

%%
S: P {$$ = newNode(SS); addChild($$, $1); root = $$; root = $$; }
    |  PLUS P {$$ = newNode(SS); node temp = newNode(PLUS); temp->val = '+'; addChild($$, temp); addChild($$, $2); root = $$; }
    |  MINUS P {$$ = newNode(SS); node temp = newNode(MINUS); temp->val = '-'; addChild($$, temp); addChild($$, $2); root = $$; }
    ;

P: T {$$ = newNode(PP); addChild($$, $1);}
    |  T PLUS P {$$ = newNode(PP); addChild($$, $1); node temp = newNode(PLUS); temp->val = '+'; addChild($$, temp); addChild($$, $3);}
    |  T MINUS P {$$ = newNode(PP); addChild($$, $1); node temp = newNode(MINUS); temp->val = '-'; addChild($$, temp); addChild($$, $3);}
    ;

T: ONE {$$ = newNode(TT); node temp = newNode(ONE); temp->val = 1; addChild($$, temp);}
    | N {$$ = newNode(TT); addChild($$, $1);}
    | X {$$ = newNode(TT); addChild($$, $1);}
    | N X {$$ = newNode(TT); addChild($$, $1); addChild($$, $2);}
    ;

X : XSYM {$$ = newNode(XX); node temp = newNode(XSYM); addChild($$, temp);}
    | XSYM EXP N {$$ = newNode(XX); node temp = newNode(XSYM); addChild($$, temp); temp = newNode(EXP); temp->val = '^'; addChild($$, temp); addChild($$, $3);}
    ;

N: D {$$ = newNode(NN); node temp = newNode(D); temp->val = $1; addChild($$, temp);}
    | ONE M {$$ = newNode(NN); node temp = newNode(ONE); temp->val = 1; addChild($$, temp); addChild($$, $2);}
    | D M {$$ = newNode(NN); node temp = newNode(D); temp->val = $1; addChild($$, temp); addChild($$, $2);}
    ;

M: ZERO {$$ = newNode(MM); node temp = newNode(ZERO); temp->val = 0; addChild($$, temp);}
    | ONE {$$ = newNode(MM); node temp = newNode(ONE); temp->val = 1; addChild($$, temp);}
    | D {$$ = newNode(MM); node temp = newNode(D); temp->val = $1; addChild($$, temp);}
    | ZERO M {$$ = newNode(MM); node temp = newNode(ZERO); temp->val = 0; addChild($$, temp); addChild($$, $2);}
    | ONE M {$$ = newNode(MM); node temp = newNode(ONE); temp->val = 1; addChild($$, temp); addChild($$, $2);}
    | D M {$$ = newNode(MM); node temp = newNode(D); temp->val = $1; addChild($$, temp); addChild($$, $2);}
    ;
%%
