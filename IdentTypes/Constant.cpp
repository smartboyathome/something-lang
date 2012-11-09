// Constant.cpp
#include "Constant.h"


// Constructor
// Takes a string name, not yet a value.
Constant::Constant(const string name) : MetaType(name, CONSTANT) {
    constant_value = "";
}

// Constructor
// Takes a string name and string value
Constant::Constant(const string name, const string value) : MetaType(name, CONSTANT) {
    constant_value = value;
}

// Destructor
Constant::~Constant() {
}

// Get the value
string Constant::GetValue() {
    return constant_value;
}

// Return a string representation of this object
string Constant::ToString() const {
    return identifier + " " + constant_value;
}

// Return a C-formatted string representation of this object
string Constant::CString() const {
    return "";
}    
