// Pointer.cpp
#include "Pointer.h"

// Constructor
Pointer::Pointer(const string name, const string type) : VariableType(name, VarTypes::POINTER) {
    type_identifier = type;
    my_type = NULL;
}

// Destructor
Pointer::~Pointer() {}

// SetObjectPtr
void Pointer::SetTypePtr(VariableType *type) {
    my_type = type;
}

string Pointer::GetTypeIdentifier()
{
    return type_identifier;
}

// Return a string representation of this object
string Pointer::ToString() const {
    return identifier + " ^" + type_identifier;
}

// Return a C-formatted string representation of this object
string Pointer::CString() const {
    return "";
}
