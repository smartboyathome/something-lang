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
public:
    LocalScope();
    LocalScope(map<string, Type*>);
    bool IsInScope(string);
    bool IsInLocalScope(string);
    bool IsInParentScope(string);
    Type* Get(string);
    bool Insert(string, Type*);
    pair<bool,Type*> Modify(string, Type*);
    pair<bool,Type*> Remove(string);
    map<string, Type*> GetParentScope();
    map<string, Type*> GetLocalScope();
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
};
