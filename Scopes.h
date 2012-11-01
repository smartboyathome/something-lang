#pragma once
#include <map>
#include <stack>
#include <string>
#include "IdentList/Type.h"
using namespace std;

class LocalScope
{
private:
    Map<string, Type*> parent_scope;
    Map<string, Type*> local_scope;
public:
    bool IsInScope(string);
    bool Insert(string, Type*);
    bool Modify(string, Type*);
    bool Remove(string);
};

class GlobalScope
{
private:
    stack<LocalScope> program_scopes;
public:
    bool CreateNewScope();
    LocalScope* GetCurrentScope();
    bool PopCurrentScope();
};
