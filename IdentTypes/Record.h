// Record.h
#pragma once
#include "MetaType.h"
#include "Variable.h"
#include <vector>

class Record:public MetaType {
public:
    Record(const string name);
    ~Record();
    
    bool InsertMember(Variable*);
    bool HasDuplicateMember(const Variable*);
    
    string ToString() const;
    string CString() const;

private:
    // Vector holding pointers to Variables that represent the members 
    // of this Record
    vector<Variable*> members;
};
