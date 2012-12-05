%{
#include <cstdio>
#include <cstring>
#include <cmath>
#include <iostream>
#include <stack>
#include <vector>
#include <sstream>
#include <deque>
#include "Scopes.h"
#include "IdentTypes/MetaType.h"
#include "IdentTypes/Procedure.h"
#include "IdentTypes/Variable.h"
#include "IdentTypes/Record.h"
#include "IdentTypes/Array.h"
#include "GrammarUtils.h"
#include "CppOutputUtils.h"
using namespace std;
#define YYDEBUG 1

// stuff from flex that bison needs to know about:
extern "C" int yylex();
extern "C" FILE *yyin;
extern "C" char* yytext;
extern ostream* output_file;
extern string s; // This is the metadata, such a s an int or string value.
extern int line_num; // And this is the line number that flex is on.
void yyerror(const char *s) {
    cout << "ERROR: " << s << " on line " << line_num << " with token " << yytext << endl;
}
extern "C" int yyparse();

GlobalScope global_scope;
deque<string> output_deque;
bool is_main = true;

void CreateNewScope()
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
};

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
                          //global_scope.GetCurrentScope()->PushTempStrings(s);
                      }
                      ProgramParameters
                      {
                          LocalScope* prev_scope = global_scope.GetCurrentScope();
                          /*string program_name = prev_scope->PopTempStrings();
                          Procedure* program = new Procedure(program_name);*/
                          while(!prev_scope->TempVarsEmpty())
                          {
                              Variable* param = prev_scope->PopTempVars();
                              // Zander said to ignore these parameters, so we will.
                              delete param;
                          }
                          /*global_scope.CreateNewScope();
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          current_scope->Insert(program_name, program);
                          // This scope is for all the variables defined in the program.
                          global_scope.CreateNewScope();*/
                          *output_file << "#include <string>" << endl;
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
                          if(is_main)
                          {
                              *output_file << "void main()" << endl << "{" << endl;
                              global_scope.IncrementScopeLevel();
                          }
                      }
                      StatementSequence  yend
                      {
                          if(is_main)
                          {
                              *output_file << "};" << endl;
                              global_scope.DecrementScopeLevel();
                          }
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
                              if(IsInScopeCheck(current_scope, identifier)() && IsMetatypeCheck(current_scope->Get(identifier), VARIABLE_TYPE)())
                              {
                                  VariableType* type = (VariableType*)current_scope->Get(identifier);
                                  pointer->SetTypePtr(type);
                                  TypeDefOutput generate_output(global_scope.CurrentScopeLevel(), pointer);
                                  *output_file << generate_output() << endl;
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
                          if(NotIsInScopeCheck(current_scope, identifier)())
                          {
                              Variable* constvar = new Variable(identifier);
                              constvar->SetVarType(current_scope->PopTempConstants());
                              constvar->ToggleConst();
                              current_scope->Insert(identifier, constvar);
                              ConstDefOutput generate_output(global_scope.CurrentScopeLevel(), constvar);
                              *output_file << generate_output() << endl;
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
                          if(NotIsInLocalScopeCheck(current_scope, identifier)())
                          {
                              VariableType* type = current_scope->PopTempTypes();
                              type->SetName(identifier);
                              current_scope->Insert(identifier, type);
                              bool non_temp_pointer = true;
                              if(type->GetEnumType() == VarTypes::POINTER)
                              {
                                  Pointer* ptr = (Pointer*)type;
                                  string type_identifier = ptr->GetTypeIdentifier();
                                  if(current_scope->IsInLocalScope(type_identifier))
                                  {
                                      MetaType* ptr_type = current_scope->GetFromLocal(type_identifier);
                                      if(IsMetatypeCheck(ptr_type, VARIABLE_TYPE)())
                                      {
                                          ptr->SetTypePtr((VariableType*)ptr_type);
                                      }
                                  }
                                  else
                                  {
                                      non_temp_pointer = false;
                                      current_scope->PushTempPointers(ptr);
                                  }
                              }
                              else if(non_temp_pointer) // Pointers will be output when they are verified.
                              {
                                  TypeDefOutput generate_output(global_scope.CurrentScopeLevel(), type);
                                  *output_file << generate_output() << endl;
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
                              VarDefOutput generate_output(global_scope.CurrentScopeLevel(), var);
                              *output_file << generate_output() << endl;
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
                          if(IsInScopeCheck(current_scope, s)())
                          {
                              MetaType* var = current_scope->IsInScope(s) ? current_scope->Get(s) : current_scope->Get(s+"_");
                              if(IsMetatypeCheck(var, VARIABLE)() && IsVarTypeCheck(var, VarTypes::INTEGER)())
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
                          if(IsInScopeCheck(current_scope, s)())
                          {
                              MetaType* var = current_scope->IsInScope(s) ? current_scope->Get(s) : current_scope->Get(s+"_");
                              if(IsMetatypeCheck(var, VARIABLE_TYPE)())
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
                      {
                          *output_file << ";" << endl;
                      }
                   |  ProcedureCall
                      {
                          *output_file << ";" << endl;
                      }
                   |  IfStatement
                      {
                          *output_file << endl;
                      }
                   |  CaseStatement
                      {
                          *output_file << endl;
                      }
                   |  WhileStatement
                      {
                          *output_file << endl;
                      }
                   |  RepeatStatement
                      {
                          *output_file << endl;
                      }
                   |  ForStatement
                      {
                          *output_file << endl;
                      }
                   |  ybegin StatementSequence yend
                   |  /*** empty ***/
                   ;
Assignment         :  Designator
                      {
                          AssignLeftOutput generate_output(global_scope.CurrentScopeLevel(), output_deque);
                          *output_file << generate_output();
                          output_deque.clear();
                      }
                      yassign Expression
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          Variable* var = current_scope->PopTempExpressions();
                          MetaType* origtype = current_scope->PopTempDesignators();
                          MetaTypeType types[] = {VARIABLE, VARIABLE_TYPE};
                          if(IsOneOfMetatypesCheck(origtype, 2, types)())
                          {
                              if(origtype->GetType() == VARIABLE_TYPE) // Yes, this is sort of a hack since designator *shouldn't* return a type, but it does sometimes.
                              {
                                  VariableType* origvartype = (VariableType*)origtype;
                                  IsVarTypeCheck(var, origvartype->GetEnumType())();
                              }
                              else
                              {
                                  Variable* origvar = (Variable*)origtype;
                                  IsVarTypeCheck(var, origvar->GetVarType()->GetEnumType())();
                              }
                          }
                      }
                   ;
ProcedureCall      :  yident 
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          if(IsInScopeCheck(current_scope, s)())
                          {
                              MetaType* proc = current_scope->IsInScope(s) ? current_scope->Get(s) : current_scope->Get(s+"_");
                              IsMetatypeCheck(proc, PROCEDURE)();
                              *output_file << OutputFunctor::make_indent(global_scope.CurrentScopeLevel()) << proc->GetName() << "()";
                          }
                      }
                   |  yident
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          if(IsInScopeCheck(current_scope, s)())
                          {
                              MetaType* proc = current_scope->IsInScope(s) ? current_scope->Get(s) : current_scope->Get(s+"_");
                              IsMetatypeCheck(proc, PROCEDURE)();
                              *output_file << OutputFunctor::make_indent(global_scope.CurrentScopeLevel()) << proc->GetName() << "( ";
                          }
                      }
                      ActualParameters
                      {
                          *output_file << ")";
                      }
                   ;
IfStatement        :  yif
                      {
                          *output_file << OutputFunctor::make_indent(global_scope.CurrentScopeLevel()) << "if (";
                      }
                      Expression
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          Variable* var = current_scope->PopTempExpressions();
                          IsVarTypeCheck(var, VarTypes::BOOLEAN);
                          *output_file << ")" << endl;
                          *output_file << OutputFunctor::make_indent(global_scope.CurrentScopeLevel()) << "{" << endl;
                          global_scope.IncrementScopeLevel();
                      }
                      ythen  Statement
                      {
                          global_scope.DecrementScopeLevel();
                          *output_file << OutputFunctor::make_indent(global_scope.CurrentScopeLevel()) << "}" << endl;
                      }
                      ElsePart
                   ;
ElsePart           :  /*** empty ***/
                   |  yelse
                      {
                          *output_file << OutputFunctor::make_indent(global_scope.CurrentScopeLevel()) << "else" << endl;
                          *output_file << OutputFunctor::make_indent(global_scope.CurrentScopeLevel()) << "{" << endl;
                          global_scope.IncrementScopeLevel();
                      }
                      Statement
                      {
                          global_scope.DecrementScopeLevel();
                          *output_file << OutputFunctor::make_indent(global_scope.CurrentScopeLevel()) << "}" << endl;
                      }
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
                          IsVarTypeCheck(var, VarTypes::BOOLEAN);
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
                          if(IsInScopeCheck(current_scope, s)())
                          {
                              MetaType* metatype = current_scope->IsInScope(s) ? current_scope->Get(s) : current_scope->Get(s+"_");
                              current_scope->PushTempDesignators(metatype);
                              output_deque.push_back(metatype->GetName());
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
                              metatype = ((Variable*)metatype)->GetVarType();
                          }
                          if(IsMetatypeCheck(metatype, VARIABLE_TYPE)() && IsVarTypeCheck(metatype, VarTypes::RECORD)())
                          {
                              Record* record = (Record*)metatype;
                              if(!record->HasMember(s))
                              {
                                  yyerror(("RECORD '" + record->GetName() + "' DOES NOT CONTAIN A MEMBER '" + s + "'").c_str());
                              }
                              else
                              {
                                  current_scope->PushTempDesignators(record->GetMember(s));
                                  output_deque.push_back("." + record->GetName());
                              }
                          }
                          
                      }
                   |  yleftbracket
                      {
                          output_deque.push_back("[");
                      }
                      ExpList yrightbracket 
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          MetaType* metatype = current_scope->PopTempDesignators();
                          if(metatype->GetType() == VARIABLE)
                          {
                              metatype = ((Variable*)metatype)->GetVarType();
                          }
                          if(IsMetatypeCheck(metatype, VARIABLE_TYPE)() && IsVarTypeCheck(metatype, VarTypes::ARRAY)())
                          {
                              ArrayType* array = (ArrayType*)metatype;
                              current_scope->PushTempDesignators(array->GetArrayType());
                              output_deque.push_back("]");
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
                          if(IsMetatypeCheck(metatype, VARIABLE_TYPE)() && IsVarTypeCheck(metatype, VarTypes::POINTER)())
                          {
                              current_scope->PushTempDesignators(((Pointer*)metatype)->GetTypePtr());
                              output_deque.pop_back();
                              output_deque.push_back("(*" + metatype->GetName() + ")");
                          }
                      }
                   ;
ActualParameters   :  yleftparen  ExpList  yrightparen
                   ;
ExpList            :  Expression   
                   |  ExpList  ycomma
                      {
                          *output_file << ", ";
                      }
                      Expression       
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
                              if(IsVarTypeCheck(newvar, oldvar->GetVarType()->GetEnumType())())
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
                              if(IsVarTypeCheck(newvar, oldvar->GetVarType()->GetEnumType())())
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
                          double temp;
                          double temp_int;
                          stringstream(s) >> temp;
                          if(modf(temp, &temp_int) == 0.0)
                          {
                              IntegerType* Int = new IntegerType("", (int)temp_int);
                              global_scope.GetCurrentScope()->PushTempTypes(Int);
                              IntOutput generate_output(global_scope.CurrentScopeLevel(), Int->GetValue());
                              *output_file << generate_output() << " ";
                          }
                          else
                          {
                              RealType* Real = new RealType("", temp);
                              global_scope.GetCurrentScope()->PushTempTypes(Real);
                              RealOutput generate_output(global_scope.CurrentScopeLevel(), Real->GetValue());
                              *output_file << generate_output() << " ";
                          }
                      }
                   |  ynil
                   |  ystring
                      {
                          StringType* String = new StringType("", s);
                          global_scope.GetCurrentScope()->PushTempTypes(String);
                          StringOutput generate_output(global_scope.CurrentScopeLevel(), String->GetValue());
                          *output_file << generate_output() << " ";
                      }
                   |  Designator
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          MetaType* var = current_scope->PopTempDesignators();
                          if(var->GetType() == VARIABLE_TYPE)
                          {
                              current_scope->PushTempTypes((VariableType*)var);
                          }
                          else if(var->GetType() == VARIABLE)
                          {
                              current_scope->PushTempTypes(((Variable*)var)->GetVarType());
                              
                          }
                          else if(var->GetType() == PROCEDURE)
                          {
                              current_scope->PushTempTypes(((Procedure*)var)->GetReturnType()->GetVarType());
                          }
                          DesignatorOutput generate_output(global_scope.CurrentScopeLevel(), output_deque);
                          *output_file << generate_output() << " ";
                          output_deque.clear();
                      }
                   |  yleftparen
                      {
                          *output_file << "(";
                      }
                      Expression
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          current_scope->PushTempTypes(current_scope->PopTempExpressions()->GetVarType());
                      }
                      yrightparen
                      {
                          *output_file << ")";
                      }
                   |  ynot Factor
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          current_scope->PopTempVars();
                          Variable* var = new Variable("");
                          var->SetVarType(new BooleanType());
                          current_scope->PushTempVars(var);
                          *output_file << "!";
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
                          if(IsInScopeCheck(current_scope, s)())
                          {
                              MetaType* var = current_scope->IsInScope(s) ? current_scope->Get(s) : current_scope->Get(s+"_");
                              if(IsMetatypeCheck(var, PROCEDURE)())
                              {
                                  current_scope->PushTempTypes(((Procedure*)var)->GetReturnType()->GetVarType());
                              }
                          }
                      }
                      ActualParameters
                   ;
Setvalue           :  yleftbracket
                      {
                          *output_file << "{";
                      }
                      ElementList  yrightbracket
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
                          *output_file << "}";
                      }
                   |  yleftbracket yrightbracket
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          ArrayType* array = new ArrayType("");
                          current_scope->PushTempTypes(array);
                          *output_file << "{ }";
                      }
                   ;
ElementList        :  Element  
                   |  ElementList  ycomma
                      {
                          *output_file << ", ";
                      }
                      Element
                   ;
Element            :  ConstExpression  
                      {
                          VariableType* temp = global_scope.GetCurrentScope()->PopTempConstants();
                          if(temp->GetEnumType() == VarTypes::INTEGER)
                          {
                              int temp_val = ((IntegerType*)temp)->GetValue();
                              global_scope.GetCurrentScope()->PushTempRanges(Range(temp_val, temp_val));
                              *output_file << temp_val;
                          }
                          else if(temp->GetEnumType() == VarTypes::STRING)
                          {
                              string temp_val = ((StringType*)temp)->GetValue();
                              if(temp_val.size() != 1)
                              {
                                  yyerror("STRING MUST BE 1 CHARACTER LONG!");
                              }
                              else
                              {
                                  global_scope.GetCurrentScope()->PushTempRanges(Range(temp_val[0], temp_val[0]));
                                  *output_file << "'" << temp_val << "'";
                              }
                          }
                      }
                   |  ConstExpression  ydotdot  ConstExpression 
                      {
                          VariableType* b = global_scope.GetCurrentScope()->PopTempConstants();
                          VariableType* a = global_scope.GetCurrentScope()->PopTempConstants();
                          bool result = IsVarTypeCheck(a, b->GetEnumType())();
                          if(result && a->GetEnumType() == VarTypes::INTEGER)
                          {
                              IntegerType* a_int = (IntegerType*)a;
                              IntegerType* b_int = (IntegerType*)b;
                              int a_val = a_int->GetValue();
                              int b_val = b_int->GetValue();
                              if(a_val > b_val)
                              {
                                  // swap without using a temp var
                                  a_val ^= b_val;
                                  b_val ^= a_val;
                                  a_val ^= b_val;
                              }
                              global_scope.GetCurrentScope()->PushTempRanges(Range(a_val, b_val));
                              bool first = true;
                              for(int i = a_val; i < b_val; ++i)
                              {
                                  if(!first)
                                      *output_file << ", ";
                                  else
                                      first = false;
                                  *output_file << i << " ";
                              }
                          }
                          if(result && a->GetEnumType() == VarTypes::STRING)
                          {
                              StringType* a_str = (StringType*)a;
                              StringType* b_str = (StringType*)b;
                              string a_val = a_str->GetValue();
                              string b_val = b_str->GetValue();
                              if(a_val.size() != b_val.size() || a_val.size() != 1)
                              {
                                  yyerror("STRINGS MUST BE 1 CHARACTER LONG!");
                              }
                              else
                              {
                                  global_scope.GetCurrentScope()->PushTempRanges(Range(a_val[0], b_val[0]));
                                  char a_char = a_val[0];
                                  char b_char = b_val[0];
                                  if(a_char > b_char)
                                  {
                                      // swap without using a temp var
                                      a_char ^= b_char;
                                      b_char ^= a_char;
                                      a_char ^= b_char;
                                  }
                                  for(char i = a_char; i < b_char; ++i)
                                  {
                                      *output_file << "'" << i << "' ";
                                  }
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
                          CreateNewScope();
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
                          Procedure* func = (Procedure*)current_scope->Get(func_name+"_");
                          MetaType* metatype = current_scope->Get(s);
                          if(IsMetatypeCheck(metatype, VARIABLE_TYPE)())
                          {
                              Variable* retval = new Variable(func_name);
                              retval->SetVarType((VariableType*)metatype);
                              func->SetReturnType(retval);
                              current_scope->PushTempProcParams(retval);
                              SubprogDefOutput generate_output(global_scope.CurrentScopeLevel(), func);
                              *output_file << generate_output();
                          }
                          *output_file << SubprogDefOutput::BeginBlock(global_scope.CurrentScopeLevel()) << endl;
                          CreateNewScope();
                          is_main = false;
                          
                      }
                      ysemicolon  Block
                      {
                          global_scope.PopCurrentScope();
                          *output_file << SubprogDefOutput::EndBlock(global_scope.CurrentScopeLevel()) << endl;
                          if(global_scope.CurrentScopeLevel() == 0)
                              is_main = true;
                      }
                   ;
ProcedureHeading   :  yprocedure  yident  
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          NotIsInScopeCheck(current_scope, s)();
                          Procedure* procedure = new Procedure(s + "_");
                          current_scope->Insert(s + "_", procedure);
                      }
                   |  yprocedure  yident
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          current_scope->PushTempStrings(s);
                      }
                      FormalParameters
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          string var_identifier = current_scope->PopTempStrings();
                          string identifier = var_identifier + "_";
                          if(NotIsInScopeCheck(current_scope, identifier)())
                          {
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
                      }
                   ;
FunctionHeading    :  yfunction  yident  
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          if(NotIsInScopeCheck(current_scope, s)())
                          {
                              Procedure* procedure = new Procedure(s+"_");
                              current_scope->Insert(s+"_", procedure);
                              current_scope->PushTempStrings(s);
                          }
                      }
                   |  yfunction  yident
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          current_scope->PushTempStrings(s);
                      }
                      FormalParameters
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          string var_identifier = current_scope->PopTempStrings();
                          string identifier = var_identifier + "_";
                          if(NotIsInScopeCheck(current_scope, identifier)())
                          {
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
                              current_scope->PushTempStrings(var_identifier);
                          }
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
                          if(IsInScopeCheck(current_scope, s)())
                          {
                              MetaType* var = current_scope->IsInScope(s) ? current_scope->Get(s) : current_scope->Get(s+"_");
                              if(IsMetatypeCheck(var, VARIABLE_TYPE)())
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
                          if(IsInScopeCheck(current_scope, s)())
                          {
                              MetaType* var = current_scope->IsInScope(s) ? current_scope->Get(s) : current_scope->Get(s+"_");
                              if(IsMetatypeCheck(var, VARIABLE_TYPE)())
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
                          global_scope.GetCurrentScope()->PushTempStrings("+");
                      }
                   |  yminus
                      {
                          global_scope.GetCurrentScope()->PushTempStrings("-");
                          *output_file << "-";
                      }
                   ;
MultOperator       :  ymultiply
                      {
                          *output_file << "* ";
                      }
                   |  ydivide
                      {
                          *output_file << "/ ";
                      }
                   |  ydiv
                      {
                          *output_file << "/ ";
                      }
                   |  ymod
                      {
                          *output_file << "% ";
                      }
                   |  yand
                      {
                          *output_file << "& ";
                      }
                   ;
AddOperator        :  yplus
                      {
                          *output_file << "+ ";
                      }
                   |  yminus
                      {
                          *output_file << "- ";
                      }
                   |  yor
                      {
                          *output_file << "| ";
                      }
                   ;
Relation           :  yequal
                      {
                          *output_file << "== ";
                      }
                   |  ynotequal
                      {
                          *output_file << "!= ";
                      }
                   |  yless
                      {
                          *output_file << "< ";
                      }
                   |  ygreater
                      {
                          *output_file << "> ";
                      }
                   |  ylessequal
                      {
                          *output_file << "<= ";
                      }
                   |  ygreaterequal
                      {
                          *output_file << ">= ";
                      }
                   |  yin
                      {
                          // TODO: Should this be in a library?
                          *output_file << "";
                      }
                   ;
%%
