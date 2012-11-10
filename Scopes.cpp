#include "Scopes.h"
#include "IdentTypes/MetaType.h"
#include "IdentTypes/VariableType.h"
#include <sstream>


GlobalScope::GlobalScope()
{
    program_scopes.push(new LocalScope(program_scopes.size()-1));
    
    IntegerType* Int = new IntegerType("integer");
    program_scopes.top()->Insert("integer", Int);
    
    BooleanType* Bool = new BooleanType("boolean");
    program_scopes.top()->Insert("boolean", Bool);
    
    BooleanType* True = new BooleanType("true", "true");
    program_scopes.top()->Insert("true", True);
    
    BooleanType* False = new BooleanType("false", "false");
    program_scopes.top()->Insert("false", False);
    
    // TODO: Strings/Chars and Reals and dummy functions
}

void GlobalScope::CreateNewScope()
{
    typedef map<string, MetaType*>::iterator iterator;
    LocalScope* top_scope = program_scopes.top();
    map<string, MetaType*> new_parent_scope = top_scope->GetLocalScope();
    map<string, MetaType*> old_parent_scope = top_scope->GetParentScope();
    for(iterator i = old_parent_scope.begin(); i != old_parent_scope.end(); ++i)
    {
        new_parent_scope.insert(pair<string, MetaType*>(i->first, i->second)); // This will only insert if the ident doesn't exist.
    }
    program_scopes.push(new LocalScope(program_scopes.size()-1, new_parent_scope));
}

LocalScope* GlobalScope::GetCurrentScope()
{
    return program_scopes.top();
}

bool GlobalScope::PopCurrentScope()
{
    if (program_scopes.size() <= 1)
        return false;
    LocalScope* old_scope = program_scopes.top();
    program_scopes.pop();
    delete old_scope;
    return true;
}

GlobalScope::~GlobalScope()
{
    int size = program_scopes.size();
    while(!program_scopes.empty())
    {
        LocalScope* top_scope = program_scopes.top();
        program_scopes.pop();
        delete top_scope;
    }
}

LocalScope::LocalScope(int level)
{
    scope_level = level;
    cout << "LEVEL " << level << endl;
}

LocalScope::LocalScope(int level, map<string, MetaType*> new_parent_scope)
{
    scope_level = level;
    cout << "LEVEL " << level << endl;
    parent_scope = new_parent_scope;
}

bool LocalScope::IsInScope(string identifier)
{
    return local_scope.count(identifier) > 0 or parent_scope.count(identifier) > 0;
}

bool LocalScope::IsInLocalScope(string identifier)
{
    return local_scope.count(identifier) > 0;
}

bool LocalScope::IsInParentScope(string identifier)
{
    return parent_scope.count(identifier) > 0;
}

MetaType* LocalScope::Get(string identifier)
{
    if (local_scope.count(identifier) > 0)
        return local_scope[identifier];
    else if (parent_scope.count(identifier) > 0)
        return parent_scope[identifier];
    else
        return NULL;
}

MetaType* LocalScope::GetFromLocal(string identifier)
{
    if (local_scope.count(identifier) > 0)
        return local_scope[identifier];
    else
        return NULL;
}

MetaType* LocalScope::GetFromParent(string identifier)
{
    if (parent_scope.count(identifier) > 0)
        return parent_scope[identifier];
    else
        return NULL;
}

bool LocalScope::Insert(string identifier, MetaType* type)
{
    if (local_scope.count(identifier) > 0)
        return false;
    local_scope.insert(pair<string, MetaType*>(identifier, type));
    cout << make_indent() << type->ToString() << endl;
    return true;
}

pair<bool,MetaType*> LocalScope::Modify(string identifier, MetaType* type)
{
    if (local_scope.count(identifier) == 0)
        return pair<bool, MetaType*>(false, NULL);
    MetaType* retval = local_scope[identifier];
    local_scope[identifier] = type;
    return pair<bool, MetaType*>(true, retval);
}

pair<bool,MetaType*> LocalScope::Remove(string identifier)
{
    if (local_scope.count(identifier) == 0)
        return pair<bool, MetaType*>(false, NULL);
    MetaType* retval = local_scope[identifier];
    local_scope.erase(identifier);
    return pair<bool, MetaType*>(true, retval);
}

map<string, MetaType*> LocalScope::GetParentScope()
{
    return parent_scope;
}

map<string, MetaType*> LocalScope::GetLocalScope()
{
    return local_scope;
}

string LocalScope::make_indent()
{
    cout << "INDENT: " << scope_level << endl;
    stringstream ss;
    for(int i = 0; i < scope_level; ++i)
    {
        ss << "   ";
    }
    return ss.str();
}

string LocalScope::ToString()
{
    typedef map<string, MetaType*>::iterator iterator;
    string indent = make_indent();
    bool first = true;
    stringstream ss;
    for(iterator i = local_scope.begin(); i != local_scope.end(); ++i)
    {
        if(first)
            first = false;
        else
            ss << endl;
        ss << indent << i->second->ToString();
    }
    return ss.str();
}

LocalScope::~LocalScope()
{
    // We won't do anything since the type references should be deleted manually.
    // They may be attached to other objects and could affect those objects.
}

void LocalScope::PushTempVars(Variable* temp_var)
{
    temporary_variables.push(temp_var);
}

Variable* LocalScope::PopTempVars()
{
    if(temporary_variables.empty())
        return NULL;
    Variable* retval = temporary_variables.top();
    temporary_variables.pop();
    return retval;
}

bool LocalScope::TempVarsEmpty()
{
    return temporary_variables.empty();
}

void LocalScope::PushTempTypes(VariableType* temp_type)
{
    temporary_types.push(temp_type);
}

VariableType* LocalScope::PopTempTypes()
{
    if(temporary_types.empty())
        return NULL;
    VariableType* retval = temporary_types.top();
    temporary_types.pop();
    return retval;
}

bool LocalScope::TempTypesEmpty()
{
    return temporary_types.empty();
}

void LocalScope::PushTempStrings(string temp_str)
{
    temporary_strings.push(temp_str);
}

string LocalScope::PopTempStrings()
{
    if (temporary_strings.empty())
        return "";
    string retval = temporary_strings.top();
    temporary_strings.pop();
    return retval;
}

bool LocalScope::TempStringsEmpty()
{
    return temporary_strings.empty();
}

void LocalScope::PushTempInts(int temp_int)
{
    temporary_ints.push(temp_int);
}

int LocalScope::PopTempInts()
{
    if (temporary_ints.empty())
        return 0;
    int retval = temporary_ints.top();
    temporary_ints.pop();
    return retval;
}

bool LocalScope::TempIntsEmpty()
{
    return temporary_ints.empty();
}

void LocalScope::PushTempRanges(Range temp_range)
{
    temporary_ranges.push(temp_range);
}

Range LocalScope::PopTempRanges()
{
    if (temporary_ranges.empty())
        return Range(-1, -1);
    Range retval = temporary_ranges.top();
    temporary_ranges.pop();
    return retval;
}

bool LocalScope::TempRangesEmpty()
{
    return temporary_ranges.empty();
}

bool LocalScope::AllTempsEmpty()
{
    return temporary_variables.empty() && temporary_types.empty() && temporary_strings.empty() && temporary_ints.empty() && temporary_ranges.empty();
}
