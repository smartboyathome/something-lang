// MetaType.h
// Abstract superclass that other identMetaTypes 
#pragma once
#include <iostream>
#include <string>

using namespace std;

// This is needed since in C++ there's no type checking.
enum MetaTypeType
{
    ARRAY,
    CONSTANT,
    PROCEDURE,
    VARIABLE,
    VARIABLE_TYPE
};

class MetaType {
public:
	// Constructor takes the name and a value
	MetaType(const string name, MetaTypeType);	
	~MetaType();
	
	// Returns int: -1 for less, 0 for equal, 1 for greater
	int Compare(const MetaType &rhs) const;
	
	// gets string name
	string GetName();
	
	// Pure virtual string-producing files
	virtual string ToString() const = 0;
	virtual string CString() const = 0;
	
	// Operator overloading for 'equals'
	friend bool operator==(const MetaType &lhs, const MetaType &rhs);	
	
	
protected:	// Not private, grants access to the subclasses
	string identifier;		// The name of the MetaType
	MetaTypeType metatype;
};
