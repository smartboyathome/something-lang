// Array.h
#pragma once
#include "MetaType.h"
#include "VariableType.h"
#include <vector>
using namespace std;

struct Range {
    int low;        // Low value 
    int high;    // .. High value
    Range(int, int);
};

class ArrayType:public VariableType {
public:
    ArrayType(const string name);
    ~ArrayType();
    
    void AddDimension(int, int);
    
    void SetType(VariableType* varType);
    
    string ToString() const;
    string CString() const;

private:
    // RangeStruct allows us to hold a vector of 'low' and 'high' values
    vector <Range> ranges;    // Vector holding ranges
    
    /* As shown in the testoutput, Arrays must show what 
       kind of value they contain */
    VariableType* my_type;    
    
};
