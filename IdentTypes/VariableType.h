// VariableType.h
#pragma once
#include "MetaType.h"

// The four basic variable types
enum VarType {
	INTEGER,
	BOOLEAN,
	REAL,
	CHAR
};

class VariableType:public MetaType {
public:
	// Constructor takes a VarType, "INTEGER", "BOOLEAN", "REAL", or "CHAR"
	VariableType(const VarType type);
	~VariableType();
	
	string GetVarType();	// Returns a string representation of the type
	
private:
	VarType var_type;
};
