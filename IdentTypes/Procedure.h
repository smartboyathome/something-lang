// Procedure.h
#pragma once
#include "MetaType.h"
#include "Variable.h"
#include "VariableType.h"
#include <vector>

class Procedure:public MetaType {
public:
    Procedure(const string name);
    ~Procedure();
    
    // TODO: Make Variable* VariableTypes* instead.
    bool InsertParameter(Variable*);
    bool HasDuplicateParameter(const Variable*);
    
    VariableType* GetReturnType();
    void SetReturnType(VariableType*);
    
    string ToString() const;
    string CString() const;

private:
    // Vector holding pointers to Variables that represent the parameters 
    // of this procedure
    vector<Variable*> parameters;
    VariableType* return_type;
    
};
