#include "Scopes.h"
#include "IdentTypes/MetaType.h"
#include <sstream>

GlobalScope::GlobalScope()
{
    program_scopes.push(new LocalScope(program_scopes.size()+1));
    
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

LocalScope::LocalScope(int scope_level)
{
    this->scope_level = scope_level;
}

LocalScope::LocalScope(int scope_level, map<string, MetaType*> new_parent_scope)
{
    this->scope_level = scope_level;
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
