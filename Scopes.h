#pragma once
#include <map>
#include <stack>
#include <string>
#include "IdentTypes/MetaType.h"
#include "IdentTypes/Variable.h"
using namespace std;

class LocalScope
{
private:
    map<string, MetaType*> parent_scope;
    map<string, MetaType*> local_scope;
    
    stack<Variable*> temporary_variables;
    stack<string> temporary_strings;
    
    // This is for outputting Zander-style strings.
    int scope_level;
    string make_indent();
public:
    LocalScope(int scope_level);
    LocalScope(int scope_level, map<string, MetaType*>);
    ~LocalScope();
    bool IsInScope(string);
    bool IsInLocalScope(string);
    bool IsInParentScope(string);
    MetaType* Get(string);
    bool Insert(string, MetaType*);
    pair<bool,MetaType*> Modify(string, MetaType*);
    pair<bool,MetaType*> Remove(string);
    map<string, MetaType*> GetParentScope();
    map<string, MetaType*> GetLocalScope();
    string ToString();
    void PushTempVars(Variable*);
    void PushTempStrings(string);
    Variable* PopTempVars();
    string PopTempStrings();
    bool TempVarsEmpty();
    bool TempStringsEmpty();
    bool AllTempsEmpty();
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
