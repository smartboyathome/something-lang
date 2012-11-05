// VariableType.cpp
#include "VariableType.h"

// Constructor
VariableType::VariableType(const string name) : MetaType(name, VARIABLE_TYPE) {

/* Note: I have no idea what I'm doing here. 
	If these four types are even the four we want, if they're even the proper
	names, if strcmp is even the right thing... Whatever... General idea...
*/
	type = name;
}

VariableType::~VariableType() {}

string VariableType::GetType() {
	return type;
}
