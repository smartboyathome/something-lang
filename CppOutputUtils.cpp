#include "CppOutputUtils.h"

// ---------------- OutputFunctor ---------------------------------------------

OutputFunctor::OutputFunctor(int the_scope_level)
{
    scope_level = the_scope_level;
}

string OutputFunctor::make_indent()
{
    return make_indent(scope_level);
}

string OutputFunctor::make_indent(int level)
{
    stringstream ss;
    for(int i = 0; i < level; ++i)
        ss << "    ";
    return ss.str();
}

string OutputFunctor::get_c_type(VariableType* the_type, bool is_output)
{
    VarTypes::Type enum_type = the_type->GetEnumType();
    string retval;
    if(enum_type == VarTypes::INTEGER)
    {
        retval =  "int";
    }
    else if(enum_type == VarTypes::BOOLEAN)
    {
        retval =  "bool";
    }
    else if(enum_type == VarTypes::REAL)
    {
        retval =  "double";
    }
    else if(enum_type == VarTypes::STRING)
    {
        string value = ((StringType*)the_type)->GetValue();
        if(value.length() == 1)
            retval = "char";
        else
            retval =  "string";
    }
    else if(enum_type == VarTypes::POINTER)
    {
        Pointer* pointer = (Pointer*)the_type;
        if(pointer->GetName() == "nil")
            retval =  "void";
        else
        {
            stringstream ss;
            if(pointer->GetTypePtr() != NULL && pointer->GetTypePtr()->GetName() != "nil")
            {
                ss << get_c_func_type(pointer->GetTypePtr()) << "*";
            }
            else
            {
                ss << pointer->GetTypeIdentifier() << "*";
            }
            retval =  ss.str();
            //retval = pointer->GetTypeIdentifier() + "*";
        }
    }
    else if(enum_type == VarTypes::RECORD)
    {
        retval =  the_type->GetName();
    }
    else
    {
        retval =  "";
    }
    if(is_output)
        retval += "*";
    return retval;
}

string OutputFunctor::create_array_indexes(ArrayType* array)
{
    stringstream ss;
    for(int i = 0; i < array->ranges.size(); ++i)
    {
        ss << "[";
        if(array->ranges[i].rangeType == AcceptedTypes::INT)
        {
            ss << array->ranges[i].intHigh + 1;
        }
        else if(array->ranges[i].rangeType == AcceptedTypes::CHAR)
        {
            ss << (int)(array->ranges[i].charHigh + 1);
        }
        ss << "]";
    }
    return ss.str();
}

string OutputFunctor::get_c_func_type(VariableType* the_type)
{
    VarTypes::Type enum_type = the_type->GetEnumType();
    if(enum_type == VarTypes::ARRAY)
    {
        ArrayType* array = (ArrayType*)the_type;
        stringstream ss;
        ss << get_c_func_type(array->GetArrayType());
        ss << create_array_indexes(array);
        return ss.str();
    }
    else
    {
        return get_c_type(the_type, false);
    }
}

string OutputFunctor::get_c_var_type(Variable* the_var)
{
    
    VarTypes::Type enum_type = the_var->GetVarType()->GetEnumType();
    if(enum_type == VarTypes::ARRAY)
    {
        ArrayType* array = (ArrayType*)the_var->GetVarType();
        stringstream ss;
        ss << get_c_func_type(array->GetArrayType());
        ss << " " << the_var->GetName();
        ss << create_array_indexes(array);
        return ss.str();
    }
    if(enum_type == VarTypes::POINTER)
    {
        Pointer* ptr = (Pointer*)the_var->GetVarType();
        if(ptr->GetTypePtr()->GetEnumType() == VarTypes::ARRAY)
        {
            ArrayType* array = (ArrayType*)ptr->GetTypePtr();
            stringstream ss;
            Variable* new_var = new Variable("(*"+the_var->GetName()+")");
            new_var->SetVarType(array);
            ss << get_c_var_type(new_var);
            return ss.str();
        }
        else
        {
            return get_c_type(the_var->GetVarType(), false) + " " + the_var->GetName();
        }
    }
    else
    {
        return get_c_type(the_var->GetVarType(), false) + " " + the_var->GetName();
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
        string value = ((StringType*)the_type)->GetValue();
        if(value.length() == 1)
            return "'" + value + "'";
        else
            return "\"" + value + "\"";
    }
    else if(enum_type == VarTypes::ARRAY)
    {
        stringstream ss;
        ArrayType* array = (ArrayType*)the_type;
        ss << "new " << get_c_func_type(array) << "()";
        return ss.str();
    }
    else if(enum_type == VarTypes::POINTER)
    {
        Pointer* pointer = (Pointer*)the_type;
        stringstream ss;
        ss << "new " << get_c_value(pointer->GetTypePtr());
        return ss.str();
    }
    else if(enum_type == VarTypes::RECORD)
    {
        Record* record = (Record*)the_type;
        stringstream ss;
        ss << record->GetName() << "()";
        return ss.str();
    }
    else
    {
        return "xxx";
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
    ss << "const " << get_c_var_type(var);
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
    Record* record = (Record*)var_type;
    stringstream ss;
    ss << make_indent() << "struct " << record->GetName() << endl;
    ss << make_indent() << "{" << endl;
    ++scope_level;
    for(int i = 0; i < record->members.size(); ++i)
    {
        ss << make_indent();
        ss << get_c_var_type(record->members[i]) << ";";
        ss << endl;
    }
    --scope_level;
    ss << make_indent() << "};";
    return ss.str();
}

string TypeDefOutput::OtherOutput()
{
    Variable var(var_type->GetName());
    var.SetVarType(var_type);
    stringstream ss;
    ss << make_indent();
    ss << "typedef " << get_c_var_type(&var) << ";";
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
    ss << get_c_var_type(var) << ";";
    return ss.str();
}

// ---------------- SubprogDefOutput ------------------------------------------

SubprogDefOutput::SubprogDefOutput(int the_scope_level, Procedure* the_proc, bool this_has_return_type) :
    OutputFunctor(the_scope_level)
{
    proc = the_proc;
    has_return_type = this_has_return_type;
}

string SubprogDefOutput::operator() ()
{
    stringstream ss;
    if(has_return_type)
        ss << get_c_type(proc->GetReturnType()->GetVarType(), false);
    else
        ss << "void";
    ss << " " << proc->GetName() << "(";
    bool first = true;
    for(int i = 0; i < proc->parameters.size(); ++i)
    {
        if(!first)
            ss << ", ";
        else
            first = false;
        if(proc->parameters[i]->IsOutput())
        {
            Variable* new_var = new Variable(proc->parameters[i]->GetName());
            Pointer* new_ptr = new Pointer("");
            new_ptr->SetTypePtr(proc->parameters[i]->GetVarType());
            new_var->SetVarType(new_ptr);
            ss << get_c_var_type(new_var);
        }
        else
        {
            ss << get_c_var_type(proc->parameters[i]);
        }
    }
    ss << ")";
    return ss.str();
}

string SubprogDefOutput::BeginBlock()
{
    return make_indent() + "{";
}

string SubprogDefOutput::BeginBlock(int level)
{
    return make_indent(level) + "{";
}

string SubprogDefOutput::EndBlock()
{
    return make_indent() + "};";
}

string SubprogDefOutput::EndBlock(int level)
{
    return make_indent(level) + "};";
}

// ---------------- DequeOutputFunctor ----------------------------------------

DequeOutputFunctor::DequeOutputFunctor(int the_scope_level, deque<string> the_deque) :
    OutputFunctor(the_scope_level)
{
    output_deque = the_deque;
}

string DequeOutputFunctor::DequeToString()
{
    stringstream ss;
    while(!output_deque.empty())
    {
        ss << output_deque.front();
        output_deque.pop_front();
    }
    return ss.str();
}

// ---------------- AssignLeftOutput ------------------------------------------

AssignLeftOutput::AssignLeftOutput(int the_level, deque<string> the_deque) :
    DequeOutputFunctor(the_level, the_deque)
{

}

string AssignLeftOutput::operator() ()
{
    stringstream ss;
    ss << make_indent() << DequeToString() << " = "; 
    return ss.str();
}

// ---------------- DesignatorOutput ------------------------------------------

DesignatorOutput::DesignatorOutput(int the_level, deque<string> the_deque) :
    DequeOutputFunctor(the_level, the_deque)
{

}

string DesignatorOutput::operator() ()
{
    stringstream ss;
    ss << DequeToString();
    return ss.str();
}

// ---------------- IntOutput -------------------------------------------------

IntOutput::IntOutput(int the_scope_level, int the_int_to_output) :
    OutputFunctor(the_scope_level)
{
    int_to_output = the_int_to_output;
}

string IntOutput::operator() ()
{
    stringstream ss;
    ss << int_to_output;
    return ss.str();
}

// ---------------- RealOutput ------------------------------------------------

RealOutput::RealOutput(int the_scope_level, double the_real_to_output) :
    OutputFunctor(the_scope_level)
{
    real_to_output = the_real_to_output;
}

string RealOutput::operator() ()
{
    stringstream ss;
    ss << real_to_output;
    return ss.str();
}

// ---------------- BooleanOutput ---------------------------------------------

BooleanOutput::BooleanOutput(int the_scope_level, bool the_bool_to_output) :
    OutputFunctor(the_scope_level)
{
    bool_to_output = the_bool_to_output;
}

string BooleanOutput::operator() ()
{
    stringstream ss;
    ss << boolalpha << bool_to_output;
    return ss.str();
}

// ---------------- StringOutput ----------------------------------------------

StringOutput::StringOutput(int the_scope_level, string the_string_to_output) :
    OutputFunctor(the_scope_level)
{
    string_to_output = the_string_to_output;
}

string StringOutput::operator() ()
{
    if(string_to_output.length() == 1)
        return "'" + string_to_output + "'";
    else
        return "\"" + string_to_output + "\"";
}

// ---------------- ProcedureCallOutput ---------------------------------------

ProcedureCallOutput::ProcedureCallOutput(int the_level, Procedure* the_proc) :
    OutputFunctor(the_level)
{
    proc = the_proc;
}

string ProcedureCallOutput::operator() ()
{
    stringstream ss;
    ss << proc->GetName() << "(";
    return ss.str();
}

// ---------------- ForStatementOutput ----------------------------------------

ForStatementOutput::ForStatementOutput(int the_level, Variable* the_new_var,
    string the_left_side, string the_right_side, bool the_up_to) :
    OutputFunctor(the_level)
{
    new_var = the_new_var;
    left_side = the_left_side;
    right_side = the_right_side;
    up_to = the_up_to;
}

string ForStatementOutput::operator() ()
{
    stringstream ss;
    
    ss << make_indent() << "for(" << get_c_var_type(new_var);
    ss << " = " << left_side << "; ";
    string less_than = up_to ? " <= " : " >= ";
    ss << new_var->GetName() << less_than << right_side << ";";
    string the_increment = up_to ? "++" : "--";
    ss << the_increment << new_var->GetName() << ")";
    return ss.str();
}
