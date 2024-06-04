CC = gcc
LEX = flex
YACC = yacc

parser: scanner.l parser.y
	$(YACC) -v -d parser.y
	$(LEX) scanner.l
	$(CC) -o parser lex.yy.c y.tab.c -lfl

clean:
	rm lex.yy.c parser y.tab.c y.tab.h
