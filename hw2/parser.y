%{
    #include <stdio.h>
    #include <string.h>
    #include <stdlib.h>
    #include <stdarg.h>

    char* auto_sprintf(char *fmt, ...) {
        va_list args, args2;
        va_start(args, fmt);
        va_copy(args2, args);
        int len = vsnprintf(NULL, 0, fmt, args);
        char *dest = (char*)malloc(len + 1);
        vsprintf(dest, fmt, args2);
        va_end(args);
        va_end(args2);
        return dest;
    }
%}
%union {
    int int_val;
    double float_val;
    char *str;
}
%token<int_val> INT_NUM
%token<float_val> FLOAT_NUM
%token<str> CHARACTER STRING IDENTIFIER
%token CONST SIGNED UNSIGNED FLOAT DOUBLE INT LONG SHORT VOID CHAR
%token FOR DO WHILE BREAK CONTINUE IF ELSE RETURN SWITCH CASE DEFAULT NULL_
%type<str> expr literal variable params
%type<str> scalar_decl data_type idents ident init_ident unconst_type unsign_type
%type<str> array_decl arrays array arr_var arr_content seperated
%type<str> func_decl_params
%type<str> statement compound_statement multiline_statement in_compound_statement
%type<str> if_statement switch_statement switch_clauses switch_clause while_statement for_statement empty_or_expr return_statement

%nonassoc ','
%right '='
%left LOGICAL_OR
%left LOGICAL_AND
%left '|'
%left '^'
%left '&'
%left EQ NEQ
%left '<' '>' LEQ GEQ
%left LEFT_SHIFT RIGHT_SHIFT
%left '+' '-'
%left '*' '/' '%'
%right INC DEC
%right RTL
%right LTR
%nonassoc THEN
%nonassoc ELSE

%start Ss

%%
Ss: S | S Ss

S: statement { printf("%s", $1); }
| scalar_decl { printf("%s", $1); } 
| array_decl { printf("%s", $1); } 
| func_decl
| func_def

/* ******* expr ********* */
expr:
variable '(' params ')' {
    $$ = auto_sprintf("<expr><expr>%s</expr>(%s)</expr>", $1, $3);
}
| '(' expr ')' {
    $$ = auto_sprintf("<expr>(%s)</expr>", $2);
}
| expr '=' expr {
    $$ = auto_sprintf("<expr>%s=%s</expr>", $1, $3);
}
| expr LOGICAL_OR expr {
    $$ = auto_sprintf("<expr>%s||%s</expr>", $1, $3);
}
| expr LOGICAL_AND expr {
    $$ = auto_sprintf("<expr>%s&&%s</expr>", $1, $3);
}
| expr '|' expr {
    $$ = auto_sprintf("<expr>%s|%s</expr>", $1, $3);
}
| expr '^' expr {
    $$ = auto_sprintf("<expr>%s^%s</expr>", $1, $3);
}
| expr '&' expr {
    $$ = auto_sprintf("<expr>%s&%s</expr>", $1, $3);
}
| expr EQ expr {
    $$ = auto_sprintf("<expr>%s==%s</expr>", $1, $3);
}
| expr NEQ expr {
    $$ = auto_sprintf("<expr>%s!=%s</expr>", $1, $3);
}
| expr '<' expr {
    $$ = auto_sprintf("<expr>%s<%s</expr>", $1, $3);
}
| expr '>' expr {
    $$ = auto_sprintf("<expr>%s>%s</expr>", $1, $3);
}
| expr LEQ expr {
    $$ = auto_sprintf("<expr>%s<=%s</expr>", $1, $3);
}
| expr GEQ expr {
    $$ = auto_sprintf("<expr>%s>=%s</expr>", $1, $3);
}
| expr LEFT_SHIFT expr {
    $$ = auto_sprintf("<expr>%s<<%s</expr>", $1, $3);
}
| expr RIGHT_SHIFT expr {
    $$ = auto_sprintf("<expr>%s>>%s</expr>", $1, $3);
}
| expr '+' expr {
    $$ = auto_sprintf("<expr>%s+%s</expr>", $1, $3);
}
| expr '-' expr {
    $$ = auto_sprintf("<expr>%s-%s</expr>", $1, $3);
}
| expr '*' expr {
    $$ = auto_sprintf("<expr>%s*%s</expr>", $1, $3);
}
| expr '/' expr {
    $$ = auto_sprintf("<expr>%s/%s</expr>", $1, $3);
}
| expr '%' expr {
    $$ = auto_sprintf("<expr>%s%%%s</expr>", $1, $3);
}

| INC expr {
    $$ = auto_sprintf("<expr>++%s</expr>", $2);
}
| DEC expr {
    $$ = auto_sprintf("<expr>--%s</expr>", $2);
}
| '+' expr %prec RTL {
    $$ = auto_sprintf("<expr>+%s</expr>", $2);
}
| '-' expr %prec RTL {
    $$ = auto_sprintf("<expr>-%s</expr>", $2);
}
| '*' expr %prec RTL {
    $$ = auto_sprintf("<expr>*%s</expr>", $2);
}
| '&' expr %prec RTL {
    $$ = auto_sprintf("<expr>&%s</expr>", $2);
}
| '!' expr %prec RTL {
    $$ = auto_sprintf("<expr>!%s</expr>", $2);
}
| '~' expr %prec RTL {
    $$ = auto_sprintf("<expr>~%s</expr>", $2);
}
| '(' data_type ')' expr %prec RTL {
    $$ = auto_sprintf("<expr>(%s)%s</expr>", $2, $4);
}
| '(' data_type '*' ')' expr %prec RTL {
    $$ = auto_sprintf("<expr>(%s*)%s</expr>", $2, $5);
}


| expr INC %prec LTR {
    $$ = auto_sprintf("<expr>%s++</expr>", $1);
}
| expr DEC %prec LTR {
    $$ = auto_sprintf("<expr>%s--</expr>", $1);
}

| literal {
    $$ = auto_sprintf("<expr>%s</expr>", $1);
}
| variable {
    $$ = auto_sprintf("<expr>%s</expr>", $1);
}
| NULL_ {
    $$ = "<expr>0</expr>";
}

params: params ',' expr {
    $$ = auto_sprintf("%s,%s", $1, $3);
}
| expr { $$ = $1; }
| /* empty */ {
    $$ = "";
};

literal: INT_NUM { $$ = auto_sprintf("%d", $1); }
| FLOAT_NUM { $$ = auto_sprintf("%f", $1); }
| CHARACTER { 
    $$ = auto_sprintf("'%s'", $1);
}
| STRING { 
    $$ = auto_sprintf("\"%s\"", $1);
}

variable: IDENTIFIER { $$ = $1; }
| variable '[' expr ']' {
    $$ = auto_sprintf("%s[%s]", $1, $3);
}

/* ******************** */

/* **** scalar_decl *** */
scalar_decl: data_type idents ';' {
    $$ = auto_sprintf("<scalar_decl>%s%s;</scalar_decl>", $1, $2);
}

idents: init_ident { $$ = $1; }
| idents ',' init_ident { $$ = auto_sprintf("%s,%s", $1, $3); }

init_ident: ident { $$ = $1; }
| ident '=' expr { $$ = auto_sprintf("%s=%s", $1, $3); }

ident: IDENTIFIER { $$ = $1; }
| '*' IDENTIFIER { $$ = auto_sprintf("*%s", $2); }

data_type: CONST { $$ = "const"; }
| unconst_type { $$ = $1; }
| CONST unconst_type { $$ = auto_sprintf("const%s", $2); }

unconst_type: SIGNED { $$ = "signed"; }
| UNSIGNED { $$ = "unsigned"; }
| FLOAT { $$ = "float"; }
| DOUBLE { $$ = "double"; }
| VOID { $$ = "void"; }
| SIGNED unsign_type { $$ = auto_sprintf("signed%s", $2); }
| UNSIGNED unsign_type { $$ = auto_sprintf("unsigned%s", $2); }
| unsign_type { $$ = $1; }

unsign_type: LONG LONG { $$ = "longlong"; }
| LONG { $$ = "long"; }
| SHORT { $$ = "short"; }
| CHAR { $$ = "char"; }
| INT { $$ = "int"; }
| LONG LONG INT { $$ = "longlongint"; }
| LONG INT { $$ = "longint"; }
| SHORT INT { $$ = "shortint"; }
/* ******************** */

/* **** array_decl **** */
array_decl: data_type arrays ';' {
    $$ = auto_sprintf("<array_decl>%s%s;</array_decl>", $1, $2);
}

arrays:
array { $$ = $1; }
| arrays ',' array { $$ = auto_sprintf("%s,%s", $1, $3); }

array: 
arr_var { $$ = $1; }
| arr_var '=' arr_content { $$ = auto_sprintf("%s=%s", $1, $3); }

arr_var:
IDENTIFIER '[' expr ']'{ $$ = auto_sprintf("%s[%s]", $1, $3); }
| arr_var '[' expr ']' {
    $$ = auto_sprintf("%s[%s]", $1, $3);
}

arr_content: '{' seperated '}' { $$ = auto_sprintf("{%s}", $2); }

seperated: seperated ',' expr { $$ = auto_sprintf("%s,%s", $1, $3); }
| seperated ',' arr_content { $$ = auto_sprintf("%s,%s", $1, $3); }
| arr_content { $$ = $1; }
| expr { $$ = $1; }

/* ******************** */

/* ***** func_decl ****** */
func_decl: data_type ident '(' func_decl_params ')' ';' {
    printf("<func_decl>%s%s(%s);</func_decl>", $1, $2, $4);
}
func_decl_params:
/* empty */ { $$ = ""; }
| data_type ident {
    $$ = auto_sprintf("%s%s", $1, $2);
}
| func_decl_params ',' data_type ident {
    $$ = auto_sprintf("%s,%s%s", $1, $3, $4);
}

/* ******************** */

/* ***** func_def ****** */
func_def: data_type ident '(' func_decl_params ')' compound_statement {
    printf("<func_def>%s%s(%s)%s</func_def>", $1, $2, $4, $6);
}

compound_statement: '{' '}' { $$ = "{}"; }
| '{' multiline_statement '}' { $$ = auto_sprintf("{%s}", $2); }

multiline_statement: in_compound_statement { $$ = $1; }
| multiline_statement in_compound_statement { $$ = auto_sprintf("%s%s", $1, $2); }

in_compound_statement: statement { $$ = $1; } | scalar_decl { $$ = $1; } | array_decl { $$ = $1; }

/* ******************** */

/* **** statement ***** */
statement: expr ';' {$$ = auto_sprintf("<stmt>%s;</stmt>", $1); }
| if_statement { $$ = auto_sprintf("<stmt>%s</stmt>", $1); }
| switch_statement { $$ = auto_sprintf("<stmt>%s</stmt>", $1); }
| while_statement { $$ = auto_sprintf("<stmt>%s</stmt>", $1); }
| for_statement { $$ = auto_sprintf("<stmt>%s</stmt>", $1); }
| return_statement { $$ = auto_sprintf("<stmt>%s</stmt>", $1); }
| BREAK ';' { $$ = "<stmt>break;</stmt>"; }
| CONTINUE ';' { $$ = "<stmt>continue;</stmt>"; }
| compound_statement { $$ = auto_sprintf("<stmt>%s</stmt>", $1); }

if_statement:
IF '(' expr ')' compound_statement %prec THEN {
    $$ = auto_sprintf("if(%s)%s", $3, $5);
}
| IF '(' expr ')' compound_statement ELSE compound_statement {
    $$ = auto_sprintf("if(%s)%selse%s", $3, $5, $7);
}

switch_statement: SWITCH '(' expr ')' '{' switch_clauses '}' {
    $$ = auto_sprintf("switch(%s){%s}", $3, $6);
}

switch_clauses: switch_clause { $$ = $1; }
| switch_clause switch_clauses { $$ = auto_sprintf("%s%s", $1, $2); }

switch_clause:
CASE expr ':' multiline_statement {
    $$ = auto_sprintf("case%s:%s", $2, $4);
}
| CASE expr ':' {
    $$ = auto_sprintf("case%s:", $2);
}
| DEFAULT ':' {
    $$ = "default:";
}
| DEFAULT ':' multiline_statement {
    $$ = auto_sprintf("default:%s", $3);
}

while_statement:
WHILE '(' expr ')' statement {
    $$ = auto_sprintf("while(%s)%s", $3, $5);
}
| DO statement WHILE '(' expr ')' ';' {
    $$ = auto_sprintf("do%swhile(%s);", $2, $5);
}

for_statement: FOR '(' empty_or_expr ';' empty_or_expr ';' empty_or_expr ')' statement {
    $$ = auto_sprintf("for(%s;%s;%s)%s", $3, $5, $7, $9);
}

empty_or_expr: { $$ = ""; }
| expr { $$ = $1; }

return_statement: RETURN expr ';' { $$ = auto_sprintf("return%s;", $2); }
| RETURN ';' { $$ = "return;"; }


%%

int main(void) {
    yyparse();
    return 0;
}

int yyerror(const char *s) {
    fprintf(stderr, "%s\n", s);
    return 0;
}