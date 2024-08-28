%{
    #include "y.tab.h"
    #include <stdio.h>
    #include <string.h>
%}
%option noyywrap

digit           [0-9]

letter          [a-z]

number          0|[1-9]{digit}*|-[1-9]{digit}*

id              {letter}({letter}|{digit}|-)*

paren           "("|")"

%%

"print-num"		{return PRINT_NUM;}
"print-bool"	{return PRINT_BOOL;}

"t"             {yylval.boolean = 1; return BOOL;}
"f"             {yylval.boolean = 0; return BOOL;}

"mod"           {return MOD;}
"and"           {return AND;}
"or"            {return OR;}
"not"           {return NOT;}
"if"            {return IF;}
"fun"           {return FUNC;}
"define"        {return DEF;}

{number}        {yylval.ival = atoi(yytext); return NUMBER;}

{id}            {yylval.word = strdup(yytext); return WORD;}

"+"             {return ADD;}
"-"             {return SUB;}
"*"             {return MUL;}
"/"             {return DIV;}
">"             {return GREATER;}
"<"             {return SMALLER;}
"="             {return EQUAL;}
{paren}         {return yytext[0];}

.|\n            {; /* do nothing */}

%%

