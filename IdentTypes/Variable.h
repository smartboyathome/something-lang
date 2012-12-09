// Variable.h
#pragma once
#include "MetaType.h"
#include "VariableType.h"
#include "Pointer.h"

class Variable:public MetaType {
public:
    Variable(const string name);
    Variable(const string name, const string value);
    ~Variable();
    
    void SetValue(string value);
    void SetVarType(VariableType* varType);
    VariableType* GetVarType();
    string GetValue();
    void ToggleConst();
    bool IsConst();
    void ToggleOutput();
    bool IsOutput();
    
    string ToString() const;
    string CString() const;
    
private:
    bool is_const;
    bool is_output;
    string variable_value;
    VariableType* my_type;
};
