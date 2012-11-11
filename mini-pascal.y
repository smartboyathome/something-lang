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
extern "C" char* yytext;
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
                              LocalScope* new_scope = global_scope.GetCurrentScope();
                              while(!current_scope->TempProcParamsEmpty())
                              {
                                  Variable* param = current_scope->PopTempProcParams();
                                  cout << "INSERTING PARAM " << param->GetName() << endl;
                                  current_scope->Insert(param->GetName(), param);
                              }
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
                              var->SetVarType(type);
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
                              else if(((VariableType*)var)->GetEnumType() != VarTypes::INTEGER)
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
                          VariableType* type = current_scope->PopTempTypes();
                          array->SetArrayType(type);
                          current_scope->PushTempTypes(array);
                          cout << "TEST TYPE ARRAY 1" << endl;
                      }
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
Assignment         :  Designator  yassign Expression
                      {
                          cout << "TEST ASSIGNMENT" << endl;
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          string identifier = current_scope->PopTempStrings();
                          Variable* var = current_scope->PopTempVars();
                          if(!current_scope->IsInScope(identifier))
                          {
                              // This breaks because of the broken designator.
                              //yyerror(("UNDEFINED " + identifier).c_str());
                              //YYERROR;
                          }
                          else
                          {
                              MetaType* origtype = current_scope->Get(identifier);
                              if(origtype->GetType() != VARIABLE)
                              {
                                  yyerror(("NOT A VARIABLE '" + identifier + "'").c_str());
                                  //YYERROR;
                              }
                              else
                              {
                                  Variable* origvar = (Variable*)origtype;
                                  if(var->GetVarType() != origvar->GetVarType())
                                  {
                                      yyerror((("VAR TYPES DO NOT MATCH " + identifier)).c_str());
                                      YYERROR;
                                  }
                                  else
                                  {
                                      origvar->SetVarType(var->GetVarType());
                                  }
                              }
                          }
                      }
                   ;
ProcedureCall      :  yident 
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          if(!current_scope->IsInScope(s))
                          {
                               // This is the same problem as with Designator
                               //yyerror(("UNDEFINED " + s).c_str());
                               //YYERROR;
                          }
                          else if(current_scope->Get(s)->GetType() != PROCEDURE)
                          {
                              yyerror("NOT A PROCEDURE");
                              YYERROR;
                          }
                      }
                   |  yident
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          if(!current_scope->IsInScope(s))
                          {
                               // This is the same problem as with Designator
                               //yyerror(("UNDEFINED " + s).c_str());
                               //YYERROR;
                          }
                          else if(current_scope->Get(s)->GetType() != PROCEDURE)
                          {
                              yyerror("NOT A PROCEDURE");
                              YYERROR;
                          }
                      }
                      ActualParameters
                   ;
IfStatement        :  yif  Expression
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          Variable* var = current_scope->PopTempVars();
                          if(var->GetVarType() == NULL)
                          {
                              // I don't know why it'd be null, but apparently
                              // it is if it gets here.
                          }
                          else if(var->GetVarType()->GetEnumType() != VarTypes::BOOLEAN)
                          {
                              yyerror("NOT A BOOLEAN");
                              YYERROR;
                          }
                      }
                      ythen  Statement  ElsePart
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
WhileStatement     :  ywhile  Expression
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          Variable* var = current_scope->PopTempVars();
                          if(var->GetVarType() == NULL)
                          {
                              // I don't know why it'd be null, but apparently
                              // it is.
                          }
                          else if(var->GetVarType()->GetEnumType() != VarTypes::BOOLEAN)
                          {
                              yyerror("NOT A BOOLEAN");
                              YYERROR;
                          }
                      }
                      ydo  Statement  
                   ;
RepeatStatement    :  yrepeat  StatementSequence  yuntil  Expression
                   ;
ForStatement       :  yfor  yident  yassign  Expression  WhichWay  Expression
                            ydo  Statement
                   ;
WhichWay           :  yto  |  ydownto
                   ;


/***************************  Designator Stuff  ******************************/

Designator         :  yident
                      {
                          // This is broken, for some reason yident reduces to
                          // the next token before running this code. This
                          // breaks any rule that uses designator, and this
                          // problem shows up other places in the code.
                          cout << "TEST DESIGNATOR" << endl;
                          if(s == "")
                              cout << "BLANK DESIGNATOR" << endl;
                          else
                              cout << "DESIGNATOR " << s << endl;
                          cout << "YYTEXT " << yytext << endl;
                          global_scope.GetCurrentScope()->PushTempStrings(s);
                      }
                      DesignatorStuff 
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
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          Variable* var = current_scope->PopTempVars();
                          var->SetVarType(new BooleanType());
                          current_scope->PushTempVars(var);
                      }
                   ;
SimpleExpression   :  TermExpr
                   |  UnaryOperator  TermExpr
                   ;
TermExpr           :  Term  
                   |  TermExpr AddOperator  Term
                      {
                          cout << "TEST ADD OPERATOR" << endl;
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          Variable* newvar = new Variable("");
                          newvar->SetVarType(current_scope->PopTempTypes());
                          if(newvar->GetVarType() == NULL)
                          {
                              // This is because designator DOES NOT WORK
                          }
                          else if(!current_scope->TempVarsEmpty())
                          {
                              Variable* oldvar = current_scope->PopTempVars();
                              if(oldvar->GetVarType() == NULL)
                                  cout << "OLDVAR'S VARTYPE IS NULL" << endl;
                              if(newvar->GetVarType() == NULL)
                                  cout << "NEWVAR'S VARTYPE IS NULL" << endl;
                              if(newvar->GetVarType()->GetEnumType() != oldvar->GetVarType()->GetEnumType())
                              {
                                  yyerror("TYPES DO NOT MATCH");
                                  YYERROR;
                              }
                              else
                              {
                                  current_scope->PushTempVars(newvar);
                              }
                          }
                          else
                          {
                              current_scope->PushTempVars(newvar);
                          }
                      }
                   ;
Term               :  Factor  
                      {
                          cout << "TEST TERM FACTOR" << endl;
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          Variable* var = new Variable("");
                          var->SetVarType(current_scope->PopTempTypes());
                          current_scope->PushTempVars(var);
                      }
                   |  Term  MultOperator  Factor
                      {
                          cout << "TEST MULTIPLY OPERATOR" << endl;
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          Variable* newvar = new Variable("");
                          newvar->SetVarType(current_scope->PopTempTypes());
                          if(newvar->GetVarType() == NULL)
                          {
                              // This is because designator DOES NOT WORK
                          }
                          else if(!current_scope->TempVarsEmpty())
                          {
                              Variable* oldvar = current_scope->PopTempVars();
                              if(newvar->GetVarType()->GetEnumType() != oldvar->GetVarType()->GetEnumType())
                              {
                                  yyerror("TYPES DO NOT MATCH");
                                  YYERROR;
                              }
                              else
                              {
                                  current_scope->PushTempVars(newvar);
                              }
                          }
                          else
                          {
                              current_scope->PushTempVars(newvar);
                          }
                      }
                   ;
Factor             :  ynumber
                      {
                          cout << "TEST FACTOR NUMBER" << endl;
                          int temp;
                          stringstream(s) >> temp;
                          IntegerType* Int = new IntegerType("", temp);
                          global_scope.GetCurrentScope()->PushTempTypes(Int);
                      }
                   |  ynil
                   |  ystring
                      {
                          cout << "TEST FACTOR STRING" << endl;
                          StringType* String = new StringType("", s);
                          global_scope.GetCurrentScope()->PushTempTypes(String);
                      }
                   |  Designator
                      {
                          cout << "TEST FACTOR DESIGNATOR" << endl;
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          if(current_scope->TempStringsEmpty())
                          {
                              yyerror("Temp strings is empty!");
                          }
                          string temp = current_scope->PopTempStrings();
                          if(!current_scope->IsInScope(temp))
                          {
                              //yyerror(("UNDEFINED VAR " + temp).c_str());
                              //YYERROR;
                          }
                          else
                          {
                              cout << "Designator somehow succeeded on line " << line_num << endl;
                              MetaType* var = current_scope->Get(temp);
                              if(var->GetType() == VARIABLE_TYPE || var->GetType() == RECORD || var->GetType() == RANGE)
                              {
                                  yyerror("BAD TYPE FOR OPERATION");
                                  YYERROR;
                              }
                              else if(var->GetType() == VARIABLE)
                              {
                                  current_scope->PushTempTypes(((Variable*)var)->GetVarType());
                              }
                              else if(var->GetType() == PROCEDURE)
                              {
                                  current_scope->PushTempTypes(((Procedure*)var)->GetReturnType());
                              }
                              else if(var->GetType() == POINTER)
                              {
                                  // TODO: Implement this.
                              }
                          }
                      }
                   |  yleftparen  Expression
                      {
                          cout << "TEST FACTOR EXPRESSION" << endl;
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          current_scope->PushTempTypes(current_scope->PopTempVars()->GetVarType());
                      }
                      yrightparen
                   |  ynot Factor
                   |  Setvalue
                   |  FunctionCall
                   ;
/*  Functions with no parameters have no parens, but you don't need         */
/*  to handle that in FunctionCall because it is handled by Designator.     */
/*  A FunctionCall has at least one parameter in parens, more are           */
/*  separated with commas.                                                  */
FunctionCall       :  yident
                      {
                          cout << "TEST FUNCTION CALL" << endl;
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          if(!current_scope->IsInScope(s))
                          {
                              yyerror(("UNDEFINED PROCEDURE " + s).c_str());
                              YYERROR;
                          }
                          else
                          {
                              MetaType* var = current_scope->Get(s);
                              if(var->GetType() != PROCEDURE)
                              {
                                  yyerror(("NON-PROCEDURAL OBJECT " + s).c_str());
                                  YYERROR;
                              }
                              else
                              {
                                  current_scope->PushTempTypes(((Procedure*)var)->GetReturnType());
                              }
                          }
                      }
                      ActualParameters
                   ;
Setvalue           :  yleftbracket ElementList  yrightbracket
                      {
                          cout << "TEST SET VALUE" << endl;
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
                          cout << "TEST ELEMENT CONST" << endl;
                          // TODO: Handle string consts.
                          int temp = global_scope.GetCurrentScope()->PopTempInts();
                          global_scope.GetCurrentScope()->PushTempRanges(Range(temp, temp));
                      }
                   |  ConstExpression  ydotdot  ConstExpression 
                      {
                          cout << "TEST ELEMENT DOTDOT" << endl;
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
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          if(current_scope->IsInScope(s))
                          {
                              yyerror(("REDEFINITION " + s).c_str());
                              YYERROR;
                          }
                          if(s == "")
                          {
                              yyerror((string("THAR BE BLANK NAMES HERE! THE TOKEN IS ") + string(yytext)).c_str());
                          }
                          Procedure* procedure = new Procedure(s);
                          current_scope->Insert(s, procedure);
                      }
                   |  yprocedure  yident
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          current_scope->PushTempStrings(s);
                      }
                      FormalParameters
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          string identifier = current_scope->PopTempStrings();
                          if(current_scope->IsInScope(identifier))
                          {
                              yyerror(("REDEFINITION " + identifier).c_str());
                              YYERROR;
                          }
                          if(identifier == "")
                          {
                              yyerror((string("THAR BE BLANK NAMES HERE! THE TOKEN IS ") + string(yytext)).c_str());
                          }
                          Procedure* procedure = new Procedure(identifier);
                          stack<Variable*> reversed;
                          while(!current_scope->TempProcParamsEmpty())
                          {
                              reversed.push(current_scope->PopTempProcParams());
                          }
                          while(!reversed.empty())
                          {
                              LocalScope* current_scope = global_scope.GetCurrentScope();
                              Variable* param = reversed.top();
                              reversed.pop();
                              procedure->InsertParameter(param);
                              current_scope->PushTempProcParams(param);
                          }
                          current_scope->Insert(identifier, procedure);
                      }
                   ;
FunctionHeading    :  yfunction  yident  
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          if(current_scope->IsInScope(s))
                          {
                              yyerror(("REDEFINITION " + s).c_str());
                              YYERROR;
                          }
                          if(s == "")
                          {
                              yyerror((string("THAR BE BLANK NAMES HERE! THE TOKEN IS ") + string(yytext)).c_str());
                          }
                          Procedure* procedure = new Procedure(s);
                          current_scope->Insert(s, procedure);
                      }
                   |  yfunction  yident
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          current_scope->PushTempStrings(s);
                      }
                      FormalParameters
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          string identifier = current_scope->PopTempStrings();
                          if(current_scope->IsInScope(identifier))
                          {
                              yyerror(("REDEFINITION " + identifier).c_str());
                              YYERROR;
                          }
                          if(identifier == "")
                          {
                              yyerror((string("THAR BE BLANK NAMES HERE! THE TOKEN IS ") + string(yytext)).c_str());
                          }
                          Procedure* procedure = new Procedure(identifier);
                          stack<Variable*> reversed;
                          while(!current_scope->TempProcParamsEmpty())
                          {
                              reversed.push(current_scope->PopTempProcParams());
                          }
                          while(!reversed.empty())
                          {
                              LocalScope* current_scope = global_scope.GetCurrentScope();
                              Variable* param = reversed.top();
                              reversed.pop();
                              procedure->InsertParameter(param);
                              current_scope->PushTempProcParams(param);
                          }
                          current_scope->Insert(identifier, procedure);
                      }
                   ;
FormalParameters   :  yleftparen FormalParamList yrightparen 
                   ;
FormalParamList    :  OneFormalParam 
                   |  FormalParamList ysemicolon OneFormalParam
                   ;
OneFormalParam     :  yvar  IdentList  ycolon  yident
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          if(!current_scope->IsInScope(s))
                          {
                              yyerror(("UNDEFINED " + s).c_str());
                              YYERROR;
                          }
                          else
                          {
                              MetaType* var = current_scope->Get(s);
                              if(!var->GetType() == VARIABLE_TYPE)
                              {
                                  yyerror(("NOT A TYPE " + s).c_str());
                                  YYERROR;
                              }
                              else
                              {
                                  VariableType* type = (VariableType*)var;
                                  while(!current_scope->TempVarsEmpty())
                                  {
                                      Variable* param = current_scope->PopTempVars();
                                      param->SetVarType(type);
                                      current_scope->PushTempProcParams(param);
                                  }
                              }
                          }
                      }
                   |  IdentList  ycolon  yident
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          if(!current_scope->IsInScope(s))
                          {
                              yyerror(("UNDEFINED " + s).c_str());
                              YYERROR;
                          }
                          else
                          {
                              MetaType* var = current_scope->Get(s);
                              if(!var->GetType() == VARIABLE_TYPE)
                              {
                                  yyerror(("NOT A TYPE " + s).c_str());
                                  YYERROR;
                              }
                              else
                              {
                                  VariableType* type = (VariableType*)var;
                                  while(!current_scope->TempVarsEmpty())
                                  {
                                      Variable* param = current_scope->PopTempVars();
                                      param->SetVarType(type);
                                      current_scope->PushTempProcParams(param);
                                  }
                              }
                          }
                      }
                   ;

/***************************  More Operators  ********************************/

UnaryOperator      :  yplus
                      {
                          cout << "TEST UNARY PLUS" << endl;
                          global_scope.GetCurrentScope()->PushTempStrings("+");
                      }
                   |  yminus
                      {
                          cout << "TEST UNARY MINUS" << endl;
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
