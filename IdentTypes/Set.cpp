// Set.cpp
#include "Set.h"

// Constructor
Set::Set(const string name) : MetaType(name, SET) {
	low = -1;
	high = -1;
}

// Destructor
Set::~Set() {}

// Write the range of this set
void Set::SetRange(int inLow, int inHigh) {
	low = inLow;
	high = inHigh;
}
	
// Return a string representation of this object
string Set::ToString() const {
	return identifier + " " + low + ".." + high;
}

// Return a C-formatted string representation of this object
string Set::CString() const {
	return "";
}
