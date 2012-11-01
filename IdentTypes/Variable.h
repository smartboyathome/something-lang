// Variable.h
#pragma once
#include "Type.h"

class Variable:public Type {
public:
	Variable(const string name);
	Variable(const string name, const string value);
	~Variable();
	
	bool SetValue(string value);
	
	string ToString() const;
	string CString() const;
	
private:
	string variable_value;
}