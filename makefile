LEX_FILE = mini-pascal.l
YACC_FILE = mini-pascal.y
MAIN_FILE = main.cpp
BINARY_FILE = mini-pascal
OBJ_FILES = y.tab.o lex.yy.o main.o
LIBS = -lfl

mini-pascal: $(OBJ_FILES)
	g++ $(OBJ_FILES) $(LIBS) -o $(BINARY_FILE)

main.o: $(MAIN_FILE)
	g++ -c $(MAIN_FILE) -o main.o

lex.yy.o: lex.yy.c
	g++ -c lex.yy.c -o lex.yy.o

lex.yy.c: $(LEX_FILE)
	flex $(LEX_FILE)

y.tab.o: y.tab.c
	g++ -c y.tab.c -o y.tab.o

y.tab.c: $(YACC_FILE)
	bison --yacc -d $(YACC_FILE)

clean:
	    rm -f $(BINARY_FILE) $(OBJ_FILES) lex.yy.c y.tab.c y.tab.h
