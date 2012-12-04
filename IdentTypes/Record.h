// Record.h
#pragma once
#include "MetaType.h"
#include "Variable.h"
#include "VariableType.h"
#include "Pointer.h"
#include <vector>

class Record:public VariableType {
public:
    Record(const string name);
    ~Record();
    
    bool InsertMember(Variable*);
    bool HasDuplicateMember(const Variable*);
    bool HasMember(string);
    Variable* GetMember(string);
    
    string ToString() const;
    string CString() const;
    string CString(string) const;


    // Vector holding pointers to Variables that represent the members 
    // of this Record
    vector<Variable*> members;
};
