// Array.h
#pragma once
#include "MetaType.h"

class Array:public MetaType {
public:
	Array(const string name);
	~Array();
	
	void AddDimension(string, string);
	void SetType(string);
	
	string ToString() const;
	string CString() const;

private:
	// RangeStruct allows us to hold a vector of 'low' and 'high' values
	struct RangeStruct {
		string low;		// Low value 
		string high;	// .. High value
	}
	vector <RangeStruct> ranges;	// Vector holding ranges
	
	int dimensions; // Count of dimensions (1d, 2d, 3d, etc)
	
	/* As shown in the testoutput, Arrays must show what 
	   kind of value they contain */
	string type;	
	
};
