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

struct ArrayDimensionTypes
{
    enum Types
    {
        NONE,
        VALUE,
        ARRAY_DIMENSION
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
    ArrayDimension();
    ~ArrayDimension();
    ArrayDimension(Variable*);
    ArrayDimension(ArrayDimension*);
    Variable* GetValue();
    pair<bool, ArrayDimension*> GetDimension(int);
    bool SetValue(Variable*);
    bool AddDimension(int, int);
    bool IsDimension();
    bool IsValue();
private:
    ArrayDimensionTypes.Types type;
    Variable* value;
    Range range;
    map<int, ArrayDimension*> next_dimension;
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
    bool AddDimensionLegal(int, int);
    map<int, ArrayDimension*> array;
    vector<Range> ranges;
    AcceptedTypes.Types key_type;
    VariableType* value_type;
};
