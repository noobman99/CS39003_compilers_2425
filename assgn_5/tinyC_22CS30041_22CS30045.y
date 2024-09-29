%{
#include<stdlib.h>
int yylex();
void yyerror(char *s);

struct _node
{
        struct _linkednodelist *children;
        char *data;
};

typedef struct _node* node;

node newnode(char *data);
void addchild(node parent, node child);
void printtree(node n, int depth);
char *embed(char *base, char *val);
void freetree(node n);
%}

%union { struct _node* node; char * val; }
%token <val> IDENTIFIER FLOATING_CONSTANT INTEGER_CONSTANT CHAR_CONSTANT STRING_LITERAL
%token SIZEOF EXTERN STATIC AUTO REGISTER VOID CHAR SHORT INT LONG FLOAT DOUBLE SIGNED UNSIGNED BOOL_ COMPLEX_ IMAGINARY_ 
%token CONST RESTRICT VOLATILE INLINE CASE DEFAULT IF SWITCH WHILE DO FOR GOTO CONTINUE BREAK RETURN
%token LPARENSQ RPARENSQ LPAREN RPAREN LBRACE RBRACE
%token DOT ARROW INCREMENT DECREMENT AMPERSAND ASTERISK PLUS MINUS TILDE NOT DIV MOD LSHIFT RSHIFT LESS GREATER LESSEQ GREATEREQ EQUAL NOTEQUAL 
%token XOR OR LOG_OR LOG_AND QUESTION COLON SEMICOLON ELLIPSIS ASSIGN MULASSIGN DIVASSIGN MODASSIGN ADDASSIGN SUBASSIGN LEFTASSIGN RIGHTASSIGN 
%token ANDASSIGN XORASSIGN ORASSIGN COMMA
%type <node> primary_expression expression postfix_expression argument_expression_list type_name initializer_list assignment_expression unary_expression cast_expression multiplicative_expression additive_expression shift_expression relational_expression equality_expression and_expression exclusive_or_expression inclusive_or_expression logical_and_expression logical_or_expression conditional_expression constant_expression
%type <node> unary_operator assignment_operator
%type <node> declaration declaration_specifiers init_declarator_list storage_class_specifier type_specifier type_qualifier function_specifier init_declarator declarator initializer specifier_qualifier_list direct_declarator type_qualifier_list parameter_type_list identifier_list parameter_list parameter_declaration designation designator_list designator
%type <node> statement labeled_statement compound_statement expression_statement selection_statement iteration_statement jump_statement block_item block_item_list
%type <node> translation_unit external_declaration function_definition declaration_list 
%type <node> argument_expression_list_opt expression_opt declaration_specifiers_opt init_declarator_list_opt specifier_qualifier_list_opt pointer pointer_opt declaration_list_opt block_item_list_opt type_qualifier_list_opt assignment_expression_opt identifier_list_opt designation_opt
%type <node> constant
%type <node> start_symbol
%nonassoc PSEUDO_ELSE
%nonassoc ELSE

%start start_symbol

%%

/* Start Symbol */

start_symbol:
        translation_unit { printtree($$, 0); freetree($$); }
        ;

/* External Definitions */

translation_unit:
        external_declaration { $$ = newnode("translation_unit -> external_declaration"); addchild($$, $1); }
        | translation_unit external_declaration { $$ = newnode("translation_unit -> translation_unit external_declaration"); addchild($$, $1); addchild($$, $2); }
        ;

external_declaration:
        function_definition { $$ = newnode("external_declaration -> function_definition"); addchild($$, $1); }
        | declaration { $$ = newnode("external_declaration -> declaration"); addchild($$, $1); }
        ;

function_definition:
        declaration_specifiers declarator declaration_list_opt compound_statement { $$ = newnode("function_definition -> declaration_specifiers declarator declaration_list_opt compound_statement"); addchild($$, $1); addchild($$, $2); addchild($$, $3); addchild($$, $4); }
        ;

declaration_list:
        declaration { $$ = newnode("declaration_list -> declaration"); addchild($$, $1); }
        | declaration_list declaration { $$ = newnode("declaration_list -> declaration_list declaration"); addchild($$, $1); addchild($$, $2); }
        ;

/* Expressions */

primary_expression:
        IDENTIFIER { char* s = embed("primary_expression -> IDENTIFIER (%S)", $1); $$ = newnode(s); free(s); free($1); }
        | constant { $$ = newnode("primary_expression -> constant");  addchild($$, $1); }
        | STRING_LITERAL { char*s = embed("primary_expression -> STRING_LITERAL (%s)", $1); $$ = newnode(s); free(s); free($1); }
        | LPAREN expression RPAREN { $$ = newnode("primary_expression -> LPAREN expression RPAREN"); addchild($$, $2); }
        ;

postfix_expression:
        primary_expression { $$ = newnode("postfix_expression -> primary_expression"); addchild($$, $1); }
        | postfix_expression LPAREN argument_expression_list_opt RPAREN { $$ = newnode("postfix_expression -> postfix_expression LPAREN argument_expression_list_opt RPAREN"); addchild($$, $1); addchild($$, $3); }
        | postfix_expression LPARENSQ expression RPARENSQ { $$ = newnode("postfix_expression -> postfix_expression LPARENSQ expression RPARENSQ"); addchild($$, $1); addchild($$, $3); }
        | postfix_expression DOT IDENTIFIER { char* s = embed("postfix_expression -> postfix_expression DOT IDENTIFIER (%s)", $3); $$ = newnode(s); addchild($$, $1); free(s); free($3); }
        | postfix_expression ARROW IDENTIFIER { char* s = embed("postfix_expression -> postfix_expression ARROW IDENTIFIER (%s)", $3); $$ = newnode(s); addchild($$, $1); free(s); free($3); }
        | postfix_expression INCREMENT { $$ = newnode("postfix_expression -> postfix_expression INCREMENT"); addchild($$, $1); }
        | postfix_expression DECREMENT { $$ = newnode("postfix_expression -> postfix_expression DECREMENT"); addchild($$, $1); }
        | LPAREN type_name RPAREN LBRACE initializer_list RBRACE { $$ = newnode("postfix_expression -> LPAREN type_name RPAREN LBRACE initializer_list RBRACE"); addchild($$, $2); addchild($$, $5); }
        | LPAREN type_name RPAREN LBRACE initializer_list COMMA RBRACE { $$ = newnode("postfix_expression -> LPAREN type_name RPAREN LBRACE initializer_list COMMA RBRACE"); addchild($$, $2); addchild($$, $5); }
        ;

argument_expression_list:
        assignment_expression { $$ = newnode("argument_expression_list -> assignment_expression"); addchild($$, $1); }
        | argument_expression_list COMMA assignment_expression { $$ = newnode("argument_expression_list -> argument_expression_list COMMA assignment_expression"); addchild($$, $1); addchild($$, $3); }
        ;

unary_expression:
        postfix_expression { $$ = newnode("unary_expression -> postfix_expression"); addchild($$, $1); }
        | INCREMENT unary_expression { $$ = newnode("unary_expression -> INCREMENT unary_expression"); addchild($$, $2); }
        | DECREMENT unary_expression { $$ = newnode("unary_expression -> DECREMENT unary_expression"); addchild($$, $2); }
        | unary_operator cast_expression { $$ = newnode("unary_expression -> unary_operator cast_expression"); addchild($$, $1); addchild($$, $2); }
        | SIZEOF unary_expression { $$ = newnode("unary_expression -> SIZEOF unary_expression"); addchild($$, $2); }
        | SIZEOF LPAREN type_name RPAREN { $$ = newnode("unary_expression -> SIZEOF LPAREN type_name RPAREN"); addchild($$, $3); }
        ;

unary_operator:
        AMPERSAND { $$ = newnode("unary_operator -> AMPERSAND"); }
        | ASTERISK { $$ = newnode("unary_operator -> ASTERISK"); }
        | PLUS { $$ = newnode("unary_operator -> PLUS"); }
        | MINUS { $$ = newnode("unary_operator -> MINUS"); }
        | TILDE { $$ = newnode("unary_operator -> TILDE"); }
        | NOT { $$ = newnode("unary_operator -> NOT"); }
        ;

cast_expression:
        unary_expression { $$ = newnode("cast_expression -> unary_expression"); addchild($$, $1); }
        | LPAREN type_name RPAREN cast_expression { $$ = newnode("cast_expression -> LPAREN type_name RPAREN cast_expression"); addchild($$, $2); addchild($$, $4); }
        ;


multiplicative_expression:
        cast_expression { $$ = newnode("multiplicative_expression -> cast_expression"); addchild($$, $1); }
        | multiplicative_expression ASTERISK cast_expression { $$ = newnode("multiplicative_expression -> multiplicative_expression ASTERISK cast_expression"); addchild($$, $1); addchild($$, $3); }
        | multiplicative_expression DIV cast_expression { $$ = newnode("multiplicative_expression -> multiplicative_expression DIV cast_expression"); addchild($$, $1); addchild($$, $3); }
        | multiplicative_expression MOD cast_expression { $$ = newnode("multiplicative_expression -> multiplicative_expression MOD cast_expression"); addchild($$, $1); addchild($$, $3); }
        ;

additive_expression:
        multiplicative_expression { $$ = newnode("additive_expression -> multiplicative_expression"); addchild($$, $1); }
        | additive_expression PLUS multiplicative_expression { $$ = newnode("additive_expression -> additive_expression PLUS multiplicative_expression"); addchild($$, $1); addchild($$, $3); }
        | additive_expression MINUS multiplicative_expression { $$ = newnode("additive_expression -> additive_expression MINUS multiplicative_expression"); addchild($$, $1); addchild($$, $3); }
        ;

shift_expression:
        additive_expression { $$ = newnode("shift_expression -> additive_expression"); addchild($$, $1); }
        | shift_expression LSHIFT additive_expression { $$ = newnode("shift_expression -> shift_expression LSHIFT additive_expression"); addchild($$, $1); addchild($$, $3); }
        | shift_expression RSHIFT additive_expression { $$ = newnode("shift_expression -> shift_expression RSHIFT additive_expression"); addchild($$, $1); addchild($$, $3); }
        ;

relational_expression:
        shift_expression { $$ = newnode("relational_expression -> shift_expression"); addchild($$, $1); }
        | relational_expression LESS shift_expression { $$ = newnode("relational_expression -> relational_expression LESS shift_expression"); addchild($$, $1); addchild($$, $3); }
        | relational_expression GREATER shift_expression { $$ = newnode("relational_expression -> relational_expression GREATER shift_expression"); addchild($$, $1); addchild($$, $3); }
        | relational_expression LESSEQ shift_expression { $$ = newnode("relational_expression -> relational_expression LESSEQ shift_expression"); addchild($$, $1); addchild($$, $3); }
        | relational_expression GREATEREQ shift_expression { $$ = newnode("relational_expression -> relational_expression GREATEREQ shift_expression"); addchild($$, $1); addchild($$, $3); }
        ;

equality_expression:
        relational_expression { $$ = newnode("equality_expression -> relational_expression"); addchild($$, $1); }
        | equality_expression EQUAL relational_expression { $$ = newnode("equality_expression -> equality_expression EQUAL relational_expression"); addchild($$, $1); addchild($$, $3); }
        | equality_expression NOTEQUAL relational_expression { $$ = newnode("equality_expression -> equality_expression NOTEQUAL relational_expression"); addchild($$, $1); addchild($$, $3); }
        ;

and_expression:
        equality_expression { $$ = newnode("and_expression -> equality_expression"); addchild($$, $1); }
        | and_expression AMPERSAND equality_expression { $$ = newnode("and_expression -> and_expression AMPERSAND equality_expression"); addchild($$, $1); addchild($$, $3); }
        ;

exclusive_or_expression:
        and_expression { $$ = newnode("exclusive_or_expression -> and_expression"); addchild($$, $1); }
        | exclusive_or_expression XOR and_expression { $$ = newnode("exclusive_or_expression -> exclusive_or_expression XOR and_expression"); addchild($$, $1); addchild($$, $3); }
        ;

inclusive_or_expression:
        exclusive_or_expression { $$ = newnode("inclusive_or_expression -> exclusive_or_expression"); addchild($$, $1); }
        | inclusive_or_expression OR exclusive_or_expression { $$ = newnode("inclusive_or_expression -> inclusive_or_expression OR exclusive_or_expression"); addchild($$, $1); addchild($$, $3); }
        ;

logical_and_expression:
        inclusive_or_expression { $$ = newnode("logical_and_expression -> inclusive_or_expression"); addchild($$, $1); }
        | logical_and_expression LOG_AND inclusive_or_expression { $$ = newnode("logical_and_expression -> logical_and_expression LOG_AND inclusive_or_expression"); addchild($$, $1); addchild($$, $3); }
        ;

logical_or_expression:
        logical_and_expression { $$ = newnode("logical_or_expression -> logical_and_expression"); addchild($$, $1); }
        | logical_or_expression LOG_OR logical_and_expression { $$ = newnode("logical_or_expression -> logical_or_expression LOG_OR logical_and_expression"); addchild($$, $1); addchild($$, $3); }
        ;

conditional_expression:
        logical_or_expression { $$ = newnode("conditional_expression -> logical_or_expression"); addchild($$, $1); }
        | logical_or_expression QUESTION expression COLON conditional_expression { $$ = newnode("conditional_expression -> logical_or_expression QUESTION expression COLON conditional_expression"); addchild($$, $1); addchild($$, $3); addchild($$, $5); }
        ;

assignment_expression:
        conditional_expression { $$ = newnode("assignment_expression -> conditional_expression"); addchild($$, $1); }
        | unary_expression assignment_operator assignment_expression { $$ = newnode("assignment_expression -> unary_expression assignment_operator assignment_expression"); addchild($$, $1); addchild($$, $2); addchild($$, $3); }
        ;

assignment_operator:
        ASSIGN { $$ = newnode("assignment_operator -> ASSIGN"); }
        | MULASSIGN { $$ = newnode("assignment_operator -> MULASSIGN"); }
        | DIVASSIGN { $$ = newnode("assignment_operator -> DIVASSIGN"); }
        | MODASSIGN { $$ = newnode("assignment_operator -> MODASSIGN"); }
        | ADDASSIGN { $$ = newnode("assignment_operator -> ADDASSIGN"); }
        | SUBASSIGN { $$ = newnode("assignment_operator -> SUBASSIGN"); }
        | LEFTASSIGN { $$ = newnode("assignment_operator -> LEFTASSIGN"); }
        | RIGHTASSIGN { $$ = newnode("assignment_operator -> RIGHTASSIGN"); }
        | ANDASSIGN { $$ = newnode("assignment_operator -> ANDASSIGN"); }
        | XORASSIGN { $$ = newnode("assignment_operator -> XORASSIGN"); }
        | ORASSIGN { $$ = newnode("assignment_operator -> ORASSIGN"); }
        ;

expression:
        assignment_expression { $$ = newnode("expression -> assignment_expression"); addchild($$, $1); }
        | expression COMMA assignment_expression { $$ = newnode("expression -> expression COMMA assignment_expression"); addchild($$, $1); addchild($$, $3); }
        ;

constant_expression:
        conditional_expression { $$ = newnode("constant_expression -> conditional_expression"); addchild($$, $1); }
        ;

/* Declarations */

declaration:
        declaration_specifiers init_declarator_list_opt SEMICOLON { $$ = newnode("declaration -> declaration_specifiers init_declarator_list_opt SEMICOLON"); addchild($$, $1); addchild($$, $2); }
        ;

declaration_specifiers:
        storage_class_specifier declaration_specifiers_opt { $$ = newnode("declaration_specifiers -> storage_class_specifier declaration_specifiers_opt"); addchild($$, $1); addchild($$, $2); }
        | type_specifier declaration_specifiers_opt { $$ = newnode("declaration_specifiers -> type_specifier declaration_specifiers_opt"); addchild($$, $1); addchild($$, $2); }
        | type_qualifier declaration_specifiers_opt { $$ = newnode("declaration_specifiers -> type_qualifier declaration_specifiers_opt"); addchild($$, $1); addchild($$, $2); }
        | function_specifier declaration_specifiers_opt { $$ = newnode("declaration_specifiers -> function_specifier declaration_specifiers_opt"); addchild($$, $1); addchild($$, $2); }
        ;

init_declarator_list:
        init_declarator { $$ = newnode("init_declarator_list -> init_declarator"); addchild($$, $1); }
        | init_declarator_list COMMA init_declarator { $$ = newnode("init_declarator_list -> init_declarator_list COMMA init_declarator"); addchild($$, $1); addchild($$, $3); }
        ;

init_declarator:
        declarator { $$ = newnode("init_declarator -> declarator"); addchild($$, $1); }
        | declarator ASSIGN initializer { $$ = newnode("init_declarator -> declarator ASSIGN initializer"); addchild($$, $1); addchild($$, $3); }
        ;

storage_class_specifier:
        EXTERN { $$ = newnode("storage_class_specifier -> EXTERN"); }
        | STATIC { $$ = newnode("storage_class_specifier -> STATIC"); }
        | AUTO { $$ = newnode("storage_class_specifier -> AUTO"); }
        | REGISTER { $$ = newnode("storage_class_specifier -> REGISTER"); }
        ;

type_specifier:
        VOID { $$ = newnode("type_specifier -> VOID"); }
        | CHAR { $$ = newnode("type_specifier -> CHAR"); }
        | SHORT { $$ = newnode("type_specifier -> SHORT"); }
        | INT { $$ = newnode("type_specifier -> INT"); }
        | LONG { $$ = newnode("type_specifier -> LONG"); }
        | FLOAT { $$ = newnode("type_specifier -> FLOAT"); }
        | DOUBLE { $$ = newnode("type_specifier -> DOUBLE"); }
        | SIGNED { $$ = newnode("type_specifier -> SIGNED"); }
        | UNSIGNED { $$ = newnode("type_specifier -> UNSIGNED"); }
        | BOOL_ { $$ = newnode("type_specifier -> BOOL_"); }
        | COMPLEX_ { $$ = newnode("type_specifier -> COMPLEX_"); }
        | IMAGINARY_ { $$ = newnode("type_specifier -> IMAGINARY_"); }
        ;

specifier_qualifier_list:
        type_specifier specifier_qualifier_list_opt { $$ = newnode("specifier_qualifier_list -> type_specifier specifier_qualifier_list_opt"); addchild($$, $1); addchild($$, $2); }
        | type_qualifier specifier_qualifier_list_opt { $$ = newnode("specifier_qualifier_list -> type_qualifier specifier_qualifier_list_opt"); addchild($$, $1); addchild($$, $2); }
        ;

type_qualifier:
        CONST { $$ = newnode("type_qualifier -> CONST"); }
        | RESTRICT { $$ = newnode("type_qualifier -> RESTRICT"); }
        | VOLATILE { $$ = newnode("type_qualifier -> VOLATILE"); }
        ;

function_specifier:
        INLINE { $$ = newnode("function_specifier -> INLINE"); }
        ;

declarator:
        pointer_opt direct_declarator { $$ = newnode("declarator -> pointer_opt direct_declarator"); addchild($$, $1); addchild($$, $2); }
        ;

direct_declarator:
        IDENTIFIER { char* s = embed("direct_declarator -> IDENTIFIER (%s)", $1); $$ = newnode(s); free(s); free($1); }
        | LPAREN declarator RPAREN { $$ = newnode("direct_declarator -> LPAREN declarator RPAREN"); addchild($$, $2); }
        | direct_declarator LPARENSQ type_qualifier_list_opt assignment_expression_opt RPARENSQ { $$ = newnode("direct_declarator -> direct_declarator LPARENSQ type_qualifier_list_opt assignment_expression_opt RPARENSQ"); addchild($$, $1); addchild($$, $3); addchild($$, $4); }
        | direct_declarator LPARENSQ STATIC type_qualifier_list_opt assignment_expression RPARENSQ { $$ = newnode("direct_declarator -> direct_declarator LPARENSQ STATIC type_qualifier_list_opt assignment_expression RPARENSQ"); addchild($$, $1); addchild($$, $4); addchild($$, $5); }
        | direct_declarator LPARENSQ type_qualifier_list STATIC assignment_expression RPARENSQ { $$ = newnode("direct_declarator -> direct_declarator LPARENSQ type_qualifier_list STATIC assignment_expression RPARENSQ"); addchild($$, $1); addchild($$, $3); addchild($$, $5); }
        | direct_declarator LPARENSQ type_qualifier_list_opt ASTERISK RPARENSQ { $$ = newnode("direct_declarator -> direct_declarator LPARENSQ type_qualifier_list_opt ASTERISK RPARENSQ"); addchild($$, $1); addchild($$, $3); }
        | direct_declarator LPAREN parameter_type_list RPAREN { $$ = newnode("direct_declarator -> direct_declarator LPAREN parameter_type_list RPAREN"); addchild($$, $1); addchild($$, $3); }
        | direct_declarator LPAREN identifier_list_opt RPAREN { $$ = newnode("direct_declarator -> direct_declarator LPAREN identifier_list_opt RPAREN"); addchild($$, $1); addchild($$, $3); }
        ;

pointer:
        ASTERISK type_qualifier_list_opt { $$ = newnode("pointer -> ASTERISK type_qualifier_list_opt"); addchild($$, $2); }
        | ASTERISK type_qualifier_list_opt pointer { $$ = newnode("pointer -> ASTERISK type_qualifier_list_opt pointer"); addchild($$, $2); addchild($$, $3); }
        ;

type_qualifier_list:
        type_qualifier { $$ = newnode("type_qualifier_list -> type_qualifier"); addchild($$, $1); }
        | type_qualifier_list type_qualifier { $$ = newnode("type_qualifier_list -> type_qualifier_list type_qualifier"); addchild($$, $1); addchild($$, $2); }
        ;

parameter_type_list:
        parameter_list { $$ = newnode("parameter_type_list -> parameter_list"); addchild($$, $1); }
        | parameter_list COMMA ELLIPSIS { $$ = newnode("parameter_type_list -> parameter_list COMMA ELLIPSIS"); addchild($$, $1); }
        ;

parameter_list:
        parameter_declaration { $$ = newnode("parameter_list -> parameter_declaration"); addchild($$, $1); }
        | parameter_list COMMA parameter_declaration { $$ = newnode("parameter_list -> parameter_list COMMA parameter_declaration"); addchild($$, $1); addchild($$, $3); }
        ;

parameter_declaration:
        declaration_specifiers declarator { $$ = newnode("parameter_declaration -> declaration_specifiers declarator"); addchild($$, $1); addchild($$, $2); }
        | declaration_specifiers { $$ = newnode("parameter_declaration -> declaration_specifiers"); addchild($$, $1); }
        ;

identifier_list:
        IDENTIFIER { char* s = embed("identifier_list -> IDENTIFIER (%s)", $1); $$ = newnode(s); free(s); free($1); }
        | identifier_list COMMA IDENTIFIER { char* s = embed("identifier_list -> identifier_list COMMA IDENTIFIER (%s)", $3); $$ = newnode(s); addchild($$, $1); free(s); free($3); }
        ;

type_name:
        specifier_qualifier_list { $$ = newnode("type_name -> specifier_qualifier_list"); addchild($$, $1); }
        ;

initializer:
        assignment_expression { $$ = newnode("initializer -> assignment_expression"); addchild($$, $1); }
        | LBRACE initializer_list RBRACE { $$ = newnode("initializer -> LBRACE initializer_list RBRACE"); addchild($$, $2); }
        | LBRACE initializer_list COMMA RBRACE { $$ = newnode("initializer -> LBRACE initializer_list COMMA RBRACE"); addchild($$, $2); }
        ;

initializer_list:
        designation_opt initializer { $$ = newnode("initializer_list -> designation_opt initializer"); addchild($$, $1); addchild($$, $2); }
        | initializer_list COMMA designation_opt initializer { $$ = newnode("initializer_list -> initializer_list COMMA designation_opt initializer"); addchild($$, $1); addchild($$, $3); }
        ;

designation:
        designator_list ASSIGN { $$ = newnode("designation -> designator_list ASSIGN"); addchild($$, $1); }
        ;

designator_list:
        designator { $$ = newnode("designator_list -> designator"); addchild($$, $1); }
        | designator_list designator { $$ = newnode("designator_list -> designator_list designator"); addchild($$, $1); addchild($$, $2); }
        ;

designator:
        LPARENSQ constant_expression RPARENSQ { $$ = newnode("designator -> LPARENSQ constant_expression RPARENSQ"); addchild($$, $2); }
        | DOT IDENTIFIER { char* s = embed("designator -> DOT IDENTIFIER (%s)", $2); $$ = newnode(s); free(s); free($2); }
        ;

/* Statements */

statement:
        labeled_statement { $$ = newnode("statement -> labeled_statement"); addchild($$, $1); }
        | compound_statement { $$ = newnode("statement -> compound_statement"); addchild($$, $1); }
        | expression_statement { $$ = newnode("statement -> expression_statement"); addchild($$, $1); }
        | selection_statement { $$ = newnode("statement -> selection_statement"); addchild($$, $1); }
        | iteration_statement { $$ = newnode("statement -> iteration_statement"); addchild($$, $1); }
        | jump_statement { $$ = newnode("statement -> jump_statement"); addchild($$, $1); }
        ;

labeled_statement:
        IDENTIFIER COLON statement { char* s = embed("labeled_statement -> IDENTIFIER (%s) COLON statement", $1); $$ = newnode(s); addchild($$, $3); free(s); free($1); }
        | CASE constant_expression COLON statement { $$ = newnode("labeled_statement -> CASE constant_expression COLON statement"); addchild($$, $2); addchild($$, $4); }
        | DEFAULT COLON statement { $$ = newnode("labeled_statement -> DEFAULT COLON statement"); addchild($$, $3); }
        ;

compound_statement:
        LBRACE block_item_list_opt RBRACE { $$ = newnode("compound_statement -> LBRACE block_item_list_opt RBRACE"); addchild($$, $2); }
        ;

block_item_list:
        block_item { $$ = newnode("block_item_list -> block_item"); addchild($$, $1); }
        | block_item_list block_item { $$ = newnode("block_item_list -> block_item_list block_item"); addchild($$, $1); addchild($$, $2); }
        ;

block_item:
        declaration { $$ = newnode("block_item -> declaration"); addchild($$, $1); }
        | statement { $$ = newnode("block_item -> statement"); addchild($$, $1); }
        ;

expression_statement:
        expression_opt SEMICOLON { $$ = newnode("expression_statement -> expression_opt SEMICOLON"); addchild($$, $1); }
        ;

selection_statement:
        IF LPAREN expression RPAREN statement   %prec PSEUDO_ELSE { $$ = newnode("selection_statement -> IF LPAREN expression RPAREN statement"); addchild($$, $3); addchild($$, $5); }
        | IF LPAREN expression RPAREN statement ELSE statement { $$ = newnode("selection_statement -> IF LPAREN expression RPAREN statement ELSE statement"); addchild($$, $3); addchild($$, $5); addchild($$, $7); }
        | SWITCH LPAREN expression RPAREN statement { $$ = newnode("selection_statement -> SWITCH LPAREN expression RPAREN statement"); addchild($$, $3); addchild($$, $5); }
        ;

iteration_statement:
        WHILE LPAREN expression RPAREN statement { $$ = newnode("iteration_statement -> WHILE LPAREN expression RPAREN statement"); addchild($$, $3); addchild($$, $5); }
        | DO statement WHILE LPAREN expression RPAREN SEMICOLON { $$ = newnode("iteration_statement -> DO statement WHILE LPAREN expression RPAREN SEMICOLON"); addchild($$, $2); addchild($$, $5); }
        | FOR LPAREN expression_opt SEMICOLON expression_opt SEMICOLON expression_opt RPAREN statement { $$ = newnode("iteration_statement -> FOR LPAREN expression_opt SEMICOLON expression_opt SEMICOLON expression_opt RPAREN statement"); addchild($$, $3); addchild($$, $5); addchild($$, $7); addchild($$, $9); }
        | FOR LPAREN declaration expression_opt SEMICOLON expression_opt RPAREN statement { $$ = newnode("iteration_statement -> FOR LPAREN declaration expression_opt SEMICOLON expression_opt RPAREN statement"); addchild($$, $3); addchild($$, $4); addchild($$, $6); addchild($$, $8); }
        ;

jump_statement:
        GOTO IDENTIFIER SEMICOLON { char* s = embed("jump_statement -> GOTO IDENTIFIER (%s) SEMICOLON", $2); $$ = newnode(s); free(s); free($2); }
        | CONTINUE SEMICOLON { $$ = newnode("jump_statement -> CONTINUE SEMICOLON"); }
        | BREAK SEMICOLON { $$ = newnode("jump_statement -> BREAK SEMICOLON"); }
        | RETURN expression_opt SEMICOLON { $$ = newnode("jump_statement -> RETURN expression_opt SEMICOLON"); addchild($$, $2); }
        ;

/* Constants */

constant:
        INTEGER_CONSTANT { char* s = embed("constant -> INTEGER_CONSTANT (%s)", $1); $$ = newnode(s); free(s); free($1); }
        | FLOATING_CONSTANT { char* s = embed("constant -> FLOATING_CONSTANT (%s)", $1); $$ = newnode(s); free(s); free($1); }
        | CHAR_CONSTANT { char* s = embed("constant -> CHAR_CONSTANT (%s)", $1); $$ = newnode(s); free(s); free($1); }
        ;

/* Optionals */

argument_expression_list_opt:
        argument_expression_list { $$ = newnode("argument_expression_list_opt -> argument_expression_list"); addchild($$, $1); }
        | {/* Epsilon */ $$ = newnode("argument_expression_list_opt -> Epsilon"); }
        ;

declaration_specifiers_opt:
        declaration_specifiers { $$ = newnode("declaration_specifiers_opt -> declaration_specifiers"); addchild($$, $1); }
        | {/* Epsilon */ $$ = newnode("declaration_specifiers_opt -> Epsilon"); }
        ;

init_declarator_list_opt:
        init_declarator_list { $$ = newnode("init_declarator_list_opt -> init_declarator_list"); addchild($$, $1); }
        | {/* Epsilon */ $$ = newnode("init_declarator_list_opt -> Epsilon"); }
        ;

specifier_qualifier_list_opt:
        specifier_qualifier_list { $$ = newnode("specifier_qualifier_list_opt -> specifier_qualifier_list"); addchild($$, $1); }
        | {/* Epsilon */ $$ = newnode("specifier_qualifier_list_opt -> Epsilon"); }
        ;

pointer_opt:
        pointer { $$ = newnode("pointer_opt -> pointer"); addchild($$, $1); }
        | {/* Epsilon */ $$ = newnode("pointer_opt -> Epsilon"); }
        ;

type_qualifier_list_opt:
        type_qualifier_list { $$ = newnode("type_qualifier_list_opt -> type_qualifier_list"); addchild($$, $1); }
        | {/* Epsilon */ $$ = newnode("type_qualifier_list_opt -> Epsilon"); }
        ;

expression_opt:
        expression { $$ = newnode("expression_opt -> expression"); addchild($$, $1); }
        | {/* Epsilon */ $$ = newnode("expression_opt -> Epsilon"); }
        ;

assignment_expression_opt:
        assignment_expression { $$ = newnode("assignment_expression_opt -> assignment_expression"); addchild($$, $1); }
        | {/* Epsilon */ $$ = newnode("assignment_expression_opt -> Epsilon"); }
        ;

identifier_list_opt:
        identifier_list { $$ = newnode("identifier_list_opt -> identifier_list"); addchild($$, $1); }
        | {/* Epsilon */ $$ = newnode("identifier_list_opt -> Epsilon"); }
        ;

designation_opt:
        designation { $$ = newnode("designation_opt -> designation"); addchild($$, $1); }
        | {/* Epsilon */ $$ = newnode("designation_opt -> Epsilon"); }
        ;

block_item_list_opt:
        block_item_list { $$ = newnode("block_item_list_opt -> block_item_list"); addchild($$, $1); }
        | {/* Epsilon */ $$ = newnode("block_item_list_opt -> Epsilon"); }
        ;

declaration_list_opt:
        declaration_list { $$ = newnode("declaration_list_opt -> declaration_list"); addchild($$, $1); }
        | {/* Epsilon */ $$ = newnode("declaration_list_opt -> Epsilon"); }
        ;

%%