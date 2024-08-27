#include <iostream>
#include <stack>
#include "lex.yy.c"

// compile using 'g++ evalexpr.cpp'

using namespace std;

// The tokens from lex
#define EXPR_BEGIN 1
#define EXPR_END 2
#define VARIABLE 3
#define CONSTANT 4
#define OPERATION 5

// The grammar for given expression
// EXPR -> EXP_ST OP ARG ARG EXP_EN
// ARG -> TERM | EXPR
// OP -> +|-|*|/|%
// TERM -> id | num
// EXP_ST -> (
// EXP_EN -> )
#define EXPR 0
#define ARG 1
#define OP 2
#define TERM 3
#define EXP_ST 4
#define EXP_EN 5

int expr_eval[6] = {EXP_EN, ARG, ARG, OP, EXP_ST, -1};
int arg_term_eval[2] = {TERM, -1};
int arg_expr_eval[2] = {EXPR, -1};
int error_eval[1] = {-2};
int esp_eval[1] = {-1};

int* PARSER_TABLE[6][5] = {
 {expr_eval, error_eval, error_eval, error_eval, error_eval},
 {arg_expr_eval, error_eval, arg_term_eval, arg_term_eval, error_eval},
 {error_eval, error_eval, error_eval, error_eval, esp_eval},
 {error_eval, error_eval, esp_eval, esp_eval, error_eval},
 {esp_eval, error_eval, error_eval, error_eval, error_eval},
 {error_eval, esp_eval, error_eval, error_eval, error_eval}
 };

extern int yylex();
extern char* yytext;

typedef struct _idlinkedlistnode
{
    char* symbol;
    int value;
    struct _idlinkedlistnode* next;
} idlinkedlistnode;

typedef struct _numlinkedlistnode
{
    int value;
    struct _numlinkedlistnode* next;
} numlinkedlistnode;

typedef struct _treenode {
    struct _treenode* left;
    struct _treenode* right;
    struct _treenode* parent;
    int type; 
    union
    {
        /* data */
        idlinkedlistnode* id;
        numlinkedlistnode* num;
        char opr;
    } ref;
} treenode;


// returns popped stack top -- to be used to move counter
int predictive_parse(stack<int> &S, int token, char* token_text) {
    if (S.empty()) {
        cout << "Invalid Syntax" << endl;
        exit(1);
    }

    int stack_top = S.top();
    int* to_push = PARSER_TABLE[stack_top][token - 1];
    int pushed_cnt = 0;
    S.pop();

    while (to_push[pushed_cnt] >= 0) {
        S.push(to_push[pushed_cnt]);
        pushed_cnt++;
    }

    // Error Handling during parsing 
    if (to_push[pushed_cnt] == -2) {
        cout << "*** Error: ";
        switch (stack_top)
        {
        case EXPR:
            cout << "Left paranthesis";
            break;
        case ARG:
            cout << "ID|NUM|LP";
            break;
        case OP:
            cout << "Operator";
            break;
        case EXP_EN:
            cout << "Right parenthesis";
            break;
        default:
            break;
        }

        cout << " expected in place of " << token_text << endl;

        exit(1);
    }

    return stack_top;
}

// Code to add to table of IDs
idlinkedlistnode* new_node(char* token) {
    idlinkedlistnode* node = (idlinkedlistnode *) malloc(sizeof(idlinkedlistnode));
    node->symbol = strdup(token);
    node->value = 0;
    node->next = NULL;

    return node;
}
idlinkedlistnode* add_to_table(idlinkedlistnode* table_head,char* token) {
    idlinkedlistnode* curr = table_head;
    idlinkedlistnode* par = NULL;
    while (curr != NULL)
    {
        if (!strcmp(curr->symbol, token)) break;

        par = curr;
        curr = curr->next;
    }
    if (curr == NULL) {
        if (par == NULL) {
            curr = new_node(token);
        } else {
            par->next = new_node(token);
            curr = par->next;
        }
    }

    return curr;
}

// Code to add to table of constants (does not have a symbol field)
numlinkedlistnode* new_node(int val) {
    numlinkedlistnode* node = (numlinkedlistnode *) malloc(sizeof(numlinkedlistnode));
    node->value = val;
    node->next = NULL;

    return node;
}
numlinkedlistnode* add_to_table(numlinkedlistnode* table_head,int token) {
    numlinkedlistnode* curr = table_head;
    numlinkedlistnode* par = NULL;
    while (curr != NULL)
    {
        if (curr->value == token) break;

        par = curr;
        curr = curr->next;
    }
    if (curr == NULL) {
        if (par == NULL) {
            curr = new_node(token);
        } else {
            par->next = new_node(token);
            curr = par->next;
        }
    }

    return curr;
}

// generate a new tree node
treenode* new_tree_node(treenode* parent, int type) {
    treenode* node = (treenode *) malloc(sizeof(treenode));
    node->left = NULL;
    node->right = NULL;
    node->parent = parent;
    node->type = type;

    return node;
}

// recursively print nodes of the tree
void print_tree(treenode* root, int level) {
    for (int i=0; i<level; i++) {
        cout << "  ";
    }
    cout << "--->";
    switch (root->type)
    {
        case OPERATION:
            cout << "OP(" << root->ref.opr << ")\n";
            if (root->left) {
                print_tree(root->left, level + 1);
            }
            if (root->right) {
                print_tree(root->right, level + 1);
            }
            break;
        case CONSTANT:
            cout << "NUM(" << root->ref.num->value << ")\n";
            break;
        case VARIABLE:
            cout << "ID(" << root->ref.id->symbol << ")\n";
            break;
        default:
            break;
    }
}

// take values of variables from input
void evaluate_variables(idlinkedlistnode *table) {
    idlinkedlistnode* curr = table;
    int tok;
    
    cout << "Reading variable values from the input" << endl;
    while (curr)
    {
        tok = yylex();
        if (!tok) {
            cout << "Did not find enough values" << endl;
            exit(1);
        }
        if (tok != CONSTANT) {
            cout << "Expected an integer value for " << curr->symbol << " instead found " << yytext << endl;
            exit(1);
        }

        curr->value = stoi(yytext);
        cout << curr->symbol << " = " << curr->value << endl;

        curr = curr->next;
    }
}

// recursively evaluate tree
int evaluate_tree(treenode* root) {
    // base case, root->type != 0 (NOT AN OPERATION)
    if (root->type != OPERATION) {
        return (root->type == CONSTANT) ? root->ref.num->value : root->ref.id->value;
    }

    int lval = 0, rval = 0, out = 0;
    if (root->left) {
        lval = evaluate_tree(root->left);
    }
    if (root->right) {
        rval = evaluate_tree(root->right);
    }

    switch (root->ref.opr)
    {
        case '+':
            out = lval + rval;
            break;
        case '-':
            out = lval - rval;
            break;
        case '*':
            out = lval * rval;
            break;
        case '/':
            out = lval / rval;
            break;
        case '%':
            out = lval % rval;
            break;
        default:
            break;
    }

    return out;
}

int main() {
    int tok, stack_top;
    idlinkedlistnode* id_table = NULL;
    numlinkedlistnode* constant_table = NULL;
    treenode* parse_tree = NULL;
    stack<int> parse_stack;
    parse_stack.push(0);
    while ( !parse_stack.empty() && (tok = yylex())) {
        // Error for invalid token
        if (tok == 6) {
            cout << "Invalid token detected: " << yytext << endl;
            exit(1);
        }

        stack_top = predictive_parse(parse_stack, tok, yytext);
        // if stack_top < 2, the grammar symbol does not produce a terminal
        while (stack_top < 2) {
            stack_top = predictive_parse(parse_stack, tok, yytext);
        }

        // we move to the next token as well while adding current token to parse tree
        switch (stack_top)
        {
            case OP:
                if (parse_tree == NULL) {
                    parse_tree = new_tree_node(NULL, OPERATION);
                } else {
                    if (parse_tree->left == NULL) {
                        parse_tree->left = new_tree_node(parse_tree, OPERATION);
                        parse_tree = parse_tree->left;
                    } else {
                        while(parse_tree->right != NULL && parse_tree->parent != NULL) {
                            parse_tree = parse_tree->parent;
                        }
                        parse_tree->right = new_tree_node(parse_tree, OPERATION);
                        parse_tree = parse_tree->right;
                    }
                }
                parse_tree->ref.opr = *yytext;
                break;
            case TERM:
                {
                    treenode* temptreenode;
                    if (tok == CONSTANT) {
                        temptreenode = new_tree_node(parse_tree, CONSTANT);
                        temptreenode->ref.num = add_to_table(constant_table, stoi(yytext));
                        if (constant_table == NULL) {
                            constant_table = temptreenode->ref.num;
                        }
                    } else {
                        temptreenode = new_tree_node(parse_tree, VARIABLE);
                        temptreenode->ref.id = add_to_table(id_table, yytext);
                        if (id_table == NULL) {
                            id_table = temptreenode->ref.id;
                        }
                    }
                    if (parse_tree->left == NULL) {
                        parse_tree->left = temptreenode;
                    } else {
                        while(parse_tree->right != NULL && parse_tree->parent != NULL) {
                            parse_tree = parse_tree->parent;
                        }
                        parse_tree->right = temptreenode;
                    }
                }
                break;
            // in case the stack_top is EXP_ST or EXP_EN, we do not need to process that token
            default:
                break;
        }
    }

    // Reset the parse_tree to its root
    while (parse_tree->parent != NULL) {
        parse_tree = parse_tree->parent;
    }

    cout << "Parsing is successful" << endl;
    // print parse tree
    print_tree(parse_tree, 0);

    // input variables
    if (id_table) {
        evaluate_variables(id_table);
    }

    // evaluate parse tree
    cout << "The expression evaluates to " << evaluate_tree(parse_tree) << endl;
}
