#pragma once
#include <map>
#include <stack>
#include <string>
using namespace std;

class Object
{

};

class LocalScope
{
private:
    Map<string, Object*> parent_scope;
    Map<string, Object*> local_scope;
public:
    bool IsInScope(string);
    bool Insert(string, Object*);
    bool Modify(string, Object*);
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
