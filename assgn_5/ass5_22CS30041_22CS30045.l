%{
    #include "y.tab.h"
%}

AUTO		            "auto"
BREAK		            "break"
CASE		            "case"
CHAR		            "char"
CONST		            "const"
CONTINUE		        "continue"
DEFAULT		            "default"
DO		                "do"
DOUBLE		            "double"
ELSE		            "else"
ENUM		            "enum"
EXTERN		            "extern"
FLOAT		            "float"
FOR		                "for"
GOTO		            "goto"
IF		                "if"
INLINE		            "inline"
INT		                "int"
LONG		            "long"
REGISTER		        "register"
RESTRICT		        "restrict"
RETURN		            "return"
SHORT		            "short"
SIGNED		            "signed"
SIZEOF		            "sizeof"
STATIC		            "static"
STRUCT		            "struct"
SWITCH		            "switch"
TYPEDEF		            "typedef"
UNION		            "union"
UNSIGNED		        "unsigned"
VOID		            "void"
VOLATILE		        "volatile"
WHILE		            "while"
BOOL_		            "_Bool"
COMPLEX_		        "_Complex"
IMAGINARY_		        "_Imaginary"

LPARENSQ                "["
RPARENSQ                "]"
LPAREN                  "("
RPAREN                  ")"
LBRACE                  "{"
RBRACE                  "}"
DOT                     "."
ARROW                   "->"
INCREMENT               "++"
DECREMENT               "--"
AMPERSAND               "&"
ASTERISK                "*"
PLUS                    "+"
MINUS                   "-"
TILDE                   "~"
NOT             "!"
DIV                   "/"
PERCENT                 "%"
LSHIFT                  "<<"
RSHIFT                  ">>"
LESS                    "<"
GREATER                 ">"
LESSEQ                  "<="
GREATEREQ               ">="
EQUAL                   "=="
NOTEQUAL                "!="
XOR                     "^"
OR                      "|"
LOG_AND                 "&&"
LOG_OR                  "||"
QUESTION                "?"
COLON                   ":"
SEMICOLON               ";"
ELLIPSIS                "..."
ASSIGN                  "="
MULASSIGN               "*="
DIVASSIGN               "/="
MODASSIGN               "%="
ADDASSIGN               "+="
SUBASSIGN               "-="
LSHIFTASSIGN            "<<="
RSHIFTASSIGN            ">>="
ANDASSIGN               "&="
XORASSIGN               "^="
ORASSIGN                "|="
COMMA                   ","
HASH                    "#"

DIGIT                   [0-9]
NON_DIGIT               [_A-Za-z]
DIGIT_SEQUENCE          {DIGIT}+
EXPONENT_PART           [eE]{SIGN}?{DIGIT_SEQUENCE}
ALPHA_NUM               {NON_DIGIT}|{DIGIT}

IDENTIFIER              {NON_DIGIT}({ALPHA_NUM})*
SIGN                    [+-]
ESCAPE_SEQ              \\['"?\\abfnrtv]
C_CHAR                  [^'\\\n]|{ESCAPE_SEQ}
CHAR_CONSTANT           \'{C_CHAR}\'

INTEGER_CONSTANT        {DIGIT_SEQUENCE}
FRACTIONAL_CONSTANT     {DIGIT_SEQUENCE}\.|({DIGIT_SEQUENCE}?\.{DIGIT_SEQUENCE})
FLOATING_CONSTANT       ({FRACTIONAL_CONSTANT}{EXPONENT_PART}?)|({DIGIT_SEQUENCE}{EXPONENT_PART})

S_CHAR                  [^"\\\n]|{ESCAPE_SEQ}
S_CHAR_SEQ              {S_CHAR}+
STRING_LITERAL           \"{S_CHAR_SEQ}?\"

MULTI_LINE_COMMENT_START "/*"
MULTI_LINE_COMMENT_END   "*/"
MULTI_LINE_COMMENT_BODY  [^*]|[*][^/]
MULTI_LINE_COMMENT       {MULTI_LINE_COMMENT_START}{MULTI_LINE_COMMENT_BODY}*{MULTI_LINE_COMMENT_END}
SINGLE_LINE_COMMENT     \/\/[^\n]*
COMMENT                 {SINGLE_LINE_COMMENT}|{MULTI_LINE_COMMENT}

NEWLINE                 \n
WS                      [ \t]

%%

{COMMENT}               { }

{AUTO}		            { return AUTO; }
{BREAK}		            { return BREAK; }
{CASE}		            { return CASE; }
{CHAR}		            { return CHAR; }
{CONST}		            { return CONST; }
{CONTINUE}		        { return CONTINUE; }
{DEFAULT}		        { return DEFAULT; }
{DO}		            { return DO; }
{DOUBLE}		        { return DOUBLE; }
{ELSE}		            { return ELSE; }
{ENUM}		            { return ENUM; }
{EXTERN}		        { return EXTERN; }
{FLOAT}		            { return FLOAT; }
{FOR}		            { return FOR; }
{GOTO}		            { return GOTO; }
{IF}		            { return IF; }
{INLINE}		        { return INLINE; }
{INT}		            { return INT; }
{LONG}		            { return LONG; }
{REGISTER}		        { return REGISTER; }
{RESTRICT}		        { return RESTRICT; }
{RETURN}		        { return RETURN; }
{SHORT}		            { return SHORT; }
{SIGNED}		        { return SIGNED; }
{SIZEOF}		        { return SIZEOF; }
{STATIC}		        { return STATIC; }
{STRUCT}		        { return STRUCT; }
{SWITCH}		        { return SWITCH; }
{TYPEDEF}		        { return TYPEDEF; }
{UNION}		            { return UNION; }
{UNSIGNED}		        { return UNSIGNED; }
{VOID}		            { return VOID; }
{VOLATILE}		        { return VOLATILE; }
{WHILE}		            { return WHILE; }
{BOOL_}		            { return BOOL_; }
{COMPLEX_}		        { return COMPLEX_; }
{IMAGINARY_}		    { return IMAGINARY_; }

{IDENTIFIER}            { return IDENTIFIER; }  
{FLOATING_CONSTANT}     { return FLOATING_CONSTANT; }
{INTEGER_CONSTANT}      { return INTEGER_CONSTANT; }
{CHAR_CONSTANT}         { return CHAR_CONSTANT; }
{STRING_LITERAL}        { return STRING_LITERAL; }

{LPARENSQ}              { return LPARENSQ; }
{RPARENSQ}              { return RPARENSQ; }
{LPAREN}                { return LPAREN; }
{RPAREN}                { return RPAREN; }
{LBRACE}                { return LBRACE; }
{RBRACE}                { return RBRACE; }
{DOT}                   { return DOT; }
{ARROW}                 { return ARROW; }
{INCREMENT}             { return INCREMENT; }
{DECREMENT}             { return DECREMENT; }
{AMPERSAND}             { return AMPERSAND; }
{ASTERISK}              { return ASTERISK; }
{PLUS}                  { return PLUS; }
{MINUS}                 { return MINUS; }
{TILDE}                 { return TILDE; }
{NOT}                   { return NOT; }
{DIV}                   { return DIV; }
{PERCENT}               { return PERCENT; }
{LSHIFT}                { return LSHIFT; }
{RSHIFT}                { return RSHIFT; }
{LESS}                  { return LESS; }
{GREATER}               { return GREATER; }
{LESSEQ}                { return LESSEQ; }
{GREATEREQ}             { return GREATEREQ; }
{EQUAL}                 { return EQUAL; }
{NOTEQUAL}              { return NOTEQUAL; }
{XOR}                   { return XOR; }
{OR}                    { return OR; }
{LOG_AND}               { return LOG_AND; }
{LOG_OR}                { return LOG_OR; }
{QUESTION}              { return QUESTION; }
{COLON}                 { return COLON; }
{SEMICOLON}             { return SEMICOLON; }
{ELLIPSIS}              { return ELLIPSIS; }
{ASSIGN}                { return ASSIGN; }
{MULASSIGN}             { return MULASSIGN; }
{DIVASSIGN}             { return DIVASSIGN; }
{MODASSIGN}             { return MODASSIGN; }
{ADDASSIGN}             { return ADDASSIGN; }
{SUBASSIGN}             { return SUBASSIGN; }
{LSHIFTASSIGN}          { return LSHIFTASSIGN; }
{RSHIFTASSIGN}          { return RSHIFTASSIGN; }
{ANDASSIGN}             { return ANDASSIGN; }
{XORASSIGN}             { return XORASSIGN; }
{ORASSIGN}              { return ORASSIGN; }
{COMMA}                 { return COMMA; }
{HASH}                  { return HASH; }

{WS}                    { }
{NEWLINE}               { lineno++; }

.                       { }

%%

int yywrap() {
    return 1;
}