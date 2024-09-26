#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "y.tab.h"

void yyerror(char *s);
extern int yyparse();

struct _linkednodelist;

struct _node
{
    struct _linkednodelist *children;
    char *data;
};

struct _linkednodelist
{
    struct _node *node;
    struct _linkednodelist *next;
};

typedef struct _node *node;
typedef struct _linkednodelist *linkednodelist;

node newnode(char *data)
{
    node n = (node)malloc(sizeof(struct _node));
    n->data = strdup(data);
    n->children = NULL;
    return n;
}

linkednodelist newlinkednode(node n)
{
    linkednodelist l = (linkednodelist)malloc(sizeof(struct _linkednodelist));
    l->node = n;
    l->next = NULL;
    return l;
}

void addchild(node parent, node child)
{
    if (parent->children == NULL)
    {
        parent->children = newlinkednode(child);
        return;
    }

    linkednodelist temp = parent->children;
    while (temp->next != NULL)
    {
        temp = temp->next;
    }
    temp->next = newlinkednode(child);
}

void printtree(node n, int depth)
{
    for (int i = 0; i < depth; i++)
    {
        printf("  ");
    }
    printf("%s\n", n->data);
    linkednodelist temp = n->children;
    while (temp != NULL)
    {
        printtree(temp->node, depth + 1);
        temp = temp->next;
    }
}

void yyerror(char *s)
{
    fprintf(stderr, "%s\n", s);
}

char *embed(char *base, char *val)
{
    int n1, n2;
    n1 = strlen(base);
    n2 = strlen(val);
    char *s = (char *)malloc((n1 + n2 - 2) * sizeof(char));
    sprintf(s, base, val);
    return s;
}

int main()
{
    yyparse();
    return 0;
}