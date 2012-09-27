#include <iostream>
#include <string>
#include <stdio.h>
#include <vector>
#include "tokenconsts.h"
using namespace std;

extern "C" int yylex();    // extern says they will be defined elsewhere
extern FILE *yyin, *yyout;
extern string s;
extern int line_num;

string pretty_spacing(int size)
{
    string spaces = "";
    for(int i = size; i > 0; --i)
    {
        spaces = spaces + " ";
    }
    return spaces;
};

class HashedTokenStrings 
{
private:
    vector<string> HashMap;
public:
    HashedTokenStrings()
    {
        this->HashMap.push_back("and");
        this->HashMap.push_back("array");
        this->HashMap.push_back("assign");
        this->HashMap.push_back("begin");
        this->HashMap.push_back("caret");
        this->HashMap.push_back("case");
        this->HashMap.push_back("colon");
        this->HashMap.push_back("comma");
        this->HashMap.push_back("const");
        this->HashMap.push_back("dispose");
        this->HashMap.push_back("div");
        this->HashMap.push_back("divide");
        this->HashMap.push_back("do");
        this->HashMap.push_back("dot");
        this->HashMap.push_back("dotdot");
        this->HashMap.push_back("downto");
        this->HashMap.push_back("else");
        this->HashMap.push_back("end");
        this->HashMap.push_back("equal");
        this->HashMap.push_back("false");
        this->HashMap.push_back("for");
        this->HashMap.push_back("function");
        this->HashMap.push_back("greater");
        this->HashMap.push_back("greaterequal");
        this->HashMap.push_back("ident");
        this->HashMap.push_back("if");
        this->HashMap.push_back("in");
        this->HashMap.push_back("leftbracket");
        this->HashMap.push_back("leftparen");
        this->HashMap.push_back("less");
        this->HashMap.push_back("lessequal");
        this->HashMap.push_back("minus");
        this->HashMap.push_back("mod");
        this->HashMap.push_back("multiply");
        this->HashMap.push_back("new");
        this->HashMap.push_back("nil");
        this->HashMap.push_back("notequal");
        this->HashMap.push_back("number");
        this->HashMap.push_back("of");
        this->HashMap.push_back("or");
        this->HashMap.push_back("plus");
        this->HashMap.push_back("procedure");
        this->HashMap.push_back("program");
        this->HashMap.push_back("read");
        this->HashMap.push_back("readln");
        this->HashMap.push_back("record");
        this->HashMap.push_back("repeat");
        this->HashMap.push_back("rightbracket");
        this->HashMap.push_back("rightparen");
        this->HashMap.push_back("semicolon");
        this->HashMap.push_back("set");
        this->HashMap.push_back("string");
        this->HashMap.push_back("then");
        this->HashMap.push_back("to");
        this->HashMap.push_back("true");
        this->HashMap.push_back("type");
        this->HashMap.push_back("until");
        this->HashMap.push_back("var");
        this->HashMap.push_back("while");
        this->HashMap.push_back("write");
        this->HashMap.push_back("writeln");
        this->HashMap.push_back("unknown");
    }
    
    string getString(int token)
    {
        int i = token - 257;
        if(i < 0 || i >= this->HashMap.size())
            return "";
        return this->HashMap[i];
    }
    
    int getSize()
    {
        return this->HashMap.size();
    }
};

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
    HashedTokenStrings hash;
    while (true)
    {
        token = yylex();
        if (token == 0) break;
        string token_string = hash.getString(token);
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
