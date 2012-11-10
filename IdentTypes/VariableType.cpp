// VariableType.cpp
#include "VariableType.h"

// Constructor
VariableType::VariableType(string name, const VarTypes::Type varType) : MetaType(name, VARIABLE_TYPE) {
    this->var_type = varType;
}

VariableType::~VariableType() {}

VarTypes::Type VariableType::GetVarType() {return var_type;}

// IntegerType ----------------------------------------------------------------
IntegerType::IntegerType(string name) : VariableType(name, VarTypes::INTEGER) 
{
    value = 0;
}

IntegerType::IntegerType(string name, int value) : VariableType(name, VarTypes::INTEGER)
{
    this->value = value;
}

int IntegerType::GetValue() {return value;}

void IntegerType::SetValue(int value) {this->value = value;}

string IntegerType::ToString() const {
    stringstream ss;
    ss << value;
    return ss.str();
}

string IntegerType::CString() const {
    return "";
}

// BooleanType ----------------------------------------------------------------
BooleanType::BooleanType() : VariableType("", VarTypes::BOOLEAN) {
    value = true;   // defaults to true
}       

// String for 'true' and 'false'
BooleanType::BooleanType(string name, string input) : VariableType(name, VarTypes::BOOLEAN) {   
    SetValue(input);
}

// for 0 and 1 defined boolean values
BooleanType::BooleanType(string name, int input) : VariableType(name, VarTypes::BOOLEAN) {      
    SetValue(input);
}     

bool BooleanType::GetValue() {return value;}

void BooleanType::SetValue(int input) {
    if (input == 0)
        value = false;
    else    // Going by C++ standards, anything other than zero equals true
        value = true; 
}

void BooleanType::SetValue(string input) {
    if (input == "false")
        value = false;
    else    // We'll set the value to true with any other string value
        value = true;
}

string BooleanType::ToString() const {
    stringstream ss;
    ss << boolalpha << value;
    return ss.str();
}

string BooleanType::CString() const {
    return "";
}

// RealType -------------------------------------------------------------------
RealType::RealType() : VariableType("", VarTypes::REAL) {
    value = 0;
}

RealType::RealType(string name) : VariableType(name, VarTypes::REAL) {
    value = 0;
}

RealType::RealType(string name, double value) : VariableType(name, VarTypes::REAL) {
    this->value = value;
}

double RealType::GetValue() {return value;}

void RealType::SetValue(double value) {this->value = value;}

string RealType::ToString() const {
    stringstream ss;
    ss << value;
    return ss.str();
}
string RealType::CString() const {
    return "";
}

// StringType -----------------------------------------------------------------
StringType::StringType() : VariableType("", VarTypes::CHAR) {
    value = "";
}
StringType::StringType(string name) : VariableType(name, VarTypes::CHAR) {
    value = "";
}

StringType::StringType(string name, string value) : VariableType(name, VarTypes::CHAR) {
    this->value = value;
}
    
string StringType::GetValue() {return value;}

void StringType::SetValue(string value) {this->value = value;}

string IntegerType::ToString() const {
    stringstream ss;
    ss << "\"" << value << "\"";
    return ss.str();
    
}
string IntegerType::CString() const {
    return "";
}
