// Pointer.h
#pragma once
#include "MetaType.h"

class Pointer:public MetaType {
public:
	Pointer(const string name);
	~Pointer();
	
	void SetObjectPtr(MetaType *obj);
	
	string ToString() const;
	string CString() const;

private:
	string name;
	MetaType* obj_ptr;
};
