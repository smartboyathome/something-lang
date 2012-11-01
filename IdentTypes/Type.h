// Type.h
// Abstract superclass that other identTypes 

#ifndef Type_H
#define Type_H
#include <iostream>
#include <string>

using namespace std;

class Type {
public:
	// Constructor takes the name and a value
	Type(const string &name, const string value);	
	~Type();
	
	// This will differ for subclasses, so it's pure virtual
	virtual void Display(ostream &out) const = 0;
	
	// Returns int: -1 for less, 0 for equal, 1 for greater
	int Compare(const Type &rhs) const;
	
	// gets string name
	string GetName();
	
	// Set and "Get" values
	bool SetValue(string value);
	
	string ToString();
	string CString();
	
	/* Things I think that may come up:
		1. ==, <, and > operators? No, yeah, this will make things easier.
		
		2. Some sort of indentation function, one that receives scope levels?
		That way when doing display, we wouldn't have to put in the code every
		time that it was to print out to a line.
	*/
	
				// Had to look up the syntax for operator overload, hope these are right------
	bool operator==(const Type &rhs) const;	// I know we'll need ==... 
				// do we need < or >?
	//bool operator>(const Type &rhs) const;
	//bool operator<(const Type &rhs) const;
	
	
protected:	// Not private, grants access to the subclasses
	string Type_identifier;		// The name of the Type
	
};
#endif
