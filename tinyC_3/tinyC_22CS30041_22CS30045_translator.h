#ifndef _TRANSLATOR_H
#define _TRANSLATOR_H

#include <iostream>
#include <string>
#include <vector>
#include <list>
#include <string.h>

extern int yyparse();

using namespace std;

// defining size of data types (can be changed as it is machine-dependent)
#define __SIZE_VOID__ 0
#define __SIZE_CHAR__ 1
#define __SIZE_INT__ 4
#define __SIZE_FLOAT__ 8
#define __SIZE_POINTER__ 4
#define __SIZE_FUNCTION__ 0
#define __PRINT_TABLE_WIDTH 20

// Classes
class SymType;    // Used for creating a type for a symbol
class SymTable;   // Used for creating a symbol table
class Symbol;     // Used for creating a symbol table entry
class Quad;       // Used for creating an entry in quad array
class Expression; // Used for creating an expression attributes (used while parsing)
class Array;      // Used for creating an array attributes (used while parsing)
class Statement;  // Used for creating a statement attributes (used while parsing)

enum TYPE
{
    VOID,
    CHAR,
    INT,
    FLOAT,
    POINTER,
    FUNCTION,
    ARRAY,
    BLOCK
};

class SymType
{
public:
    TYPE type;         // Type of the symbol
    int width;         // Width of the symbol -> for arrays, 1 if not array
    SymType *arr_type; // For arrays, NULL if not array

    SymType(TYPE type_, SymType *arr_type_ = NULL, int width_ = 1); // constructor

    int computeSize(); // To compute size of the symbol type

    string toString(); // Returns the string representation of the type
};

class SymTable
{
public:
    string name;          // Name of the symbol table (e.g. "main_0", "func_1" etc.)
    list<Symbol> symbols; // List containing all symbols/variables in this symbol table
    SymTable *parent;     // Points to the parent/enclosing scope's symbol table (NULL for global scope)
    int count;            // Tracks total number of symbols in this table

    SymTable(string = "NULL", SymTable * = NULL); // Constructor to create new symbol table with given name and parent

    Symbol *lookup(string); // Looks up symbol by name in current and parent tables, creates new entry if not found

    void print(); // Prints formatted table showing all symbols with their properties

    void update(); // Updates offsets of symbols in the table
};

class Symbol
{
public:
    string name;        // Name of the symbol/variable
    int size;           // Size of the symbol in bytes
    int offset;         // Memory offset from base pointer
    SymType *type;      // Data type information of the symbol
    SymTable *nestedST; // Points to nested symbol table for functions/blocks
    string init_val;    // Initial value if symbol is initialized

    Symbol(string, TYPE = INT, string = "-"); // Constructor taking name, type and initial value

    Symbol *update(SymType *); // Updates symbol type and related attributes

    Symbol *convert(TYPE); // Performs type conversion of symbol to specified type
};

class Quad
{
public:
    // res = arg1 op arg2
    string op;      // Operator or instruction type
    string arg1;    // First operand 
    string arg2;    // Second operand (optional)
    string res;     // Result or target

    // Constructors for different operand types
    Quad(string op_, string arg1_, string arg2_ = "", string res_ = "");  // For string operands
    Quad(string op_, int val_, string arg2_ = "", string res_ = "");      // For integer operands

    void print();   // Print the quad in readable format
};

class QuadArray
{
public:
    vector<Quad *> array; // vector of quads
};

class Expression
{
public:
    Symbol *symbol;      // Pointer to symbol table entry for this expression
    enum typeEnum
    {
        NONBOOLEAN,     // Expression evaluates to a non-boolean value (e.g. integer)
        BOOLEAN         // Expression evaluates to a boolean value
    } type;             // Tracks whether expression is boolean or non-boolean
    list<int> truelist; // List of instructions that branch when expression is true
    list<int> falselist;// List of instructions that branch when expression is false  
    list<int> nextlist; // List of instructions that need address of next instruction

    void conv2Int();    // Converts a boolean expression to equivalent integer value (0/1)

    void conv2Bool();   // Converts an integer expression to equivalent boolean condition
};

class Array
{
public:
    Symbol *loc;          // Base address used for array offset calculations
    enum typeEnum
    {
        NEITHER,         // Not an array or pointer type
        POINTER,         // Pointer type (single memory location)
        ARRAY           // Array type (contiguous memory block)
    } type;              // Tracks whether this represents an array, pointer or neither
    Symbol *symbol;      // Symbol table entry associated with this array
    SymType *subarr_type; // Type information for array elements (used for nested arrays)
};

class Statement
{
public:
    list<int> nextlist; // Nextlist for the statement
};

// Global variables
extern vector<Quad *> qArr;    // Vector storing all generated quadruples for intermediate code
extern SymTable *currentST;    // Pointer to symbol table currently in scope
extern SymTable *globalST;     // Root symbol table containing program-wide symbols
extern int block_count;        // Counter for generating unique nested block identifiers
extern Symbol *current_symbol; // Symbol being processed during scope transitions
extern TYPE current_type;      // Active data type for type checking and casting
extern bool isDeclaration;    // Indicates if current symbol is being declared

// Emit functions to generate quadruple instructions
// Overloaded versions for different argument types
void emit(string, string, string = "", string = "");  // For string arguments
void emit(string, string, int, string = "");          // For integer arguments

// Core backpatching and list management functions
list<int> makelist(int);                // Creates new list with single instruction number
list<int> merge(list<int>, list<int>);  // Concatenates two instruction lists
void backpatch(list<int>, int);         // Fills target addresses in instruction list

// Type checking functions
bool typecheck(Symbol *&, Symbol *&);    // Checks type compatibility between symbols
bool typecheck(SymType *, SymType *);    // Checks type compatibility between type objects

// Utility functions for translation
int nextinstr();                         // Gets index for next instruction
Symbol *gentemp(TYPE, string = "-");     // Creates new temporary with given type
void changeTable(SymTable *);            // Switches active symbol table
void printQuadArray();                   // Displays generated intermediate code

#endif