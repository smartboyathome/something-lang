// Variable.cpp
#include "Variable.h"

// Constructor
// Takes a string name (identifier)
Variable::Variable(const string name) 
: Type(name) {
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
	return identifier + " " + variable_value;
}

// Return a C-formatted string representation of this object
string Variable::CString() const {
	// For later
}