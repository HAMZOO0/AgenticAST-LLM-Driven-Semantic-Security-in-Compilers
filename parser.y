%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

extern FILE *yyin;
extern int yylineno;
int yylex();
void yyerror(const char *s);

char* vars[100];
int var_count = 0;

int is_declared(char* name) {
    for(int i = 0; i < var_count; i++) {
        if(strcmp(vars[i], name) == 0) return 1;
    }
    return 0;
}

void declare(char* name) {
    vars[var_count] = strdup(name);
    var_count++;
}

char* mks(const char* s1, const char* s2, const char* s3) {
    char* res = (char*)malloc(strlen(s1) + strlen(s2) + strlen(s3) + 1);
    sprintf(res, "%s%s%s", s1, s2, s3);
    return res;
}
%}

%union {
    char* str;
}

%token <str> ID INT_VAL FLOAT_VAL STRING_VAL CHAR_VAL
%token <str> EQ LT GT
%token IF ELSE WHILE PRINT NEWLINE

%type <str> program statements statement assignment print_stmt if_stmt while_stmt condition expr

%left '+' '-'
%left '*' '/'

%%

program:
    statements {
        // --- AST GENERATION ---
        FILE* ast_f = fopen("ast.json", "w");
        if (ast_f) {
            fprintf(ast_f, "{\n  \"type\": \"Program\",\n  \"body\": [\n%s\n  ]\n}", $1);
            fflush(ast_f);
            fclose(ast_f);
        }

        // --- CODE GENERATION ---
        FILE* out_f = fopen("output.cpp", "w");
        if (out_f) {
            fprintf(out_f, "#include <iostream>\n#include <string>\nusing namespace std;\n\nint main() {\n%s\nreturn 0;\n}", $1);
            fclose(out_f);
        }
    }
    ;

statements:
    statement { $$ = $1; }
    | statements statement { $$ = mks($1, $2, ""); }
    ;

statement:
    assignment opt_newline   { $$ = $1; }
    | print_stmt opt_newline { $$ = $1; }
    | if_stmt opt_newline    { $$ = $1; }
    | while_stmt opt_newline { $$ = $1; }
    | NEWLINE                { $$ = strdup(""); }
    ;

opt_newline:
    NEWLINE | /* empty */ ;

assignment:
    ID '=' expr {
        char* prefix = is_declared($1) ? "    " : "    auto ";
        if (!is_declared($1)) declare($1);
        char* t1 = mks(prefix, $1, " = ");
        $$ = mks(t1, $3, ";\n");
        free(t1);
    }
    ;

print_stmt:
    PRINT expr { $$ = mks("    cout << ", $2, " << endl;\n"); }
    ;

if_stmt:
    IF '(' condition ')' '{' statements '}' {
        char* p1 = mks("    if (", $3, ") {\n");
        char* p2 = mks(p1, $6, "    }\n");
        $$ = p2;
    }
    ;

while_stmt:
    WHILE '(' condition ')' '{' statements '}' {
        char* p1 = mks("    while (", $3, ") {\n");
        char* p2 = mks(p1, $6, "    }\n");
        $$ = p2;
    }
    ;

condition:
    expr EQ expr   { $$ = mks($1, " == ", $3); }
    | expr LT expr { $$ = mks($1, " < ", $3); }
    | expr GT expr { $$ = mks($1, " > ", $3); }
    | expr         { $$ = $1; }
    ;

expr:
    INT_VAL | FLOAT_VAL | STRING_VAL | CHAR_VAL | ID { $$ = $1; }
    | expr '+' expr { $$ = mks($1, " + ", $3); }
    | expr '-' expr { $$ = mks($1, " - ", $3); }
    | expr '*' expr { $$ = mks($1, " * ", $3); }
    | expr '/' expr { $$ = mks($1, " / ", $3); }
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Error at line %d: %s\n", yylineno, s);
}

int main(int argc, char **argv) {
    if (argc < 2) return 1;
    yyin = fopen(argv[1], "r");
    if (yyparse() == 0) {
        printf("\n[1] Syntax Check: Passed.\n");
        printf("[2] AST Generated: ast.json created.\n");
        
        // Critical for WSL/Mounted drives: Force OS to sync file to disk
        system("sync");
        usleep(500000); // 0.5s delay to ensure visibility

        printf("[3] AI Security Agent: Analyzing logic via Groq...\n");
        // Use python3 if environment is sourced
        int security_check = system("python3 security_bridge.py");

        if (security_check == 0) {
            printf("\n[4] Security Check: Passed. Proceeding to execution...\n");
            system("g++ output.cpp -o app");
            printf("\n--- Final Program Output ---\n");
            system("./app");
            printf("\n---------------------------\n");
        } else {
            printf("\n[!] SECURITY ALARM: Execution blocked by AI Agent.\n");
        }
    }
    if (yyin) fclose(yyin);
    return 0;
}