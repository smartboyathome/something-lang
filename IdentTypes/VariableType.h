// VariableType.h
#pragma once
#include "MetaType.h"
using namespace std;

// The four basic variable types
struct VarTypes
{
    enum Type {
        INTEGER,
        BOOLEAN,
        REAL,
        CHAR,
        ARRAY
    };
};

class VariableType:public MetaType {
public:
    // Constructor takes a VarType, "INTEGER", "BOOLEAN", "REAL", or "CHAR"
    VariableType(string name, const VarTypes::Type type);
    ~VariableType();
    
    VarTypes::Type GetVarType();    // Returns a string representation of the type
    
private:
    VarTypes::Type var_type;
};

class IntegerType : public VariableType
{
public:
    IntegerType(string, int);
    int GetValue();
    void SetValue(int);
private:
    int value;
};
