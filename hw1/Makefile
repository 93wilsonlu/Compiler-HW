CC = gcc
LEX = flex

scanner: scanner.l
	$(LEX) scanner.l
	$(CC) -o scanner lex.yy.c -lfl

clean:
	rm lex.yy.c scanner