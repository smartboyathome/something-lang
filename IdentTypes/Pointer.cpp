// Pointer.cpp
#include "Pointer.h"

// Constructor
Pointer::Pointer(const string name) : MetaType(name, POINTER) {
	
}

// Destructor
Pointer::~Pointer() {}

// SetObjectPtr
void Pointer::SetObjectPtr(MetaType *obj) {
	obj_ptr = obj;
}

// Return a string representation of this object
string ToString() const {
	return identifier + " ^ " + obj_ptr->GetName();
}

// Return a C-formatted string representation of this object
string CString() const {
	return "";
}
