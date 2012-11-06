// VariableType.cpp
#include "VariableType.h"

// Constructor
VariableType::VariableType(const VarType varType) : MetaType(name, VARIABLE_TYPE) {
	this->var_type = varType;
}

VariableType::~VariableType() {}

string VariableType::GetType() {
	switch (var_type) {
		case INTEGER:
			return "integer";
			break;
		case BOOLEAN:
			return "Boolean";
			break;
		case REAL:
			return "real";
			break;
		case CHAR:
			return "char";
			break;
	}
}
