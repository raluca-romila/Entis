all:
	bison -d parser.y
	flex lexer.l
	g++ -o my_compiler lex.yy.c parser.tab.c -lfl
clean:
	rm -f my_compiler lex.yy.c parser.tab.c parser.tab.h