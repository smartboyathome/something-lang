// Variable.cpp
#include "Variable.h"

// Constructor
// Takes a string name (identifier)
Variable::Variable(const string name) {
	identifier = name;
	variable_value = "";
}

// Constructor
// Takes a string name (identifier) and a string value
Variable::Variable(const string name, const string value) {
	identifier = name;
	variable_value = value;
}

// Destructor
Variable::~Variable() {
}

// Set the value
bool Variable::SetValue(string value) {
	variable_value = value;
}

// Get a value
string Variable::GetValue() {
	return variable_value;
}

// Return a string representation of this object
string Variable::ToString() const {

			// If this variable has no set value...
	if ( strcmp(variable_value, "") == 0)
		return identifier;	
	else	// This variable has a set value, print it out as well
		return identifier + " " + variable_value;
}

// Return a C-formatted string representation of this object
string Variable::CString() const {
	return "";
}
