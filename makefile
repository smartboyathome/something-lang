LEX_FILE = mini-pascal.l
YACC_FILE = mini-pascal.y
MAIN_FILE = main.cpp
BINARY_FILE = mini-pascal
SCOPES_FILE = Scopes.cpp
ARRAY_FILE = IdentTypes/Array.cpp
CONSTANT_FILE = IdentTypes/Constant.cpp
METATYPE_FILE = IdentTypes/MetaType.cpp
PROCEDURE_FILE = IdentTypes/Procedure.cpp
VARIABLE_FILE = IdentTypes/Variable.cpp
VARIABLETYPE_FILE = IdentTypes/VariableType.cpp
POINTER_FILE = IdentTypes/Pointer.cpp
OBJ_FILES = y.tab.o lex.yy.o main.o scopes.o IdentTypes/array.o IdentTypes/constant.o IdentTypes/metatype.o IdentTypes/pointer.o IdentTypes/procedure.o IdentTypes/variable.o IdentTypes/variabletype.o
COMPILER_FLAGS = -lfl -g

mini-pascal: $(OBJ_FILES)
	g++ $(OBJ_FILES) $(COMPILER_FLAGS) -o $(BINARY_FILE)

main.o: $(MAIN_FILE)
	g++ -c $(MAIN_FILE) -o main.o

scopes.o: $(SCOPES_FILE)
	g++ -c $(SCOPES_FILE) -o scopes.o

IdentTypes/array.o: $(ARRAY_FILE)
	g++ -c $(ARRAY_FILE) -o IdentTypes/array.o

IdentTypes/constant.o: $(CONSTANT_FILE)
	g++ -c $(CONSTANT_FILE) -o IdentTypes/constant.o

IdentTypes/metatype.o: $(METATYPE_FILE)
	g++ -c $(METATYPE_FILE) -o IdentTypes/metatype.o
	
IdentTypes/pointer.o: $(POINTER_FILE)
	g++ -c $(POINTER_FILE) -o IdentTypes/pointer.o

IdentTypes/procedure.o: $(PROCEDURE_FILE)
	g++ -c $(PROCEDURE_FILE) -o IdentTypes/procedure.o

IdentTypes/variable.o: $(VARIABLE_FILE)
	g++ -c $(VARIABLE_FILE) -o IdentTypes/variable.o

IdentTypes/variabletype.o: $(VARIABLETYPE_FILE)
	g++ -c $(VARIABLETYPE_FILE) -o IdentTypes/variabletype.o

lex.yy.o: lex.yy.c
	g++ -c lex.yy.c -o lex.yy.o

lex.yy.c: $(LEX_FILE)
	flex $(LEX_FILE)

y.tab.o: y.tab.c
	g++ -c y.tab.c -o y.tab.o

y.tab.c: $(YACC_FILE)
	bison --yacc -d --report=state $(YACC_FILE)

clean:
	    rm -f $(BINARY_FILE) $(OBJ_FILES) lex.yy.c y.tab.c y.tab.h
