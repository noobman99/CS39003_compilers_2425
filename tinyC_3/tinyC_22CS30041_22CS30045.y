%{
    #include "tinyC_22CS30041_22CS30045_translator.h"
    extern int yylex();
    extern int yylineno;
    extern char *yytext;
    void yyerror(const char*);
%}

%union {
    int ival;
    char* val;
    char* unary_op; 
    int instr_num;
    int num_params;
    Expression* expr;
    Statement* stmt;
    Array* array;
    SymType* sym_type;
    Symbol* symbol;
}

// parenthesis
%token LPAREN RPAREN LBRACE RBRACE LPARENSQ RPARENSQ 

// operators
%token INCREMENT DECREMENT LSHIFT RSHIFT EQUAL NOTEQUAL LESSEQ GREATEREQ LOG_AND LOG_OR ARROW LESS GREATER ASSIGN DOT AMPERSAND OR XOR ASTERISK PLUS MINUS TILDE NOT DIV MOD

// assignment operators
%token ADDASSIGN SUBASSIGN MULASSIGN DIVASSIGN MODASSIGN LEFTASSIGN RIGHTASSIGN ORASSIGN ANDASSIGN XORASSIGN

// other tokens
%token COLON SEMICOLON ELLIPSIS QUESTION COMMA

// keywords
%token EXTERN STATIC AUTO REGISTER
%token VOID_TYPE CHAR_TYPE SHORT INT_TYPE LONG FLOAT_TYPE DOUBLE SIGNED UNSIGNED BOOL_ COMPLEX_ IMAGINARY_
%token CONST RESTRICT VOLATILE INLINE
%token SIZEOF
%token IF ELSE CASE DEFAULT WHILE CONTINUE DO GOTO FOR RETURN BREAK SWITCH

// default case - unexpected token
%token UNEXPECTED_TOKEN


%token<symbol> IDENTIFIER
%token<ival> INTEGER_CONSTANT
%token<val> FLOATING_CONSTANT
%token<val> CHAR_CONSTANT
%token<val> STRING_LITERAL

%start translation_unit

%right THEN ELSE

// unary-operator
%type<unary_op> unary_operator

// number of parameters, in case of function call
%type<num_params> argument_expression_list argument_expression_list_opt

// expressions
%type<expr> constant expression expression_opt expression_statement primary_expression multiplicative_expression additive_expression shift_expression relational_expression equality_expression and_expression exclusive_or_expression inclusive_or_expression logical_and_expression logical_or_expression conditional_expression assignment_expression

// arrays
%type<array> postfix_expression unary_expression cast_expression

// statements
%type <stmt>  statement compound_statement selection_statement iteration_statement labeled_statement  jump_statement block_item block_item_list block_item_list_opt

// symbol type
%type<sym_type> pointer

// symbol
%type<symbol> initializer direct_declarator init_declarator declarator

// non-terminals used for backpatching
%type <instr_num> M; 
%type <stmt> N; 

%%

// production rule of auxillary non-terminals 

M:  
    {
        $$ = nextinstr();
    }   
;

N: 
    {
        $$ = new Statement();
        $$->nextlist = makelist(nextinstr());
        emit("goto", "");
    }
;

// to change symbol table, in case of functions
CT:
    {
        if(current_symbol->nestedST == NULL) {
            changeTable(new SymTable(""));
        }
        else {
            changeTable(current_symbol->nestedST);
            emit("label", currentST->name);
        }
    }
;

// to change symbol table, in case of blocks (like if statements)
CB: 
    {
        string name = currentST->name + "_" + to_string(block_count++); // name for new ST
        Symbol *s = currentST->lookup(name); 
        s->nestedST = new SymTable(name, currentST);
        s->type = new SymType(BLOCK);
        current_symbol = s;
    } 
;


// The rules that have been ignored (according to assignment specifications) have been left blank. The other rules are left blank because nothing is to be done at that rule


// ----------1. Declarations----------


primary_expression: 
    IDENTIFIER 
        { 
            $$ = new Expression(); // making a new expression and storing the symbol
            $$->symbol = $1;
            $$->type = Expression::NONBOOLEAN; 
        }
    | constant 
        {
            $$ = $1; // depends on which type of constant
        }

    | STRING_LITERAL 
        { 
            $$ = new Expression(); // making a new expression and storing the symbol
            $$->symbol = gentemp(POINTER, $1);
            $$->symbol->type->arr_type = new SymType(CHAR); // string = char *
        }

    | LPAREN expression RPAREN
        { 
            $$ = $2; // simply equate to expression
        }
    ;

// depending on type of constant, generate temporary and store the value in it
constant: 
    INTEGER_CONSTANT 
        { 
            $$ = new Expression(); 
            $$->symbol = gentemp(INT, to_string($1));
            emit("=", $$->symbol->name, $1);
        }

    | FLOATING_CONSTANT 
        { 
            $$ = new Expression();
            $$->symbol = gentemp(FLOAT, $1);
            emit("=", $$->symbol->name, $1);
        }

    | CHAR_CONSTANT 
        { 
            $$ = new Expression();
            $$->symbol = gentemp(CHAR, $1);
            emit("=", $$->symbol->name, $1);
        }
    ;

postfix_expression:
    primary_expression
        { 
            // create a new array and append location of primary_expression
            $$ = new Array();
            $$->symbol = $1->symbol;
            $$->loc = $$->symbol;
            $$->subarr_type = $1->symbol->type;
        }

    | postfix_expression LPARENSQ expression RPARENSQ
        { 
            $$ = new Array();
            $$->symbol = $1->symbol;    
            $$->subarr_type = $1->subarr_type->arr_type; // indexing - going one level deeper
            $$->loc = gentemp(INT); 
            $$->type = Array::ARRAY;

            // checking if array is 1D or multi-dimensional
            if($1->type == Array::ARRAY) {
                // multi-dimensional array - so need to multiply size and add offset
                Symbol *sym = gentemp(INT);
                int size = $$->subarr_type->computeSize();
                emit("*", sym->name, $3->symbol->name, to_string(size));
                emit("+", $$->loc->name, $1->loc->name, sym->name);
            } else {
                // 1D array - just calculate size
                int size = $$->subarr_type->computeSize();
                emit("*", $$->loc->name, $3->symbol->name, to_string(size));
            }

        }

    | postfix_expression LPAREN argument_expression_list_opt RPAREN
        { 
            // function call
            $$ = new Array();
            $$->symbol = gentemp($1->symbol->type->type);
            emit("call", $$->symbol->name, $1->symbol->name, to_string($3));
        }

    /* below 2 rules are struct-related -> ignored */
    | postfix_expression DOT IDENTIFIER
        { }

    | postfix_expression ARROW IDENTIFIER
        { }

    | postfix_expression INCREMENT
        { 
            $$ = new Array();
            // temp with old value, then add 1
            $$->symbol = gentemp($1->symbol->type->type);
            emit("=", $$->symbol->name, $1->symbol->name);
            emit("+", $1->symbol->name, $1->symbol->name, "1"); 
        }
    | postfix_expression DECREMENT
        { 
            $$ = new Array();
            // temp with old value, then subtract 1
            $$->symbol = gentemp($1->symbol->type->type);
            emit("=", $$->symbol->name, $1->symbol->name);
            emit("-", $1->symbol->name, $1->symbol->name, "1");
        }

    | LPAREN type_name RPAREN LBRACE initializer_list RBRACE
        { }

    | LPAREN type_name RPAREN LBRACE initializer_list COMMA RBRACE
        { }
    ;


// number of arguments/parameters is computed here
argument_expression_list_opt:
    argument_expression_list
        { 
            $$ = $1; // depends on argument expression list
        }

    | /* empty */
        { 
            $$ = 0; // no arguments
        }
    ;

argument_expression_list:
    assignment_expression
        { 
            $$ = 1; // 1 argument
            emit("param", $1->symbol->name);
        }

    | argument_expression_list COMMA assignment_expression
        { 
            $$ = $1 + 1; // one more argument added
            emit("param", $3->symbol->name);
        }
    ;

unary_expression:
    postfix_expression
        { 
            $$ = $1; // depends on postfix expression
        }
    | INCREMENT unary_expression
        { 
            $$ = $2;
            // this is pre increment, so 1 is added directly
            emit("+", $2->symbol->name, $2->symbol->name, "1");
        }

    | DECREMENT unary_expression
        { 
            $$ = $2;
            // similar to pre increment
            emit("-", $2->symbol->name, $2->symbol->name, "1");
        }

    | unary_operator cast_expression
        { 
            // operation depends on unary operator

            $$ = new Array();

            if(strcmp($1, "&") == 0) {
                // address of -> generate new pointer type
                $$->symbol = gentemp(POINTER);
                $$->symbol->type->arr_type = $2->symbol->type;
                emit("=&", $$->symbol->name, $2->symbol->name);
            } 
            
            else if(strcmp($1, "*") == 0) {
                // dereferencing
                $$->symbol = $2->symbol;
                $$->loc = gentemp($2->loc->type->arr_type->type);
                $$->loc->type->arr_type = $2->loc->type->arr_type->arr_type;
                $$->type = Array::POINTER;
                emit("=*", $$->loc->name, $2->loc->name);
            } 

            else if(strcmp($1, "+") == 0) {
                // unary plus
                $$ = $2;
            } 
            else { 
                // for unary minus, bitwise not and logical not
                $$ = new Array();
                $$->symbol = gentemp($2->symbol->type->type);
                
                if (strcmp($1,"-")==0)
                    emit("=-", $$->symbol->name, "0", $2->symbol->name); // to differentiate between unary and binary minus
                else
                    emit($1, $$->symbol->name, $2->symbol->name);
            }
        }

    /* below 2 rules involve SIZEOF -> ignored */
    | SIZEOF unary_expression
        { }

    | SIZEOF LPAREN type_name RPAREN
        { }
    ;


// just getting the operator, which will be used later on
unary_operator:
    AMPERSAND
        { 
            $$ = strdup("&"); 
        }
    | ASTERISK
        { 
            $$ = strdup("*"); 
        }
    | PLUS
        { 
            $$ = strdup("+"); 
        }
    | MINUS
        { 
            $$ = strdup("=-"); 
        }
    | TILDE
        { 
            $$ = strdup("~"); 
        }
    | NOT
        { 
            $$ = strdup("!"); 
        }
    ;

// typecasting
cast_expression:
    unary_expression
        { 
            $$ = $1; // depends on unary expression
        }

    | LPAREN type_name RPAREN cast_expression 
        { 
            $$ = new Array();
            $$->symbol = $4->symbol->convert(current_type); // convert to required type
        }
    ;


multiplicative_expression:
    cast_expression
        { 
            $$ = new Expression();

            // we have to obtain base type of the expression in case of array
            SymType *bType = $1->symbol->type;
            while(bType->arr_type != NULL)
                bType = bType->arr_type;

            // if array, then we create a temp symbol and emit code
            if($1->type == Array::ARRAY) {
                $$->symbol = gentemp(bType->type);
                emit("=[]", $$->symbol->name, $1->symbol->name, $1->loc->name);
            } 
            
            // if pointer, then we simply store the location
            else if($1->type == Array::POINTER)
                $$->symbol = $1->loc;

            // if normal variable, then we simply store the symbol
            else
                $$->symbol = $1->symbol;

        }
    | multiplicative_expression ASTERISK cast_expression
        { 
            // similar to above, we obtain base type and create temp symbol
            SymType *bType = $1->symbol->type;
            while(bType->arr_type != NULL)
                bType = bType->arr_type;

            Symbol *temp;

            if($3->type == Array::ARRAY) {
                temp = gentemp(bType->type);
                emit("=[]", temp->name, $3->symbol->name, $3->loc->name);
            } 
            else if($3->type == Array::POINTER)
                temp = $3->loc;
            else
                temp = $3->symbol;

            // now we execute the required operation (here, multiplication)
            // type compatibility is also checked
            if(typecheck($1->symbol, temp)) {
                $$ = new Expression();
                $$->symbol = gentemp($1->symbol->type->type);
                emit("*", $$->symbol->name, $1->symbol->name, temp->name);
            } 
            else {
                yyerror("Type mismatch!");
            }
        }

    | multiplicative_expression DIV cast_expression
        { 
            // similar to above agains
            SymType *bType = $1->symbol->type;
            while(bType->arr_type != NULL)
                bType = bType->arr_type;

            Symbol *temp;

            if($3->type == Array::ARRAY) {
                temp = gentemp(bType->type);
                emit("=[]", temp->name, $3->symbol->name, $3->loc->name);
            } 
            else if($3->type == Array::POINTER)
                temp = $3->loc;
            else
                temp = $3->symbol;

            if(typecheck($1->symbol, temp)) {
                $$ = new Expression();
                $$->symbol = gentemp($1->symbol->type->type);
                emit("/", $$->symbol->name, $1->symbol->name, temp->name);
            } 
            else {
                yyerror("Type mismatch!");
            }
        }

    | multiplicative_expression MOD cast_expression
        { 
            // similar to above again
            SymType *bType = $1->symbol->type;
            while(bType->arr_type != NULL)
                bType = bType->arr_type;

            Symbol *temp;

            if($3->type == Array::ARRAY) {
                temp = gentemp(bType->type);
                emit("=[]", temp->name, $3->symbol->name, $3->loc->name);
            } 
            else if($3->type == Array::POINTER)
                temp = $3->loc;
            else
                temp = $3->symbol;

            if(typecheck($1->symbol, temp)) {
                $$ = new Expression();
                $$->symbol = gentemp($1->symbol->type->type);
                emit("%", $$->symbol->name, $1->symbol->name, temp->name);
            } 
            else {
                yyerror("Type mismatch!");
            }
        }
    ;

additive_expression:
    multiplicative_expression
        { 
            $$ = $1; // depends on multiplicative expression
        }

    | additive_expression PLUS multiplicative_expression
        {   
            // addition operation, but type compatibility is checked
            if(typecheck($1->symbol, $3->symbol)) {
                $$ = new Expression();
                $$->symbol = gentemp($1->symbol->type->type);
                emit("+", $$->symbol->name, $1->symbol->name, $3->symbol->name);
            } 
            else {
                yyerror("Type mismatch!");
            }
        }

    | additive_expression MINUS multiplicative_expression
        { 
            // subtraction operation, but type compatibility is checked
            if(typecheck($1->symbol, $3->symbol)) {
                $$ = new Expression();
                $$->symbol = gentemp($1->symbol->type->type);
                emit("-", $$->symbol->name, $1->symbol->name, $3->symbol->name);
            } 
            else {
                yyerror("Type mismatch!");
            }
        }
    ;

shift_expression:
    additive_expression
        { 
            $$ = $1; // depends on additive expression
        }
        
    | shift_expression LSHIFT additive_expression
        { 
            // left shift operation
            if($3->symbol->type->type == INT) {
                $$ = new Expression();
                $$->symbol = gentemp(INT);
                emit("<<", $$->symbol->name, $1->symbol->name, $3->symbol->name);
            } 
            else {
                yyerror("Type mismatch!");
            }
        }

    | shift_expression RSHIFT additive_expression
        { 
            // right shift operation
            if($3->symbol->type->type == INT) {
                $$ = new Expression();
                $$->symbol = gentemp(INT);
                emit(">>", $$->symbol->name, $1->symbol->name, $3->symbol->name);
            } 
            else {
                yyerror("Type mismatch!");
            }
        }
    ;

// boolean expressions (>, <, <=, >=, =, !=) -> truelist and falselist is made as discussed in class, then backpatching will be done later on

relational_expression:
    shift_expression
        { 
            $$ = $1; // depends on shift expression
        }
    | relational_expression LESS shift_expression
        {   
            if(typecheck($1->symbol, $3->symbol)) {
                $$ = new Expression();
                $$->type = Expression::BOOLEAN;
                $$->truelist = makelist(nextinstr());
                $$->falselist = makelist(nextinstr() + 1);
                emit("<", "", $1->symbol->name, $3->symbol->name);
                emit("goto", "");
            } 
            else {
                yyerror("Type mismatch!");
            }
        }

    | relational_expression GREATER shift_expression
        { 
            if(typecheck($1->symbol, $3->symbol)) {
                $$ = new Expression();
                $$->type = Expression::BOOLEAN;
                $$->truelist = makelist(nextinstr());
                $$->falselist = makelist(nextinstr() + 1);
                emit(">", "", $1->symbol->name, $3->symbol->name);
                emit("goto", "");
            } 
            else {
                yyerror("Type mismatch!");
            }
        }

    | relational_expression LESSEQ shift_expression
        { 
            if(typecheck($1->symbol, $3->symbol)) {
                $$ = new Expression();
                $$->type = Expression::BOOLEAN;
                $$->truelist = makelist(nextinstr());
                $$->falselist = makelist(nextinstr() + 1);
                emit("<=", "", $1->symbol->name, $3->symbol->name);
                emit("goto", "");
            } 
            else {
                yyerror("Type mismatch!");
            }
        }

    | relational_expression GREATEREQ shift_expression
        { 
            if(typecheck($1->symbol, $3->symbol)) {
                $$ = new Expression();
                $$->type = Expression::BOOLEAN;
                $$->truelist = makelist(nextinstr());
                $$->falselist = makelist(nextinstr() + 1);
                emit(">=", "", $1->symbol->name, $3->symbol->name);
                emit("goto", "");
            } 
            else {
                yyerror("Type mismatch!");
            }
        }
    ;

equality_expression:
    relational_expression
        { 
            $$ = $1; // depends on relational expression
        }

    | equality_expression EQUAL relational_expression
        { 
            if(typecheck($1->symbol, $3->symbol)) {
                $1->conv2Int();
                $3->conv2Int();

                $$ = new Expression();
                $$->type = Expression::BOOLEAN;
                $$->truelist = makelist(nextinstr());
                $$->falselist = makelist(nextinstr() + 1);

                emit("==", "", $1->symbol->name, $3->symbol->name);
                emit("goto", "");

            } 
            else {
                yyerror("Type mismatch!");
            }
        }

    | equality_expression NOTEQUAL relational_expression
        { 
            if(typecheck($1->symbol, $3->symbol)) {
                $1->conv2Int();
                $3->conv2Int();

                $$ = new Expression();
                $$->type = Expression::BOOLEAN;
                $$->truelist = makelist(nextinstr());
                $$->falselist = makelist(nextinstr() + 1);

                emit("!=", "", $1->symbol->name, $3->symbol->name);
                emit("goto", "");

            } 
            else {
                yyerror("Type mismatch!");
            }
        }
    ;


// in these cases, there is no need for falselist and truelist, but booleans are involved, hence conversion is done

and_expression:
    equality_expression
        { 
            $$ = $1; // depends on equality expression
        }

    | and_expression AMPERSAND equality_expression
        { 
            $1->conv2Int();
            $3->conv2Int();

            $$ = new Expression();
            $$->type = Expression::NONBOOLEAN;
            $$->symbol = gentemp(INT);

            emit("&", $$->symbol->name, $1->symbol->name, $3->symbol->name);
        }
    ;

exclusive_or_expression:
    and_expression
        { 
            $$ = $1; // depends on AND expression
        }
    | exclusive_or_expression XOR and_expression
        { 
            $1->conv2Int();
            $3->conv2Int();

            $$ = new Expression();
            $$->type = Expression::NONBOOLEAN;
            $$->symbol = gentemp(INT);

            emit("^", $$->symbol->name, $1->symbol->name, $3->symbol->name);
        }
    ;

inclusive_or_expression:
    exclusive_or_expression
        { 
            $$ = $1; // depends on exclusive OR expression
        }
    | inclusive_or_expression OR exclusive_or_expression
        {  
            $1->conv2Int();
            $3->conv2Int();

            $$ = new Expression();
            $$->type = Expression::NONBOOLEAN;
            $$->symbol = gentemp(INT);

            emit("|", $$->symbol->name, $1->symbol->name, $3->symbol->name);
        }
    ;

// in these cases, backpatching needs to be done (as discussed in class), so M and N are used 

logical_and_expression:
    inclusive_or_expression
        { 
            $$ = $1; // depends on inclusive OR expression
        }

    | logical_and_expression LOG_AND M inclusive_or_expression
        { 
            $1->conv2Bool();
            $4->conv2Bool();

            $$ = new Expression();
            $$->type = Expression::BOOLEAN;

            backpatch($1->truelist, $3); // backpatching
            $$->truelist = $4->truelist; // B.truelist = B2.truelist
            $$->falselist = merge($1->falselist, $4->falselist); // B.falselist = merge(B1.falselist, B2.falselist)
        }
    ;

// similarly, done for the rest too
logical_or_expression:
    logical_and_expression
        { 
            $$ = $1; // depends on logical AND expression
        }

    | logical_or_expression LOG_OR M logical_and_expression
        {  
            $1->conv2Bool();
            $4->conv2Bool();

            $$ = new Expression();
            $$->type = Expression::BOOLEAN;

            backpatch($1->falselist, $3); // backpatching
            $$->truelist = merge($1->truelist, $4->truelist); // B.truelist = merge(B1.truelist, B2.truelist)
            $$->falselist = $4->falselist; // B.falselist = B2.falselist
        }
    ;

conditional_expression:
    logical_or_expression
        { 
            $$ = $1; // depends on logical OR expression
        }

    // this is like "if (logical_or_expression) { expression } else { conditional_expression }", so similar addition of M and N is done
    | logical_or_expression N QUESTION M expression N COLON M conditional_expression
        { 
            $$->symbol = gentemp($5->symbol->type->type);
            emit("=", $$->symbol->name, $9->symbol->name);

            list<int> l = makelist(nextinstr());
            emit("goto", "");

            backpatch($6->nextlist, nextinstr());
            emit("=", $$->symbol->name, $5->symbol->name);

            l = merge(l, makelist(nextinstr()));
            emit("goto", "");

            backpatch($2->nextlist, nextinstr());

            $1->conv2Bool();

            backpatch($1->truelist, $4);
            backpatch($1->falselist, $8);

            backpatch(l, nextinstr());
        }
    ;


assignment_expression:
    conditional_expression
        { 
            $$ = $1; // depends on conditional expression
        }

    // assignment in case of array or pointer or normal variable
    | unary_expression assignment_operator assignment_expression
        { 
            if($1->type == Array::ARRAY) {
                $3->symbol = $3->symbol->convert($1->subarr_type->type);
                emit("[]=", $1->symbol->name, $1->loc->name, $3->symbol->name);
            } 
            else if ($1->type == Array::POINTER) {
                $3->symbol = $3->symbol->convert($1->loc->type->type);
                emit("*=", $1->loc->name, $3->symbol->name);
            } 
            else {
                $3->symbol = $3->symbol->convert($1->symbol->type->type);
                emit("=", $1->symbol->name, $3->symbol->name);
            }

            $$ = $3;
        }
    ;

assignment_operator:
    ASSIGN
        { }

    /* all below rules -> ignored */
    | MULASSIGN
        { }
    | DIVASSIGN
        { }
    | MODASSIGN
        { }
    | ADDASSIGN
        { }
    | SUBASSIGN
        { }
    | LEFTASSIGN
        { }
    | RIGHTASSIGN
        { }
    | ANDASSIGN
        { }
    | XORASSIGN
        { }
    | ORASSIGN
        { }
    ;

expression:
    assignment_expression
        { 
            $$ = $1; // depends on assignment expression
        }
    
    /* expression involving comma operator -> ignored */
    | expression COMMA assignment_expression
        { }
    ;

constant_expression:
    conditional_expression
        { }
    ;

// ----------2. Declarations----------


declaration:
    declaration_specifiers init_declarator_list_opt SEMICOLON
        { }
    ;

/* rules involving storage_class_specifier, enum_specifier, type_qualifier, function_specifier  -> ignored */
declaration_specifiers:
    storage_class_specifier declaration_specifiers_opt
        { }

    | type_specifier declaration_specifiers_opt
        { }

    | type_qualifier declaration_specifiers_opt
        { }

    | function_specifier declaration_specifiers_opt
        { }
    ;

declaration_specifiers_opt:
    declaration_specifiers
        { }

    | /* empty */
        { }
    ;

init_declarator_list:
    init_declarator
        { }

    | init_declarator_list COMMA init_declarator
        { }
    ;

init_declarator_list_opt:
    init_declarator_list
        { }

    | /* empty */
        { }
    ;

init_declarator:
    declarator
        { 
            $$ = $1; // depends on declarator
        }
    | declarator ASSIGN initializer
        {   
            // if non-empty, then we assign the initial value
            if($3->init_val != "-") $1->init_val = $3->init_val;
            emit("=", $1->name, $3->name);
        }
    ;

/* storage_class_specifier -> ignored */
storage_class_specifier:
    EXTERN
        { }

    | STATIC
        { }

    | AUTO
        { }

    | REGISTER
        { }
    ;

/* only void, char, int, float considered */
/* their token names were changed to avoid overlap with enum names */
/* depending on the type, current type is updated */
type_specifier:
    VOID_TYPE
        { 
            current_type = VOID;
        }

    | CHAR_TYPE
        { 
            current_type = CHAR;
        }
    | SHORT
        { }
    | INT_TYPE
        { 
            current_type = INT;
        }
    | LONG
        { }
    | FLOAT_TYPE
        { 
            current_type = FLOAT;
        }
    | DOUBLE
        { }
    | SIGNED
        { }
    | UNSIGNED
        { }
    | BOOL_
        { }
    | COMPLEX_
        { }
    | IMAGINARY_
        { }
    ;

/* rules involving type_qualifier -> ignored */
specifier_qualifier_list:
    type_specifier specifier_qualifier_list_opt
        { }
    | type_qualifier specifier_qualifier_list_opt
        { }
    ;


specifier_qualifier_list_opt:
    specifier_qualifier_list
        { }

    | /* empty */
        { }
    ;

identifier_opt:
    IDENTIFIER 
        { }

    | /* empty */
        { }
    ;

enumerator_list:
    enumerator 
        { }

    | enumerator_list COMMA enumerator
        { }
    ;

enumerator:
    IDENTIFIER 
        { }
        
    | IDENTIFIER ASSIGN constant_expression
        { }
    ;

type_qualifier:
    CONST
        { }

    | RESTRICT
        { }

    | VOLATILE
        { }
    ;

function_specifier:
    INLINE
        { }
    ;

declarator:
    pointer direct_declarator
        { 
            // for multi-dimensional arrays -> moving deeper until base type is obtained
            SymType *temp = $1;
            while(temp->arr_type != NULL) 
                temp = temp->arr_type;

            // updating type of declarator
            temp->arr_type = $2->type;
            $$ = $2->update($1);
        }

    | direct_declarator
        { }
    ;

/*

Declarations

*/

/* rules involving type_qualifier ignored */
/* rules involving static ignored */
/* type_qualifier_list_opt replaced with type_qualifier_list and epsilon */
/* assignment_expression_opt replaced with assignment_expression and epsilon */
/* identifier_list_opt replaced  with identifier_list and epsilon */
direct_declarator:
    IDENTIFIER 
        { 
            // variable declaration
            $$ = $1->update(new SymType(current_type)); 
            current_symbol = $$;
        }

    | LPAREN declarator RPAREN
        { 
            $$ = $2; // depends on declarator
        }

    | direct_declarator LPARENSQ type_qualifier_list assignment_expression RPARENSQ
        { }

    | direct_declarator LPARENSQ type_qualifier_list RPARENSQ
        { }

    | direct_declarator LPARENSQ assignment_expression RPARENSQ
        { 
            
            // to check whether array is 1D or multi-dimensional
            SymType *temp = $1->type, *prev = NULL;
            while(temp->type == ARRAY) { 
                prev = temp;
                temp = temp->arr_type;
            }

            if(prev != NULL) { 
                // case of multi-dimensional array -> base type is obtained from temp
                prev->arr_type =  new SymType(ARRAY, temp, atoi($3->symbol->init_val.c_str()));	
                $$ = $1->update($1->type);
            }
            else { 
                // just 1D array
                SymType* new_type = new SymType(ARRAY, $1->type, atoi($3->symbol->init_val.c_str()));
                $$ = $1->update(new_type);
            }
        }

    | direct_declarator LPARENSQ RPARENSQ
        { 
            // similar to previous one, but initial value is kept as 0 as we don't know the size
            SymType *temp = $1->type, *prev = NULL;
            while(temp->type == ARRAY) { 
                prev = temp;
                temp = temp->arr_type;
            }

            if(prev != NULL) { 
                // case of multi-dimensional array
                prev->arr_type =  new SymType(ARRAY, temp, 0);	
                $$ = $1->update($1->type);
            }
            else { 
                // just 1D array
                SymType* new_type = new SymType(ARRAY, $1->type, 0);
                $$ = $1->update(new_type);
            }
        }

    | direct_declarator LPARENSQ STATIC type_qualifier_list assignment_expression RPARENSQ
        { }

    | direct_declarator LPARENSQ STATIC assignment_expression RPARENSQ
        { }

    | direct_declarator LPARENSQ type_qualifier_list STATIC assignment_expression RPARENSQ
        { }

    | direct_declarator LPARENSQ type_qualifier_list ASTERISK RPARENSQ
        { }

    | direct_declarator LPARENSQ ASTERISK RPARENSQ
        { }
    
    /* additional non-terminal used to trigger changing of symbol table in case of function  */
    | direct_declarator LPAREN CT parameter_type_list RPAREN
        { 
            // function declaration
            currentST->name = $1->name;

            if($1->type->type != VOID) {
                // return symbol is updated, for non-void functions
                Symbol* s = currentST->lookup("return");
                s->update($1->type);
            }

            // set nested table for function
            $1->nestedST = currentST;
            currentST->parent = globalST;

            changeTable(globalST); // change to global table
            current_symbol = $$;
        }

    | direct_declarator LPAREN identifier_list RPAREN
        { }

    | direct_declarator LPAREN CT RPAREN
        { 
            // same as previous one
            currentST->name = $1->name;

            if($1->type->type != VOID) {
                Symbol* s = currentST->lookup("return");
                s->update($1->type);
            }

            // set nested table for function
            $1->nestedST = currentST;
            currentST->parent = globalST;

            changeTable(globalST); // change to global table
            current_symbol = $$;
        }
    ;



pointer:
    ASTERISK type_qualifier_list_opt
        { 
            $$ = new SymType(POINTER); // new pointer
        }

    | ASTERISK type_qualifier_list_opt pointer
        { 
            $$ = new SymType(POINTER, $3); // nested pointer
        }
    ;

type_qualifier_list:
    type_qualifier
        { }

    | type_qualifier_list type_qualifier
        { }
    ;

type_qualifier_list_opt:
    type_qualifier_list
        { }

    | /* empty */
        { }
    ;

parameter_type_list:
    parameter_list
        { }

    | parameter_list COMMA ELLIPSIS
        { }
    ;

parameter_list:
    parameter_declaration
        { }

    | parameter_list COMMA parameter_declaration
        { }
    ;

parameter_declaration:
    declaration_specifiers declarator
        { }

    | declaration_specifiers
        { }
    ;

identifier_list:
    IDENTIFIER 
        { }

    | identifier_list COMMA IDENTIFIER
        { }
    ;

type_name:
    specifier_qualifier_list
        { }
    ;

initializer:
    assignment_expression
        { 
            $$ = $1->symbol; // depends on assignment expression
        }

    | LBRACE initializer_list RBRACE
        { }  

    | LBRACE initializer_list COMMA RBRACE
        { }
    ;

initializer_list:
    designation_opt initializer
        { }

    | initializer_list COMMA designation_opt initializer
        { }
    ;

designation:
    designator_list ASSIGN
        { }
    ;

designation_opt:
    designation
        { }

    | /* empty */
        { }
    ;

designator_list:
    designator
        { }

    | designator_list designator
        { }
    ;

designator:
    LPARENSQ constant_expression RPARENSQ
        { }

    | DOT IDENTIFIER
        { }   
    ;


// ----------3. Statements----------

/* labeled_statement -> ignored */
statement:
    labeled_statement
        { }

    | compound_statement
        { 
            $$ = $1; 
        }

    | expression_statement
        { 
            $$ = new Statement();
            $$->nextlist = $1->nextlist;
        }

    | selection_statement
        { 
            $$ = $1;
        }

    | iteration_statement
        { 
            $$ = $1;
        }

    | jump_statement
        { 
            $$ = $1;
        }
    ;

/* labeled_statement -> ignored */
labeled_statement:
    IDENTIFIER COLON statement
        { }

    | CASE constant_expression COLON statement
        { }    

    | DEFAULT COLON statement
        { }
    ;



compound_statement:
    LBRACE CB CT block_item_list_opt RBRACE
        { 
            $$ = $4;
            changeTable(currentST->parent); // return to parent ST
        }
    ;

block_item_list:
    block_item
        {
            $$ = $1;
        }

    // backpatching needs to be done 
    // L -> L1 M S 
    | block_item_list M block_item
        { 
            $$ = $3;
            backpatch($1->nextlist,$2);
        }
    ;

block_item_list_opt:
    block_item_list
        { 
            $$ = $1; // depends on block item list
        }

    | /* empty */
        { 
            $$ = new Statement(); // new statement
        }
    ;


block_item:
    declaration
        { 
            $$ = new Statement(); // new statement
        }
    | statement
        { 
            $$ = $1; // depends on statement
        }
    ;

expression_statement:
    expression_opt SEMICOLON
        { 
            $$ = $1; // depends on expression
        }
    ;

expression_opt:
    expression
        { 
            $$ = $1; // depends on expression
        }
    | /* empty */
        { 
            $$ = new Expression(); // new expression
        }
    ;

/* switch ignored */
/* for with declaration inside ignored */

/* in IF, WHILE, DO and FOR: backpatching needs to be done (as discussed in class) */
selection_statement:
    /* if (expression) M statement N else M statement */
    IF LPAREN expression RPAREN M statement N ELSE M statement
        { 
            $$ = new Statement();

            $3->conv2Bool();

            backpatch($3->truelist, $5); // if true, go to M1 (if-statement)
            backpatch($3->falselist, $9); // if false, go to M2 (else-statement)

            $$->nextlist = merge($10->nextlist, merge($6->nextlist, $7->nextlist)); // to go out of if-else after it's done
        }
    
    /* %prec THEN added to remove translation conflicts */
    /* if (expression) M statement */
    /* N also added before %prec THEN to exit if condition ("THEN" is not actually checked) */
    | IF LPAREN expression RPAREN M statement N %prec THEN
        { 
            $$ = new Statement();

            $3->conv2Bool();

            backpatch($3->truelist, $5); // // if true, go to M1 (if-statement)

            $$->nextlist = merge($3->falselist, merge($6->nextlist, $7->nextlist)); // to go out of if when expression is false
        }
    
    | SWITCH LPAREN expression RPAREN statement
        { }
    ;

iteration_statement:

    /* while M1 (expression) M2 statement */
    WHILE M LPAREN expression RPAREN M statement
        { 
            $$ = new Statement();

            $4->conv2Bool();

            backpatch($7->nextlist, $2); // M1 -> to go back to start of loop
            backpatch($4->truelist, $6); // if true, go to M2 (statement)

            $$->nextlist = $4->falselist; // to go out of while when expression is false

            emit("goto", to_string($2));
        }

    // similar to while ...
    // do M1 statement M2 while (expression) ;
    | DO M statement M WHILE LPAREN expression RPAREN SEMICOLON
        { 
            $$ = new Statement();

            $7->conv2Bool();

            backpatch($7->truelist, $2); // if true, go to M1 (statement)
            backpatch($3->nextlist, $4); // M2 -> to go to check expression once statement is executed

            $$->nextlist = $7->falselist; // to go out of do-while when expression is false
        }

    // again similar to while ... 
    | FOR LPAREN expression_opt SEMICOLON M expression_opt SEMICOLON M expression_opt N RPAREN M statement
        { 
            $$ = new Statement();

            $6->conv2Bool();

            backpatch($6->truelist, $12); // if true, go to M3 (statement)
            backpatch($10->nextlist, $5); // go to M1 after N1 (for checking condition)
            backpatch($13->nextlist, $8); // go to M2 (3rd part of for loop), after statement is executed

            emit("goto", to_string($8));

            $$->nextlist = $6->falselist; // to go out of for when expression is false
        }

    | FOR LPAREN declaration expression_opt SEMICOLON expression_opt RPAREN statement
        { }
    ;

/* only return is considered */
jump_statement:
    GOTO IDENTIFIER SEMICOLON
        { }    

    | CONTINUE SEMICOLON
        { }

    | BREAK SEMICOLON
        { }

    | RETURN expression_opt SEMICOLON
        {   
            // depending on whether expression_opt is epsilon or not, return is handled
            $$ = new Statement();
            emit("return",($2->symbol == NULL) ? "" : $2->symbol->name);
        }
    ;

/* External definitions */

/* external_declaration and translation_unit -> ignored */
translation_unit:
    external_declaration
        { }

    | translation_unit external_declaration
        { }
    ;

external_declaration:
    function_definition
        { }

    | declaration
        { }
    ;

// compound_statement at the end is expanded - to avoid block change in function definition
function_definition: 
    declaration_specifiers declarator declaration_list_opt CT LBRACE block_item_list_opt RBRACE
        { 
            block_count = 0; // reset block count for function
            $2->type->type = FUNCTION;
            changeTable(globalST); // return to global ST
        }
    ;

declaration_list:
    declaration
        { }

    | declaration_list declaration
        { }
    ;

declaration_list_opt:
    declaration_list
        { }

    |
        { }
    ;

%%

void yyerror(const char* s) {
    printf("ERROR [Line %d] : %s, unable to parse : %s\n", yylineno, s, yytext);
}   