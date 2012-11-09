// Array.cpp
#include "Array.h"

Range::Range(int low, int high)
{
    if(low > high)
    {
        int temp = low;
        low = high;
        high = low;
    }
    this->low = low;
    this->high = high;
}

// Constructor
ArrayType::ArrayType(const string name) : VariableType(name, VarTypes::ARRAY) {
    my_type = NULL;
}

// Destructor
// Clears out "ranges" vector
ArrayType::~ArrayType() {
    ranges.clear();
}

// Create a new dimension and set low/high values
void ArrayType::AddDimension(int low, int high) {
    ranges.push_back(Range(low, high));    // Add Range to end
}


// Set the type of the variable using the VariableType object
void ArrayType::SetType(VariableType* varType) {
    my_type = varType;
}
    
// Return a string representation of this object
string ArrayType::ToString() const {
    // No valid type recorded
    /*if ( VariableType == NULL ) 
        return "ERROR: 'type' of " + identifier + " was not set.\n";*/
    
    string s = identifier + " ";
    
    // Creating "low..high, low..high, low..high"
    for (int x = 0; x < ranges.size(); x++) {
        s += ranges[x].low + ".." + ranges[x].high;
        
        if (x < ranges.size()-1)    // Smart commas
            s += ", ";
    }
    
    //s += type;
    
    return s;
}

// Return a C-formatted string representation of this object
string ArrayType::CString() const {
    return "";
}
