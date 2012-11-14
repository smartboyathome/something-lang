// Pointer.h
#pragma once
#include "MetaType.h"
#include "VariableType.h"

class Pointer:public VariableType {
public:
    Pointer(const string name);
    Pointer(const string name, const string type);
    ~Pointer();
    
    string GetTypeIdentifier();
    void SetTypePtr(VariableType *type);
    VariableType* GetTypePtr();
    
    string ToString() const;
    string CString() const;

private:
    string name;
    string type_identifier;
    VariableType* my_type;
};

class NilType : public Pointer
{
public:
    NilType();
    NilType(string);
    string ToString() const;
    string CString() const;
};
