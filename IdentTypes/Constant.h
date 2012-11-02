// Constant.h
#pragma once
#include "Type.h"

class Constant:public Type {
public:
	Constant(const string name, const string value);
	~Constant();
	
	string GetValue();
	
	string ToString() const;
	string CString() const;
	
private:
	string constant_value;

}