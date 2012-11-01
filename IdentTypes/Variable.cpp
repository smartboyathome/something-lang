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

string Variable::ToString() const {
	// Note: No new line
	cout << identifier << " " << variable_value;

}

string Variable::CString() const {
	// For later
}