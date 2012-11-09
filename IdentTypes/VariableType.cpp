// VariableType.cpp
#include "VariableType.h"

// Constructor
VariableType::VariableType(string name, const VarTypes::Type varType) : MetaType(name, VARIABLE_TYPE) {
    this->var_type = varType;
}

VariableType::~VariableType() {}

VarTypes::Type VariableType::GetVarType() {
    return var_type;
}

IntegerType::IntegerType(string name, int value) : VariableType(name, VarTypes::BOOLEAN)
{
    this->value = value;
}

int IntegerType::GetValue()
{
    return value;
}

void IntegerType::SetValue(int value)
{
    this->value = value;
}
