#include "Scopes.h"
#include <stringstream>

GlobalScope::GlobalScope()
{
    program_scopes.push(new LocalScope(program_scopes.size()+1));
    
}

void GlobalScope::CreateNewScope()
{
    typedef map<string, Type*>::iterator iterator;
    LocalScope* top_scope = program_scopes.top();
    map<string, Type*> new_parent_scope = top_scope->GetLocalScope();
    map<string, Type*> old_parent_scope = top_scope->GetParentScope();
    for(iterator i = old_parent_scope.begin(); i != old_parent_scope.end(); ++i)
    {
        new_parent_scope.insert(pair<string, Type*>(i->first, i->second)); // This will only insert if the ident doesn't exist.
    }
    program_scopes.push(new LocalScope(program_scopes.size()+1, new_parent_scope));
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

LocalScope::LocalScope()
{
    
}

LocalScope::LocalScope(map<string, Type*> new_parent_scope)
{
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

Type* LocalScope::Get(string identifier)
{
    if (local_scope.count(identifier) > 0)
        return local_scope[identifier];
    else if (parent_scope.count(identifier) > 0)
        return parent_scope[identifier];
    else
        return NULL;
}

bool LocalScope::Insert(string identifier, Type* type)
{
    if (local_scope.count(identifier) > 0)
        return false;
    local_scope.insert(pair<string, Type*>(identifier, type));
    cout << make_indent() << type->ToString() << endl;
    return true;
}

pair<bool,Type*> LocalScope::Modify(string identifier, Type* type)
{
    if (local_scope.count(identifier) == 0)
        return pair<bool, Type*>(false, NULL);
    Type* retval = local_scope[identifier];
    local_scope[identifier] = type;
    return pair<bool, Type*>(true, retval);
}

pair<bool,Type*> LocalScope::Remove(string identifier)
{
    if (local_scope.count(identifier) == 0)
        return pair<bool, Type*>(false, NULL);
    Type* retval = local_scope[identifier];
    local_scope.erase(identifier);
    return pair<bool, Type*>(true, retval);
}

map<string, Type*> LocalScope::GetParentScope()
{
    return parent_scope;
}

map<string, Type*> LocalScope::GetLocalScope()
{
    return local_scope;
}

string LocalScope::make_indent()
{
    stringstream ss;
    for(int i = 0; i < scope_level; ++i)
    {
        indent = indent + "   ";
    }
    return ss.str();
}

string LocalScope::ToString()
{
    typedef map<string, Type*>::iterator iterator;
    string indent = make_indent();
    bool first = true;
    stringstream ss;
    for(iterator i = local_scope.begin(); i != local_scope.end(); ++i)
    {
        if(first)
            first = false
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
