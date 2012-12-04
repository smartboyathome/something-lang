#pragma once
#include <map>
#include <stack>
#include <string>
#include "IdentTypes/MetaType.h"
#include "IdentTypes/Variable.h"
#include "IdentTypes/VariableType.h"
#include "IdentTypes/Array.h"
#include "IdentTypes/Pointer.h"
#include "IdentTypes/Procedure.h"
#include <sstream>
#include <fstream>
using namespace std;

class LocalScope
{
private:
    map<string, MetaType*> parent_scope;
    map<string, MetaType*> local_scope;
    
    // The temporary stacks. These are split to ease use.
    stack<Variable*> temporary_variables;
    stack<string> temporary_strings;
    stack<VariableType*> temporary_types;
    stack<int> temporary_ints;
    stack<Range> temporary_ranges;
    stack<Variable*> temporary_proc_params;
    stack<Pointer*> temporary_pointers;
    stack<VariableType*> temporary_constants;
    stack<MetaType*> temporary_designators;
    stack<Variable*> temporary_expressions;
    
    // This is for outputting Zander-style strings.
    int scope_level;
public:
    LocalScope(int scope_level);
    LocalScope(int scope_level, map<string, MetaType*>);
    ~LocalScope();
    bool IsInScope(string);
    bool IsInLocalScope(string);
    bool IsInParentScope(string);
    MetaType* Get(string);
    MetaType* GetFromLocal(string);
    MetaType* GetFromParent(string);
    bool Insert(string, MetaType*);
    pair<bool,MetaType*> Modify(string, MetaType*);
    pair<bool,MetaType*> Remove(string);
    map<string, MetaType*> GetParentScope();
    map<string, MetaType*> GetLocalScope();
    string ToString();
    string make_indent();
    
    void PushTempVars(Variable*);
    Variable* PopTempVars();
    bool TempVarsEmpty();
    
    void PushTempTypes(VariableType*);
    VariableType* PopTempTypes();
    bool TempTypesEmpty();
    
    void PushTempStrings(string);
    string PopTempStrings();
    bool TempStringsEmpty();
    
    void PushTempInts(int);
    int PopTempInts();
    bool TempIntsEmpty();
    
    void PushTempRanges(Range);
    Range PopTempRanges();
    bool TempRangesEmpty();
    
    void PushTempProcParams(Variable*);
    Variable* PopTempProcParams();
    bool TempProcParamsEmpty();
    
    void PushTempPointers(Pointer*);
    Pointer* PopTempPointers();
    bool TempPointersEmpty();
    
    void PushTempConstants(VariableType*);
    VariableType* PopTempConstants();
    bool TempConstantsEmpty();
    
    void PushTempDesignators(MetaType*);
    MetaType* PopTempDesignators();
    bool TempDesignatorsEmpty();
    
    void PushTempExpressions(Variable*);
    Variable* PopTempExpressions();
    bool TempExpressionsEmpty();
    
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
    int CurrentScopeLevel();
};
