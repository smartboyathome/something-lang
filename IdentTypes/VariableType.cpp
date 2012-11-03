// VariableType.cpp
#include "VariableType.h"

// Constructor
VariableType::VariableType(const string typeName) {

/* Note: I have no idea what I'm doing here. 
	If these four types are even the four we want, if they're even the proper
	names, if strcmp is even the right thing... Whatever... General idea...
*/
	if (strcmp(typeName, "integer") == 0 ||
		strcmp(typeName, "real") == 0 ||
		strcmp(typeName, "character" == 0 ||
		strcmp(typeName, "boolean" == 0)
		my_type = typeName;
	else
		my_type = "";	// Or maybe it should be "NULL" ?
}

VariableType::~VariableType() {}

string VariableType::GetType() {
	return my_type;
}