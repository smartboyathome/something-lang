// Array.h
#pragma once
#include "MetaType.h"
#include <vector>

class Array:public MetaType {
public:
	Array(const string);
	~Array();
	
	bool AddDimension(int, int);
	bool AddDimension(char, char);
	
	void SetType(VariableType* varType);
	
	string ToString() const;
	string CString() const;

	
	// Range allows us to hold a vector of 'low' and 'high' values
	struct Range {
		char charLow;
		char charHigh;
		
		int intLow;
		int intHigh;
	};
	
	struct AcceptedTypes {
		enum Types {
			NONE,
			CHAR,
			INT
		};
	};
	
private:
	int key_type;			// Tracking ints vs chars
	vector <Range> ranges;	// Vector holding ranges
	
	int dimensions; // Count of dimensions (1d, 2d, 3d, etc)
	int array_dimensions;	// Track the size of the array to hold each entry
	int get_array_dimensions();	// Use a simple algorithm
	
	/* As shown in the testoutput, Arrays must show what 
	   kind of value they contain */
	VariableType* my_type;	
	
};
