%{
#include "parser.tab.h"
#include <string.h>
#include <stdlib.h>
%}

%option noyywrap
%option yylineno

%%

"if"        { return IF; }
"else"      { return ELSE; }
"while"     { return WHILE; }
"print"     { return PRINT; }

[0-9]+                 { yylval.str = strdup(yytext); return INT_VAL; }
[0-9]+\.[0-9]+         { yylval.str = strdup(yytext); return FLOAT_VAL; }
\"[^\"\n]*\"           { yylval.str = strdup(yytext); return STRING_VAL; }
\'[^\'\n]\'            { yylval.str = strdup(yytext); return CHAR_VAL; }
[a-zA-Z_][a-zA-Z0-9_]* { yylval.str = strdup(yytext); return ID; }

"=="        { yylval.str = strdup(yytext); return EQ; }
"<"         { yylval.str = strdup(yytext); return LT; }
">"         { yylval.str = strdup(yytext); return GT; }

"+"         { return '+'; }
"-"         { return '-'; }
"*"         { return '*'; }
"/"         { return '/'; }
"="         { return '='; }
"("         { return '('; }
")"         { return ')'; }
"{"         { return '{'; }
"}"         { return '}'; }

\n          { return NEWLINE; }
[ \t\r]+    { /* Ignore whitespace */ }
.           { printf("Lexical Error at line %d: Unknown character '%s'\n", yylineno, yytext); }

%%