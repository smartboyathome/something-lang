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
#include "IdentTypes/Record.h"
#include "IdentTypes/Array.h"
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
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          while(!current_scope->TempPointersEmpty())
                          {
                              Pointer* pointer = current_scope->PopTempPointers();
                              string identifier = pointer->GetTypeIdentifier();
                              if(!current_scope->IsInScope(identifier))
                              {
                                  yyerror("This is not the type you're looking for...");
                                  YYERROR;
                              }
                              else
                              {
                                  MetaType* var = current_scope->Get(identifier);
                                  if(var->GetType() != VARIABLE_TYPE)
                                  {
                                      yyerror("It's a trap, not a type!");
                                      YYERROR;
                                  }
                                  else
                                  {
                                      VariableType* type = (VariableType*)var;
                                      pointer->SetTypePtr(type);
                                  }
                              }
                          }
                      }
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
                              if(current_scope->TempConstantsEmpty())
                                  cout << "TEST AFTER ConstDef 1a" << endl;
                              VariableType* type = current_scope->PopTempConstants();
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
                              cout << "TEST AFTER TYPE 1A identifier '" << identifier << "'" << endl;
                              current_scope->Insert(identifier, type);
                              cout << "TEST AFTER TYPE 1B" << endl;
                              if(type->GetEnumType() == VarTypes::POINTER)
                              {
                                  Pointer* ptr = (Pointer*)type;
                                  string type_identifier = ptr->GetTypeIdentifier();
                                  if(current_scope->IsInLocalScope(type_identifier))
                                  {
                                      MetaType* ptr_type = current_scope->GetFromLocal(type_identifier);
                                      if(ptr_type->GetType() != VARIABLE_TYPE)
                                      {
                                          yyerror(("NOT A TYPE " + type_identifier).c_str());
                                          YYERROR;
                                      }
                                      else
                                      {
                                          ptr->SetTypePtr((VariableType*)ptr_type);
                                      }
                                  }
                                  else
                                  {
                                      current_scope->PushTempPointers(ptr);
                                  }
                              }
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
                          
                          current_scope->PushTempConstants(new IntegerType("", value));
                          // TODO: Fix so that it pushes a variable.
                      }
                   |  ConstFactor
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          current_scope->PushTempConstants(new IntegerType("", current_scope->PopTempInts()));
                      }
                   |  ystring // TODO: handle strings
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          current_scope->PushTempConstants(new StringType("", s));
                      }
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
                          cout << "TEST B0" << endl;
                          global_scope.GetCurrentScope()->PushTempStrings(s);
                          cout << "TEST B1" << endl;
                      }
                      ydotdot  ystring
                      {
                          cout << "TEST C0" << endl;
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
                          cout << "TEST C1" << endl;
                      }
                   ;
RecordType         :  yrecord
                      {
                          cout << "TEST BEGIN RECORD 0" << endl;
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          Record* record = new Record("");
                          current_scope->PushTempTypes(record);
                          cout << "TEST BEGIN RECORD 1" << endl;
                      }
                      FieldListSequence  yend
                   ;
SetType            :  yset  yof  Subrange
                   ;
PointerType        :  ycaret  yident 
                      {
                          cout << "TEST POINTER TYPE 0" << endl;
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          Pointer* pointer = new Pointer("", s);
                          current_scope->PushTempTypes(pointer);
                          cout << "TEST POINTER TYPE 1" << endl;
                      }
                   ;
FieldListSequence  :  FieldList  
                   |  FieldListSequence  ysemicolon  FieldList
                   ;
FieldList          :  IdentList  ycolon  Type
                      {
                          cout << "TEST FIELDLIST 0" << endl;
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          VariableType* var_type = current_scope->PopTempTypes();
                          Record* record = (Record*)current_scope->PopTempTypes();
                          while(!current_scope->TempVarsEmpty())
                          {
                              Variable* var = current_scope->PopTempVars();
                              var->SetVarType(var_type);
                              record->InsertMember(var);
                          }
                          current_scope->PushTempTypes(record);
                          cout << "TEST FIELDLIST 1" << endl;
                      }
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
                          cout << "TEST ASSIGNMENT 0" << endl;
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          Variable* var = current_scope->PopTempExpressions();
                          MetaType* origtype = current_scope->PopTempDesignators();
                          cout << "TEST ASSIGNMENT 0A" << endl;
                          if(origtype->GetType() != VARIABLE)
                          {
                              yyerror(("NOT A VARIABLE '" + origtype->GetName() + "'").c_str());
                              YYERROR;
                          }
                          else
                          {
                              cout << "TEST ASSIGNMENT 0B" << endl;
                              Variable* origvar = (Variable*)origtype;
                              if(var->GetVarType() == NULL)
                                  cout << "TEST ASSIGNMENT 0B var is NULL ident is '" << var->GetName() << "' on line " << line_num << endl;
                              if(origvar->GetVarType() == NULL)
                                  cout << "TEST ASSIGNMENT 0B origvar is NULL" << endl;
                              if(var->GetVarType()->GetEnumType() != origvar->GetVarType()->GetEnumType())
                              {
                                  yyerror(("VAR TYPES DO NOT MATCH " + origtype->GetName() + " is of type " + VarTypes::ToString(origvar->GetVarType()->GetEnumType()) + " not type " + VarTypes::ToString(var->GetVarType()->GetEnumType())).c_str());
                                  YYERROR;
                              }
                              else
                              {
                                  cout << "TEST ASSIGNMENT 0C" << endl;
                                  origvar->SetVarType(var->GetVarType());
                              }
                              cout << "TEST ASSIGNMENT 0D" << endl;
                          }
                          cout << "TEST ASSIGNMENT 1" << endl;
                      }
                   ;
ProcedureCall      :  yident 
                      {
                          cout << "TEST PROCEDURECALL NOPARAMS 0" << endl;
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          if(!current_scope->IsInScope(s))
                          {
                               yyerror(("UNDEFINED " + s).c_str());
                               YYERROR;
                          }
                          else if(current_scope->Get(s)->GetType() != PROCEDURE)
                          {
                              yyerror("NOT A PROCEDURE");
                              YYERROR;
                          }
                          cout << "TEST PROCEDURECALL NOPARAMS 1" << endl;
                      }
                   |  yident
                      {
                          cout << "TEST PROCEDURECALL PARAMS 0" << endl;
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          if(!current_scope->IsInScope(s))
                          {
                               yyerror(("UNDEFINED " + s).c_str());
                               YYERROR;
                          }
                          else if(current_scope->Get(s)->GetType() != PROCEDURE)
                          {
                              yyerror("NOT A PROCEDURE");
                              YYERROR;
                          }
                          cout << "TEST PROCEDURECALL PARAMS 1" << endl;
                      }
                      ActualParameters
                   ;
IfStatement        :  yif  Expression
                      {
                          cout << "TEST IFSTATEMENT 0" << endl;
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          Variable* var = current_scope->PopTempExpressions();
                          if(var->GetVarType() == NULL)
                          {
                              cout << var->GetName() << "'s VarType is NULL" << endl;
                          }
                          else if(var->GetVarType()->GetEnumType() != VarTypes::BOOLEAN)
                          {
                              yyerror("NOT A BOOLEAN");
                              YYERROR;
                          }
                          cout << "TEST IFSTATEMENT 0" << endl;
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
                          cout << "TEST WHILESTATEMENT 0" << endl;
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          Variable* var = current_scope->PopTempExpressions();
                          if(var->GetVarType() == NULL)
                          {
                              cout << var->GetName() << "'s VarType is NULL" << endl;
                          }
                          else if(var->GetVarType()->GetEnumType() != VarTypes::BOOLEAN)
                          {
                              yyerror("NOT A BOOLEAN");
                              YYERROR;
                          }
                          cout << "TEST WHILESTATEMENT 0" << endl;
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
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          cout << "TEST DESIGNATOR 0" << endl;
                          if(s == "")
                              cout << "BLANK DESIGNATOR" << endl;
                          else
                              cout << "DESIGNATOR " << s << endl;
                          if(!current_scope->IsInScope(s))
                          {
                              yyerror(("DESIGNATOR NOT IN SCOPE "+s).c_str());
                              YYERROR;
                          }
                          else
                          {
                              current_scope->PushTempDesignators(current_scope->Get(s));
                          }
                          cout << "TEST ASSIGNMENT 1" << endl;
                      }
                      DesignatorStuff 
                   ;
DesignatorStuff    :  /*** empty ***/
                   |  DesignatorStuff  theDesignatorStuff
                   ;
theDesignatorStuff :  ydot yident 
                      {
                          cout << "TEST THEDESIGNATORSTUFF DOTIDENT 0" << endl;
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          MetaType* metatype = current_scope->PopTempDesignators();
                          if(metatype->GetType() == VARIABLE)
                          {
                              metatype = ((Variable*)metatype)->GetVarType();
                          }
                          if(metatype->GetType() != VARIABLE_TYPE)
                          {
                              string str_type;
                              switch(metatype->GetType())
                              {
                                  case(VARIABLE):
                                      str_type = "VARIABLE";
                                      break;
                                  case(PROCEDURE):
                                      str_type = "PROCEDURE";
                                      break;
                                  case(RANGE):
                                      str_type = "RANGE";
                                      break;
                                  case(POINTER):
                                      str_type = "POINTER";
                                      break;
                                  case(RECORD):
                                      str_type = "RECORD";
                                      break;
                                  default:
                                      str_type = "IDFK";
                                      break;
                              }
                              yyerror(("NOT A TYPE " + metatype->GetName() + " " + str_type).c_str());
                              YYERROR;
                          }
                          else
                          {
                              VariableType* type = (VariableType*)metatype;
                              if(type->GetEnumType() != VarTypes::RECORD)
                              {
                                  yyerror(("NOT A RECORD " + type->GetName()).c_str());
                                  YYERROR;
                              }
                              else
                              {
                                  Record* record = (Record*)type;
                                  if(!record->HasMember(s))
                                  {
                                      yyerror(("RECORD '" + record->GetName() + "' DOES NOT CONTAIN A MEMBER '" + s + "'").c_str());
                                      YYERROR;
                                  }
                                  else
                                  {
                                      current_scope->PushTempDesignators(record->GetMember(s));
                                  }
                              }
                          }
                          cout << "TEST THEDESIGNATORSTUFF DOTIDENT 1" << endl;
                          
                      }
                   |  yleftbracket ExpList yrightbracket 
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          MetaType* metatype = current_scope->PopTempDesignators();
                          if(metatype->GetType() == VARIABLE)
                          {
                              metatype = ((Variable*)metatype)->GetVarType();
                          }
                          if(metatype->GetType() != VARIABLE_TYPE)
                          {
                              yyerror(("NOT A TYPE " + metatype->GetName()).c_str());
                              YYERROR;
                          }
                          else
                          {
                              VariableType* type = (VariableType*)metatype;
                              if(type->GetEnumType() != VarTypes::ARRAY)
                              {
                                  yyerror(("NOT AN ARRAY " + type->GetName()).c_str());
                                  YYERROR;
                              }
                              else
                              {
                                  ArrayType* array = (ArrayType*)type;
                                  /*stack<Variable*> reversed;
                                  while(!current_scope->TempExpressionsEmpty())
                                  {
                                      Variable* var = current_scope->PopTempExpressions();
                                      if(var->GetVarType()->GetEnumType() != VarTypes::INTEGER && var->GetVarType()->GetEnumType() != VarTypes::STRING)
                                      {
                                          cout << "Type is " << VarTypes::ToString(var->GetVarType()->GetEnumType()) << endl;
                                          current_scope->PushTempVars(var);
                                          break;
                                      }
                                      reversed.push(var);
                                  }
                                  if(reversed.size() != array->GetArrayDimensions())
                                  {
                                      stringstream ss;
                                      ss << "WRONG NUMBER OF DIMENSIONS " << array->GetName();
                                      ss << " passed in dimensions: " << reversed.size();
                                      ss << " array dimensions: " << array->GetArrayDimensions();
                                      yyerror(ss.str().c_str());
                                      YYERROR;
                                  }
                                  else
                                  {
                                      while(!reversed.empty())
                                      {
                                          Variable* var = reversed.top();
                                          reversed.pop();
                                          VarTypes::Type var_type = var->GetVarType()->GetEnumType();
                                          AcceptedTypes::Types array_type = array->GetAcceptedType();
                                          if(!(var_type == VarTypes::INTEGER && array_type == AcceptedTypes::INT) ||
                                             !(var_type == VarTypes::STRING && array_type == AcceptedTypes::CHAR))
                                          {
                                              yyerror("WRONG INDEX TYPE");
                                              YYERROR;
                                          }
                                      }*/
                                  current_scope->PushTempDesignators(array->GetArrayType());
                                  //}
                              }
                          }
                      }
                   |  ycaret
                      {
                          cout << "TEST THEDESIGNATORSTUFF CARET 0" << endl;
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          MetaType* metatype = current_scope->PopTempDesignators();
                          if(metatype->GetType() == VARIABLE)
                          {
                              metatype = ((Variable*)metatype)->GetVarType();
                          }
                          if(metatype->GetType() != VARIABLE_TYPE)
                          {
                              yyerror(("NOT A TYPE " + metatype->GetName()).c_str());
                              YYERROR;
                          }
                          else
                          {
                              VariableType* type = (VariableType*)metatype;
                              if(type->GetEnumType() != VarTypes::POINTER)
                              {
                                  yyerror(("NOT A POINTER " + type->GetName()).c_str());
                                  YYERROR;
                              }
                              else
                              {
                                  current_scope->PushTempDesignators(((Pointer*)type)->GetTypePtr());
                              }
                          }
                          cout << "TEST THEDESIGNATORSTUFF CARET 1" << endl;
                      }
                   ;
ActualParameters   :  yleftparen  ExpList  yrightparen
                   ;
ExpList            :  Expression   
                   |  ExpList  ycomma  Expression       
                   ;

/***************************  Expression Stuff  ******************************/

Expression         :  SimpleExpression
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          current_scope->PushTempExpressions(current_scope->PopTempVars());
                      }  
                   |  SimpleExpression  Relation  SimpleExpression 
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          Variable* var = current_scope->PopTempVars();
                          var->SetVarType(new BooleanType());
                          current_scope->PushTempExpressions(var);
                      }
                   ;
SimpleExpression   :  TermExpr
                   |  UnaryOperator  TermExpr
                   ;
TermExpr           :  Term  
                   |  TermExpr AddOperator  Term
                      {
                          cout << "TEST ADDOPERATOR 0" << endl;
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          Variable* newvar = new Variable("");
                          newvar->SetVarType(current_scope->PopTempTypes());
                          if(newvar->GetVarType() == NULL)
                          {
                              cout << "The vartype is null!" << endl;
                          }
                          else if(!current_scope->TempVarsEmpty())
                          {
                              Variable* oldvar = current_scope->PopTempVars();
                              VarTypes::Type newvartype = newvar->GetVarType()->GetEnumType();
                              VarTypes::Type oldvartype = oldvar->GetVarType()->GetEnumType();
                              if(oldvar->GetVarType() == NULL)
                                  cout << "OLDVAR'S VARTYPE IS NULL" << endl;
                              if(newvar->GetVarType() == NULL)
                                  cout << "NEWVAR'S VARTYPE IS NULL" << endl;
                              if(newvar->GetVarType()->GetEnumType() != oldvar->GetVarType()->GetEnumType())
                              {
                                  yyerror(("TYPES DO NOT MATCH newvar is " + VarTypes::ToString(newvar->GetVarType()->GetEnumType()) + " oldvar is " + VarTypes::ToString(oldvar->GetVarType()->GetEnumType())).c_str());
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
                          cout << "TEST ADDOPERATOR 1" << endl;
                      }
                   ;
Term               :  Factor  
                      {
                          cout << "TEST TERM FACTOR 0" << endl;
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          Variable* var = new Variable("");
                          var->SetVarType(current_scope->PopTempTypes());
                          current_scope->PushTempVars(var);
                          cout << "TEST TERM FACTOR 1" << endl;
                      }
                   |  Term  MultOperator  Factor
                      {
                          cout << "TEST MULTIPLY OPERATOR 0" << endl;
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          Variable* newvar = new Variable("");
                          newvar->SetVarType(current_scope->PopTempTypes());
                          if(newvar->GetVarType() == NULL)
                          {
                              cout << "The vartype is null!" << endl;
                          }
                          else if(!current_scope->TempVarsEmpty())
                          {
                              Variable* oldvar = current_scope->PopTempVars();
                              VarTypes::Type newvartype = newvar->GetVarType()->GetEnumType();
                              VarTypes::Type oldvartype = oldvar->GetVarType()->GetEnumType();
                              if(newvar->GetVarType()->GetEnumType() != oldvar->GetVarType()->GetEnumType())
                              {
                                  yyerror(("TYPES DO NOT MATCH a = " + VarTypes::ToString(newvartype) + " b = " + VarTypes::ToString(oldvartype)).c_str());
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
                          cout << "TEST MULTIPLYOPERATOR 1" << endl;
                      }
                   ;
Factor             :  ynumber
                      {
                          cout << "TEST FACTOR NUMBER 0" << endl;
                          int temp;
                          stringstream(s) >> temp;
                          IntegerType* Int = new IntegerType("", temp);
                          global_scope.GetCurrentScope()->PushTempTypes(Int);
                          cout << "TEST FACTOR NUMBER 1" << endl;
                      }
                   |  ynil
                   |  ystring
                      {
                          cout << "TEST FACTOR STRING 0" << endl;
                          StringType* String = new StringType("", s);
                          global_scope.GetCurrentScope()->PushTempTypes(String);
                          cout << "TEST FACTOR NUMBER 1" << endl;
                      }
                   |  Designator
                      {
                          cout << "TEST FACTOR DESIGNATOR 0" << endl;
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          MetaType* var = current_scope->PopTempDesignators();
                          if(var->GetType() == RANGE)
                          {
                              string str_type = var->GetType() == VARIABLE_TYPE ? "VARIABLE_TYPE" : "RANGE";
                              yyerror(("BAD TYPE FOR OPERATION, " + var->GetName() + " is of type " + str_type).c_str());
                              YYERROR;
                          }
                          else if(var->GetType() == VARIABLE_TYPE)
                          {
                              current_scope->PushTempTypes((VariableType*)var);
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
                              current_scope->PushTempTypes(((Pointer*)var)->GetTypePtr()); // This will push null on NilType
                          }
                          cout << "TEST FACTOR DESIGNATOR 1" << endl;
                      }
                   |  yleftparen  Expression
                      {
                          cout << "TEST FACTOR EXPRESSION 0" << endl;
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          current_scope->PushTempTypes(current_scope->PopTempExpressions()->GetVarType());
                          cout << "TEST FACTOR EXPRESSION 1" << endl;
                      }
                      yrightparen
                   |  ynot Factor
                      {
                          cout << "TEST NOT FACTOR 0" << endl;
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          current_scope->PopTempVars();
                          Variable* var = new Variable("");
                          var->SetVarType(new BooleanType());
                          current_scope->PushTempVars(var);
                          cout << "TEST NOT FACTOR 1" << endl;
                      }
                   |  Setvalue
                   |  FunctionCall
                   ;
/*  Functions with no parameters have no parens, but you don't need         */
/*  to handle that in FunctionCall because it is handled by Designator.     */
/*  A FunctionCall has at least one parameter in parens, more are           */
/*  separated with commas.                                                  */
FunctionCall       :  yident
                      {
                          cout << "TEST FUNCTION CALL 0" << endl;
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
                          cout << "TEST FUNCTION CALL 1" << endl;
                      }
                      ActualParameters
                   ;
Setvalue           :  yleftbracket ElementList  yrightbracket
                      {
                          cout << "TEST SET VALUE 0" << endl;
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
                          cout << "TEST SET VALUE 1" << endl;
                      }
                   |  yleftbracket yrightbracket
                   ;
ElementList        :  Element  
                   |  ElementList  ycomma  Element
                   ;
Element            :  ConstExpression  
                      {
                          cout << "TEST ELEMENT CONST 0" << endl;
                          // TODO: Handle string consts.
                          VariableType* temp = global_scope.GetCurrentScope()->PopTempConstants();
                          if(temp->GetEnumType() == VarTypes::INTEGER)
                          {
                              int temp_val = ((IntegerType*)temp)->GetValue();
                              global_scope.GetCurrentScope()->PushTempRanges(Range(temp_val, temp_val));
                          }
                          else if(temp->GetEnumType() == VarTypes::STRING)
                          {
                              string temp_val = ((StringType*)temp)->GetValue();
                              if(temp_val.size() != 1)
                              {
                                  yyerror("STRING MUST BE 1 CHARACTER LONG!");
                                  YYERROR;
                              }
                              else
                              {
                                  global_scope.GetCurrentScope()->PushTempRanges(Range(temp_val[0], temp_val[0]));
                              }
                          }
                          cout << "TEST ELEMENT CONST 1" << endl;
                      }
                   |  ConstExpression  ydotdot  ConstExpression 
                      {
                          cout << "TEST ELEMENT DOTDOT 0" << endl;
                          // TODO: Handle string consts.
                          VariableType* b = global_scope.GetCurrentScope()->PopTempConstants();
                          VariableType* a = global_scope.GetCurrentScope()->PopTempConstants();
                          if(a->GetEnumType() != b->GetEnumType())
                          {
                              yyerror("Range types must match!");
                              YYERROR;
                          }
                          else if(a->GetEnumType() == VarTypes::INTEGER)
                          {
                              IntegerType* a_int = (IntegerType*)a;
                              IntegerType* b_int = (IntegerType*)b;
                              int a_val = a_int->GetValue();
                              int b_val = b_int->GetValue();
                              global_scope.GetCurrentScope()->PushTempRanges(Range(a_val, b_val));
                          }
                          else if(a->GetEnumType() == VarTypes::STRING)
                          {
                              StringType* a_str = (StringType*)a;
                              StringType* b_str = (StringType*)b;
                              string a_val = a_str->GetValue();
                              string b_val = b_str->GetValue();
                              if(a_val.size() != b_val.size() || a_val.size() != 1)
                              {
                                  yyerror("STRINGS MUST BE 1 CHARACTER LONG!");
                                  YYERROR;
                              }
                              else
                              {
                                  global_scope.GetCurrentScope()->PushTempRanges(Range(a_val[0], b_val[0]));
                              }
                          }
                          cout << "TEST ELEMENT DOTDOT 1" << endl;
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
                          cout << "TEST PROCEDUREHEADING NOPARAMS 0" << endl;
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
                          cout << "TEST PROCEDUREHEADING NOPARAMS 1" << endl;
                      }
                   |  yprocedure  yident
                      {
                          cout << "TEST PROCEDUREHEADING PARAMS IDENT 0" << endl;
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          current_scope->PushTempStrings(s);
                          cout << "TEST PROCEDUREHEADING PARAMS IDENT 1" << endl;
                      }
                      FormalParameters
                      {
                          cout << "TEST PROCEDUREHEADING PARAMS 0" << endl;
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
                          cout << "TEST PROCEDUREHEADING PARAMS 1" << endl;
                      }
                   ;
FunctionHeading    :  yfunction  yident  
                      {
                          cout << "TEST FUNCTIONHEADING NOPARAMS 0" << endl;
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
                          cout << "TEST FUNCTIONHEADING NOPARAMS 1" << endl;
                      }
                   |  yfunction  yident
                      {
                          cout << "TEST FUNCTIONHEADING PARAMS IDENT 0" << endl;
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          current_scope->PushTempStrings(s);
                          cout << "TEST FUNCTIONHEADING PARAMS IDENT 1" << endl;
                      }
                      FormalParameters
                      {
                          cout << "TEST FUNCTIONHEADING PARAMS 0" << endl;
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
                          cout << "TEST FUNCTIONHEADING PARAMS 0" << endl;
                      }
                   ;
FormalParameters   :  yleftparen FormalParamList yrightparen 
                   ;
FormalParamList    :  OneFormalParam 
                   |  FormalParamList ysemicolon OneFormalParam
                   ;
OneFormalParam     :  yvar  IdentList  ycolon  yident
                      {
                          cout << "TEST ONEFORMALPARAM VAR 0" << endl;
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
                          cout << "TEST ONEFORMALPARAM VAR 1" << endl;
                      }
                   |  IdentList  ycolon  yident
                      {
                          cout << "TEST ONEFORMALPARAM 0" << endl;
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
                          cout << "TEST ONEFORMALPARAM 1" << endl;
                      }
                   ;

/***************************  More Operators  ********************************/

UnaryOperator      :  yplus
                      {
                          cout << "TEST UNARY PLUS 0" << endl;
                          global_scope.GetCurrentScope()->PushTempStrings("+");
                          cout << "TEST UNARY PLUS 1" << endl;
                      }
                   |  yminus
                      {
                          cout << "TEST UNARY MINUS 0" << endl;
                          global_scope.GetCurrentScope()->PushTempStrings("-");
                          cout << "TEST UNARY MINUS 1" << endl;
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
