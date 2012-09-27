#include <iostream>
#include <string>
#include <stdio.h>
#include "tokenconsts.h"
using namespace std;

extern "C" int yylex();    // extern says they will be defined elsewhere
extern FILE *yyin, *yyout;
extern string s;
extern int line_num;
string tokenToString(int);
string pretty_spacing(int);

int main(int argc, char* argv[]) {
    if ( argc > 2 ) // argc should not be greater than 2 for correct execution
    {
        // We print argv[0] assuming it is the program name
        cout<<"usage: "<< argv[0] <<" [<filename>]\n";
        return -1;
    }
    else if(argc == 2)
    {
        // open a file handle to a particular file:
	    FILE *myfile = fopen(argv[1], "r");
	    // make sure it's valid:
	    if (!myfile) {
		    cout << "I can't open " << argv[1] << "!" << endl;
		    return -1;
	    }
	    // set lex to read from it instead of defaulting to STDIN:
	    yyin = myfile;
    }
    // lex through the input:
    int token;
    while (true)
    {
        token = yylex();
        if (token == 0) break;
        string token_string = tokenToString(token);
        int token_col_size = 14;
        string token_spaces = pretty_spacing(token_col_size - token_string.length());
        int line_num_col_size = 6;
        string line_num_spaces = pretty_spacing(line_num_col_size - line_num / 10 + 1);
        cout << "token = " << token << " (" << token_string << ")";
        cout << token_spaces << "line = " << line_num;
        cout << line_num_spaces << "s = " << s << endl;
    }
    return 0;
}

string pretty_spacing(int size)
{
    string spaces = "";
    for(int i = size; i > 0; --i)
    {
        spaces = spaces + " ";
    }
    return spaces;
}

string tokenToString(int token)
{
    switch(token)
    {
        case yand:
            return "and";
        case yarray:
            return "array";
        case yassign:
            return "assign";
        case ybegin:
            return "begin";
        case ycaret:
            return "caret";
        case ycase:
            return "case";
        case ycolon:
            return "colon";
        case ycomma:
            return "comma";
        case yconst:
            return "const";
        case ydispose:
            return "dispose";
        case ydiv:
            return "div";
        case ydivide:
            return "divide";
        case ydo:
            return "do";
        case ydot:
            return "dot";
        case ydotdot:
            return "dotdot";
        case ydownto:
            return "downto";
        case yelse:
            return "else";
        case yend:
            return "end";
        case yequal:
            return "equal";
        case yfalse:
            return "false";
        case yfor:
            return "for";
        case yfunction:
            return "function";
        case ygreater:
            return "greater";
        case ygreaterequal:
            return "greaterequal";
        case yident:
            return "ident";
        case yif:
            return "if";
        case yin:
            return "in";
        case yleftbracket:
            return "leftbracket";
        case yleftparen:
            return "leftparen";
        case yless:
            return "less";
        case ylessequal:
            return "lessequal";
        case yminus:
            return "minus";
        case ymod:
            return "mod";
        case ymultiply:
            return "multiply";
        case ynew:
            return "new";
        case ynil:
            return "nil";
        case ynotequal:
            return "notequal";
        case ynumber:
            return "number";
        case yof:
            return "of";
        case yor:
            return "or";
        case yplus:
            return "plus";
        case yprocedure:
            return "procedure";
        case yprogram:
            return "program";
        case yread:
            return "read";
        case yreadln:
            return "readln";
        case yrecord:
            return "record";
        case yrepeat:
            return "repeat";
        case yrightbracket:
            return "rightbracket";
        case yrightparen:
            return "rightparen";
        case ysemicolon:
            return "semicolon";
        case yset:
            return "set";
        case ystring:
            return "string";
        case ythen:
            return "then";
        case yto:
            return "to";
        case ytrue:
            return "true";
        case ytype:
            return "type";
        case yuntil:
            return "until";
        case yvar:
            return "var";
        case ywhile:
            return "while";
        case ywrite:
            return "write";
        case ywriteln:
            return "writeln";
        case yunknown:
            return "unknown";
    }
}
