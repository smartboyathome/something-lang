// Variable.cpp
#include "Variable.h"

// Constructor
// Takes a string name (identifier)
Variable::Variable(const string name) : MetaType(name, VARIABLE) {
    variable_value = "";
}

// Constructor
// Takes a string name (identifier) and a string value
Variable::Variable(const string name, const string value) : MetaType(name, VARIABLE) {
    variable_value = value;
}

// Destructor
Variable::~Variable() {
}

// Set the value
void Variable::SetValue(string value) {
    variable_value = value;
}

// Set the type of the variable using the VariableType object
void Variable::SetVarType(VariableType* varType) {
    my_type = varType;
}

VariableType* Variable::GetVarType()
{
    return my_type;
}

// Get a value
string Variable::GetValue() {
    return variable_value;
}

// Return a string representation of this object
string Variable::ToString() const {

            // If this variable has no set value...
    if (variable_value.empty())
        return identifier;    
    else    // This variable has a set value, print it out as well
        return identifier + " " + variable_value;
}

// Return a C-formatted string representation of this object
string Variable::CString() const {
    return "";
}
