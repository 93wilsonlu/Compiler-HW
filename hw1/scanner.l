%{
    #include <string.h>
    #include <stdarg.h>

    #define N 300

    char buffer[N], line[N];
    int line_count = 0;
    int buffer_len = 0;
    int token_on = 1, source_on = 1;

    void store_line(char *yytext, size_t yyleng) {
        strcpy(line, yytext);
    }

    void print_line() {
        if (source_on){
            printf("%d:%s\n", line_count + 1, line);
        }
        line_count++;
    }

    void append_string(char* yytext, size_t yyleng) {
        strcat(buffer + buffer_len, yytext);
        buffer_len += yyleng;
    }

    void print_token(char * format, ...) {
        if (token_on){
            char buf[300];
            va_list ap;
            va_start(ap, format);
            vsprintf(buf, format, ap);
            va_end(ap);
            printf("%s", buf);
        }
    }

    void print_char() {
        print_token("#char:\'%s\'\n", buffer);
        buffer[0] = '\0';
        buffer_len = 0;
    }

    void print_string() {
        print_token("#string:\"%s\"\n", buffer);
        buffer[0] = '\0';
        buffer_len = 0;
    }

%}

keyword (for|do|while|break|continue|if|else|return|struct|switch|case|default|void|int|double|float|char|const|signed|unsigned|short|long)

macro (NULL|__COUNTER__|__LINE__|INT_MAX|INT_MIN|CHAR_MAX|CHAR_MIN|MAX|MIN)

identifier [a-zA-Z_][a-zA-Z0-9_]*

operator (\+|-|\*|\/|%|\+\+|--|\<|\<=|\>|\>=|==|!=|=|&&|\|\||!|\&|\|)

punctuation (:|;|,|\.|\[|\]|\(|\)|\{|\})

integer [+-]?[0-9]+

float [+-]?([0-9]+\.[0-9]*|[0-9]*\.[0-9]+)

%x COMMENT
%x LINE_COMMENT
%x STRING
%x CHAR

%%
"#pragma"[ \t]+"token"[ \t]+"on" { token_on = 1; }
"#pragma"[ \t]+"token"[ \t]+"off" { token_on = 0; }
"#pragma"[ \t]+"source"[ \t]+"on" { source_on = 1; }
"#pragma"[ \t]+"source"[ \t]+"off" { source_on = 0; }

^.*$ {
    store_line(yytext, yyleng);
    REJECT;
}
\n { print_line(); }


\/\* { BEGIN COMMENT; }
<COMMENT>^.*$ {
    store_line(yytext, yyleng);
    REJECT;
}
<COMMENT>. {;}
<COMMENT>\n { print_line(); }
<COMMENT>\*\/ { BEGIN 0; }


\/\/ { BEGIN LINE_COMMENT; }
<LINE_COMMENT>. {;}
<LINE_COMMENT>\n {
    print_line();
    BEGIN 0;
}


\' { BEGIN CHAR; }
<CHAR>[^\'] { append_string(yytext, yyleng); }
<CHAR>\\. { append_string(yytext, yyleng); }
<CHAR>\' {
    print_char();
    BEGIN 0;
}

\" { BEGIN STRING; }
<STRING>[^\"] { append_string(yytext, yyleng);}
<STRING>\\. { append_string(yytext, yyleng);}
<STRING>\" {
    print_string();
    BEGIN 0;
}

{keyword} print_token("#key:%s\n", yytext);

{macro} print_token("#macro:%s\n", yytext);

{identifier} print_token("#id:%s\n", yytext);

{operator} print_token("#op:%s\n", yytext);

{punctuation} print_token("#punc:%s\n", yytext);

{integer} print_token("#integer:%s\n", yytext);

{float} print_token("#float:%s\n", yytext);

(" "|"	") {;}
%%

int main() {
    yylex();
    return 0;
}