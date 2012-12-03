#pragma once
#include "y.tab.h"
#include "Scopes.h"
#include "IdentTypes/MetaType.h"
#include "IdentTypes/VariableType.h"
#include <vector>

extern void yyerror(const char *s);

class ErrorFunctor
{
public:
    virtual bool operator() () = 0;
};

//bool CheckAllErrors(int, ErrorFunctor[]);

class IsInScopeCheck : public ErrorFunctor
{
private:
    LocalScope* scope;
    string obj;
public:
    IsInScopeCheck(LocalScope*, string);
    bool operator() ();
};

class IsInLocalScopeCheck : public ErrorFunctor
{
private:
    LocalScope* scope;
    string obj;
public:
    IsInLocalScopeCheck(LocalScope*, string);
    bool operator() ();
};

class NotIsInLocalScopeCheck : public ErrorFunctor
{
private:
    LocalScope* scope;
    string obj;
public:
    NotIsInLocalScopeCheck(LocalScope*, string);
    bool operator() ();
};

class IsInParentScopeCheck : public ErrorFunctor
{
private:
    LocalScope* scope;
    string obj;
public:
    IsInParentScopeCheck(LocalScope*, string);
    bool operator() ();
};

class NotIsInParentScopeCheck : public ErrorFunctor
{
private:
    LocalScope* scope;
    string obj;
public:
    NotIsInParentScopeCheck(LocalScope*, string);
    bool operator() ();
};

class NotIsInScopeCheck : public ErrorFunctor
{
private:
    LocalScope* scope;
    string obj;
public:
    NotIsInScopeCheck(LocalScope*, string);
    bool operator() ();
};

class IsMetatypeCheck : public ErrorFunctor
{
private:
    MetaType* metatype;
    MetaTypeType type;
public:
    IsMetatypeCheck(MetaType*, MetaTypeType);
    bool operator() ();
};

class NotIsMetatypeCheck : public ErrorFunctor
{
private:
    MetaType* metatype;
    MetaTypeType type;
public:
    NotIsMetatypeCheck(MetaType*, MetaTypeType);
    bool operator() ();
};

class IsOneOfMetatypesCheck : public ErrorFunctor
{
private:
    MetaType* metatype;
    MetaTypeType *types;
    int types_length;
public:
    IsOneOfMetatypesCheck(MetaType*, int, MetaTypeType[]);
    bool operator() ();
};

class IsVarTypeCheck : public ErrorFunctor
{
private:
    MetaType* metatype;
    VarTypes::Type type;
public:
    IsVarTypeCheck(MetaType*, VarTypes::Type);
    bool operator() ();
};

class NotIsVarTypeCheck : public ErrorFunctor
{
private:
    MetaType* metatype;
    VarTypes::Type type;
public:
    NotIsVarTypeCheck(MetaType*, VarTypes::Type);
    bool operator() ();
};
