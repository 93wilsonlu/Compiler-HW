%{
    #include <string.h>
    #include <stdarg.h>
    #include "y.tab.h"
%}

identifier [a-zA-Z_][a-zA-Z0-9_]*

operator (\+|-|\*|\/|\<|=|&)

punctuation (,|;|\.|\[|\]|\(|\)|\{|\})

integer [0-9]+

%x LEX_COMMENT
%x LEX_LINE_COMMENT

%%
\/\* { BEGIN LEX_COMMENT; }
<LEX_COMMENT>(.|"\n") {;}
<LEX_COMMENT>\*\/ { BEGIN 0; }


\/\/ { BEGIN LEX_LINE_COMMENT; }
<LEX_LINE_COMMENT>. {;}
<LEX_LINE_COMMENT>\n { BEGIN 0; }

"for" { return FOR; }
"do" { return DO; }
"while" { return WHILE; }
"break" { return BREAK; }
"if" { return IF; }
"else" { return ELSE; }
"return" { return RETURN; }
"void" { return VOID; }
"int" { return INT; }
"uint32_t" { return INT; }
"const" { return CONST; }
"HIGH" { return HIGH; }
"LOW" { return LOW; }

{identifier} {
    yylval.str = strdup(yytext);
    return IDENTIFIER;
}

{operator} {
    return yytext[0];
}
"==" { return EQ; }
"!=" { return NEQ; }

{punctuation} {
    return yytext[0];
}

{integer} {
    yylval.int_val = atoi(yytext);
    return INT_NUM;
}

(" "|"	"|"\n") {;}
%%
