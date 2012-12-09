#pragma once
#include <deque>
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
    static string get_c_type(VariableType*, bool);
    static string create_array_indexes(ArrayType*);
public:
    OutputFunctor(int);
    static string get_c_func_type(VariableType*);
    static string get_c_var_type(Variable*);
    static string get_c_value(VariableType*);
    virtual string operator() () = 0;
    string make_indent();
    static string make_indent(int);
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
    bool has_return_type;
public:
    SubprogDefOutput(int, Procedure*, bool);
    string operator() ();
    string BeginBlock();
    static string BeginBlock(int);
    string EndBlock();
    static string EndBlock(int);
};

class DequeOutputFunctor : public OutputFunctor
{
private:
    deque<string> output_deque;
public:
    DequeOutputFunctor(int, deque<string>);
    string DequeToString();
};

class AssignLeftOutput : public DequeOutputFunctor
{
public:
    AssignLeftOutput(int, deque<string>);
    string operator() ();
};

class DesignatorOutput : public DequeOutputFunctor
{
public:
    DesignatorOutput(int, deque<string>);
    string operator() ();
};

class IntOutput : public OutputFunctor
{
private:
    int int_to_output;
public:
    IntOutput(int, int);
    string operator() ();
};

class RealOutput : public OutputFunctor
{
private:
    double real_to_output;
public:
    RealOutput(int, double);
    string operator() ();
};

class BooleanOutput : public OutputFunctor
{
private:
    bool bool_to_output;
public:
    BooleanOutput(int, bool);
    string operator() ();
};

class StringOutput : public OutputFunctor
{
private:
    string string_to_output;
public:
    StringOutput(int, string);
    string operator() ();
};

class ProcedureCallOutput : public OutputFunctor
{
private:
    Procedure* proc;
public:
    ProcedureCallOutput(int, Procedure*);
    string operator() ();
};

class ForStatementOutput : public OutputFunctor
{
private:
    Variable* new_var;
    string left_side;
    string right_side;
    bool up_to;
public:
    ForStatementOutput(int, Variable*, string, string, bool);
    string operator() ();
};
