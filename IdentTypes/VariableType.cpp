// VariableType.cpp
#include "VariableType.h"

string VarTypes::ToString(Type type)
{
    string StringTypes[] = {
        "NIL",
        "INTEGER",
        "BOOLEAN",
        "REAL",
        "STRING",
        "ARRAY",
        "POINTER",
        "RECORD"
    };
    if((int)type >= 0 && (int)type <= 7)
        return StringTypes[type];
    else
    {
        stringstream ss;
        ss << (int)type;
        return ss.str();
    }
}

// Constructor
VariableType::VariableType(string name, const VarTypes::Type varType) : MetaType(name, VARIABLE_TYPE) {
    this->var_type = varType;
}

VariableType::~VariableType() {}

VarTypes::Type VariableType::GetEnumType() {return var_type;}

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
    return "int";
}

string IntegerType::CString(string var_name) const {
    stringstream ss;
    ss << "int " << var_name << " = " << value << ";";
    return ss.str();
}

// BooleanType ----------------------------------------------------------------
BooleanType::BooleanType() : VariableType("", VarTypes::BOOLEAN) {
    value = true;   // defaults to true
}     

BooleanType::BooleanType(string name) : VariableType(name, VarTypes::BOOLEAN) {
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
    return "bool";
}

string BooleanType::CString(string var_name) const {
    stringstream ss;
    ss << "bool " << var_name << " = " << boolalpha << value << ";";
    return "bool ";
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
    return "double";
}

string RealType::CString(string var_name) const {
    stringstream ss;
    ss << "double " << var_name << " = " << value << ";";
    return ss.str();
}

// StringType -----------------------------------------------------------------
StringType::StringType() : VariableType("", VarTypes::STRING) {
    value = "";
}
StringType::StringType(string name) : VariableType(name, VarTypes::STRING) {
    value = "";
}

StringType::StringType(string name, string value) : VariableType(name, VarTypes::STRING) {
    this->value = value;
}
    
string StringType::GetValue() {return value;}

void StringType::SetValue(string value) {this->value = value;}

string StringType::ToString() const {
    stringstream ss;
    ss << "\"" << value << "\"";
    return ss.str();
    
}
string StringType::CString() const {
    return "string";
}

string StringType::CString(string var_name) const {
    stringstream ss;
    ss << "string " << var_name << " = \"" << value << "\";";
    return ss.str();
}
