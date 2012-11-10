%{
#include <cstdio>
#include <cstring>
#include <iostream>
#include <stack>
#include <vector>
#include <sstream>
#include "Scopes.h"
#include "IdentTypes/MetaType.h"
#include "IdentTypes/Procedure.h"
#include "IdentTypes/Variable.h"
using namespace std;
#define YYDEBUG 1

// stuff from flex that bison needs to know about:
extern "C" int yylex();
extern "C" FILE *yyin;
extern string s; // This is the metadata, such a s an int or string value.
extern int line_num; // And this is the line number that flex is on.
void yyerror(const char *s) {
    cout << "ERROR: " << s << " on line " << line_num << endl;
}
extern "C" int yyparse();
GlobalScope global_scope;
%}

%start CompilationUnit

%union {
	char *sval;
}

%token       yand yarray yassign ybegin ycaret ycase ycolon ycomma yconst ydiv
             ydivide ydo ydot ydotdot ydownto yelse yend yequal yfor yfunction
             ygreater ygreaterequal yident yif yin yleftbracket yleftparen
             yless ylessequal yminus ymod ymultiply ynil ynot ynotequal ynumber
             yof yor yplus yprocedure yprogram yrecord yrepeat yrightbracket
             yrightparen ysemicolon yset ystring ythen yto ytype yuntil yvar
             ywhile yunknown

%left ythen
%left yelse

%%
/* rules section */

/**************************  Pascal program **********************************/

CompilationUnit    :  ProgramModule        
                   ;
ProgramModule      :  yprogram yident
                      {
                          global_scope.GetCurrentScope()->PushTempStrings(s);
                      }
                      ProgramParameters
                      {
                          LocalScope* prev_scope = global_scope.GetCurrentScope();
                          string program_name = prev_scope->PopTempStrings();
                          Procedure* program = new Procedure(program_name);
                          while(!prev_scope->TempVarsEmpty())
                          {
                              Variable* param = prev_scope->PopTempVars();
                              // Zander said to ignore these parameters, so we will.
                              delete param;
                          }
                          global_scope.CreateNewScope();
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          current_scope->Insert(program_name, program);
                          // This scope is for all the variables defined in the program.
                          global_scope.CreateNewScope();
                      }
                      ysemicolon Block ydot
                   ;
ProgramParameters  :  yleftparen  IdentList  yrightparen
                   ;
IdentList          :  yident 
                      {
                          global_scope.GetCurrentScope()->PushTempVars(new Variable(s));
                      }
                   |  IdentList ycomma yident
                      {
                          global_scope.GetCurrentScope()->PushTempVars(new Variable(s));
                      }
                   ;

/**************************  Declarations section ***************************/

Block              :  Declarations  ybegin
                      {
                          cout << "TEST BEGIN BLOCK 0" << endl;
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          if (!current_scope->AllTempsEmpty())
                          {
                              cout << "TEST BEGIN BLOCK 3" << endl;
                              stringstream ss;
                              ss << "UNDEFINED:" << endl;
                              while(!current_scope->TempVarsEmpty())
                              {
                                  Variable* var = current_scope->PopTempVars();
                                  ss << "VAR " << var->GetName() << endl;
                                  delete var;
                              }
                              cout << "TEST BEGIN BLOCK 4" << endl;
                              while(!current_scope->TempStringsEmpty())
                              {
                                  ss << "STRING " << current_scope->PopTempStrings() << endl;
                              }
                              cout << "TEST BEGIN BLOCK 5" << endl;
                              while(!current_scope->TempTypesEmpty())
                              {
                                  VariableType* type = current_scope->PopTempTypes();
                                  ss << "TYPE " << type->GetName() << endl;
                                  delete type;
                              }
                              cout << "TEST BEGIN BLOCK 6" << endl;
                              while(!current_scope->TempIntsEmpty())
                              {
                                  ss << "INT " << current_scope->PopTempInts() << endl;
                              }
                              cout << "TEST BEGIN BLOCK 7" << endl;
                              while(!current_scope->TempRangesEmpty())
                              {
                                  cout << "TEST BEGIN BLOCK 7A" << endl;
                                  Range range = current_scope->PopTempRanges();
                                  ss << "RANGE " << range.ToString() << endl;
                              }
                              cout << "TEST BEGIN BLOCK 8" << endl;
                              yyerror(ss.str().c_str());
                              YYERROR;
                          }
                          else
                          {
                              cout << "TEST BEGIN BLOCK 1" << endl;
                              global_scope.CreateNewScope();
                              cout << "TEST BEGIN BLOCK 2" << endl;
                          }
                      }
                      StatementSequence  yend
                      {
                          global_scope.PopCurrentScope();
                      }
                   ;
Declarations       :  ConstantDefBlock
                      TypeDefBlock
                      VariableDeclBlock
                      SubprogDeclList  
                   ;
ConstantDefBlock   :  /*** empty ***/
                   |  yconst ConstantDefList
                   ;
ConstantDefList    :  ConstantDefList ConstantDef ysemicolon
                   |  ConstantDef ysemicolon
                   ;
TypeDefBlock       :  /*** empty ***/
                   |  ytype  TypeDefList          
                   ;
TypeDefList        :  TypeDef  ysemicolon
                   |  TypeDefList TypeDef ysemicolon  
                   ;
VariableDeclBlock  :  /*** empty ***/
                   |  yvar VariableDeclList
                   ;
VariableDeclList   :  VariableDeclList VariableDecl ysemicolon
                   |  VariableDecl ysemicolon
                   ;  
/*ConstantDef        :  yident  yequal  ConstExpression
                   ;*/
ConstantDef        :  yident
                      {
                          global_scope.GetCurrentScope()->PushTempStrings(s);
                      }
                      yequal  ConstExpression
                      {
                          cout << "TEST AFTER ConstDef 0" << endl;
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          string identifier = current_scope->PopTempStrings();
                          if(current_scope->IsInLocalScope(identifier))
                          {
                              yyerror(("REDEFINED: " + identifier).c_str());
                              YYERROR;
                          }
                          else
                          {
                              cout << "TEST AFTER ConstDef 1" << endl;
                              VariableType* type = current_scope->PopTempTypes();
                              type->SetName(identifier);
                              current_scope->Insert(identifier, type);
                              cout << "TEST AFTER ConstDef 2" << endl;
                          }
                      }
                   ;
TypeDef            :  yident
                      {
                          global_scope.GetCurrentScope()->PushTempStrings(s);
                      }
                      yequal  Type
                      {
                          cout << "TEST AFTER TYPE 0" << endl;
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          string identifier = current_scope->PopTempStrings();
                          if(current_scope->IsInLocalScope(identifier))
                          {
                              yyerror(("REDEFINED: " + identifier).c_str());
                              YYERROR;
                          }
                          else
                          {
                              cout << "TEST AFTER TYPE 1" << endl;
                              VariableType* type = current_scope->PopTempTypes();
                              type->SetName(identifier);
                              current_scope->Insert(identifier, type);
                              cout << "TEST AFTER TYPE 2" << endl;
                          }
                      }
                   ;
VariableDecl       :  IdentList  ycolon  Type
                      {
                          cout << "TEST VARIABLE DECLARE 0" << endl;
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          VariableType* type = current_scope->PopTempTypes();
                          while(!current_scope->TempVarsEmpty())
                          {
                              cout << "TEST VARIABLE DECLARE 1" << endl;
                              Variable* var = current_scope->PopTempVars();
                              var->SetType(type);
                              current_scope->Insert(var->GetName(), var);
                              cout << "TEST VARIABLE DECLARE 2" << endl;
                          }
                          cout << "TEST VARIABLE DECLARE 3" << endl;
                      }
                   ;

/***************************  Const/Type Stuff  ******************************/

ConstExpression    :  UnaryOperator ConstFactor
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          string op = current_scope->PopTempStrings();
                          int value = current_scope->PopTempInts();
                          if ((op == "+" && value < 0) || (op == "-" && value > 0))
                                value *= -1;    // Overrides the original sign of value
                          
                          current_scope->PushTempInts(value);
                          // TODO: Fix so that it pushes a variable.
                      }
                   |  ConstFactor
                   |  ystring // TODO: handle strings
                   ;
ConstFactor        :  yident
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          if(!current_scope->IsInScope(s))
                          {
                              yyerror(("UNDEFINED: " + s).c_str());
                              YYERROR;
                          }
                          else 
                          {
                              MetaType* var = current_scope->Get(s);
                              if(var->GetType() != VARIABLE_TYPE)
                              {
                                  yyerror(("NOT A TYPE: " + s).c_str());
                                  YYERROR;
                              }
                              else if(((VariableType*)var)->GetVarType() != VarTypes::INTEGER)
                              {
                                  yyerror(("NOT OF TYPE INTEGER " + s).c_str());
                                  YYERROR;
                              }
                              else
                              {
                                  IntegerType* Int = (IntegerType*)var;
                                  global_scope.GetCurrentScope()->PushTempInts(Int->GetValue());
                              }
                          }
                      }
                   |  ynumber
                      {
                          int temp;
                          stringstream(s) >> temp;
                          global_scope.GetCurrentScope()->PushTempInts(temp);
                      }
                   |  ynil
                      {
                          global_scope.GetCurrentScope()->PushTempInts(0);
                      }
                   ;
Type               :  yident
                      {
                          cout << "TEST TYPE IDENT 0" << endl;
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          if(!current_scope->IsInScope(s))
                          {
                              yyerror(("UNDEFINED: " + s).c_str());
                              YYERROR;
                          }
                          else
                          {
                              cout << "TEST TYPE IDENT 1" << endl;
                              LocalScope* current_scope = global_scope.GetCurrentScope();
                              MetaType* var = current_scope->Get(s);
                              if(var->GetType() != VARIABLE_TYPE)
                              {
                                  yyerror(("NOT A TYPE " + s).c_str());
                                  YYERROR;
                              }
                              else
                              {
                                  cout << "TEST TYPE IDENT 2" << endl;
                                  current_scope->PushTempTypes((VariableType*) var);
                                  cout << "TEST TYPE IDENT 3" << endl;
                              }
                          }
                          cout << "TEST TYPE IDENT 4" << endl;
                      }
                   |  ArrayType
                      {
                          cout << "TEST TYPE ARRAY 0" << endl;
                          ArrayType* array = new ArrayType("");
                          stack<Range> reversed; // Needed since the ranges will be backwards
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          while(!current_scope->TempRangesEmpty())
                          {
                              reversed.push(current_scope->PopTempRanges());
                          }
                          while(!reversed.empty())
                          {
                              Range range = reversed.top();
                              reversed.pop();
                              array->AddDimension(range);
                          }
                          current_scope->PushTempTypes(array);
                          cout << "TEST TYPE ARRAY 1" << endl;
                      }
                   |  PointerType
                   |  RecordType
                   |  SetType
                      {
                          cout << "TEST TYPE SET 0" << endl;
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          ArrayType* array = new ArrayType("");
                          // We can do this without a loop like above since there's
                          // only one range.
                          Range range = current_scope->PopTempRanges();
                          array->AddDimension(range);
                          current_scope->PushTempTypes(array);
                          cout << "TEST TYPE SET 1" << endl;
                      }
                   ;
ArrayType          :  yarray yleftbracket Subrange SubrangeList 
                      yrightbracket  yof Type
                   ;
SubrangeList       :  /*** empty ***/
                   |  SubrangeList ycomma Subrange 
                   ;
Subrange           :  ConstFactor ydotdot ConstFactor
                      {
                          cout << "TEST A0" << endl;
                          int b = global_scope.GetCurrentScope()->PopTempInts();
                          int a = global_scope.GetCurrentScope()->PopTempInts();
                          cout << "TEST A1" << endl;
                          Range temp(a, b);
                          cout << "TEST A2" << endl;
                          global_scope.GetCurrentScope()->PushTempRanges(temp);
                          cout << "TEST A5" << endl;
                      }
                   |  ystring
                      {
                          cout << "TEST B" << endl;
                          global_scope.GetCurrentScope()->PushTempStrings(s);
                      }
                      ydotdot  ystring
                      {
                          cout << "TEST C" << endl;
                          string a = global_scope.GetCurrentScope()->PopTempStrings();
                          string b = s;
                          if (a.length() != 1 || b.length() != 1)
                          {
                              yyerror(("BAD SUBRANGE: '" + a + "'..'" + b + "'").c_str());
                              YYERROR;
                          }
                          else
                          {
                              Range temp(a[0], b[0]);
                              global_scope.GetCurrentScope()->PushTempRanges(temp);
                          }
                      }
                   ;
RecordType         :  yrecord  FieldListSequence  yend
                   ;
SetType            :  yset  yof  Subrange
                   ;
PointerType        :  ycaret  yident 
                   ;
FieldListSequence  :  FieldList  
                   |  FieldListSequence  ysemicolon  FieldList
                   ;
FieldList          :  IdentList  ycolon  Type
                   ;

/***************************  Statements  ************************************/

StatementSequence  :  Statement  
                   |  StatementSequence  ysemicolon  Statement
                   ;
Statement          :  Assignment
                   |  ProcedureCall
                   |  IfStatement
                   |  CaseStatement
                   |  WhileStatement
                   |  RepeatStatement
                   |  ForStatement
                   |  ybegin StatementSequence yend
                   |  /*** empty ***/
                   ;
Assignment         :  Designator yassign Expression
                   ;
ProcedureCall      :  yident 
                   |  yident ActualParameters
                   ;
IfStatement        :  yif  Expression  ythen  Statement  ElsePart
                   ;
ElsePart           :  /*** empty ***/
                   |  yelse  Statement  
                   ;
CaseStatement      :  ycase  Expression  yof  CaseList  yend
                   ;
CaseList           :  Case
                   |  CaseList  ysemicolon  Case  
                   ;
Case               :  CaseLabelList  ycolon  Statement
                   ;
CaseLabelList      :  ConstExpression  
                   |  CaseLabelList  ycomma  ConstExpression   
                   ;
WhileStatement     :  ywhile  Expression  ydo  Statement  
                   ;
RepeatStatement    :  yrepeat  StatementSequence  yuntil  Expression
                   ;
ForStatement       :  yfor  yident  yassign  Expression  WhichWay  Expression
                            ydo  Statement
                   ;
WhichWay           :  yto  |  ydownto
                   ;


/***************************  Designator Stuff  ******************************/

Designator         :  yident  DesignatorStuff 
                   ;
DesignatorStuff    :  /*** empty ***/
                   |  DesignatorStuff  theDesignatorStuff
                   ;
theDesignatorStuff :  ydot yident 
                   |  yleftbracket ExpList yrightbracket 
                   |  ycaret 
                   ;
ActualParameters   :  yleftparen  ExpList  yrightparen
                   ;
ExpList            :  Expression   
                   |  ExpList  ycomma  Expression       
                   ;

/***************************  Expression Stuff  ******************************/

Expression         :  SimpleExpression  
                   |  SimpleExpression  Relation  SimpleExpression 
                   ;
SimpleExpression   :  TermExpr
                   |  UnaryOperator  TermExpr
                   ;
TermExpr           :  Term  
                   |  TermExpr  AddOperator  Term
                   ;
Term               :  Factor  
                   |  Term  MultOperator  Factor
                   ;
Factor             :  ynumber
                      {
                          int temp;
                          stringstream(s) >> temp;
                          IntegerType* Int = new IntegerType("", temp);
                          global_scope.GetCurrentScope()->PushTempTypes(Int);
                      }
                   |  ynil
                   |  ystring
                      {
                          StringType* String = new StringType("", s);
                          global_scope.GetCurrentScope()->PushTempTypes(String);
                      }
                   |  Designator
                   |  yleftparen  Expression  yrightparen
                   |  ynot Factor
                   |  Setvalue
                   |  FunctionCall
                   ;
/*  Functions with no parameters have no parens, but you don't need         */
/*  to handle that in FunctionCall because it is handled by Designator.     */
/*  A FunctionCall has at least one parameter in parens, more are           */
/*  separated with commas.                                                  */
FunctionCall       :  yident ActualParameters
                   ;
Setvalue           :  yleftbracket ElementList  yrightbracket
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          ArrayType* array = new ArrayType("");
                          vector<int> temp;
                          while(!current_scope->TempRangesEmpty())
                          {
                              Range range = current_scope->PopTempRanges();
                              for(int i = range.intLow; i <= range.intHigh; ++i)
                              {
                                  temp.push_back(i);
                              }
                          }
                          array->AddDimension(0, temp.size()-1);
                          current_scope->PushTempTypes(array);
                      }
                   |  yleftbracket yrightbracket
                   ;
ElementList        :  Element  
                   |  ElementList  ycomma  Element
                   ;
Element            :  ConstExpression  
                      {
                          // TODO: Handle string consts.
                          int temp = global_scope.GetCurrentScope()->PopTempInts();
                          global_scope.GetCurrentScope()->PushTempRanges(Range(temp, temp));
                      }
                   |  ConstExpression  ydotdot  ConstExpression 
                      {
                          // TODO: Handle string consts.
                          int b = global_scope.GetCurrentScope()->PopTempInts();
                          int a = global_scope.GetCurrentScope()->PopTempInts();
                          global_scope.GetCurrentScope()->PushTempRanges(Range(a, b));
                      }
                   ;

/***************************  Subprogram Stuff  ******************************/

SubprogDeclList    :  /*** empty ***/
                   |  SubprogDeclList ProcedureDecl ysemicolon  
                   |  SubprogDeclList FunctionDecl ysemicolon
                   ;
ProcedureDecl      :  ProcedureHeading  ysemicolon  Block 
                   ;
FunctionDecl       :  FunctionHeading  ycolon  yident  ysemicolon  Block
                   ;
ProcedureHeading   :  yprocedure  yident  
                   |  yprocedure  yident  FormalParameters
                   ;
FunctionHeading    :  yfunction  yident  
                   |  yfunction  yident  FormalParameters
                   ;
FormalParameters   :  yleftparen FormalParamList yrightparen 
                   ;
FormalParamList    :  OneFormalParam 
                   |  FormalParamList ysemicolon OneFormalParam
                   ;
OneFormalParam     :  yvar  IdentList  ycolon  yident
                   |  IdentList  ycolon  yident
                   ;

/***************************  More Operators  ********************************/

UnaryOperator      :  yplus
                      {
                          global_scope.GetCurrentScope()->PushTempStrings("+");
                      }
                   |  yminus
                      {
                          global_scope.GetCurrentScope()->PushTempStrings("-");
                      }
                   ;
MultOperator       :  ymultiply | ydivide | ydiv | ymod | yand 
                   ;
AddOperator        :  yplus | yminus | yor
                   ;
Relation           :  yequal  | ynotequal | yless | ygreater 
                   |  ylessequal | ygreaterequal | yin
                   ;
%%
