// Type.cpp
// Abstract superclass that other identTypes 
#include "Type.h"

// Constructor with a name
Type::Type(const string name) : Type(name) {}

// Destructor
Type::~Type() { } // Not sure if it'll need anything.

// Compare
// Takes an Type to be compared again and uses string == and > operators
// to return 1 for rhs > this, 0 for rhs == this, and -1 for else (rhs < this)
int Type::Compare(const Type& rhs) const {
	if (identifier < rhs.identifier)
		return 1;
	else if (identifier == rhs.identifier)
		return 0;
	else
		return -1;
}	
// operator==
bool operator==(const Type &rhs) const {
	return Compare(rhs) == 0;
}

// gets string name
string GetName() {
	return identifier;
}
