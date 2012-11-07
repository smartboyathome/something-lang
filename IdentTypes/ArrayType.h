#pragma once
#include <map>
#include <vector>
#include "MetaType.h"
#include "VariableType.h"

struct AcceptedTypes
{
    enum Types
    {
        NONE,
        CHAR,
        INT
    };
};

class Range : VariableType
{

};

class IntRange : Range
{
public:
    IntRange(const string, int, int);
    string ToString() const;
    string CString() const;
    int GetLow();
    int GetHigh();
private:
    int low;
    int high;
};

class CharRange : Range
{
public:
    IntRange(const string, char, char);
    string ToString() const;
    string CString() const;
    char GetLow();
    char GetHigh();
private:
    int low;
    int high;
};

class ArrayDimension
{
public:
    ArrayDimension(Variable*);
    ArrayDimension(ArrayDimension*);
    Variable* GetValue();
    ArrayDimension* GetDimension();
    bool SetValue(Variable*);
    bool SetDimension(ArrayDimension*);
    bool IsDimension();
    bool IsValue();
private:
    Variable* value;
    Range range;
    ArrayDimension* next_dimension;
};

class ArrayType : public VariableType
{
public:
    ArrayType(const string);
    ~ArrayType();
    
    string ToString() const;
    string CString() const;
    
    bool AddDimension(int, int);
    bool AddDimension(char, char);
    
    void SetType(VariableType*);
    VariableType* GetType();
    
    bool SetIndex(int, Variable*);
    bool SetIndex(char, Variable*);
    
    pair<bool, Variable*> GetIndex(int);
    pair<bool, Variable*> GetIndex(char);
private:
    map<int, ArrayDimension> array;
    vector<Range> ranges;
    AcceptedTypes.Types key_type;
    VariableType* value_type;
};
