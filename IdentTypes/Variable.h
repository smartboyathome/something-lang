// Variable.h
#pragma once
#include "MetaType.h"
#include "VariableType.h"

class Variable:public MetaType {
public:
    Variable(const string name);
    Variable(const string name, const string value);
    ~Variable();
    
    bool SetValue(string value);
    bool SetType(VariableType* varType);
    string GetValue();
    
    string ToString() const;
    string CString() const;
    
private:
    string variable_value;
    VariableType* my_type;
};
