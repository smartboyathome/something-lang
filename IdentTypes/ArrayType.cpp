#pragma once
#include <map>
#include <vector>
#include <sstream>
#include "MetaType.h"
#include "ArrayType.h"

ArrayType::ArrayType(const string name) : MetaType(name, ARRAY)
{
    key_type = AcceptedTypes.NONE;
}

string ArrayType::ToString() const
{
    return "";
}

string ArrayType::CString() const
{
    return "";
}

bool ArrayType::AddDimensionLegal(int range_index, ArrayDimension*)
{
    
}

bool ArrayType::AddDimension(int low, int high)
{
    if(key_type == AcceptedTypes.NONE)
        key_type = AcceptedTypes.INT;
    else if (key_type != AcceptedTypes.INT)
        return false;
    if (high < low)
    {
        int temp = low;
        low = high;
        high = low;
    }
    ranges.push_back(IntRange("", low, high));
    for(int i = low; i <= high; ++i)
    {
        if(array.count(i) > 0)
            continue;
        array[i] = NULL;
    }
    return true;
}

bool ArrayType::AddDimension(char low, char high)
{
    if(key_type == AcceptedTypes.NONE)
        key_type = AcceptedTypes.CHAR;
    else if (key_type != AcceptedTypes.CHAR)
        return false;
    if (high < low)
    {
        char temp = low;
        low = high;
        high = low;
    }
    if (!('a' <= low && low <= 'z' && 'a' <= high && high <= 'z') || !('A' <= low && low <= 'Z' && 'A' <= high && high <= 'Z'))
        return false;
    ranges.push_back(CharRange("", low, high));
    for(char i = low; i <= high; ++i)
    {
        if(array.count(i) > 0)
            continue;
        array[i] = NULL;
    }
    return true;
}

void ArrayType::SetType(VariableType* type)
{
    value_type = type;
}

VariableType* ArrayType::GetType()
{
    return value_type;
}

bool ArrayType::SetIndex(int key, Variable* value)
{
    if (key_type != AcceptedTypes.INT || array.count(key) == 0)
        return false;
    array[key] = value;
}

bool ArrayType::SetIndex(char key, Variable* value)
{
    if (key_type != AcceptedTypes.CHAR || array.count(key) == 0)
        return false;
    array[key] = value;
}

pair<bool, Variable*> ArrayType::GetIndex(int key)
{
    if (key_type != AcceptedTypes.INT || array.count(key) == 0)
        return pair<bool, Variable*>(false, NULL);
    return pair<bool, Variable*>(true, array[key]);
}

pair<bool, Variable*> ArrayType::GetIndex(int key)
{
    if (key_type != AcceptedTypes.CHAR || array.count(key) == 0)
        return pair<bool, Variable*>(false, NULL);
    return pair<bool, Variable*>(true, array[key]);
}

IntRange::IntRange(const string name, int low, int high) : MetaType(name, RANGE)
{
    this->low = low;
    this->high = high;
}

string IntRange::ToString() const
{
    stringstream ss;
    ss << low << ".." << high;
    return ss.str();
}

string IntRange::CString() const
{
    return "";
}

int IntRange::GetLow()
{
    return low;
}

int IntRange::GetHigh()
{
    return high;
}

CharRange::CharRange(const string name, char low, char high) : MetaType(name, RANGE)
{
    this->low = low;
    this->high = high;
}

string CharRange::ToString() const
{
    stringstream ss;
    ss << "'" << low << "'..'" << high << "'";
    return ss.str();
}

string CharRange::CString() const
{
    return "";
}

char CharRange::GetLow()
{
    return low;
}

char CharRange::GetHigh()
{
    return high;
}

ArrayDimension::ArrayDimension()
{
    type = ArrayDimensionTypes.NONE;
    this->value = NULL;
    this->next_dimension = NULL;
}

ArrayDimension::ArrayDimension(Variable* value)
{
    type = ArrayDimensionTypes.VALUE;
    this->value = value;
    this->next_dimension = NULL;
}

ArrayDimension::ArrayDimension(ArrayDimension* next_dimension)
{
    type = ArrayDimensionTypes.ARRAY_DIMENSION;
    this->value = NULL;
    this->next_dimension = next_dimension;
}

ArrayDimension::~ArrayDimension()
{
    if(next_dimension != NULL)
        delete next_dimension;
}

Variable* ArrayDimension::GetValue()
{
    return this->value;
}

ArrayDimension* ArrayDimension::GetDimension()
{
    return this->next_dimension;
}

bool ArrayDimension::SetValue(Variable* value)
{
    if(IsUnset())
        type = ArrayDimensionTypes.VALUE;
    if(!IsValue())
        return false;
    this->value = value;
    return true;
}

bool ArrayDimension::AddDimension(int, int)
{
    if(IsUnset())
        type = ArrayDimensionTypes.ARRAY_DIMENSION;
    if(!IsDimension())
        return false;
    this->next_dimension = next_dimension;
    return true;
}

bool ArrayDimension::IsUnset()
{
    return type == ArrayDimensionTypes.NONE;
}

bool ArrayDimension::IsDimension()
{
    return type == ArrayDimensionTypes.ARRAY_DIMENSION;
}

bool ArrayDimension::IsValue()
{
    return type == ArrayDimensionTypes.VALUE;
}
