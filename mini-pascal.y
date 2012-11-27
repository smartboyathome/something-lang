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
    cout << "ERROR: " << s << " on line " << line_num << " with token " << yytext << endl;
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
                      
                      StatementSequence  yend
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
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          string identifier = current_scope->PopTempStrings();
                          if(current_scope->IsInLocalScope(identifier))
                          {
                              yyerror(("REDEFINED: " + identifier).c_str());
                              YYERROR;
                          }
                          else
                          {
                              Variable* constvar = new Variable(identifier);
                              constvar->SetVarType(current_scope->PopTempConstants());
                              constvar->ToggleConst();
                              current_scope->Insert(identifier, constvar);
                          }
                      }
                   ;
TypeDef            :  yident
                      {
                          global_scope.GetCurrentScope()->PushTempStrings(s);
                      }
                      yequal  Type
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          string identifier = current_scope->PopTempStrings();
                          if(current_scope->IsInLocalScope(identifier))
                          {
                              yyerror(("REDEFINED: " + identifier).c_str());
                              YYERROR;
                          }
                          else
                          {
                              VariableType* type = current_scope->PopTempTypes();
                              type->SetName(identifier);
                              current_scope->Insert(identifier, type);
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
                          }
                      }
                   ;
VariableDecl       :  IdentList  ycolon  Type
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          VariableType* type = current_scope->PopTempTypes();
                          while(!current_scope->TempVarsEmpty())
                          {
                              Variable* var = current_scope->PopTempVars();
                              var->SetVarType(type);
                              current_scope->Insert(var->GetName(), var);
                          }
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
                              if(var->GetType() != VARIABLE)
                              {
                                  yyerror(("NOT A TYPE TYPE TAPPA: " + s).c_str());
                                  YYERROR;
                              }
                              else if(((Variable*)var)->GetVarType()->GetEnumType() != VarTypes::INTEGER)
                              {
                                  yyerror(("NOT OF TYPE INTEGER " + s).c_str());
                                  YYERROR;
                              }
                              else
                              {
                                  IntegerType* Int = (IntegerType*)((Variable*)var)->GetVarType();
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
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          if(!current_scope->IsInScope(s))
                          {
                              yyerror(("UNDEFINED: " + s).c_str());
                              YYERROR;
                          }
                          else
                          {
                              LocalScope* current_scope = global_scope.GetCurrentScope();
                              MetaType* var = current_scope->Get(s);
                              if(var->GetType() != VARIABLE_TYPE)
                              {
                                  yyerror(("NOT A TYPE " + s).c_str());
                                  YYERROR;
                              }
                              else
                              {
                                  current_scope->PushTempTypes((VariableType*) var);
                              }
                          }
                      }
                   |  ArrayType
                   |  PointerType
                   |  RecordType
                   |  SetType
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          ArrayType* array = new ArrayType("");
                          // We can do this without a loop like above since there's
                          // only one range.
                          Range range = current_scope->PopTempRanges();
                          array->AddDimension(range);
                          switch(range.rangeType)
                          {
                              case(AcceptedTypes::CHAR):
                                  array->SetArrayType((VariableType*)current_scope->Get("char"));
                                  break;
                              case(AcceptedTypes::INT):
                                  array->SetArrayType((VariableType*)current_scope->Get("integer"));
                                  break;
                          }
                          current_scope->PushTempTypes(array);
                      }
                   ;
ArrayType          :  yarray yleftbracket Subrange SubrangeList 
                      yrightbracket  yof Type
                      {
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
                      }
                   ;
SubrangeList       :  /*** empty ***/
                   |  SubrangeList ycomma Subrange 
                   ;
Subrange           :  ConstFactor ydotdot ConstFactor
                      {
                          int b = global_scope.GetCurrentScope()->PopTempInts();
                          int a = global_scope.GetCurrentScope()->PopTempInts();
                          Range temp(a, b);
                          global_scope.GetCurrentScope()->PushTempRanges(temp);
                      }
                   |  ystring
                      {
                          global_scope.GetCurrentScope()->PushTempStrings(s);
                      }
                      ydotdot  ystring
                      {
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
RecordType         :  yrecord
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          Record* record = new Record("");
                          current_scope->PushTempTypes(record);
                      }
                      FieldListSequence  yend
                   ;
SetType            :  yset  yof  Subrange
                   ;
PointerType        :  ycaret  yident 
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          Pointer* pointer = new Pointer("", s);
                          current_scope->PushTempTypes(pointer);
                      }
                   ;
FieldListSequence  :  FieldList  
                   |  FieldListSequence  ysemicolon  FieldList
                   ;
FieldList          :  IdentList  ycolon  Type
                      {
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
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          Variable* var = current_scope->PopTempExpressions();
                          MetaType* origtype = current_scope->PopTempDesignators();
                          if(origtype->GetType() != VARIABLE && origtype->GetType() != VARIABLE_TYPE)
                          {
                              string str_type = "";
                              switch(origtype->GetType())
                              {
                                  case VARIABLE_TYPE:
                                      str_type = "VariableType";
                                      break;
                                  case PROCEDURE:
                                      str_type = "Procedure";
                                      break;
                              }
                              yyerror(("NOT A VARIABLE '" + origtype->GetName() + "' is type '" + str_type + "'").c_str());
                              YYERROR;
                          }
                          else if(origtype->GetType() == VARIABLE_TYPE) // Yes, this is sort of a hack since designator *shouldn't* return a type, but it does sometimes.
                          {
                              VariableType* origvartype = (VariableType*)origtype;
                              if(var->GetVarType()->GetEnumType() != origvartype->GetEnumType())
                              {
                                  yyerror(("Var Types DO NOT MATCH " + origtype->GetName() + " is of type " + VarTypes::ToString(origvartype->GetEnumType()) + " not type " + VarTypes::ToString(var->GetVarType()->GetEnumType())).c_str());
                                  YYERROR;
                              }
                          }
                          else
                          {
                              Variable* origvar = (Variable*)origtype;
                              if(var->GetVarType()->GetEnumType() != origvar->GetVarType()->GetEnumType())
                              {
                                  yyerror(("VAR TYPES DO NOT MATCH " + origtype->GetName() + " is of type " + VarTypes::ToString(origvar->GetVarType()->GetEnumType()) + " not type " + VarTypes::ToString(var->GetVarType()->GetEnumType())).c_str());
                                  YYERROR;
                              }
                          }
                      }
                   ;
ProcedureCall      :  yident 
                      {
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
                      }
                   |  yident
                      {
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
                      }
                      ActualParameters
                   ;
IfStatement        :  yif  Expression
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          Variable* var = current_scope->PopTempExpressions();
                          if(var->GetVarType()->GetEnumType() != VarTypes::BOOLEAN)
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
                          Variable* var = current_scope->PopTempExpressions();
                          if(var->GetVarType()->GetEnumType() != VarTypes::BOOLEAN)
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
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          if(!current_scope->IsInScope(s))
                          {
                              yyerror(("DESIGNATOR NOT IN SCOPE "+s).c_str());
                              YYERROR;
                          }
                          else
                          {
                              current_scope->PushTempDesignators(current_scope->Get(s));
                          }
                      }
                      DesignatorStuff 
                   ;
DesignatorStuff    :  /*** empty ***/
                   |  DesignatorStuff  theDesignatorStuff
                   ;
theDesignatorStuff :  ydot yident 
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          MetaType* metatype = current_scope->PopTempDesignators();
                          if(metatype->GetType() == VARIABLE)
                          {
                              //cout << "Variable designator, id '" << metatype->GetName() << "' on line " << line_num << endl;
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
                                  yyerror(("NOT A RECORD " + type->GetName() + " is a " + VarTypes::ToString(type->GetEnumType())).c_str());
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
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          Variable* newvar = current_scope->PopTempVars();
                          if(!current_scope->TempVarsEmpty())
                          {
                              Variable* oldvar = current_scope->PopTempVars();
                              VarTypes::Type newvartype = newvar->GetVarType()->GetEnumType();
                              VarTypes::Type oldvartype = oldvar->GetVarType()->GetEnumType();
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
                      }
                   ;
Term               :  Factor  
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          Variable* var = new Variable("");
                          var->SetVarType(current_scope->PopTempTypes());
                          current_scope->PushTempVars(var);
                      }
                   |  Term  MultOperator  Factor
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          Variable* newvar = new Variable("");
                          newvar->SetVarType(current_scope->PopTempTypes());
                          if(!current_scope->TempVarsEmpty())
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
                      }
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
                      {
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
                              //cout << "Pushing on designator type " << var->GetName() << endl;
                              current_scope->PushTempTypes((VariableType*)var);
                          }
                          else if(var->GetType() == VARIABLE)
                          {
                              //cout << "Pushing on designator var " << var->GetName() << endl;
                              current_scope->PushTempTypes(((Variable*)var)->GetVarType());
                          }
                          else if(var->GetType() == PROCEDURE)
                          {
                              //cout << "Pushing on designator proc " << var->GetName() << endl;
                              current_scope->PushTempTypes(((Procedure*)var)->GetReturnType()->GetVarType());
                          }
                          else if(var->GetType() == POINTER)
                          {
                              current_scope->PushTempTypes(((Pointer*)var)->GetTypePtr()); // This will push null on NilType
                          }
                      }
                   |  yleftparen  Expression
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          current_scope->PushTempTypes(current_scope->PopTempExpressions()->GetVarType());
                      }
                      yrightparen
                   |  ynot Factor
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          current_scope->PopTempVars();
                          Variable* var = new Variable("");
                          var->SetVarType(new BooleanType());
                          current_scope->PushTempVars(var);
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
                                  current_scope->PushTempTypes(((Procedure*)var)->GetReturnType()->GetVarType());
                              }
                          }
                      }
                      ActualParameters
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
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          ArrayType* array = new ArrayType("");
                          current_scope->PushTempTypes(array);
                      }
                   ;
ElementList        :  Element  
                   |  ElementList  ycomma  Element
                   ;
Element            :  ConstExpression  
                      {
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
                      }
                   |  ConstExpression  ydotdot  ConstExpression 
                      {
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
                      }
                   ;

/***************************  Subprogram Stuff  ******************************/

SubprogDeclList    :  /*** empty ***/
                   |  SubprogDeclList ProcedureDecl ysemicolon  
                   |  SubprogDeclList FunctionDecl ysemicolon
                   ;
ProcedureDecl      :  ProcedureHeading  ysemicolon
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          if (!current_scope->AllTempsEmpty())
                          {
                              stringstream ss;
                              ss << "UNDEFINED:" << endl;
                              while(!current_scope->TempVarsEmpty())
                              {
                                  Variable* var = current_scope->PopTempVars();
                                  ss << "VAR " << var->GetName() << endl;
                                  delete var;
                              }
                              while(!current_scope->TempStringsEmpty())
                              {
                                  ss << "STRING " << current_scope->PopTempStrings() << endl;
                              }
                              while(!current_scope->TempTypesEmpty())
                              {
                                  VariableType* type = current_scope->PopTempTypes();
                                  ss << "TYPE " << type->GetName() << endl;
                                  delete type;
                              }
                              while(!current_scope->TempIntsEmpty())
                              {
                                  ss << "INT " << current_scope->PopTempInts() << endl;
                              }
                              while(!current_scope->TempRangesEmpty())
                              {
                                  Range range = current_scope->PopTempRanges();
                                  ss << "RANGE " << range.ToString() << endl;
                              }
                              yyerror(ss.str().c_str());
                              YYERROR;
                          }
                          else
                          {
                              global_scope.CreateNewScope();
                              LocalScope* new_scope = global_scope.GetCurrentScope();
                              while(!current_scope->TempProcParamsEmpty())
                              {
                                  Variable* param = current_scope->PopTempProcParams();
                                  new_scope->Insert(param->GetName(), param);
                              }
                          }
                      }
                      Block 
                      {
                          global_scope.PopCurrentScope();
                      }
                   ;
FunctionDecl       :  FunctionHeading  ycolon  yident
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          string func_name = current_scope->PopTempStrings();
                          Procedure* func = (Procedure*)current_scope->Get(func_name);
                          MetaType* metatype = current_scope->Get(s);
                          if(metatype->GetType() != VARIABLE_TYPE)
                          {
                              yyerror("Functions must return a type.");
                              YYERROR;
                          }
                          else
                          {
                              //cout << "Creating function " << func_name << endl;
                              Variable* retval = new Variable(func_name);
                              retval->SetVarType((VariableType*)metatype);
                              func->SetReturnType(retval);
                              current_scope->PushTempProcParams(retval);
                          }
                          if (!current_scope->AllTempsEmpty())
                          {
                              stringstream ss;
                              ss << "UNDEFINED:" << endl;
                              while(!current_scope->TempVarsEmpty())
                              {
                                  Variable* var = current_scope->PopTempVars();
                                  ss << "VAR " << var->GetName() << endl;
                                  delete var;
                              }
                              while(!current_scope->TempStringsEmpty())
                              {
                                  ss << "STRING " << current_scope->PopTempStrings() << endl;
                              }
                              while(!current_scope->TempTypesEmpty())
                              {
                                  VariableType* type = current_scope->PopTempTypes();
                                  ss << "TYPE " << type->GetName() << endl;
                                  delete type;
                              }
                              while(!current_scope->TempIntsEmpty())
                              {
                                  ss << "INT " << current_scope->PopTempInts() << endl;
                              }
                              while(!current_scope->TempRangesEmpty())
                              {
                                  Range range = current_scope->PopTempRanges();
                                  ss << "RANGE " << range.ToString() << endl;
                              }
                              yyerror(ss.str().c_str());
                              YYERROR;
                          }
                          else
                          {
                              global_scope.CreateNewScope();
                              LocalScope* new_scope = global_scope.GetCurrentScope();
                              while(!current_scope->TempProcParamsEmpty())
                              {
                                  Variable* param = current_scope->PopTempProcParams();
                                  new_scope->Insert(param->GetName(), param);
                              }
                          }
                      }
                      ysemicolon  Block
                      {
                          global_scope.PopCurrentScope();
                      }
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
                          current_scope->PushTempStrings(s);
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
                          current_scope->PushTempStrings(identifier);
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
                                      //cout << "Assigning var " << param->GetName() << " type " << type->GetName() << endl;
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
                                      //cout << "Assigning var " << param->GetName() << " type " << type->GetName() << endl;
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
