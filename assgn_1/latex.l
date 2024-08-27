%{
#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#define ENVIRONMENT_BEGIN 1
#define ENVIRONMENT_END 2
#define COMMAND 3
#define INLINE_MATH 4
#define DISPLAY_MATH 5
%}

%%
\\% return (COMMAND); // Included earlier to escape comment
%.* ;

\\begin[ \t]*\{[a-zA-Z_]+\} return (ENVIRONMENT_BEGIN);
\\end[ \t]*\{[a-zA-Z_]+\} return (ENVIRONMENT_END);

\\[\[\]] return (DISPLAY_MATH); // Included earlier to avoid detection as command

~ return (COMMAND);
\\[a-zA-Z]+ return (COMMAND);
\\. return (COMMAND);

\$\$ return (DISPLAY_MATH);
\$ return (INLINE_MATH);

[ \t\n] ; // To avoid extra printing of newlines
. ; // ignore other words
%%

int yywrap(void) {
    return 1;
}