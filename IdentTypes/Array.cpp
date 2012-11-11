// Array.cpp
#include "Array.h"
#include <sstream>
#include <math.h>


Range::Range() : MetaType("", RANGE)
{
    rangeType = AcceptedTypes::NONE;
}

Range::Range(int low, int high) : MetaType("", RANGE)
{
    rangeType = AcceptedTypes::INT;
    if(low > high) {
        int temp = low;
        low = high;
        high = low;
    }
    intLow = low;
    intHigh = high;
}

Range::Range(char low, char high) : MetaType("", RANGE)
{
    if (!('a' <= low && low <= 'z' && 'a' <= high && high <= 'z') 
	|| !('A' <= low && low <= 'Z' && 'A' <= high && high <= 'Z'))
        return;
        
    rangeType = AcceptedTypes::CHAR;
    if(low > high) {
        char temp = low;
        low = high;
        high = low;
    }
    charLow = low;
    charHigh = high;
}

string Range::ToString() const {
    stringstream ss;
    if (rangeType == AcceptedTypes::INT)
        ss << intLow << ".." << intHigh;
    else
        ss << "'" << charLow << "'..'" << charHigh << "'";
        
    return ss.str();
}

string Range::CString() const
{
    return "";
}

// Constructor
ArrayType::ArrayType(const string name) : VariableType(name, VarTypes::ARRAY) {
    my_type = new NilType("nil");
}

// Destructor
// Clears out "ranges" vector
ArrayType::~ArrayType() {
    ranges.clear();
}

// Create a new dimension and set low/high values (ints)
bool ArrayType::AddDimension(int low, int high) {
	
    // Filter with the array's stated type
	if (ranges.size() > 0 && ranges[0].rangeType != AcceptedTypes::INT)
        return false;	// Not acceptable
        
	ranges.push_back(Range(low, high));	// Add Range to end
	
	// Set the low and high values in the new Range
	ranges[ranges.size() - 1].intLow = low;
	ranges[ranges.size() - 1].intHigh = high;
	
	return true;
}

// Create a new dimension and set low/high values (chars)
bool ArrayType::AddDimension(char low, char high) {
	
    // Filter with the array's stated type
    if (ranges.size() > 0 && ranges[0].rangeType != AcceptedTypes::CHAR)
        return false;
	
	ranges.push_back(Range(low, high));	// Add Range to end
	
	// Set the low and high values in the new Range
	ranges[ranges.size() - 1].charLow = low;
	ranges[ranges.size() - 1].charHigh = high;

	return true;
}

bool ArrayType::AddDimension(Range range) {
	if(range.rangeType == AcceptedTypes::INT)
        return AddDimension(range.intLow, range.intHigh);
    else if(range.rangeType == AcceptedTypes::CHAR)
        return AddDimension(range.charLow, range.charHigh);
    else
        return false;
}

VariableType* ArrayType::GetArrayType()
{
    return my_type;
}

// Set the type of the variable using the VariableType object
void ArrayType::SetArrayType(VariableType* varType) {
    my_type = varType;
}
    
// Return a string representation of this object
string ArrayType::ToString() const {
    // No valid type recorded
    if ( my_type == NULL ) 
        return "ERROR: 'type' of " + identifier + " was not set.\n";
    
    stringstream ss;
    
    ss << identifier + " ";
    
    // Creating "low..high, low..high, low..high"
    for (int x = 0; x < ranges.size(); x++) {
        ss << ranges[x].ToString();
        
        if (x < ranges.size()-1)    // Smart commas
            ss << ", ";
    }
    
    ss << " of " << my_type->GetName();
    
    return ss.str();
}

// Return a C-formatted string representation of this object
string ArrayType::CString() const {
    return "";
}

// Find the size of a multi-dimensional array
int ArrayType::get_array_dimensions() {	
	if (ranges.size() == 0) 
		return 0;	// No work needed
		
	int sum = 0;
	if (ranges[0].rangeType == AcceptedTypes::INT) {	// Dealing with ints
		
		for (int x = 0; x < ranges.size(); x++) {
			sum += (int)((ranges[x].intHigh + 1 - ranges[x].intLow) 
							* pow(ranges.size(), (ranges.size() - 1 - x)));
		}
	} else {								// Dealing with chars
	
	/* Oh god, I need to look into more of this to see if this dangerously 
	flippant casting of ints into chars and vice versa is even possible...*/
		for (int x = 0; x < ranges.size(); x++) {
			sum += (int)((ranges[x].charHigh + 1 - ranges[x].charLow) 
							* pow(ranges.size(), (ranges.size() - 1 - x)));
		}
	}
	
	return sum;
}
