// VariableType.h
#pragma once
#include "MetaType.h"
#include <sstream>
using namespace std;

// The four basic variable types
struct VarTypes
{
    enum Type {
        NIL,
        INTEGER,
        BOOLEAN,
        REAL,
        STRING,
        ARRAY,
        POINTER,
        RECORD
    };
    static string ToString(Type);
};

class VariableType:public MetaType {
public:
    VariableType(string name, const VarTypes::Type type);
    ~VariableType();
    
    VarTypes::Type GetEnumType();    // Returns a string representation of the type
    
private:
    VarTypes::Type var_type;
};

// IntegerType ----------------------------------------------------------------
class IntegerType : public VariableType
{
public:
    IntegerType(string);
    IntegerType(string, int);
    int GetValue();
    void SetValue(int);
    
    string ToString() const;
    string CString() const;
private:
    int value;
};

// BooleanType ----------------------------------------------------------------
class BooleanType : public VariableType
{
public:
    BooleanType();          // defaults to true
    BooleanType(string);
    BooleanType(string, string);    // String for 'true' and 'false'
    BooleanType(string, int);       // for 0 and 1
    bool GetValue();
    void SetValue(string);
    void SetValue(int);
    
    string ToString() const;
    string CString() const;
private:
    bool value;
};

// RealType -------------------------------------------------------------------
class RealType : public VariableType
{
public:
    RealType();
    RealType(string);
    RealType(string, double);
    double GetValue();
    void SetValue(double);  
    
    string ToString() const;
    string CString() const;
private:
    double value;
};

// StringType -----------------------------------------------------------------
class StringType : public VariableType
{
public:
    StringType();
    StringType(string);
    StringType(string, string);
    string GetValue();
    void SetValue(string);
    
    string ToString() const;
    string CString() const;
private:
    string value;
    
};
