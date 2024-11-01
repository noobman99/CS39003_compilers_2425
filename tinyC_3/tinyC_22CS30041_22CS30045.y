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
// augmented grammar solely for non boolean cases in if statements
%type<expr> selection_expression
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

// Production rules of auxillary non-terminals 

// Non-terminal M (Next Instruction) - Used to get the next instruction number
M:  
    {
        $$ = nextinstr();
    }   
;

// Non-terminal N (Goto Statement) - Used to create a new statement and emit a goto instruction
N: 
    {
        $$ = new Statement();
        $$->nextlist = makelist(nextinstr());
        emit("goto", "");
    }
;

// Non-terminal CT (Change Table) - Used when entering a function to:
// 1. Create a new symbol table if one doesn't exist for this function
// 2. Change to the function's existing symbol table if it exists
// 3. Emit a label for the function
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

// Non-terminal CB (Create Block) - Used when entering a block to:
// 1. Create a new symbol table for the block
// 2. Set the type of the new symbol table to BLOCK
// 3. Set the current symbol to the new symbol table
CB: 
    {
        isDeclaration = true;
        string name = currentST->name + "_" + to_string(block_count++); // name for new ST
        Symbol *s = currentST->lookup(name); 
        isDeclaration = false;
        s->nestedST = new SymTable(name, currentST);
        s->type = new SymType(BLOCK);
        current_symbol = s;
    } 
;


// Rules to be ignored are left blank

// -------------------------------------- Expressions --------------------------------------


primary_expression: 
    IDENTIFIER 
        { 
            $$ = new Expression(); // Add to the symbol table
            $$->symbol = $1;
            $$->type = Expression::NONBOOLEAN; 
        }
    | constant 
        {
            $$ = $1;
        }

    | STRING_LITERAL 
        { 
            $$ = new Expression(); // Add to the symbol table
            $$->symbol = gentemp(POINTER, $1);
            $$->symbol->type->arr_type = new SymType(CHAR);
        }

    | LPAREN expression RPAREN
        { 
            $$ = $2;
        }
    ;

// Depending on the type of constant, generate a temporary
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
            // Create a new array and append the location of the primary expression
            $$ = new Array();
            $$->symbol = $1->symbol;
            $$->loc = $$->symbol;
            $$->subarr_type = $1->symbol->type;
        }

    | postfix_expression LPARENSQ expression RPARENSQ
        { 
            $$ = new Array();
            $$->symbol = $1->symbol;    
            $$->subarr_type = $1->subarr_type->arr_type;
            $$->loc = gentemp(INT); 
            $$->type = Array::ARRAY;

            // Check for multi-dimensional array
            if($1->type == Array::ARRAY) {
                // For multi-dimensional arrays:
                // 1. Multiply index by element size
                // 2. Add to previous dimension's offset
                Symbol *sym = gentemp(INT);
                int size = $$->subarr_type->computeSize();
                emit("*", sym->name, $3->symbol->name, to_string(size));
                emit("+", $$->loc->name, $1->loc->name, sym->name);
            } else {
                // 1D array
                int size = $$->subarr_type->computeSize();
                emit("*", $$->loc->name, $3->symbol->name, to_string(size));
            }

        }

    | postfix_expression LPAREN argument_expression_list_opt RPAREN
        { 
            // Function call
            $$ = new Array();
            $$->symbol = gentemp($1->symbol->type->arr_type->type);
            emit("call", $$->symbol->name, $1->symbol->name, to_string($3));
        }

    /* Ignored */
    | postfix_expression DOT IDENTIFIER
        { }

    | postfix_expression ARROW IDENTIFIER
        { }

    | postfix_expression INCREMENT
        { 
            $$ = new Array();
            // Add 1 to the value
            $$->symbol = gentemp($1->symbol->type->type);
            emit("=", $$->symbol->name, $1->symbol->name);
            emit("+", $1->symbol->name, $1->symbol->name, "1"); 
        }
    | postfix_expression DECREMENT
        { 
            $$ = new Array();
            // Subtract 1 from the value
            $$->symbol = gentemp($1->symbol->type->type);
            emit("=", $$->symbol->name, $1->symbol->name);
            emit("-", $1->symbol->name, $1->symbol->name, "1");
        }

    | LPAREN type_name RPAREN LBRACE initializer_list RBRACE
        { }

    | LPAREN type_name RPAREN LBRACE initializer_list COMMA RBRACE
        { }
    ;


// Number of arguments/parameters is computed here
argument_expression_list_opt:
    argument_expression_list
        { 
            $$ = $1;
        }

    | /* empty */
        { 
            $$ = 0;
        }
    ;

argument_expression_list:
    assignment_expression
        { 
            $$ = 1;
            emit("param", $1->symbol->name);
        }

    | argument_expression_list COMMA assignment_expression
        { 
            $$ = $1 + 1;
            emit("param", $3->symbol->name);
        }
    ;

unary_expression:
    postfix_expression
        { 
            $$ = $1;
        }
    | INCREMENT unary_expression
        { 
            $$ = $2;
            // Pre-increment
            emit("+", $2->symbol->name, $2->symbol->name, "1");
        }

    | DECREMENT unary_expression
        { 
            $$ = $2;
            // Pre-decrement
            emit("-", $2->symbol->name, $2->symbol->name, "1");
        }

    | unary_operator cast_expression
        { 
            // Operation depends on unary operator
            $$ = new Array();

            if(!strcmp($1, "&")) {
                // Address of -> generate new pointer type
                $$->symbol = gentemp(POINTER);
                $$->symbol->type->arr_type = $2->symbol->type;
                emit("=&", $$->symbol->name, $2->symbol->name);
            } 
            
            else if(!strcmp($1, "*")) {
                // Dereferencing
                $$->symbol = $2->symbol;
                $$->loc = gentemp($2->loc->type->arr_type->type);
                $$->loc->type->arr_type = $2->loc->type->arr_type->arr_type;
                $$->type = Array::POINTER;
                emit("=*", $$->loc->name, $2->loc->name);
            } 

            else if(!strcmp($1, "+")) {
                // Unary plus
                $$ = $2;
            } 
            else { 
                // For unary minus, bitwise not and logical not
                $$ = new Array();
                $$->symbol = gentemp($2->symbol->type->type);
                
                if (!strcmp($1,"-"))
                    emit("=-", $$->symbol->name, "0", $2->symbol->name); // to differentiate between unary and binary minus
                else
                    emit($1, $$->symbol->name, $2->symbol->name);
            }
        }

    /* Ignored */
    | SIZEOF unary_expression
        { }

    | SIZEOF LPAREN type_name RPAREN
        { }
    ;


// Passing the operator to the next rule
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

// Typecasting
cast_expression:
    unary_expression
        { 
            $$ = $1;
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

            // Obtain base type of the expression in case of array
            SymType *bType = $1->symbol->type;
            while(bType->arr_type != NULL)
                bType = bType->arr_type;

            // If array, then create a temp symbol and emit code
            if($1->type == Array::ARRAY) {
                $$->symbol = gentemp(bType->type);
                emit("=[]", $$->symbol->name, $1->symbol->name, $1->loc->name);
            } 
            
            // If pointer, then store the location
            else if($1->type == Array::POINTER)
                $$->symbol = $1->loc;

            // If normal variable, then store the symbol
            else
                $$->symbol = $1->symbol;

        }
    | multiplicative_expression ASTERISK cast_expression
        { 
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

            // Execute the required operation (here, multiplication)
            // Type compatibility is also checked
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
            // Get the base type of the first operand
            SymType *baseType = $1->symbol->type;
            for(; baseType->arr_type; baseType = baseType->arr_type);

            // Handle the second operand based on its type
            Symbol *operand2;
            if($3->type == Array::ARRAY) {
                // For array type, create temporary and load value
                operand2 = gentemp(baseType->type); 
                emit("=[]", operand2->name, $3->symbol->name, $3->loc->name);
            }
            else {
                // For pointer/normal variable, use directly
                operand2 = ($3->type == Array::POINTER) ? $3->loc : $3->symbol;
            }

            // Create result only if types are compatible
            if(!typecheck($1->symbol, operand2)) {
                yyerror("Type mismatch!");
            }
            else {
                // Generate division operation
                $$ = new Expression();
                $$->symbol = gentemp($1->symbol->type->type);
                emit("/", $$->symbol->name, $1->symbol->name, operand2->name);
            }
        }

    | multiplicative_expression MOD cast_expression
        { 
            // Get the base type of the first operand
            SymType *baseType = $1->symbol->type;
            for(; baseType->arr_type; baseType = baseType->arr_type);

            // Handle the second operand based on its type
            Symbol *operand2;
            if($3->type == Array::ARRAY) {
                // For array type, create temporary and load value
                operand2 = gentemp(baseType->type); 
                emit("=[]", operand2->name, $3->symbol->name, $3->loc->name);
            }
            else {
                // For pointer/normal variable, use directly
                operand2 = ($3->type == Array::POINTER) ? $3->loc : $3->symbol;
            }

            // Create result only if types are compatible
            if(!typecheck($1->symbol, operand2)) {
                yyerror("Type mismatch!");
            }
            else {
                // Generate modulo operation
                $$ = new Expression();
                $$->symbol = gentemp($1->symbol->type->type);
                emit("%", $$->symbol->name, $1->symbol->name, operand2->name);
            }
        }
    ;

additive_expression:
    multiplicative_expression
        { 
            $$ = $1;
        }

    | additive_expression PLUS multiplicative_expression
        {   
            // Addition operation, but type compatibility is checked
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
            // Subtraction operation, but type compatibility is checked
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
            $$ = $1;
        }
        
    | shift_expression LSHIFT additive_expression
        { 
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

// Boolean expressions (>, <, <=, >=, =, !=) -> truelist and falselist is initialized here

relational_expression:
    shift_expression
        { 
            $$ = $1;
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
            $$ = $1;
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


// Conversion is done for boolean values

and_expression:
    equality_expression
        { 
            $$ = $1;
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
            $$ = $1;
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
            $$ = $1;
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

// Backpatching used here

logical_and_expression:
    inclusive_or_expression
        { 
            $$ = $1;
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

logical_or_expression:
    logical_and_expression
        { 
            $$ = $1;
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
            $$ = $1;
        }

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
            $$ = $1;
        }

    // Assignment in case of array or pointer or normal variable
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
            $$ = $1;
        }
    
    /* Ignored */
    | expression COMMA assignment_expression
        { }
    ;

constant_expression:
    conditional_expression
        { }
    ;

// -------------------------------------- Declarations --------------------------------------


declaration:
    declaration_specifiers init_declarator_list_opt SEMICOLON
        { }
    ;

/* Ignored */
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
            $$ = $1;
        }
    | declarator ASSIGN initializer
        {   
            if($3->init_val != "-") $1->init_val = $3->init_val;
            emit("=", $1->name, $3->name);
        }
    ;

/* Ignored */
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

/* Only void, char, int, float considered */
/* Their token names were changed to avoid overlap with enum names */
/* Depending on the type, current type is updated */
type_specifier:
    VOID_TYPE
        { 
            current_type = VOID;
            isDeclaration = true;
        }

    | CHAR_TYPE
        { 
            current_type = CHAR;
            isDeclaration = true;
        }
    | SHORT
        { }
    | INT_TYPE
        { 
            current_type = INT;
            isDeclaration = true;
        }
    | LONG
        { }
    | FLOAT_TYPE
        { 
            current_type = FLOAT;
            isDeclaration = true;
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

/* Ignored */
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
            // Obtain the base
            SymType *temp = $1;
            while(temp->arr_type != NULL) 
                temp = temp->arr_type;

            SymType* t_base = $2->type;
            SymType* t_base_prev = NULL;
            while(t_base->arr_type != NULL) {
                t_base_prev = t_base;
                t_base = t_base->arr_type;
            }
            
            // Declarator type is updated
            temp->arr_type = t_base;
            if (t_base_prev != NULL){
                t_base_prev->arr_type = $1;
                $$ = $2;
            }
            else{
                $$ = $2->update($1);
            }
            isDeclaration = false;
        }

    | direct_declarator
        { 
            isDeclaration = false;
        }
    ;

/* type_qualifier_list_opt replaced with type_qualifier_list and epsilon */
/* assignment_expression_opt replaced with assignment_expression and epsilon */
/* identifier_list_opt replaced  with identifier_list and epsilon */
direct_declarator:
    IDENTIFIER 
        { 
            // Variable declaration
            $$ = $1->update(new SymType(current_type)); 
            current_symbol = $$;
        }

    | LPAREN declarator RPAREN
        { 
            $$ = $2;
        }

    | direct_declarator LPARENSQ type_qualifier_list assignment_expression RPARENSQ
        { }

    | direct_declarator LPARENSQ type_qualifier_list RPARENSQ
        { }

    | direct_declarator LPARENSQ assignment_expression RPARENSQ
        { 
            
            // Check for array dimension
            SymType *temp = $1->type, *prev = NULL;
            while(temp->type == ARRAY) { 
                prev = temp;
                temp = temp->arr_type;
            }

            if(prev != NULL) { 
                // Multi-dimensional array -> base type is obtained from temp
                prev->arr_type =  new SymType(ARRAY, temp, atoi($3->symbol->init_val.c_str()));	
                $$ = $1->update($1->type);
            }
            else { 
                SymType* new_type = new SymType(ARRAY, $1->type, atoi($3->symbol->init_val.c_str()));
                $$ = $1->update(new_type);
            }
        }

    | direct_declarator LPARENSQ RPARENSQ
        { 
            SymType *temp = $1->type, *prev = NULL;
            while(temp->type == ARRAY) { 
                prev = temp;
                temp = temp->arr_type;
            }

            if(prev != NULL) { 
                // Multi-dimensional array
                prev->arr_type =  new SymType(ARRAY, temp, 0);	
                $$ = $1->update($1->type);
            }
            else { 
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
    
    /* Trigger changing of symbol table in case of function using CT */
    | direct_declarator LPAREN CT parameter_type_list RPAREN
        { 
            currentST->name = $1->name;

            if($1->type->type != VOID) {
                // Return symbol updated for non-void functions
                Symbol* s = currentST->lookup("return");
                s->update($1->type);
            }

            SymType* temp = new SymType(FUNCTION);
            temp->arr_type = $1->type;
            $1->update(temp);

            // Set nested table for function
            $1->nestedST = currentST;
            currentST->parent = globalST;

            changeTable(globalST);
            current_symbol = $$;
        }

    | direct_declarator LPAREN identifier_list RPAREN
        { }

    | direct_declarator LPAREN CT RPAREN
        { 
            currentST->name = $1->name;

            if($1->type->type != VOID && $1->type->type != FUNCTION) {
                Symbol* s = currentST->lookup("return");
                s->update($1->type);
            }

            SymType* temp = new SymType(FUNCTION);
            temp->arr_type = $1->type;
            $1->update(temp);

            // Set nested table for function
            $1->nestedST = currentST;
            currentST->parent = globalST;

            changeTable(globalST);
            current_symbol = $$;
        }
    ;



pointer:
    ASTERISK type_qualifier_list_opt
        { 
            $$ = new SymType(POINTER);
        }

    | ASTERISK type_qualifier_list_opt pointer
        { 
            $$ = new SymType(POINTER, $3); // Nested pointer
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
            $$ = $1->symbol;
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


// ----------------------------- Statements -----------------------------

/* Ignored */
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

/* Ignored */
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

    // Backpatching required
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
            $$ = $1;
        }

    | /* empty */
        { 
            $$ = new Statement();
        }
    ;


block_item:
    declaration
        { 
            $$ = new Statement();
        }
    | statement
        { 
            $$ = $1;
        }
    ;

expression_statement:
    expression_opt SEMICOLON
        { 
            $$ = $1;
        }
    ;

expression_opt:
    expression
        { 
            $$ = $1;
        }
    | /* empty */
        { 
            $$ = new Expression();
        }
    ;

selection_statement:
    /* if (expression) M statement N else M statement */
    IF LPAREN selection_expression RPAREN M statement N ELSE M statement
        { 
            $$ = new Statement();

            $3->conv2Bool();

            backpatch($3->truelist, $5); // if true, go to M1 (if-statement)
            backpatch($3->falselist, $9); // if false, go to M2 (else-statement)

            $$->nextlist = merge($10->nextlist, merge($6->nextlist, $7->nextlist)); // Exit if else
        }
    
    /* %prec THEN added to remove translation conflicts */
    | IF LPAREN selection_expression RPAREN M statement N %prec THEN
        { 
            $$ = new Statement();

            $3->conv2Bool();

            backpatch($3->truelist, $5); // If true, go to M1

            $$->nextlist = merge($3->falselist, merge($6->nextlist, $7->nextlist)); // Exit if when expression is false
        }
    
    | SWITCH LPAREN expression RPAREN statement
        { }
    ;

selection_expression: expression {$1->conv2Bool(); $$ = $1;}

iteration_statement:

    WHILE M LPAREN expression RPAREN M statement
        { 
            $$ = new Statement();

            $4->conv2Bool();

            backpatch($7->nextlist, $2); // M1 -> to go back to start of loop
            backpatch($4->truelist, $6); // If true, go to M2

            $$->nextlist = $4->falselist; // Exit while when expression is false

            emit("goto", to_string($2));
        }

    | DO M statement M WHILE LPAREN expression RPAREN SEMICOLON
        { 
            $$ = new Statement();

            $7->conv2Bool();

            backpatch($7->truelist, $2); // If true, go to M1
            backpatch($3->nextlist, $4); // M2 -> to go to check expression once statement is executed

            $$->nextlist = $7->falselist; // Exit do-while when expression is false
        }

    | FOR LPAREN expression_opt SEMICOLON M expression_opt SEMICOLON M expression_opt N RPAREN M statement
        { 
            $$ = new Statement();

            $6->conv2Bool();

            backpatch($6->truelist, $12); // If true, go to M3
            backpatch($10->nextlist, $5); // Go to M1 after N1
            backpatch($13->nextlist, $8); // Go to M2 after statement is executed

            emit("goto", to_string($8));

            $$->nextlist = $6->falselist; // Exit for when expression is false
        }

    | FOR LPAREN declaration expression_opt SEMICOLON expression_opt RPAREN statement
        { }
    ;

jump_statement:
    GOTO IDENTIFIER SEMICOLON
        { }    

    | CONTINUE SEMICOLON
        { }

    | BREAK SEMICOLON
        { }

    | RETURN expression_opt SEMICOLON
        {   
            $$ = new Statement();
            emit("return",($2->symbol == NULL) ? "" : $2->symbol->name);
        }
    ;

/* External definitions */

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

// Compound statement at the end is expanded
function_definition: 
    declaration_specifiers declarator declaration_list_opt CT LBRACE block_item_list_opt RBRACE
        { 
            block_count = 0; // Reset block count for function
            $2->type->type = FUNCTION;
            changeTable(globalST); // Return to global ST
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