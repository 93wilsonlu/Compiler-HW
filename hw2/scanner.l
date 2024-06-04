%{
    #include <string.h>
    #include <stdarg.h>
    #include "y.tab.h"

    #define N 300

    char buffer[N];
    int buffer_len = 0;

    void append_string(char* yytext, size_t yyleng) {
        strcat(buffer + buffer_len, yytext);
        buffer_len += yyleng;
        buffer[buffer_len] = '\0';
    }
%}

identifier [a-zA-Z_][a-zA-Z0-9_]*

operator (\+|-|\*|\/|%|\<|\>|=|!|\&|\||\~|\^)

punctuation (:|;|,|\.|\[|\]|\(|\)|\{|\})

integer [0-9]+

float ([0-9]+\.[0-9]*|[0-9]*\.[0-9]+)

%x LEX_COMMENT
%x LEX_LINE_COMMENT
%x LEX_STRING
%x LEX_CHAR

%%
\/\* { BEGIN LEX_COMMENT; }
<LEX_COMMENT>("."|"\n") {;}
<LEX_COMMENT>\*\/ { BEGIN 0; }


\/\/ { BEGIN LEX_LINE_COMMENT; }
<LEX_LINE_COMMENT>. {;}
<LEX_LINE_COMMENT>\n {
    BEGIN 0;
}


\' { BEGIN LEX_CHAR; }
<LEX_CHAR>[^\'] { append_string(yytext, yyleng); }
<LEX_CHAR>\\. { append_string(yytext, yyleng); }
<LEX_CHAR>\' {
    yylval.str = strdup(buffer);
    buffer[0] = '\0';
    buffer_len = 0;
    BEGIN 0;
    return CHARACTER;
}

\" { BEGIN LEX_STRING; }
<LEX_STRING>[^\"] { append_string(yytext, yyleng);}
<LEX_STRING>\\. { append_string(yytext, yyleng);}
<LEX_STRING>\" {
    yylval.str = strdup(buffer);
    buffer[0] = '\0';
    buffer_len = 0;
    BEGIN 0;
    return STRING;
}

"for" { return FOR; }
"do" { return DO; }
"while" { return WHILE; }
"break" { return BREAK; }
"continue" { return CONTINUE; }
"if" { return IF; }
"else" { return ELSE; }
"return" { return RETURN; }
"switch" { return SWITCH; }
"case" { return CASE; }
"default" { return DEFAULT; }
"void" { return VOID; }
"int" { return INT; }
"double" { return DOUBLE; }
"float" { return FLOAT; }
"char" { return CHAR; }
"const" { return CONST; }
"signed" { return SIGNED; }
"unsigned" { return UNSIGNED; }
"short" { return SHORT; }
"long" { return LONG; }
"NULL" { return NULL_; }

{identifier} {
    yylval.str = strdup(yytext);
    return IDENTIFIER;
}

{operator} {
    return yytext[0];
}
"++" { return INC; }
"--" { return DEC; }
"<=" { return LEQ; }
">=" { return GEQ; }
"==" { return EQ; }
"!=" { return NEQ; }
"&&" { return LOGICAL_AND; }
"||" { return LOGICAL_OR; }
"<<" { return LEFT_SHIFT; }
">>" { return RIGHT_SHIFT; }

{punctuation} {
    return yytext[0];
}

{integer} {
    yylval.int_val = atoi(yytext);
    return INT_NUM;
}

{float} {
    yylval.float_val = atof(yytext);
    return FLOAT_NUM;
}

(" "|"	"|"\n") {;}
%%
