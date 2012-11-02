// MetaType.cpp
// Abstract superclass that other identMetaTypes 
#include "MetaType.h"

// Constructor with a name
MetaType::MetaType(const string name) : MetaType(name) {}

// Destructor
MetaType::~MetaType() { } // Not sure if it'll need anything.

// Compare
// Takes an MetaType to be compared again and uses string == and > operators
// to return 1 for rhs > this, 0 for rhs == this, and -1 for else (rhs < this)
int MetaType::Compare(const MetaType& rhs) const {
	if (identifier < rhs.identifier)
		return 1;
	else if (identifier == rhs.identifier)
		return 0;
	else
		return -1;
}	
// operator==
bool operator==(const MetaType &rhs) const {
	return Compare(rhs) == 0;
}

// gets string name
string GetName() {
	return identifier;
}
