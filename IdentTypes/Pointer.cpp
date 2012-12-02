// Pointer.cpp
#include "Pointer.h"

// Constructor
Pointer::Pointer(const string name, const string type) : VariableType(name, VarTypes::POINTER) {
    type_identifier = type;
    my_type = NULL;
}

Pointer::Pointer(const string name) : VariableType(name, VarTypes::POINTER)
{
    type_identifier = "nil";
    my_type = NULL;
}

// Destructor
Pointer::~Pointer() {}

// SetTypePtr
void Pointer::SetTypePtr(VariableType *type) {
    my_type = type;
}

// GetTypePtr
VariableType* Pointer::GetTypePtr()
{
    return my_type;
}

// GetTypeIdentifier
string Pointer::GetTypeIdentifier()
{
    return type_identifier;
}

// Return a string representation of this object
string Pointer::ToString() const {
    return "^" + type_identifier;
}

// Return a C-formatted string representation of this object
string Pointer::CString() const {
    return "";
}

string Pointer::CString(string var_name) const {
    return "";
}

// NilType --------------------------------------------------------------------
NilType::NilType() : Pointer("nil")
{
    
}

NilType::NilType(string name) : Pointer(name)
{
    
}

string NilType::ToString() const
{
    return "nil";
}

string NilType::CString() const
{
    return "NULL";
}

string NilType::CString(string var_name) const {
    return "";
}
