%{
    #include <stdio.h>
    #include <string.h>
    #include <stdlib.h>
    #include <stdarg.h>
    #include "utils.h"
    int label_stack[100], tail = 0, cur_label = 0;
    int label_type[100];
%}
%union {
    int int_val;
    char *str;
}
%token<int_val> INT_NUM
%token<str> IDENTIFIER
%token CONST INT VOID FOR DO WHILE BREAK IF ELSE RETURN HIGH LOW
%type<str> func_decl ident
%type<int_val> comparator expr

%nonassoc ','
%right '='
%left EQ NEQ
%left '<'
%left '+' '-'
%left '*' '/'
%right RTL
%nonassoc THEN
%nonassoc ELSE

%start Ss

%%
Ss: S | S Ss

S: func_decl ';' | func_def

/* ******* expr ********* */
expr:
IDENTIFIER '(' params ')' {
    if(!strcmp($1, "__rv__ukadd8")) { 
        fprintf(f_asm, "ukadd8 a0, a0, a1\n\n");
    } else if(!strcmp($1, "__rv__uksub8")) {
        fprintf(f_asm, "uksub8 a0, a0, a1\n\n");
    } else if(!strcmp($1, "__rv__cmpeq8")) {
        fprintf(f_asm, "cmpeq8 a0, a0, a1\n\n");
    } else if(!strcmp($1, "__rv__ucmplt8")) {
        fprintf(f_asm, "ucmplt8 a0, a0, a1\n\n");
    } else {
        fprintf(f_asm, "call %s\n\n", $1);
    }
    push("a0");
    $$ = T_INT;
}
| '(' expr ')' {
    $$ = $2;
}
| IDENTIFIER '=' expr {
    pop("s1");
    fprintf(f_asm, "sw s1, -%d(fp)\n\n", find_offset($1));
}
| '*' IDENTIFIER '=' expr {
    pop("s1");
    fprintf(f_asm, "lw s2, -%d(fp)\n", find_offset($2));
    fprintf(f_asm, "sw s1, 0(s2)\n\n");
}
| '*' '(' expr ')' '=' expr {
    pop("s2");
    pop("s1");
    fprintf(f_asm, "sw s2, 0(s1)\n\n");
}
| IDENTIFIER '[' expr ']' '=' expr {
    pop("s2");
    pop("s1");
    fprintf(f_asm, "slli s1, s1, 2\n");
    if(table[look_up_symbol($1)].type == T_ARRAY) {
        fprintf(f_asm, "add s1, fp, s1\n");
        fprintf(f_asm, "sw s2, -%d(s1)\n\n", find_offset($1));
    } else {
        fprintf(f_asm, "lw s3, -%d(fp)\n", find_offset($1));
        fprintf(f_asm, "add s3, s3, s1\n");
        fprintf(f_asm, "sw s2, 0(s3)\n");
    }
}

| expr '+' expr {
    pop("s2");
    pop("s1");
    if ($1 != T_INT) {
        fprintf(f_asm, "slli s2, s2, 2\n");
    }
    fprintf(f_asm, "add s1, s1, s2\n");
    push("s1");
    fprintf(f_asm, "\n");
    $$ = $1;
}
| expr '-' expr {
    pop("s2");
    pop("s1");
    if ($1 != T_INT) {
        fprintf(f_asm, "slli s2, s2, 2\n");
    }
    fprintf(f_asm, "sub s1, s1, s2\n");
    push("s1");
    fprintf(f_asm, "\n");
    $$ = $1;
}
| expr '*' expr {
    pop("s2");
    pop("s1");
    fprintf(f_asm, "mul s1, s1, s2\n");
    push("s1");
    fprintf(f_asm, "\n");
    $$ = T_INT;
}
| expr '/' expr {
    pop("s2");
    pop("s1");
    fprintf(f_asm, "div s1, s1, s2\n");
    push("s1");
    fprintf(f_asm, "\n");
    $$ = T_INT;
}
| '-' expr %prec RTL {
    // sub rax, x0, rax
    pop("s1");
    fprintf(f_asm, "sub s1, x0, s1\n");
    push("s1");
    fprintf(f_asm, "\n");
    $$ = T_INT;
}
| '*' IDENTIFIER %prec RTL {
    // mov rax, [rax]
    fprintf(f_asm, "lw s1, -%d(fp)\n", find_offset($2));
    fprintf(f_asm, "lw s1, 0(s1)\n");
    push("s1");
    fprintf(f_asm, "\n");
    $$ = T_INT;
}
| '*' '(' expr ')' %prec RTL {
    // mov rax, [rax]
    pop("s1");
    fprintf(f_asm, "lw s1, 0(s1)\n");
    push("s1");
    fprintf(f_asm, "\n");
    $$ = T_INT;
}

| '&' IDENTIFIER %prec RTL {
    // push bp-offset
    fprintf(f_asm, "add s1, fp, -%d\n", find_offset($2));
    push("s1");
    fprintf(f_asm, "\n");
    $$ = T_POINTER;
}

| IDENTIFIER {
    // push [bp-offset]
    if(table[look_up_symbol($1)].type == T_ARRAY) {
        fprintf(f_asm, "add s1, fp, -%d\n", find_offset($1));
    } else {
        fprintf(f_asm, "lw s1, -%d(fp)\n", find_offset($1));
    }
    push("s1");
    $$ = table[look_up_symbol($1)].type;
    fprintf(f_asm, "\n");
}

| IDENTIFIER '[' expr ']' {
    pop("s1");
    fprintf(f_asm, "slli s1, s1, 2\n");
    if(table[look_up_symbol($1)].type == T_ARRAY) {
        fprintf(f_asm, "add s1, fp, s1\n");
        fprintf(f_asm, "lw s1, -%d(s1)\n", find_offset($1));
    } else {
        fprintf(f_asm, "lw s2, -%d(fp)\n", find_offset($1));
        fprintf(f_asm, "add s2, s2, s1\n");
        fprintf(f_asm, "lw s1, 0(s2)\n");
    }
    push("s1");
    fprintf(f_asm, "\n");
    $$ = T_INT;
}

| INT_NUM {
    fprintf(f_asm, "li s1, %d\n", $1);
    push("s1");
    fprintf(f_asm, "\n");
    $$ = T_INT;
}
| HIGH {
    fprintf(f_asm, "li s1, 1\n");
    push("s1");
    fprintf(f_asm, "\n");
    $$ = T_INT;
}
| LOW {
    fprintf(f_asm, "li s1, 0\n");
    push("s1");
    fprintf(f_asm, "\n");
    $$ = T_INT;
}

params: /* empty */
| expr {
    pop("a0");
}
| expr ',' expr {
    pop("a1");
    pop("a0");
}
| expr ',' expr ',' expr {
    pop("a2");
    pop("a1");
    pop("a0");
}

/* ******************** */

/* **** scalar_decl *** */
scalar_decl: data_type idents ';'

idents: init_ident 
| idents ',' init_ident 

init_ident: ident
| ident '=' expr_with_cmp {
    pop("s1");
    fprintf(f_asm, "sw s1, -%d(fp)", find_offset($1));
    fprintf(f_asm, "\n");
}

ident: IDENTIFIER  {
    var_declare($1, 1, T_INT);
    $$ = $1;
}
| '*' IDENTIFIER  {
    var_declare($2, 1, T_POINTER);
    $$ = $2;
}

data_type: CONST | INT | VOID | CONST INT 


expr_with_cmp: expr
| expr NEQ expr {
    pop("s2");
    pop("s1");
    fprintf(f_asm, "xor s1, s1, s2\n");
    fprintf(f_asm, "slt s1, s1, 1\n");
    fprintf(f_asm, "xor s1, s1, 1\n");
    push("s1");
}

/* ******************** */

/* **** array_decl **** */
array_decl: data_type IDENTIFIER '[' INT_NUM ']' ';' {
    var_declare($2, $4, T_ARRAY);
}

/* ******************** */

/* ***** func_decl ****** */
func_decl: data_type IDENTIFIER {
    install_symbol($2);
    $<str>$ = $2;
}
'(' func_decl_params ')' { $$ = $<str>3; }

func_decl_params: /* empty */ 
| data_type ident
| func_decl_params ',' data_type ident

/* ******************** */

/* ***** func_def ****** */
func_def: func_decl {
    set_scope_and_offset_of_param($1);
    function_start($1);
} compound_statement {
    function_end();
    pop_up_symbol_of_func();
}

compound_statement: '{' '}' 
| '{' {
    next_scope();
}
multiline_statement '}' {
    pop_up_symbol();
}

multiline_statement: statement
| multiline_statement statement

/* ******************** */

/* **** statement ***** */
statement: expr ';' 
| if_statement 
| while_statement 
| for_statement 
| return_statement 
| BREAK ';' {
    int i = tail - 1;
    while (i >= 0 && label_type[i] == 0) {
        i--;
    }
    fprintf(f_asm, "j L%d\n", label_stack[i] + 2);
}
| compound_statement 
| scalar_decl
| array_decl

comparator: '<' { $$ = 0; } | EQ { $$ = 1; } | NEQ { $$ = 2; }

if_statement:
IF '(' expr comparator expr ')' {
    pop("s2");
    pop("s1");
    if($4 == 0) {
        fprintf(f_asm, "blt s1, s2, L%d\n", cur_label);
    } else if($4 == 1) {
        fprintf(f_asm, "beq s1, s2, L%d\n", cur_label);
    } else {
        fprintf(f_asm, "bne s1, s2, L%d\n", cur_label);
    }
    fprintf(f_asm, "j L%d\n", cur_label + 1);
    fprintf(f_asm, "L%d:\n", cur_label);

    label_stack[tail] = cur_label;
    label_type[tail] = 0;
    tail++;
    cur_label += 3;
} compound_statement if_back

if_back: {
    fprintf(f_asm, "L%d:\n", label_stack[--tail] + 1);
} %prec THEN
| ELSE {
    int label = label_stack[tail - 1];
    fprintf(f_asm, "j L%d\n", label + 2);
    fprintf(f_asm, "L%d:\n", label + 1);
} compound_statement {
    fprintf(f_asm, "L%d:\n", label_stack[--tail] + 2);
}

while_statement:
WHILE '(' {
    fprintf(f_asm, "L%d:\n", cur_label);
    label_stack[tail] = cur_label;
    label_type[tail] = 1;
    tail++;
    cur_label += 3;
} while_back
| DO {
    fprintf(f_asm, "L%d:\n", cur_label);
    label_stack[tail] = cur_label;
    label_type[tail] = 1;
    tail++;
    cur_label += 3;
} statement WHILE '(' expr comparator expr ')' ';' {
    int label = label_stack[tail - 1];
    pop("s2");
    pop("s1");
    if($7 == 0) {
        fprintf(f_asm, "blt s1, s2, L%d\n", label);
    } else if($7 == 1) {
        fprintf(f_asm, "beq s1, s2, L%d\n", label);
    } else {
        fprintf(f_asm, "bne s1, s2, L%d\n", label);
    }
    fprintf(f_asm, "L%d:\n", label + 2);
} 

while_back:
expr comparator expr ')' {
    int label = label_stack[tail - 1];
    pop("s2");
    pop("s1");
    if($2 == 0) {
        fprintf(f_asm, "blt s1, s2, L%d\n", label + 1);
    } else if($2 == 1) {
        fprintf(f_asm, "beq s1, s2, L%d\n", label + 1);
    } else {
        fprintf(f_asm, "bne s1, s2, L%d\n", label + 1);
    }
    fprintf(f_asm, "j L%d\n", label + 2);
    fprintf(f_asm, "L%d:\n", label + 1);
    label += 3;
} statement {
    int label = label_stack[tail - 1];
    fprintf(f_asm, "j L%d\n", label);
    fprintf(f_asm, "L%d:\n", label + 2);
    tail--;
}
| expr ')' {
    int label = label_stack[tail - 1];
    pop("s1");
    fprintf(f_asm, "li s2, 0\n");
    fprintf(f_asm, "bne s1, s2, L%d\n", label + 1);
    fprintf(f_asm, "j L%d\n", label + 2);
    fprintf(f_asm, "L%d:\n", label + 1);
    label += 3;
} statement {
    int label = label_stack[tail - 1];
    fprintf(f_asm, "j L%d\n", label);
    fprintf(f_asm, "L%d:\n", label + 2);
    tail--;
}

for_statement: FOR '(' expr ';' {
    fprintf(f_asm, "L%d:\n", cur_label);
    label_stack[tail++] = cur_label;
    cur_label += 4;
} expr comparator expr ';' {
    int label = label_stack[tail - 1];
    pop("s2");
    pop("s1");
    if($7 == 0) {
        fprintf(f_asm, "blt s1, s2, L%d\n", label + 2);
    } else if($7 == 1) {
        fprintf(f_asm, "beq s1, s2, L%d\n", label + 2);
    } else {
        fprintf(f_asm, "bne s1, s2, L%d\n", label + 2);
    }
    fprintf(f_asm, "j L%d\n", label + 3);
    fprintf(f_asm, "L%d:\n", label + 1);
} expr {
    int label = label_stack[tail - 1];
    fprintf(f_asm, "j L%d\n", label);
    fprintf(f_asm, "L%d:\n", label + 2);
} ')' statement {
    int label = label_stack[tail - 1];
    fprintf(f_asm, "j L%d\n", label + 1);
    fprintf(f_asm, "L%d:\n", label + 3);
    tail--;
}

return_statement: RETURN expr ';' {
    pop("a0");
    function_end();
}
| RETURN ';' {
    function_end();
}

%%

int main(void) {
    f_asm = fopen("codegen.S", "w");
    yyparse();
    fclose(f_asm);
    return 0;
}

int yyerror(const char *s) {
    fprintf(stderr, "%s\n", s);
    return 0;
}