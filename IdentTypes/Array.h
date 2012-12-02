// Array.h
#pragma once
#include "MetaType.h"
#include "VariableType.h"
#include "Pointer.h"
#include <sstream>
#include <math.h>
#include <vector>
using namespace std;

struct AcceptedTypes {
    enum Types {
        NONE,
        CHAR,
        INT
    };
};

// Range allows us to hold a vector of 'low' and 'high' values
class Range : public MetaType {
public:
    char charLow;
    char charHigh;
    
    int intLow;
    int intHigh;
    AcceptedTypes::Types rangeType;
    
    Range();
    Range(int, int);
    Range(char, char);
    
    string ToString() const;
    string CString() const;
};

class ArrayType:public VariableType {
public:
	ArrayType(const string);
	~ArrayType();
	
	bool AddDimension(int, int);
	bool AddDimension(char, char);
    bool AddDimension(Range);
	
	VariableType* GetArrayType();
	void SetArrayType(VariableType* varType);
    int GetArrayDimensions();
    int GetArrayFlattenedSize();
    AcceptedTypes::Types GetAcceptedType();
	
	string ToString() const;
	string CString() const;
    string CString(string) const;

private:
    // RangeStruct allows us to hold a vector of 'low' and 'high' values
    vector <Range> ranges;    // Vector holding ranges
    
    /* As shown in the testoutput, Arrays must show what 
       kind of value they contain */
    VariableType* my_type;    
    
};
