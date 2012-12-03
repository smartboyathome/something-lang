#pragma once
#include "IdentTypes/Variable.h"
#include "IdentTypes/MetaType.h"
#include "IdentTypes/VariableType.h"

class OutputFunctor
{
private:
    int scope_level;
public:
    OutputFunctor(int);
    string make_indent();
    string get_c_type(VariableType*);
    string get_c_value(VariableType*);
    virtual string operator() () = 0;
}

class ConstDefOutput : public OutputFuctor
{
private:
    Variable* var;
public:
    ConstDefOutput(int, Variable*);
    string operator() ();
}

class TypeDefOutput : public OutputFuctor
{
private:
    VariableType* var;
public:
    TypeDefOutput(int, VariableType*);
    string operator() ();
}

class VarDefOutput : public OutputFuctor
{
private:
    Variable* var;
public:
    VarDefOutput(int, Variable*);
    string operator() ();
}
