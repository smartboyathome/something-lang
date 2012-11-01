// Type.h
// Abstract superclass that other identTypes 
#pragma once
#include <iostream>
#include <string>

using namespace std;

class Type {
public:
	// Constructor takes the name and a value
	Type(const string name);	
	~Type();
	
	// Returns int: -1 for less, 0 for equal, 1 for greater
	int Compare(const Type &rhs) const;
	
	// gets string name
	string GetName();
	
	// Pure virtual string-producing files
	virtual string ToString() const = 0;
	virtual string CString() const = 0;
	
	bool operator==(const Type &rhs) const;	
	
	
protected:	// Not private, grants access to the subclasses
	string identifier;		// The name of the Type
	
};
