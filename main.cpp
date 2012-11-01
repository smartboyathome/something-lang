#include <iostream>
#include <iomanip>
#include <string>
#include <stdio.h>
#include <vector>
#include "y.tab.h"
using namespace std;

// extern says they will be defined elsewhere
extern "C" int yylex(); // yylex is the main flex function.
extern FILE *yyin, *yyout; // yyin and yyout are the streams to read/write input.
extern string s; // This is the metadata, such a s an int or string value.
extern int line_num; // And this is the line number that flex is on.
extern "C" int yyparse(); // yyparse is the main bison/yacc function.
extern "C" int yydebug;

// A simple class that just hashes the tokens to strings using an array and
// some basic arithmetic. You can get a string from a token using the getString
// function.
class HashedTokenStrings 
{
private:
    static const int size = 63;
    string HashMap[size];
public:
    // Initialize the array with all the strings. This class was generated from
    // the tokenconsts.h file using a python script.
    HashedTokenStrings()
    {
        this->HashMap[0] = "yand";
        this->HashMap[1] = "yarray";
        this->HashMap[2] = "yassign";
        this->HashMap[3] = "ybegin";
        this->HashMap[4] = "ycaret";
        this->HashMap[5] = "ycase";
        this->HashMap[6] = "ycolon";
        this->HashMap[7] = "ycomma";
        this->HashMap[8] = "yconst";
        this->HashMap[9] = "ydispose";
        this->HashMap[10] = "ydiv";
        this->HashMap[11] = "ydivide";
        this->HashMap[12] = "ydo";
        this->HashMap[13] = "ydot";
        this->HashMap[14] = "ydotdot";
        this->HashMap[15] = "ydownto";
        this->HashMap[16] = "yelse";
        this->HashMap[17] = "yend";
        this->HashMap[18] = "yequal";
        this->HashMap[19] = "yfalse";
        this->HashMap[20] = "yfor";
        this->HashMap[21] = "yfunction";
        this->HashMap[22] = "ygreater";
        this->HashMap[23] = "ygreaterequal";
        this->HashMap[24] = "yident";
        this->HashMap[25] = "yif";
        this->HashMap[26] = "yin";
        this->HashMap[27] = "yleftbracket";
        this->HashMap[28] = "yleftparen";
        this->HashMap[29] = "yless";
        this->HashMap[30] = "ylessequal";
        this->HashMap[31] = "yminus";
        this->HashMap[32] = "ymod";
        this->HashMap[33] = "ymultiply";
        this->HashMap[34] = "ynew";
        this->HashMap[35] = "ynil";
        this->HashMap[36] = "ynot";
        this->HashMap[37] = "ynotequal";
        this->HashMap[38] = "ynumber";
        this->HashMap[39] = "yof";
        this->HashMap[40] = "yor";
        this->HashMap[41] = "yplus";
        this->HashMap[42] = "yprocedure";
        this->HashMap[43] = "yprogram";
        this->HashMap[44] = "yread";
        this->HashMap[45] = "yreadln";
        this->HashMap[46] = "yrecord";
        this->HashMap[47] = "yrepeat";
        this->HashMap[48] = "yrightbracket";
        this->HashMap[49] = "yrightparen";
        this->HashMap[50] = "ysemicolon";
        this->HashMap[51] = "yset";
        this->HashMap[52] = "ystring";
        this->HashMap[53] = "ythen";
        this->HashMap[54] = "yto";
        this->HashMap[55] = "ytrue";
        this->HashMap[56] = "ytype";
        this->HashMap[57] = "yuntil";
        this->HashMap[58] = "yvar";
        this->HashMap[59] = "ywhile";
        this->HashMap[60] = "ywrite";
        this->HashMap[61] = "ywriteln";
        this->HashMap[62] = "yunknown";
    }
    
    // The tokens start at 257. Therefore, if you subtract 257 from the token
    // int, you will get the index in the hashmap array.
    string getString(int token)
    {
        int i = token - 257;
        if(i < 0 || i >= size)
            return "";
        return this->HashMap[i];
    }
    
    // This gets how many elements are in the array. For use by anything that
    // needs to know that.
    int getSize()
    {
        return size;
    }
};

// This function strips the leading and trailing whitespace.
// It is useful for matching line 70 of array2lexoutput.
string strip_whitespace(string s)
{
    string new_s = s.erase(0, s.find_first_not_of(" \r\n\t"));
    new_s = s.erase(s.find_last_not_of(" \r\n\t") + 1);
    return new_s;
};

int main(int argc, char* argv[]) {
    if ( argc > 2 ) // argc should not be greater than 2 for correct execution
    {
        // We print argv[0] assuming it is the program name
        cout<<"usage: "<< argv[0] <<" [<filename>]\n";
        return -1; // exit code -1 means that an error has occured.
    }
    else if(argc == 2) // If there are no arguments, STDIN is used instead.
    {
        // open a file handle to a particular file:
	    FILE *myfile = fopen(argv[1], "r");
	    // make sure it's valid:
	    if (!myfile) {
	        // You haven't given us a file we can read from! ABORT! ABORT!
		    cout << "I can't open " << argv[1] << "!" << endl;
		    return -1;
	    }
	    // set lex to read from it instead of defaulting to STDIN:
	    yyin = myfile;
    }
    // lex through the input:
    HashedTokenStrings hash; // We only want to initialize the hash table once.
    while (true) // Yes an infinite loop, but its escaped using break.
    {
        //yydebug=1;
        yyparse();
        if (feof(yyin)) break;
        /*
        int token = yylex(); // Gets the token as an int.
        if (token == 0) break; // We're done when we reach the end of file token.
        cout << left << setw(6) << token; // Output the token as an int.
        if (strip_whitespace(s) != "") // We don't want the column if we don't need it.
        {
            cout << left << setw(14) << hash.getString(token); // And as a string.
            cout << s << endl; // Finally output the metadata.
        }
        else
            cout << hash.getString(token) << endl; // And as a string with no trailing spaces.
        */
    }
    return 0; // We have finished successfully.
}
