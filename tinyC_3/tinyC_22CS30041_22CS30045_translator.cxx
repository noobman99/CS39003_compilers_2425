#include "tinyC_22CS30041_22CS30045_translator.h"
#include <iomanip>
/**
 * Global variables used throughout the translator
 */

/**
 * Global variables for the translator implementation
 *
 * qArr: Vector containing all quadruples generated during translation
 *       Implemented as a vector for dynamic sizing and random access
 *
 * currentST: Pointer to the symbol table currently in scope
 *           Updated when entering/exiting blocks and functions
 *
 * globalST: Pointer to the root symbol table containing global symbols
 *          Parent of all other symbol tables in the program
 *
 * block_count: Integer counter used to generate unique identifiers
 *             for nested symbol tables within code blocks
 *
 * current_symbol: Pointer to symbol being processed during symbol
 *                table transitions and scope changes
 *
 * current_type: Tracks the active data type for type checking and
 *              casting operations during translation
 *
 * isDeclaration: Flag to check if the current symbol is being declared
 */
vector<Quad *> qArr;
TYPE current_type;
SymTable *globalST;
int block_count;
SymTable *currentST;
Symbol *current_symbol;
bool isDeclaration;

void yyerror(const char *);
extern int yylineno;
extern char *yytext;

// SymType class methods

SymType::SymType(TYPE type_, SymType *arr_type_, int width_) : type(type_), width(width_), arr_type(arr_type_) {}

// to get size (machine-dependent)
int SymType::computeSize()
{
    int ret = -1;
    switch (this->type)
    {
    case VOID:
        ret = __SIZE_VOID__;
        break;
    case CHAR:
        ret = __SIZE_CHAR__;
    case INT:
        ret = __SIZE_INT__;
        break;
    case FLOAT:
        ret = __SIZE_FLOAT__;
        break;
    case POINTER:
        ret = __SIZE_POINTER__;
        break;
    case ARRAY:
        ret = this->width * (this->arr_type->computeSize());
        break;
    case FUNCTION:
        ret = __SIZE_FUNCTION__;
        break;
    default:
        ret = -1;
        break;
    }

    return ret;
}

// to convert the enum to string, for printing
string SymType::toString()
{
    string ret = "";
    switch (this->type)
    {
    case VOID:
        ret = "void";
        break;
    case CHAR:
        ret = "char";
        break;
    case INT:
        ret = "int";
        break;
    case FLOAT:
        ret = "float";
        break;
    case POINTER:
        ret = "ptr(" + this->arr_type->toString() + ")";
        break;
    case ARRAY:
        ret = "array(" + to_string(this->width) + ", " + this->arr_type->toString() + ")";
        break;
    case BLOCK:
        ret = "block";
        break;
    case FUNCTION:
        ret = "funct(" + this->arr_type->toString() + ")";
        break;
    default:
        ret = "null";
        break;
    }

    return ret;
}

// SymTable class methods

SymTable::SymTable(string name_, SymTable *parent_) : name(name_), parent(parent_), count(0) {}

Symbol *SymTable::lookup(string name)
{
    list<Symbol>::iterator it = (this->symbols).begin();

    for (; it != (this->symbols).end(); it++)
    {
        if (it->name == name)
        {
            if (isDeclaration && name != "return")
            {
                string s = "Redeclaration of variable " + name;
                yyerror(s.c_str());
                // exit(1);
            }
            return &(*it);
        }
    }

    if (!isDeclaration && name != "return")
    {
        if (this->parent != NULL)
            return this->parent->lookup(name);
        else
        {
            string s = "Undefined variable " + name;
            yyerror(s.c_str());
            // exit(1);
        }
    }

    // if it doesnt exist, add it to the table and return it
    Symbol *sym = new Symbol(name);
    (this->symbols).push_back(*sym);

    return &(this->symbols).back();
}

// to update offsets
void SymTable::update()
{
    vector<SymTable *> nested_tables;
    list<Symbol>::iterator it = (this->symbols).begin();

    int offset = 0;

    for (; it != (this->symbols).end(); it++)
    {
        it->offset = offset;
        offset += it->size;
        if (it->nestedST)
        {
            nested_tables.push_back(it->nestedST);
        }
    }

    vector<SymTable *>::iterator it2 = nested_tables.begin();
    for (; it2 != nested_tables.end(); it2++)
    {
        (*it2)->update();
    }
}

// to print symbol name and children
void SymTable::print()
{

    // header for the table
    for (int i = 0; i < (__PRINT_TABLE_WIDTH * 7.5); i++)
        cout << "-";
    cout << endl;

    cout << "Symbol Table : " << this->name << "\t\t\t\t\t\tParent: " << (this->parent == NULL ? "NULL" : this->parent->name) << endl;

    for (int i = 0; i < (__PRINT_TABLE_WIDTH * 7.5); i++)
        cout << "-";
    cout << endl;

    cout << left << setw(__PRINT_TABLE_WIDTH * 1.5) << "Name";
    cout << left << setw(__PRINT_TABLE_WIDTH * 2) << "Type";
    cout << left << setw(__PRINT_TABLE_WIDTH) << "InitVal";
    cout << left << setw(__PRINT_TABLE_WIDTH) << "Size";
    cout << left << setw(__PRINT_TABLE_WIDTH) << "Offset";
    cout << left << setw(__PRINT_TABLE_WIDTH) << "Nested Table";
    cout << endl;

    vector<SymTable *> nested_tables;

    list<Symbol>::iterator it = (this->symbols).begin();
    for (; it != (this->symbols).end(); it++)
    {
        cout << left << setw(__PRINT_TABLE_WIDTH * 1.5) << it->name;
        // cout.flush();
        cout << left << setw(__PRINT_TABLE_WIDTH * 2) << it->type->toString();
        // cout.flush();
        cout << left << setw(__PRINT_TABLE_WIDTH) << it->init_val;
        // cout.flush();
        cout << left << setw(__PRINT_TABLE_WIDTH) << it->size;
        // cout.flush();
        cout << left << setw(__PRINT_TABLE_WIDTH) << it->offset;
        // cout.flush();
        cout << left << setw(__PRINT_TABLE_WIDTH) << (it->nestedST == NULL ? "NULL" : it->nestedST->name);
        cout << endl;

        // nested tables stored to print them later on, recursively
        if (it->nestedST != NULL)
            nested_tables.push_back(it->nestedST);
    }

    // gap before printing nested tables
    for (int i = 0; i < (__PRINT_TABLE_WIDTH * 7.5); i++)
        cout << "-";
    cout << endl;
    cout << endl;

    // print nested tables
    vector<SymTable *>::iterator it2 = nested_tables.begin();
    for (; it2 != nested_tables.end(); it2++)
    {
        (*it2)->print();
    }
}

// Symbol class methods

Symbol::Symbol(string name_str, TYPE type_val, string init_str) : name(name_str), type(new SymType(type_val)), init_val(init_str)
{
    // Initialize other members
    nestedST = nullptr;
    offset = 0;

    // Calculate size based on type
    size = type->computeSize();
}

Symbol *Symbol::update(SymType *new_type)
{
    // Update symbol type and recompute size
    // Store new type information
    Symbol *current = this;
    current->type = new_type;

    // Update memory requirements
    int computed_size = current->type->computeSize();
    current->size = computed_size;

    return this;
}

Symbol *Symbol::convert(TYPE return_type)
{
    // convert type to given type IF POSSIBLE, else return same symbol

    string op = "=";
    string suffix = this->name + ")";

    switch (this->type->type)
    {
    case INT:
        // handle integer conversions
        switch (return_type)
        {
        case FLOAT:
        {
            Symbol *temp = gentemp(return_type);
            emit(op, temp->name, "int2float(" + suffix, "");
            return temp;
        }
        case CHAR:
        {
            Symbol *temp = gentemp(return_type);
            emit(op, temp->name, "int2char(" + suffix, "");
            return temp;
        }
        default:
            return this;
        }

    case FLOAT:
        // handle float conversions
        switch (return_type)
        {
        case INT:
        {
            Symbol *temp = gentemp(return_type);
            emit(op, temp->name, "float2int(" + suffix, "");
            return temp;
        }
        case CHAR:
        {
            Symbol *temp = gentemp(return_type);
            emit(op, temp->name, "float2char(" + suffix, "");
            return temp;
        }
        default:
            return this;
        }

    case CHAR:
        // handle char conversions
        switch (return_type)
        {
        case INT:
        {
            Symbol *temp = gentemp(return_type);
            emit(op, temp->name, "char2int(" + suffix, "");
            return temp;
        }
        case FLOAT:
        {
            Symbol *temp = gentemp(return_type);
            emit(op, temp->name, "char2float(" + suffix, "");
            return temp;
        }
        default:
            return this;
        }
    }

    // no conversion possible, return original symbol
    return this;
}

// Quad class methods

Quad::Quad(string res_, string arg1_, string op_, string arg2_) : op(op_), arg1(arg1_), arg2(arg2_), res(res_) {}
Quad::Quad(string res_, int arg1_, string op_, string arg2_) : op(op_), arg1(to_string(arg1_)), arg2(arg2_), res(res_) {}

// print the quad
void Quad::print()
{

    string print_str = "";

    // Binary operations (res = arg1 op arg2)
    if (op == "+" || op == "-" || op == "*" || op == "/" || op == "%" ||
        op == "|" || op == "^" || op == "&" || op == "<<" || op == ">>")
    {
        print_str = res + " = " + arg1 + " " + op + " " + arg2;
    }
    // ifFalse
    else if (op == "ff")
    {
        // cout << "ifFalse " << arg1 << " goto " << res << endl;
        print_str = "ifFalse " + arg1 + " goto " + res;
    }
    // Assignment (res = arg1)
    else if (op == "=")
    {
        print_str = res + " = " + arg1;
    }
    // Address of operator (res = &arg1)
    else if (op == "=&")
    {
        print_str = res + " = &" + arg1;
    }
    // Pointer dereference (res = *arg1)
    else if (op == "=*")
    {
        print_str = res + " = *" + arg1;
    }
    // Unary minus (res = -arg1)
    else if (op == "=-")
    {
        print_str = res + " = -" + arg1;
    }
    // Logical not (res = !arg1)
    else if (op == "!")
    {
        print_str = res + " = !" + arg1;
    }
    // Bitwise not (res = ~arg1)
    else if (op == "~")
    {
        print_str = res + " = ~" + arg1;
    }
    // Conditional jumps (if arg1 op arg2 goto res)
    else if (op == "==" || op == "!=" || op == "<=" || op == ">=" ||
             op == "<" || op == ">")
    {
        print_str = "if " + arg1 + " " + op + " " + arg2 + " goto " + res;
    }
    // Pointer assignment (*res = arg1)
    else if (op == "*=")
    {
        print_str = "*" + res + " = " + arg1;
    }
    // Array access (res = arg1[arg2])
    else if (op == "=[]")
    {
        print_str = res + " = " + arg1 + "[" + arg2 + "]";
    }
    // Array assignment (res[arg1] = arg2)
    else if (op == "[]=")
    {
        print_str = res + "[" + arg1 + "] = " + arg2;
    }
    // Unconditional jump (goto res)
    else if (op == "goto")
    {
        print_str = "goto " + res;
    }
    // Function return (return res)
    else if (op == "return")
    {
        print_str = "return " + res;
    }
    // Function parameter (param res)
    else if (op == "param")
    {
        print_str = "param " + res;
    }
    // Function call (res = call arg1, arg2)
    else if (op == "call")
    {
        print_str = res + " = call " + arg1 + ", " + arg2;
    }
    // Label (res:)
    else if (op == "label")
    {
        print_str = res + ":";
    }

    cout << print_str << endl;
}

// Expression class methods

void Expression::conv2Int()
{
    if (type == Expression::BOOLEAN)
    {
        // Create new temporary integer variable
        symbol = gentemp(INT);

        // Handle true case
        list<int> trueInstr = truelist;
        backpatch(trueInstr, nextinstr());
        emit("=", symbol->name, "true");

        // Skip over false case
        int skipInstr = nextinstr() + 1;
        emit("goto", to_string(skipInstr));

        // Handle false case
        list<int> falseInstr = falselist;
        backpatch(falseInstr, nextinstr());
        emit("=", symbol->name, "false");
    }
}

void Expression::conv2Bool()
{
    if (type == Expression::NONBOOLEAN)
    {
        // To handle such cases, emit an ifFalse statement
        falselist = makelist(nextinstr());
        emit("ff", "", symbol->name);

        // Update expression type to boolean
        type = Expression::BOOLEAN;
    }
}

// global functions

void emit(string op, string res, string arg1, string arg2)
{
    qArr.push_back(new Quad(res, arg1, op, arg2));
}

void emit(string op, string res, int arg1, string arg2)
{
    qArr.push_back(new Quad(res, to_string(arg1), op, arg2));
}

list<int> makelist(int i)
{
    return list<int>(1, i);
}

list<int> merge(list<int> l1, list<int> l2)
{
    l1.merge(l2);
    return l1;
}

void backpatch(list<int> li, int addr)
{
    list<int>::iterator it = li.begin();
    for (; it != li.end(); it++)
    {
        qArr[*it - 1]->res = to_string(addr);
    }
}

// Performs type checking and conversion if possible
bool typecheck(Symbol *&a, Symbol *&b)
{

    // Handle same type
    // First check if types match directly
    if (typecheck(a->type, b->type))
    {
        return true;
    }

    // Check type conversion possibilities
    TYPE target_type;
    if (a->type->type == FLOAT || b->type->type == FLOAT)
    {
        target_type = FLOAT;
    }
    else if (a->type->type == INT || b->type->type == INT)
    {
        target_type = INT;
    }
    else
    {
        return false; // No valid conversion possible
    }

    // Convert both symbols to target type
    a = a->convert(target_type);
    b = b->convert(target_type);
    return true;
}

bool typecheck(SymType *st1, SymType *st2)
{
    // recursively checks base type
    if (st1 == NULL && st2 == NULL)
        return true;
    else if (st1 == NULL || st2 == NULL || st1->type != st2->type)
        return false;
    else
        return typecheck(st1->arr_type, st2->arr_type);
}

// other functions

int nextinstr()
{
    int temp = qArr.size();
    return temp + 1;
}

Symbol *gentemp(TYPE type, string val)
{
    string name = "t" + to_string(currentST->count);
    currentST->count += 1;
    Symbol *s = new Symbol(name, type, val);
    currentST->symbols.push_back(*s);
    // return s;
    return &(currentST->symbols).back();
}

void changeTable(SymTable *ST) { currentST = ST; }

void printQuadArray()
{
    cout << "Three Address Codes:" << endl;
    int i = 0;
    while (i < qArr.size())
    {
        cout << i + 1 << ": ";
        qArr[i]->print();
        i++;
    }
}

int main()
{

    block_count = 0; // Set block count to 0

    globalST = new SymTable("global"); // Set the global symbol table
    currentST = globalST;              // Set the current symbol table to the global one

    try
    {
        yyparse();
        globalST->update(); // Update offsets for all symbol tables
        globalST->print();  // Print the global symbol table (including nested ones)

        printQuadArray(); // Print the three-address code (TACs)
    }
    catch (string &e)
    {
        cout << e << endl;
    }

    return 0;
}

void yyerror(const char *s)
{
    string str = "ERROR [Line " + to_string(yylineno) + "] : " + s + ", unable to parse : " + yytext;
    throw str;
}