#include "GrammarUtils.h"

/*bool CheckAllErrors(int check_count, ErrorFunctor[] checks)
{
    if(checks == NULL || check_count <= 0)
        return false;
    for(int i = 0; i < check_count; ++i)
    {
        if(!checks[i]())
        {
            return false;
        }
    }
    return true;
}

ErrorCheck::ErrorCheck(ErrorFunctor the_functor, string the_error_str)
{
    functor = the_functor;
    error_str = the_error_str;
}*/

IsInScopeCheck::IsInScopeCheck(LocalScope* the_scope, string the_obj)
{
    scope = the_scope;
    obj = the_obj;
}

bool IsInScopeCheck::operator() ()
{
    bool retval = scope->IsInScope(obj) || scope->IsInScope(obj+"_");
    if(!retval)
        yyerror(("The object, '" + obj + "', is not in scope.").c_str());
    return retval;
}

NotIsInScopeCheck::NotIsInScopeCheck(LocalScope* the_scope, string the_obj)
{
    scope = the_scope;
    obj = the_obj;
}

bool NotIsInScopeCheck::operator() ()
{
    bool retval = !(scope->IsInScope(obj) || scope->IsInScope(obj+"_"));
    if(!retval)
        yyerror(("The object, '" + obj + "', is in scope").c_str());
    return retval;
}

IsInLocalScopeCheck::IsInLocalScopeCheck(LocalScope* the_scope, string the_obj)
{
    scope = the_scope;
    obj = the_obj;
}

bool IsInLocalScopeCheck::operator() ()
{
    bool retval = scope->IsInLocalScope(obj) || scope->IsInLocalScope(obj+"_");
    if(!retval)
        yyerror(("The object, '" + obj + "', is not in the local scope.").c_str());
    return retval;
}

NotIsInLocalScopeCheck::NotIsInLocalScopeCheck(LocalScope* the_scope, string the_obj)
{
    scope = the_scope;
    obj = the_obj;
}

bool NotIsInLocalScopeCheck::operator() ()
{
    bool retval = !(scope->IsInLocalScope(obj) || scope->IsInScope(obj+"_"));
    if(!retval)
        yyerror(("The object, '" + obj + "', is in local scope").c_str());
    return retval;
}

IsInParentScopeCheck::IsInParentScopeCheck(LocalScope* the_scope, string the_obj)
{
    scope = the_scope;
    obj = the_obj;
}

bool IsInParentScopeCheck::operator() ()
{
    bool retval = scope->IsInParentScope(obj) || scope->IsInParentScope(obj+"_");
    if(!retval)
        yyerror(("The object, '" + obj + "', is not in the parent scope.").c_str());
    return retval;
}

NotIsInParentScopeCheck::NotIsInParentScopeCheck(LocalScope* the_scope, string the_obj)
{
    scope = the_scope;
    obj = the_obj;
}

bool NotIsInParentScopeCheck::operator() ()
{
    bool retval = !(scope->IsInParentScope(obj) || scope->IsInScope(obj+"_"));
    if(!retval)
        yyerror(("The object, '" + obj + "', is in the parent scope").c_str());
    return retval;
}

IsMetatypeCheck::IsMetatypeCheck(MetaType* the_metatype, MetaTypeType the_type)
{
    metatype = the_metatype;
    type = the_type;
}

bool IsMetatypeCheck::operator() ()
{
    if(metatype == NULL)
        return false;
    bool retval = metatype->GetType() == type;
    if(!retval)
    {
        yyerror(("'" + metatype->GetName() + "' is of type '" + MetaTypeTypeToString(metatype->GetType()) + "' not of type '" + MetaTypeTypeToString(type)).c_str());
    }
    return retval;
}

NotIsMetatypeCheck::NotIsMetatypeCheck(MetaType* the_metatype, MetaTypeType the_type)
{
    metatype = the_metatype;
    type = the_type;
}

bool NotIsMetatypeCheck::operator() ()
{
    if(metatype == NULL)
        return false;
    bool retval = metatype->GetType() == type;
    if(!retval)
         yyerror(("'" + metatype->GetName() + "' is of type '" + MetaTypeTypeToString(type)).c_str());
    return metatype->GetType() != type;
}

IsOneOfMetatypesCheck::IsOneOfMetatypesCheck(MetaType* the_metatype, int the_types_length, MetaTypeType the_types[])
{
    metatype = the_metatype;
    types_length = the_types_length;
    types = the_types;
}

bool IsOneOfMetatypesCheck::operator() ()
{
    string s = "'" + metatype->GetName() + "' is not of type ";
    bool first = true;
    for(int i = 0; i < types_length; ++i)
    {
        s += "'" + MetaTypeTypeToString(types[i]) + "'";
        if(!first)
            s += " or ";
        else
            first = false;
        if(metatype->GetType() == types[i])
            return true;
    }
    yyerror(s.c_str());
    return false;
}

IsVarTypeCheck::IsVarTypeCheck(MetaType* the_metatype, VarTypes::Type the_type)
{
    metatype = the_metatype;
    type = the_type;
}

bool IsVarTypeCheck::operator() ()
{
    if(metatype == NULL)
        return false;
    VariableType* vartype;
    if(metatype->GetType() == VARIABLE)
    {
        vartype = ((Variable*)metatype)->GetVarType();
        if(vartype == NULL)
            return false;
    }
    else if(metatype->GetType() == VARIABLE_TYPE)
    {
        vartype = (VariableType*)metatype;
    }
    else
    {
        return false;
    }
    bool retval = vartype->GetEnumType() == type;
    if(!retval)
         yyerror(("'" + metatype->GetName() + "' is of type '" + VarTypes::ToString(vartype->GetEnumType()) + "' not of type '" + VarTypes::ToString(type) + "'").c_str());
    return retval;
}

NotIsVarTypeCheck::NotIsVarTypeCheck(MetaType* the_metatype, VarTypes::Type the_type)
{
    metatype = the_metatype;
    type = the_type;
}

bool NotIsVarTypeCheck::operator() ()
{
    if(metatype == NULL)
        return false;
    VariableType* vartype;
    if(metatype->GetType() == VARIABLE)
    {
        vartype = ((Variable*)metatype)->GetVarType();
        if(vartype == NULL)
            return false;
    }
    else if(metatype->GetType() == VARIABLE_TYPE)
    {
        vartype = (VariableType*)metatype;
    }
    else
    {
        return false;
    }
    bool retval = vartype->GetEnumType() != type;
    if(!retval)
         yyerror(("'" + metatype->GetName() + "' is of type '" + VarTypes::ToString(vartype->GetEnumType())).c_str());
    return retval;
}

IsOneOfVarTypesCheck::IsOneOfVarTypesCheck(MetaType* the_metatype, int the_types_length, VarTypes::Type the_types[])
{
    metatype = the_metatype;
    types_length = the_types_length;
    types = the_types;
}

bool IsOneOfVarTypesCheck::operator() ()
{
    if(metatype == NULL)
        return false;
    VariableType* vartype;
    if(metatype->GetType() == VARIABLE)
    {
        vartype = ((Variable*)metatype)->GetVarType();
        if(vartype == NULL)
            return false;
    }
    else if(metatype->GetType() == VARIABLE_TYPE)
    {
        vartype = (VariableType*)metatype;
    }
    else
    {
        return false;
    }
    string s = "'" + metatype->GetName() + "' is not of type ";
    bool first = true;
    for(int i = 0; i < types_length; ++i)
    {
        s += "'" + VarTypes::ToString(types[i]) + "'";
        if(!first)
            s += " or ";
        else
            first = false;
        if(vartype->GetEnumType() == types[i])
            return true;
    }
    yyerror(s.c_str());
    return false;
}
