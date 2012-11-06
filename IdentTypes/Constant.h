// Constant.h
#pragma once
#include "MetaType.h"

class Constant:public MetaType {
public:
	Constant(const string name);
	Constant(const string name, const string value);
	~Constant();
	
	string GetValue();
	
	string ToString() const;
	string CString() const;
	
private:
	string constant_value;
};
