#pragma once
#include <map>
#include <stack>
#include <string>
#include "IdentList/Type.h"
using namespace std;

class LocalScope
{
private:
    map<string, Type*> parent_scope;
    map<string, Type*> local_scope;
    int scope_level;
    string make_indent();
public:
    LocalScope(int scope_level);
    LocalScope(int scope_level, map<string, Type*>);
    ~LocalScope();
    bool IsInScope(string);
    bool IsInLocalScope(string);
    bool IsInParentScope(string);
    Type* Get(string);
    bool Insert(string, Type*);
    pair<bool,Type*> Modify(string, Type*);
    pair<bool,Type*> Remove(string);
    map<string, Type*> GetParentScope();
    map<string, Type*> GetLocalScope();
    string ToString(int);
    void AddCallback(LocalScopeEventType, LocalScopeEvent);
};

class GlobalScope
{
private:
    stack<LocalScope*> program_scopes;
public:
    GlobalScope();
    ~GlobalScope();
    void CreateNewScope();
    LocalScope* GetCurrentScope();
    bool PopCurrentScope();
    void PrintCurrentScope();
};
