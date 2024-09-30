#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "y.tab.h"

struct nodechild;

struct _node {
  int type;
  int inh;
  int val;
  int nchildren;
  struct _nodechild *children;
};

struct _nodechild {
  struct _node *node;
  struct _nodechild *next;
};

typedef struct _node *node;
typedef struct _nodechild *nodechild;

extern node root;

int exponent(int base, int power) {
  int result = 1;
  for (int i = 0; i < power; i++) { result *= base; }
  return result;
}

node newNode(int type) {
  node n = (node)malloc(sizeof(struct _node));
  n->type = type;
  n->inh = 0;
  n->val = 0;
  n->children = NULL;
  n->nchildren = 0;
  return n;
}

void addChild(node parent, node child) {
  nodechild children = parent->children;
  nodechild newchild = (nodechild)malloc(sizeof(struct _nodechild));
  newchild->node = child;
  newchild->next = NULL;
  if (children == NULL) {
    parent->children = newchild;
  } else {
    while (children->next != NULL) { children = children->next; }
    children->next = newchild;
  }
  parent->nchildren++;
}

void setatt(node root) {
  nodechild children[4];
  nodechild child;
  int nchild = 0;

  switch (root->type) {
    case SS:
      child = root->children;
      children[nchild++] = child;
      while (child != NULL) {
        // set the inherited attribute of the child
        if (nchild == 2) {
          child->node->inh = children[0]->node->val;
        } else if (nchild == 1 && root->nchildren == 1) {
          child->node->inh = '+';
        }
        // recursion
        setatt(child->node);
        // go to next child
        child = child->next;
        children[nchild++] = child;
      }
      break;
    case PP:
      child = root->children;
      children[nchild++] = child;
      while (child != NULL) {
        // set the inherited attribute of the child
        switch (nchild) {
          case 1: child->node->inh = root->inh; break;
          case 3: child->node->inh = children[1]->node->val; break;
          default: break;
        }
        // recursion
        setatt(child->node);
        // go to next child
        child = child->next;
        children[nchild++] = child;
      }
      break;
    case NN:
      child = root->children;
      children[nchild++] = child;
      while (child != NULL) {
        // set the inherited attribute of the child
        if (nchild == 2) { child->node->inh = children[0]->node->val; }
        // recursion
        setatt(child->node);
        // go to next child
        child = child->next;
        children[nchild++] = child;
      }
      // set the synthesized attribute of the node
      root->val = children[root->nchildren - 1]->node->val;
      break;
    case MM:
      child = root->children;
      children[nchild++] = child;
      while (child != NULL) {
        // set the inherited attribute of the child
        if (nchild == 2) {
          child->node->inh = root->inh * 10 + children[0]->node->val;
        }
        // recursion
        setatt(child->node);
        // go to next child
        child = child->next;
        children[nchild++] = child;
      }
      // set the synthesized attribute of the node
      if (root->nchildren == 2) {
        root->val = children[1]->node->val;
      } else if (root->nchildren == 1) {
        root->val = root->inh * 10 + children[0]->node->val;
      }
      break;
    default:
      child = root->children;
      while (child != NULL) {
        // recursion
        setatt(child->node);
        // go to next child
        child = child->next;
      }
      break;
  }
}

void printtree(node n, int depth) {
  for (int i = 0; i < depth - 1; i++) { printf("   "); }
  if (depth) {
    printf("==> (nchildren = %d) ", n->nchildren);
  } else {
    printf("+++ The annotated parse tree is\n");
  }

  switch (n->type) {
    case SS: printf("S []"); break;
    case PP: printf("P [inh = %c]", n->inh); break;
    case TT: printf("T [inh = %c]", n->inh); break;
    case NN: printf("N [val = %d]", n->val); break;
    case D:
    case ZERO:
    case ONE: printf("%d [val = %d]", n->val, n->val); break;
    case MM: printf("M [inh = %d, val = %d]", n->inh, n->val); break;
    case XX: printf("X []"); break;
    case PLUS:
    case MINUS:
    case EXP: printf("%c []", n->val); break;
    case XSYM: printf("x []"); break;
    default: break;
  }

  printf("\n");

  nodechild children = n->children;
  while (children != NULL) {
    printtree(children->node, depth + 1);
    children = children->next;
  }
}

int evalpoly(node root, int x) {
  nodechild children = root->children;
  int val, val2;
  val = root->val;

  switch (root->type) {
    case SS:
      while (children->next != NULL) { children = children->next; }
      val = evalpoly(children->node, x);
      break;
    case PP:
      val = evalpoly(children->node, x);
      if (root->nchildren == 3) {
        children = children->next->next;
        val2 = evalpoly(children->node, x);
        val = val + val2;
      }
      break;
    case TT:
      val = evalpoly(children->node, x);
      if (root->nchildren > 1) {
        children = children->next;
        val2 = evalpoly(children->node, x);
        val = val * val2;
      }
      val = root->inh == '+' ? val : -val;
      break;
    case NN: val = root->val; break;
    case XX:
      val = x;
      while (children->next != NULL) { children = children->next; }
      if (root->nchildren == 3) {
        int power = evalpoly(children->node, x);
        val = exponent(val, power);
      }
      break;
    default: break;
  }

  return val;
}

int printderivative(node root, int coeffecient) {
  nodechild children;
  int val = 0;

  switch (root->type) {
    case SS:
      printf("f'(x) = ");
      children = root->children;
      while (children->next != NULL) { children = children->next; }
      val += printderivative(children->node, coeffecient);
      if (val == 0) { printf("0 "); }
      break;
    case PP:
      children = root->children;
      val += printderivative(children->node, coeffecient);
      if (root->nchildren == 3) {
        children = children->next->next;
        val += printderivative(children->node, coeffecient);
      }
      break;
    case TT:
      children = root->children;
      if (root->nchildren > 1) {
        printf(" %c ", root->inh);
        int coeff = children->node->val;
        val += printderivative(children->next->node, coeff * coeffecient);
      } else if (children->node->type == XX) {
        printf(" %c ", root->inh);
        val += printderivative(children->node, coeffecient);
      }
      break;
    case XX:
      children = root->children;
      if (root->nchildren == 3) {
        int power = children->next->next->node->val;
        if (coeffecient * power != 1) { printf("%d", coeffecient * power); }
        printf("x");
        if (power > 2) { printf("^%d", power - 1); }
      } else if (coeffecient != 0) {
        printf("%d", coeffecient);
      }
      val = 1;
      break;
    default: break;
  }

  return val;
}

int main() {
  yyparse();
  setatt(root);
  printtree(root, 0);
  printf("\n");

  int evauluated;
  for (int i = -5; i <= 5; i++) {
    evauluated = evalpoly(root, i);
    printf("+++ f(%d) = %d\n", i, evauluated);
  }

  printf("\n");

  printderivative(root, 1);
  return 0;
}

void yyerror(char *s) { fprintf(stderr, "%s\n", s); }