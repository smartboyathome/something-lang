// Variable.cpp
#include "Variable.h"

// Constructor
// Takes a string name (identifier)
Variable::Variable(const string name) : MetaType(name, VARIABLE) {
    is_const = false;
    is_output = false;
    variable_value = "";
    my_type = new NilType();
}

// Constructor
// Takes a string name (identifier) and a string value
Variable::Variable(const string name, const string value) : MetaType(name, VARIABLE) {
    is_const = false;
    is_output = false;
    variable_value = value;
    my_type = new NilType();
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

void Variable::ToggleConst()
{
    is_const = is_const? false : true;
}

bool Variable::IsConst()
{
    return is_const;
}

void Variable::ToggleOutput()
{
    is_output = is_output? false : true;
}

bool Variable::IsOutput()
{
    return is_output;
}

// Return a string representation of this object
string Variable::ToString() const {

            // If this variable has no set value...
    if (my_type == NULL)
        return "nil";    
    else    // This variable has a set value, print it out as well
        return my_type->ToString();
}

// Return a C-formatted string representation of this object
string Variable::CString() const {
    stringstream ss;
    if(is_const) ss << "const ";
    ss << my_type->CString(identifier);
    return ss.str();
}
