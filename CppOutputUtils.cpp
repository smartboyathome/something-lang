#include "CppOutputUtils.h"

// ---------------- OutputFunctor ---------------------------------------------

OutputFunctor::OutputFunctor(int the_scope_level)
{
    scope_level = the_scope_level;
}

string OutputFunctor::make_indent()
{
    stringstream ss;
    for(int i = 0; i < scope_level; ++i)
        ss << "    ";
    return ss.str();
}

string OutputFunctor::get_c_type(VariableType* the_type)
{
    VarTypes::Type enum_type = the_type->GetEnumType();
    if(enum_type == VarTypes::INTEGER)
    {
        return "int";
    }
    else if(enum_type == VarTypes::BOOLEAN)
    {
        return "bool";
    }
    else if(enum_type == VarTypes::REAL)
    {
        return "double";
    }
    else if(enum_type == VarTypes::STRING)
    {
        return "string";
    }
    else if(enum_type == VarTypes::ARRAY)
    {
        ArrayType* array = (ArrayType*)the_type;
        stringstream ss;
        ss << get_c_type(array->GetArrayType());
        for(int i = 0; i < array->ranges.size(); ++i)
        {
            ss << "[";
            if(array->ranges[i].rangeType == AcceptedTypes::INT)
            {
                ss << array->ranges[i].intHigh - array->ranges[i].intLow + 1;
            }
            else if(array->ranges[i].rangeType == AcceptedTypes::CHAR)
            {
                ss << (int)(array->ranges[i].charHigh - array->ranges[i].charLow + 1);
            }
            ss << "]";
        }
        return ss.str();
    }
    else if(enum_type == VarTypes::POINTER)
    {
        Pointer* pointer = (Pointer*)the_type;
        if(pointer->GetName() == "nil")
            return "void";
        stringstream ss;
        ss << pointer->GetTypeIdentifier() << "*";
        return ss.str();
    }
    else
    {
        return the_type->GetName();
    }
}

string OutputFunctor::get_c_value(VariableType* the_type)
{
    VarTypes::Type enum_type = the_type->GetEnumType();
    if(enum_type == VarTypes::INTEGER)
    {
        stringstream ss;
        ss << ((IntegerType*)the_type)->GetValue();
        return ss.str();
    }
    else if(enum_type == VarTypes::BOOLEAN)
    {
        stringstream ss;
        ss << boolalpha << ((BooleanType*)the_type)->GetValue();
        return ss.str();
    }
    else if(enum_type == VarTypes::REAL)
    {
        stringstream ss;
        ss << ((RealType*)the_type)->GetValue();
        return ss.str();
    }
    else if(enum_type == VarTypes::STRING)
    {
        stringstream ss;
        ss << "\"" << ((StringType*)the_type)->GetValue() << "\"";
        return ss.str();
    }
    else if(enum_type == VarTypes::ARRAY)
    {
        // TODO: Implement this
        return "";
    }
    else if(enum_type == VarTypes::POINTER)
    {
        // TODO: Implement this
        return "";
    }
    else if(enum_type == VarTypes::RECORD)
    {
        // TODO: Implement this
        return "";
    }
    else
    {
        return "";
    }
}

// ---------------- ConstDefOutput --------------------------------------------

ConstDefOutput::ConstDefOutput(int the_scope_level, Variable* the_var) :
    OutputFunctor(the_scope_level)
{
    var = the_var;
}

string ConstDefOutput::operator() ()
{
    stringstream ss;
    ss << make_indent();
    ss << "const " << get_c_type(var->GetVarType()) << " " << var->GetName();
    ss << " = " << get_c_value(var->GetVarType()) << ";";
    return ss.str();
}

// ---------------- TypeDefOutput ---------------------------------------------

TypeDefOutput::TypeDefOutput(int the_scope_level, VariableType* the_var_type) :
    OutputFunctor(the_scope_level)
{
    var_type = the_var_type;
}

string TypeDefOutput::operator() ()
{
    if(var_type->GetEnumType() == VarTypes::RECORD)
    {
        return RecordOutput();
    }
    else
    {
        return OtherOutput();
    }
}

string TypeDefOutput::RecordOutput()
{
    stringstream ss;
    Record* record = (Record*)var_type;
    ss << make_indent() << "struct " << record->GetName() << endl;
    ss << make_indent() << "{" << endl;
    ++scope_level;
    for(int i = 0; i < record->members.size(); ++i)
    {
        ss << make_indent();
        ss << get_c_type(record->members[i]->GetVarType()) << " " << record->members[i]->GetName() << ";";
        ss << endl;
    }
    --scope_level;
    ss << make_indent() << "};";
    return ss.str();
}

string TypeDefOutput::OtherOutput()
{
    stringstream ss;
    ss << make_indent();
    ss << "typedef " << get_c_type(var_type);
    ss << " " << var_type->GetName();
    ss << ";";
    return ss.str();
}

// ---------------- VarDefOutput ----------------------------------------------

VarDefOutput::VarDefOutput(int the_scope_level, Variable* the_var) :
    OutputFunctor(the_scope_level)
{
    var = the_var;
}

string VarDefOutput::operator() ()
{
    stringstream ss;
    ss << make_indent();
    ss << get_c_type(var->GetVarType()) << " " << var->GetName() << ";";
    return ss.str();
}

// ---------------- SubprogDefOutput ------------------------------------------

SubprogDefOutput::SubprogDefOutput(int the_scope_level, Procedure* the_proc) :
    OutputFunctor(the_scope_level)
{
    proc = the_proc;
}

string SubprogDefOutput::operator() ()
{
    stringstream ss;
    ss << get_c_type(proc->GetReturnType()->GetVarType());
    ss << " " << proc->GetName() << "(";
    bool first = true;
    for(int i = 0; i < proc->parameters.size(); ++i)
    {
        if(!first)
            ss << ", ";
        else
            first = false;
        ss << get_c_type(proc->parameters[i]->GetVarType());
        ss << " " << proc->parameters[i]->GetName();
    }
    ss << ")";
    return ss.str();
}

string SubprogDefOutput::BeginBlock()
{
    return "{";
}

string SubprogDefOutput::EndBlock()
{
    return "};";
}
