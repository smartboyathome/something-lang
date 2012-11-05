// Array.cpp
#include "Array.h"

// Constructor
Array::Array(const string name) : MetaType(name, ARRAY) {
	type = "";
	dimensions = 0;
}

// Destructor
// Clears out "ranges" vector
Array::~Array() {
	ranges.clear();
}

// Create a new dimension and set low/high values
void Array::AddDimension(string low, string high) {
	dimensions++;				// New dimension, increase dimensions by one
	ranges.push_back(RangeStruct());	// Add RangeStruct to end
	
	// Set the low and high values in the new RangeStruct
	ranges[dimensions - 1].low = low;
	ranges[dimensions - 1].high = high;
}

// Function to set type of variables the array uses
void Array::SetType(string inType) {
	type = inType;
}
	
// Return a string representation of this object
string Array::ToString() const {
	// No valid type recorded
	if ( strcmp(variable_value, "") == 0) 
		return "ERROR: 'type' of " + identifier + " was not set.\n";
	
	string s = identifier + " ";
	
	// Creating "low..high, low..high, low..high"
	for (int x = 0; x < ranges.size(); x++) {
		s += ranges[x].low + ".." + ranges[x].high;
		
		if (x < dimensions-1)	// Smart commas
			s += ", ";
	}
	
	s += type;
	
	return s;
}

// Return a C-formatted string representation of this object
string Array::CString() const {
	return "";
}
