#pragma once
#include "IdentTypes/Variable.h"
#include "IdentTypes/MetaType.h"
#include "IdentTypes/VariableType.h"
#include "IdentTypes/Array.h"
#include "IdentTypes/Pointer.h"
#include "IdentTypes/Record.h"
#include "IdentTypes/Procedure.h"

class OutputFunctor
{
protected:
    int scope_level;
    string make_indent();
public:
    OutputFunctor(int);
    string get_c_type(VariableType*);
    string get_c_value(VariableType*);
    virtual string operator() () = 0;
};

class ConstDefOutput : public OutputFunctor
{
private:
    Variable* var;
public:
    ConstDefOutput(int, Variable*);
    string operator() ();
};

class TypeDefOutput : public OutputFunctor
{
private:
    VariableType* var_type;
    string RecordOutput();
    string OtherOutput();
public:
    TypeDefOutput(int, VariableType*);
    string operator() ();
};

class VarDefOutput : public OutputFunctor
{
private:
    Variable* var;
public:
    VarDefOutput(int, Variable*);
    string operator() ();
};

class SubprogDefOutput : public OutputFunctor
{
private:
    Procedure* proc;
public:
    SubprogDefOutput(int, Procedure*);
    string operator() ();
    string BeginBlock();
    string EndBlock();
};
