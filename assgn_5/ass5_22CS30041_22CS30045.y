%{
    extern int yylex();
    void yyerror( char *s);
%}

%token IDENTIFIER FLOATING_CONSTANT INTEGER_CONSTANT CHAR_CONSTANT STRING_LITERAL
%token SIZEOF EXTERN STATIC AUTO REGISTER VOID CHAR SHORT INT LONG FLOAT DOUBLE SIGNED UNSIGNED BOOL_ COMPLEX_ IMAGINARY_ 
%token CONST RESTRICT VOLATILE INLINE CASE DEFAULT IF SWITCH WHILE DO FOR GOTO CONTINUE BREAK RETURN
%token LPARENSQ RPARENSQ LPAREN RPAREN LBRACE RBRACE
%token DOT ARROW INCREMENT DECREMENT AMPERSAND ASTERISK PLUS MINUS TILDE NOT DIV MOD LSHIFT RSHIFT LESS GREATER LESSEQ GREATEREQ EQUAL NOTEQUAL 
%token XOR OR LOG_OR LOG_AND QUESTION COLON SEMICOLON ELLIPSIS ASSIGN MULASSIGN DIVASSIGN MODASSIGN ADDASSIGN SUBASSIGN LEFTASSIGN RIGHTASSIGN 
%token ANDASSIGN XORASSIGN ORASSIGN COMMA
%type primary_expression expression postfix_expression argument_expression_list type_name initializer_list assignment_expression unary_expression cast_expression multiplicative_expression additive_expression shift_expression relational_expression equality_expression and_expression exclusive_or_expression inclusive_or_expression logical_and_expression logical_or_expression conditional_expression constant_expression
%type unary_operator assignment_operator
%type declaration declaration_specifiers init_declarator_list storage_class_specifier type_specifier type_qualifier function_specifier init_declarator declarator initializer specifier_qualifier_list direct_declarator type_qualifier_list parameter_type_list identifier_list parameter_list parameter_declaration designation designator_list designator
%type statement labeled_statement compound_statement expression_statement selection_statement iteration_statement jump_statement block_item block_item_list
%type translation_unit external_declaration function_definition declaration_list 
%type argument_expression_list_opt expression_opt declaration_specifiers_opt init_declarator_list_opt specifier_qualifier_list_opt pointer pointer_opt declaration_list_opt block_item_list_opt type_qualifier_list_opt assignment_expression_opt identifier_list_opt designation_opt
%type constant
%nonassoc PSEUDO_ELSE
%nonassoc ELSE

%start translation_unit

%%

/* External Definitions */

translation_unit:
        external_declaration
        | translation_unit external_declaration
        ;

external_declaration:
        function_definition
        | declaration
        ;

function_definition:
        declaration_specifiers declarator declaration_list_opt compound_statement
        ;

declaration_list:
        declaration
        | declaration_list declaration
        ;

/* Expressions */

primary_expression:
        IDENTIFIER
        | constant
        | STRING_LITERAL
        | LPAREN expression RPAREN
        ;

postfix_expression:
        primary_expression
        | postfix_expression LPAREN argument_expression_list_opt RPAREN
        | postfix_expression LPARENSQ expression RPARENSQ
        | postfix_expression DOT IDENTIFIER
        | postfix_expression ARROW IDENTIFIER
        | postfix_expression INCREMENT
        | postfix_expression DECREMENT
        | LPAREN type_name RPAREN LBRACE initializer_list RBRACE
        | LPAREN type_name RPAREN LBRACE initializer_list COMMA RBRACE
        ;

argument_expression_list:
        assignment_expression
        | argument_expression_list COMMA assignment_expression
        ;

unary_expression:
        postfix_expression
        | INCREMENT unary_expression
        | DECREMENT unary_expression
        | unary_operator cast_expression
        | SIZEOF unary_expression
        | SIZEOF LPAREN type_name RPAREN
        ;

unary_operator:
        AMPERSAND
        | ASTERISK
        | PLUS
        | MINUS
        | TILDE
        | NOT
        ;

cast_expression:
        unary_expression
        | LPAREN type_name RPAREN cast_expression
        ;


multiplicative_expression:
        cast_expression
        | multiplicative_expression ASTERISK cast_expression
        | multiplicative_expression DIV cast_expression
        | multiplicative_expression MOD cast_expression
        ;

additive_expression:
        multiplicative_expression
        | additive_expression PLUS multiplicative_expression
        | additive_expression MINUS multiplicative_expression
        ;

shift_expression:
        additive_expression
        | shift_expression LSHIFT additive_expression
        | shift_expression RSHIFT additive_expression
        ;

relational_expression:
        shift_expression
        | relational_expression LESS shift_expression
        | relational_expression GREATER shift_expression
        | relational_expression LESSEQ shift_expression
        | relational_expression GREATEREQ shift_expression
        ;

equality_expression:
        relational_expression
        | equality_expression EQUAL relational_expression
        | equality_expression NOTEQUAL relational_expression
        ;

and_expression:
        equality_expression
        | and_expression AMPERSAND equality_expression
        ;

exclusive_or_expression:
        and_expression
        | exclusive_or_expression XOR and_expression
        ;

inclusive_or_expression:
        exclusive_or_expression
        | inclusive_or_expression OR exclusive_or_expression
        ;

logical_and_expression:
        inclusive_or_expression
        | logical_and_expression LOG_AND inclusive_or_expression
        ;

logical_or_expression:
        logical_and_expression
        | logical_or_expression LOG_OR logical_and_expression
        ;

conditional_expression:
        logical_or_expression
        | logical_or_expression QUESTION expression COLON conditional_expression
        ;

assignment_expression:
        conditional_expression
        | unary_expression assignment_operator assignment_expression
        ;

assignment_operator:
        ASSIGN
        | MULASSIGN
        | DIVASSIGN
        | MODASSIGN
        | ADDASSIGN
        | SUBASSIGN
        | LEFTASSIGN
        | RIGHTASSIGN
        | ANDASSIGN
        | XORASSIGN
        | ORASSIGN
        ;

expression:
        assignment_expression
        | expression COMMA assignment_expression
        ;

constant_expression:
        conditional_expression
        ;

/* Declarations */

declaration:
        declaration_specifiers init_declarator_list_opt SEMICOLON
        ;

declaration_specifiers:
        storage_class_specifier declaration_specifiers_opt
        | type_specifier declaration_specifiers_opt
        | type_qualifier declaration_specifiers_opt
        | function_specifier declaration_specifiers_opt
        ;

init_declarator_list:
        init_declarator
        | init_declarator_list COMMA init_declarator
        ;

init_declarator:
        declarator
        | declarator ASSIGN initializer
        ;

storage_class_specifier:
        EXTERN
        | STATIC
        | AUTO
        | REGISTER
        ;

type_specifier:
        VOID
        | CHAR
        | SHORT
        | INT
        | LONG
        | FLOAT
        | DOUBLE
        | SIGNED
        | UNSIGNED
        | BOOL_
        | COMPLEX_
        | IMAGINARY_
        ;

specifier_qualifier_list:
        type_specifier specifier_qualifier_list_opt
        | type_qualifier specifier_qualifier_list_opt
        ;

type_qualifier:
        CONST
        | RESTRICT
        | VOLATILE
        ;

function_specifier:
        INLINE
        ;

declarator:
        pointer_opt direct_declarator
        ;

direct_declarator:
        IDENTIFIER
        | LPAREN declarator RPAREN
        | direct_declarator LPARENSQ type_qualifier_list_opt assignment_expression_opt RPARENSQ
        | direct_declarator LPARENSQ STATIC type_qualifier_list_opt assignment_expression RPARENSQ
        | direct_declarator LPARENSQ type_qualifier_list STATIC assignment_expression RPARENSQ
        | direct_declarator LPARENSQ type_qualifier_list_opt ASTERISK RPARENSQ
        | direct_declarator LPAREN parameter_type_list RPAREN
        | direct_declarator LPAREN identifier_list_opt RPAREN
        ;

pointer:
        ASTERISK type_qualifier_list_opt
        | ASTERISK type_qualifier_list_opt pointer
        ;

type_qualifier_list:
        type_qualifier
        | type_qualifier_list type_qualifier
        ;

parameter_type_list:
        parameter_list
        | parameter_list COMMA ELLIPSIS
        ;

parameter_list:
        parameter_declaration
        | parameter_list COMMA parameter_declaration
        ;

parameter_declaration:
        declaration_specifiers declarator
        | declaration_specifiers
        ;

identifier_list:
        IDENTIFIER
        | identifier_list COMMA IDENTIFIER
        ;

type_name:
        specifier_qualifier_list
        ;

initializer:
        assignment_expression
        | LBRACE initializer_list RBRACE
        | LBRACE initializer_list COMMA RBRACE
        ;

initializer_list:
        designation_opt initializer
        | initializer_list COMMA designation_opt initializer
        ;

designation:
        designator_list ASSIGN
        ;

designator_list:
        designator
        | designator_list designator
        ;

designator:
        LPARENSQ constant_expression RPARENSQ
        | DOT IDENTIFIER
        ;

/* Statements */

statement:
        labeled_statement
        | compound_statement
        | expression_statement
        | selection_statement
        | iteration_statement
        | jump_statement
        ;

labeled_statement:
        IDENTIFIER COLON statement
        | CASE constant_expression COLON statement
        | DEFAULT COLON statement
        ;

compound_statement:
        LBRACE block_item_list_opt RBRACE
        ;

block_item_list:
        block_item
        | block_item_list block_item
        ;

block_item:
        declaration
        | statement
        ;

expression_statement:
        expression_opt SEMICOLON
        ;

selection_statement:
        IF LPAREN expression RPAREN statement   %prec PSEUDO_ELSE
        | IF LPAREN expression RPAREN statement ELSE statement
        | SWITCH LPAREN expression RPAREN statement
        ;

iteration_statement:
        WHILE LPAREN expression RPAREN statement
        | DO statement WHILE LPAREN expression RPAREN SEMICOLON
        | FOR LPAREN expression_opt SEMICOLON expression_opt SEMICOLON expression_opt RPAREN statement
        | FOR LPAREN declaration expression_opt SEMICOLON expression_opt RPAREN statement
        ;

jump_statement:
        GOTO IDENTIFIER SEMICOLON
        | CONTINUE SEMICOLON
        | BREAK SEMICOLON
        | RETURN expression_opt SEMICOLON
        ;

/* Constants */

constant:
        INTEGER_CONSTANT
        | FLOATING_CONSTANT
        | CHAR_CONSTANT
        ;

/* Optionals */

argument_expression_list_opt:
        argument_expression_list
        | {/* Epsilon */}
        ;

declaration_specifiers_opt:
        declaration_specifiers
        | {/* Epsilon */}
        ;

init_declarator_list_opt:
        init_declarator_list
        | {/* Epsilon */}
        ;

specifier_qualifier_list_opt:
        specifier_qualifier_list
        | {/* Epsilon */}
        ;

pointer_opt:
        pointer
        | {/* Epsilon */}
        ;

type_qualifier_list_opt:
        type_qualifier_list
        | {/* Epsilon */}
        ;

expression_opt:
        expression
        | {/* Epsilon */}
        ;

assignment_expression_opt:
        assignment_expression
        | {/* Epsilon */}
        ;

identifier_list_opt:
        identifier_list
        | {/* Epsilon */}
        ;

designation_opt:
        designation
        | {/* Epsilon */}
        ;

block_item_list_opt:
        block_item_list
        | {/* Epsilon */}
        ;

declaration_list_opt:
        declaration_list
        | {/* Epsilon */}
        ;

%%