// Procedure.h
#pragma once
#include "Type.h"
#include <vector>

class Procedure:public Type {
public:
	Procedure(const string name);
	~Procedure();
	
	bool InsertParameter(Variable*);
	bool HasDuplicateParameter(const Variable*);
	
	string ToString() const;
	string CString() const;

private:
	// Vector holding pointers to Variables that represent the parameters 
	// of this procedure
	vector<Variable*> parameters;
	
};
