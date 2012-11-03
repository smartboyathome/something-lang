// MetaType.h
// Abstract superclass that other identMetaTypes 
#pragma once
#include <iostream>
#include <string>

using namespace std;

class MetaType {
public:
	// Constructor takes the name and a value
	MetaType(const string name);	
	~MetaType();
	
	// Returns int: -1 for less, 0 for equal, 1 for greater
	int Compare(const MetaType &rhs) const;
	
	// gets string name
	string GetName();
	
	// Pure virtual string-producing files
	virtual string ToString() const = 0;
	virtual string CString() const = 0;
	
	// Operator overloading for 'equals'
	bool operator==(const MetaType &rhs) const;	
	
	
protected:	// Not private, grants access to the subclasses
	string identifier;		// The name of the MetaType
	
};
