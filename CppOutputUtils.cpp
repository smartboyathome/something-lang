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
    switch(the_type->GetEnumType())
    {
        case VarTypes::INTEGER:
            return "int";
        case VarTypes::BOOLEAN:
            return "bool";
        case VarTypes::REAL:
            return "double";
        case VarTypes::STRING:
            return "string";
        case VarTypes::ARRAY:
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
                else if(ranges[i].rangeType == AcceptedTypes::CHAR)
                {
                    ss << (int)(array->ranges[i].charHigh - array->ranges[i].charLow + 1);
                }
                ss << "]";
            }
            return ss.str();
        case VarTypes::POINTER:
            Pointer* pointer = (Pointer*)the_type;
            stringstream ss;
            ss << get_c_type(pointer->GetTypePtr()) << " *";
            return ss.str();
        default:
            return the_type->GetName();
    }
}

string OutputFunctor::get_c_value(VariableType* the_type)
{
    switch(the_type->GetEnumType())
    {
        case VarTypes::INTEGER:
            stringstream ss;
            ss << ((IntegerType*)the_type)->GetValue();
            return ss.str();
        case VarTypes::BOOLEAN:
            stringstream ss;
            ss << boolalpha << ((BooleanType*)the_type)->GetValue();
            return ss.str();
        case VarTypes::REAL:
            stringstream ss;
            ss << ((RealType*)the_type)->GetValue();
            return ss.str();
        case VarTypes::STRING:
            stringstream ss;
            ss << "\"" << ((StringType*)the_type)->GetValue() << "\"";
            return ss.str();
        case VarTypes::ARRAY:
            // TODO: Implement this
            return "";
        case VarTypes::POINTER:
            // TODO: Implement this
            return "";
        case VarTypes::RECORD:
            // TODO: Implement this
            return "";
    }
}

ConstDefOutput::ConstDefOutput(int the_scope_level, Variable* the_var) :
    public OutputFunctor(the_scope_level)
{
    var = the_var;
}

string ConstDefOutput::operator() ()
{
    stringstream ss;
    ss << "const " << get_c_type(var->GetVarType()) << " " << var->GetName();
    ss << " = " << get_c_value(var->GetVarType()) << ";";
}
