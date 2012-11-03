// VariableType.h
#pragma once
#include "MetaType.h"

class VariableType:public MetaType {
	
	//TODO:
	/*
		This class will maintain the types of variables properly.
		I haven't figured out how this should work. But look at Variable's
		function "SetType" and its private VariableType object "my_type" to
		see where this will be used, I guess.
		
	*/
	
public:
	// Constructor takes a string (like "integer", "real", "boolean", "character")
	VariableType(const string typeName);
	~VariableType();
	
	string GetType();
	
private:
	string type;
};
