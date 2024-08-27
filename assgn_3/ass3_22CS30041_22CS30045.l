%{
#define KEYWORD 1
#define IDENTIFIER 2
#define INTEGER_CONSTANT 3
#define FLOATING_CONSTANT 4
#define CHAR_CONSTANT 5
#define STRING_LITERAL 6
#define PUNCTUATOR 7
#define COMMENT 8
#define MULTI_LINE_COMMENT 9
#define INVALID 100
%}


keywords "auto"|"break"|"case"|"char"|"const"|"continue"|"default"|"do"|"double"|"else"|"enum"|"extern"|"float"|"for"|"goto"|"if"|"inline"|"int"|"long"|"register"|"restrict"|"return"|"short"|"signed"|"sizeof"|"static"|"struct"|"switch"|"typedef"|"union"|"unsigned"|"void"|"volatile"|"while"|"_Bool"|"_Complex"|"_Imaginary"
digit [0-9]
non_digit [_A-Za-z]

identifier {non_digit}({non_digit}|{digit})*
sign [+-]
escape_seq \\['"?\\abfnrtv]
c_char [^'\\\n]|{escape_seq}
char_constant \'{c_char}\'

digit_sequence {digit}+

integer_constant {digit_sequence}
exponent_part [eE]{sign}?{digit_sequence}
fractional_constant {digit_sequence}\.|({digit_sequence}?\.{digit_sequence})
floating_contant ({fractional_constant}{exponent_part}?)|({digit_sequence}{exponent_part})

s_char [^"\\\n]|{escape_seq}
s_char_seq {s_char}+
string_literal \"{s_char_seq}?\"

punctuators "["|"]"|"("|")"|"{"|"}"|"."|"->"|"++"|"--"|"&"|"*"|"+"|"-"|"~"|"!"|"/"|"%"|"<<"|">>"|"<"|">"|"<="|">="|"=="|"!="|"^"|"|"|"&&"|"||"|"?"|":"|";"|"..."|"="|"*="|"/="|"%="|"+="|"-="|"<<="|">>="|"&="|"^="|"|="|","|"#"

multi_line_comment_start "/*"
multi_line_comment_end "*/"
multi_line_comment_body [^*]|[*][^/]
multi_line_comment {multi_line_comment_start}{multi_line_comment_body}*{multi_line_comment_end}
single_line_comment \/\/[^\n]* 

ws [ \t\n]

%%
{multi_line_comment} { return MULTI_LINE_COMMENT; }
{string_literal} { return STRING_LITERAL; }
{char_constant} { return CHAR_CONSTANT; }
{single_line_comment} { return COMMENT; }
{keywords} { return KEYWORD; }
{identifier} { return IDENTIFIER; }
{integer_constant} { return INTEGER_CONSTANT; }
{floating_contant} { return FLOATING_CONSTANT; }
{punctuators} { return PUNCTUATOR; }
{ws} {} // ignore whitespace
. { return INVALID; }
%%

int yywrap() {
    return 1;
}