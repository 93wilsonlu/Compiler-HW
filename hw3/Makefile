CC = gcc
YACC = yacc
LEX = flex

all: codegen

y.tab.c: parser.y
	$(YACC) -d parser.y

lex.yy.c: scanner.l
	$(LEX) scanner.l

codegen: lex.yy.c y.tab.c utils.c
	$(CC) -o codegen lex.yy.c y.tab.c utils.c -lfl -Wno-implicit-function-declaration

clean:
	rm lex.yy.c y.tab.h y.tab.c codegen