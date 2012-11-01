// Type.cpp
// Abstract superclass that other identTypes 

// Constructor
Type::Type() { // Not so sure about this, maybe not needed? -------
}

// Constructor (name)
Type::Type(const string& name) {
	Type_name = name;
}

// Destructor
Type::~Type() { } // Not sure if it'll need anything.

// Compare
// Takes an Type to be compared again and uses string == and > operators
// to return 1 for rhs > this, 0 for rhs == this, and -1 for else (rhs < this)
int Type::Compare(const Type& rhs) const {
	if (Type_name < rhs.Type_name)
		return 1;
	else if (Type_name == rhs.Type_name)
		return 0;
	else
		return -1;
}	

