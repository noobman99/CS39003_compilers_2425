#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#define KEYWORD 1
#define IDENTIFIER 2
#define INTEGER_CONSTANT 3
#define FLOATING_CONSTANT 4
#define CHAR_CONSTANT 5
#define STRING_LITERAL 6
#define PUNCTUATOR 7
#define COMMENT 8
#define MULTI_LINE_COMMENT 9
#define INVALID 100

extern char *yytext;
extern int yylex();

const char *tokennames[] = {
    "",
    "KEYWORD",
    "IDENTIFIER",
    "CONSTANT",
    "CONSTANT",
    "CONSTANT",
    "STRING LITERAL",
    "PUNCTUATOR",
};

typedef struct _keyword
{
    char *word;
    int frequency;
} keyword;

keyword keywords[] = {
    {"auto", 0},
    {"break", 0},
    {"case", 0},
    {"char", 0},
    {"const", 0},
    {"continue", 0},
    {"default", 0},
    {"do", 0},
    {"double", 0},
    {"else", 0},
    {"enum", 0},
    {"extern", 0},
    {"float", 0},
    {"for", 0},
    {"goto", 0},
    {"if", 0},
    {"inline", 0},
    {"int", 0},
    {"long", 0},
    {"register", 0},
    {"restrict", 0},
    {"return", 0},
    {"short", 0},
    {"signed", 0},
    {"sizeof", 0},
    {"static", 0},
    {"struct", 0},
    {"switch", 0},
    {"typedef", 0},
    {"union", 0},
    {"unsigned", 0},
    {"void", 0},
    {"volatile", 0},
    {"while", 0},
    {"_Bool", 0},
    {"_Complex", 0},
    {"_Imaginary", 0},
};

const int keyword_count = sizeof(keywords) / sizeof(keyword);

void addkeyword(char *token)
{
    for (int i = 0; i < keyword_count; i++)
    {
        if (strcmp(keywords[i].word, token) == 0)
        {
            keywords[i].frequency++;
            return;
        }
    }
}

void printkeywords()
{
    printf("Keyword count :\n");
    for (int i = 0; i < keyword_count; i++)
    {
        printf("%s: %d\n", keywords[i].word, keywords[i].frequency);
    }
}

typedef struct _llnode
{
    char *value;
    int type;
    int frequency;
    struct _llnode *next;
} llnode;

llnode *create_node(char *token, int type)
{
    llnode *c = (llnode *)malloc(sizeof(llnode));
    c->value = strdup(token);
    c->type = type;
    c->frequency = 1;
    return c;
}

llnode *add_symbol(llnode *head, char *token, int type)
{
    llnode *temp = head;
    llnode *par = head;
    while (temp != NULL)
    {
        if (strcmp(temp->value, token) == 0)
        {
            temp->frequency++;
            return head;
        }

        par = temp;
        temp = temp->next;
    }
    if (par != NULL)
    {
        par->next = create_node(token, type);
    }
    else
    {
        head = create_node(token, type);
    }

    return head;
}

void print_symbols(llnode *head)
{
    printf("Symbol table:\n");
    char *types[] = {"IDENTIFIER", "INTEGER CONSTANT", "FLOATING CONSTANT", "CHAR CONSTANT", "STRING LITERAL"};
    llnode *temp = head;
    for (int i = IDENTIFIER; i <= STRING_LITERAL; i++)
    {
        temp = head;
        while (temp != NULL)
        {
            if (temp->type == i)
                printf("<%s, %s>  -  %d times\n", types[temp->type - 2], temp->value, temp->frequency);
            temp = temp->next;
        }
    }
}

void free_table(llnode *head)
{
    llnode *temp;
    while (head != NULL)
    {
        temp = head->next;
        free(head->value);
        free(head);
        head = temp;
    }
}

int main()
{
    int token;
    llnode *symbol_table = NULL;
    while ((token = yylex()))
    {
        if (token == MULTI_LINE_COMMENT || token == COMMENT)
        {
            continue;
        }
        if (token == INVALID)
        {
            printf("Invalid token: %s\n", yytext);
        }
        else
        {
            printf("< %s, %s >\n", tokennames[token], yytext);

            switch (token)
            {
            case KEYWORD:
                addkeyword(yytext);
                break;
            case IDENTIFIER:
            case INTEGER_CONSTANT:
            case FLOATING_CONSTANT:
            case CHAR_CONSTANT:
            case STRING_LITERAL:
                symbol_table = add_symbol(symbol_table, yytext, token);
                break;
            default:
                break;
            }
        }
    }

    // print the keyword frequency
    printf("\n");
    printkeywords();
    // print the symbol table frequency
    printf("\n");
    print_symbols(symbol_table);

    free_table(symbol_table);
}