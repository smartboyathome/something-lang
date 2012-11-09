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
    RANGE,
    VARIABLE,
    VARIABLE_TYPE,
	POINTER,
	RECORD,
	SET,
	INTEGER,
	STRING
};

class MetaType {
public:
	// Constructor takes the name and a MetaTypeType
	MetaType(const string name, MetaTypeType);
	~MetaType();
	
	// Returns int: -1 for less, 0 for equal, 1 for greater
	int Compare(const MetaType &rhs) const;
	
	// gets string name
	string GetName();
	MetaTypeType GetType();
	void SetName(string);
	
	// Pure virtual string-producing files
	virtual string ToString() const = 0;
	virtual string CString() const = 0;
	
	// Operator overloading for 'equals' and 'not equals'
	friend bool operator==(const MetaType &rhs)const;	
	friend bool operator!=(const MetaType &rhs)const;
	
protected:	// Not private, grants access to the subclasses
	string identifier;		// The name of the MetaType
	MetaTypeType metatype;
};
