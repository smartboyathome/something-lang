// Array.cpp
#include "Array.h"

// Constructor
Array::Array(const string name) : MetaType(name, ARRAY) {
	key_type = AcceptedTypes.NONE;
	array_dimensions = 0;
	dimensions = 0;
}

// Destructor
// Clears out "ranges" vector
Array::~Array() {
	ranges.clear();
}

// Create a new dimension and set low/high values (ints)
void Array::AddDimension(int low, int high) {
	// Filter with the array's stated type
	if(key_type == AcceptedTypes.NONE)
        key_type = AcceptedTypes.INT;
    else if (key_type != AcceptedTypes.INT)
        return false;	// Not acceptable
		
	// If the orders are mixed-up, fix it
    if (high < low) {
        int temp = low;
        low = high;
        high = low;
    }
	
	dimensions++;				// New dimension, increase dimensions by one
	ranges.push_back(Range());	// Add Range to end
	
	// Set the low and high values in the new Range
	ranges[dimensions - 1].intLow = low;
	ranges[dimensions - 1].intHigh = high;
	
	// Update the dimensions level
	array_dimensions = get_array_dimensions();
	
	return true;
}

// Create a new dimension and set low/high values (chars)
bool ArrayType::AddDimension(char low, char high) {
	// Filter with the array's stated type
    if(key_type == AcceptedTypes.NONE)
        key_type = AcceptedTypes.CHAR;
    else if (key_type != AcceptedTypes.CHAR)
        return false;
    if (high < low)
    {
        char temp = low;
        low = high;
        high = low;
    }
	
    if (!('a' <= low && low <= 'z' && 'a' <= high && high <= 'z') 
	|| !('A' <= low && low <= 'Z' && 'A' <= high && high <= 'Z'))
        return false;
	
	dimensions++;				// New dimension, increase dimensions by one
	ranges.push_back(Range());	// Add Range to end
	
	// Set the low and high values in the new Range
	ranges[dimensions - 1].charLow = low;
	ranges[dimensions - 1].charHigh = high;
	
	// Update the dimensions level
	array_dimensions = get_array_dimensions();
	return true;
}



// Set the type of the variable using the VariableType object
bool Array::SetType(VariableType* varType) {
	my_type = varType;
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

// Find the size of a multi-dimensional array
int Array::get_array_dimensions() {	
	if (dimensions == 0) 
		return 0;	// No work needed
		
	
	int sum = 0;
	if (key_type == AcceptedTypes.INT) {	// Dealing with ints
		
		for (int x = 0; x < dimensions; x++) {
			sum += (int)((ranges[x].intHigh + 1 - ranges[x].intLow) 
							* pow(dimensions, (dimensions - 1 - x)));
		}
	} else {								// Dealing with chars
	
	/* Oh god, I need to look into more of this to see if this dangerously 
	flippant casting of ints into chars and vice versa is even possible...*/
		for (int x = 0; x < dimensions; x++) {
			sum += (int)((ranges[x].charHigh + 1 - ranges[x].charLow) 
							* pow(dimensions, (dimensions - 1 - x)));
		}
	}
	
	return sum;
}

