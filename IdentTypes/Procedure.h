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
    
    bool InsertParameter(Variable*);
    bool HasDuplicateParameter(const Variable*);
    
    Variable* GetReturnType();
    void SetReturnType(Variable*);
    
    string ToString() const;
    string CString() const;

private:
    // Vector holding pointers to Variables that represent the parameters 
    // of this procedure
    vector<Variable*> parameters;
    Variable* return_data;
    
};
