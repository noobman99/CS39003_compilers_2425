#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#define ENVIRONMENT_BEGIN 1
#define ENVIRONMENT_END 2
#define COMMAND 3
#define INLINE_MATH 4
#define DISPLAY_MATH 5

extern int yylex();
extern char* yytext;

typedef struct _node
{
    char* data;
    int count;
    struct _node* next;
} node;

node* new_node(char* token) {
    node* tmp = (node *) malloc(sizeof(node));
    tmp->data = strdup(token);
    tmp->count = 1;
    tmp->next = NULL;

    return tmp;
}

node* add_to_table(char* token, node* head) {
    node* curr = head;
    int match_found = 0;
    while (curr !=  NULL)
    {
        if (strcmp(token, curr->data) == 0) {
            match_found = 1;
            break;
        }
        curr = curr->next;
    }

    if (match_found == 1) {
        curr->count += 1;
    } else {
        curr = new_node(token);
        curr->next = head;
        head = curr;
    }
    
    return head;
}

void print_table(node* head) {
    while (head != NULL) {
        printf("\t%s (%d)\n", head->data, head->count);
        head = head->next;
    }
}

char* get_env_name(char* token) {
    int str_len = strlen(token);
    char* env_name;
    char* tmp;
    while (*token != '{') {
        if (*token == '\0') {
            return NULL;
        }
        token++;
    }
    token++;

    env_name = strdup(token);
    tmp = env_name;
    while (*tmp != '}') tmp++;
    *tmp = '\0';

    return env_name;
}

void free_table(node* head) {
    node* tmp;
    while (head != NULL) {
        free(head->data);
        tmp = head;
        head = head->next;
        free(tmp);
    }
}

int main() {
    // INPUT SHOULD BE GIVEN TO FILE THROUGH STDIN (redirection operator)

    int inline_math = 0;
    int display_math = 0;
    int inline_active = 0; // boolean
    int display_active = 0; // boolean
    node* commands = NULL;
    node* environments = NULL;
    int tok;

    do {
        tok = yylex();

        if (tok == 0) {
            break;
        }

        switch (tok)
        {
        case INLINE_MATH:
            if (inline_active == 0) {
                inline_active = 1;
            } else {
                inline_math += 1;
                inline_active = 0;
            }
            break;
        case DISPLAY_MATH:
            if (display_active == 0) {
                display_active = 1;
            } else {
                display_math += 1;
                display_active = 0;
            }
            break;
        case COMMAND:
            commands = add_to_table(yytext, commands);
            break;
        case ENVIRONMENT_BEGIN:
            char* env_name = get_env_name(yytext); // remove the \begin \end
            environments = add_to_table(env_name, environments);
            free(env_name);
            break;
        default:
            break;
        }
    } while (1);
    
    printf("Commands Used:\n");
    print_table(commands);

    printf("Environments Used:\n");
    print_table(environments);

    printf("%d math equations found\n", inline_math);
    if (inline_active) {
        printf("One inline math equation not terminated.\n");
    }

    printf("%d display equations found\n", display_math);
    if (display_active) {
        printf("One display math not terminated.\n");
    }

    free_table(commands);
    free_table(environments);
}