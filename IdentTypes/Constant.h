// Constant.h
#pragma once
#include "MetaType.h"

class Constant:public MetaType {
public:

		/* QUESTION!
		By definition, is it not true that a constant is always defined with a value?
		So would it make any sense to have a Constructor that only accepted a name?
		Would this cause problems with inheritence to not have one, the kind that
		is defined in MetaType?
		*/
	Constant(const string name, const string value);
	~Constant();
	
	string GetValue();
	
	string ToString() const;
	string CString() const;
	
private:
	string constant_value;

};
