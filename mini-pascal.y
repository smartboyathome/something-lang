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
    cout << "***ERROR: " << s << " on line " << line_num << " with token " << yytext << endl;
}
extern "C" int yyparse();

GlobalScope global_scope;
deque<string> designator_deque;
deque<string> expression_deque;
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
                          *output_file << "#include <iostream>" << endl;
                          *output_file << "using namespace std;" << endl;
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
                              *output_file << "int main()" << endl << "{" << endl;
                              global_scope.IncrementScopeLevel();
                          }
                      }
                      StatementSequence  yend
                      {
                          if(is_main)
                          {
                              *output_file << OutputFunctor::make_indent(global_scope.CurrentScopeLevel());
                              *output_file << "return 0;" << endl;
                              global_scope.DecrementScopeLevel();
                              *output_file << "};" << endl;
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
                              if(non_temp_pointer) // Pointers will be output when they are verified.
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
                          if(type->GetEnumType() == VarTypes::POINTER)
                          {
                              Pointer* ptr = (Pointer*)type;
                              if(IsInScopeCheck(current_scope, ptr->GetTypeIdentifier())())
                              {
                                  MetaType* next = current_scope->Get(ptr->GetTypeIdentifier());
                                  if(IsMetatypeCheck(next, VARIABLE_TYPE)())
                                  {
                                      ptr->SetTypePtr((VariableType*)next);
                                  }
                              }
                          }
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
                          VariableType* type = current_scope->PopTempTypes();
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
                          if(type->GetEnumType() == VarTypes::ARRAY)
                          {
                              ArrayType* other_array = (ArrayType*)type;
                              VariableType* new_type = other_array->GetArrayType();
                              for(int i = 0; i < other_array->GetArrayDimensions(); ++i)
                              {
                                  array->AddDimension(other_array->ranges[i]);
                              }
                              array->SetArrayType(new_type);
                          }
                          else
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
                          AssignLeftOutput generate_output(global_scope.CurrentScopeLevel(), designator_deque);
                          *output_file << generate_output();
                          designator_deque.clear();
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
                              while(!expression_deque.empty())
                              {
                                  *output_file << expression_deque.front() << " ";
                                  expression_deque.pop_front();
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
                              *output_file << OutputFunctor::make_indent(global_scope.CurrentScopeLevel());
                              if(proc->GetName() == "writeln")
                              {
                                  *output_file << "cout << endl";
                              }
                              else if(proc->GetName() == "write")
                              {
                                  *output_file << "cout << \" \"";
                              }
                              else
                              {
                                  *output_file << proc->GetName() << "()";
                              }
                          }
                      }
                   |  yident
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          if(IsInScopeCheck(current_scope, s)())
                          {
                              MetaType* proc = current_scope->IsInScope(s) ? current_scope->Get(s) : current_scope->Get(s+"_");
                              IsMetatypeCheck(proc, PROCEDURE)();
                              if(proc->GetName() == "new")
                              {
                                  
                              }
                              else
                              {
                                  *output_file << OutputFunctor::make_indent(global_scope.CurrentScopeLevel());
                                  bool is_output = proc->GetName() == "write" || proc->GetName() == "writeln";
                                  bool is_input = proc->GetName() == "read" || proc->GetName() == "readln";
                                  if(is_output)
                                  {
                                      *output_file << "cout << ";
                                  }
                                  else if(is_input)
                                  {
                                      *output_file << "cin >> ";
                                  }
                                  else
                                  {
                                      *output_file << proc->GetName() << "(";
                                  }
                              }
                              current_scope->procedure_call = (Procedure*)proc;
                          }
                      }
                      ActualParameters
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          Procedure* proc = current_scope->procedure_call;
                          // Kyle says fight fire with fire, so here we go!
                          if(proc->GetName() == "new")
                          {
                              *output_file << OutputFunctor::make_indent(global_scope.CurrentScopeLevel());
                              *output_file << expression_deque.front() << " = ";
                              Variable* var = current_scope->PopTempExpressions();
                              current_scope->PushTempExpressions(var);
                              *output_file << OutputFunctor::get_c_value(var->GetVarType());
                              expression_deque.clear();
                          }
                          else
                          {
                              bool is_output = proc->GetName() == "write" || proc->GetName() == "writeln";
                              bool is_input = proc->GetName() == "read" || proc->GetName() == "readln";
                              bool do_newline = proc->GetName() == "writeln";
                              bool do_space = proc->GetName() == "write";
                              int count = 0;
                              while(!expression_deque.empty())
                              {
                                  string next_expr = expression_deque.front();
                                  if(is_output && next_expr == ",")
                                  {
                                      *output_file << " << ";
                                  }
                                  else if(is_input && next_expr == ",")
                                  {
                                      *output_file << " >> ";
                                  }
                                  else if(next_expr == ",")
                                  {
                                      ++count;
                                      *output_file << next_expr << " ";
                                  }
                                  else
                                  {
                                      if(proc->parameters.size() > count && proc->parameters[count]->IsOutput())
                                          *output_file << "&";
                                      *output_file << next_expr;
                                  }
                                  expression_deque.pop_front();
                              }
                              if(is_output && do_newline)
                                  *output_file << " << endl";
                              if(is_output && do_space)
                                  *output_file << " << \" \"";
                              else if(!is_output && !is_input)
                                  *output_file << ")";
                          }
                      }
                   ;
IfStatement        :  yif  Expression
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          Variable* var = current_scope->PopTempExpressions();
                          IsVarTypeCheck(var, VarTypes::BOOLEAN);
                          *output_file << OutputFunctor::make_indent(global_scope.CurrentScopeLevel());
                          *output_file << "if(";
                          bool first = true;
                          while(!expression_deque.empty())
                          {
                              if(!first)
                                  *output_file << " ";
                              else
                                  first = false;
                              *output_file << expression_deque.front();
                              expression_deque.pop_front();
                          }
                          *output_file << ")" << endl;
                          *output_file << OutputFunctor::make_indent(global_scope.CurrentScopeLevel());
                          *output_file << "{" << endl;
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
CaseStatement      :  ycase  Expression
                      {
                          *output_file << OutputFunctor::make_indent(global_scope.CurrentScopeLevel());
                          *output_file << "switch(";
                          while(!expression_deque.empty())
                          {
                              *output_file << expression_deque.front() << " ";
                              expression_deque.pop_front();
                          }
                          *output_file << ")" << endl;
                          *output_file << OutputFunctor::make_indent(global_scope.CurrentScopeLevel());
                          *output_file << "{" << endl;
                          global_scope.IncrementScopeLevel();
                      }
                      yof  CaseList  yend
                      {
                          global_scope.DecrementScopeLevel();
                          *output_file << OutputFunctor::make_indent(global_scope.CurrentScopeLevel());
                          *output_file << "}" << endl;
                      }
                   ;
CaseList           :  Case
                   |  CaseList  ysemicolon  Case  
                   ;
Case               :  CaseLabelList
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          *output_file << OutputFunctor::make_indent(global_scope.CurrentScopeLevel());
                          *output_file << "case ";
                          bool first = true;
                          while(!current_scope->TempConstantsEmpty())
                          {
                              if(!first)
                                  *output_file << ",";
                              else
                                  first = false;
                              *output_file << OutputFunctor::get_c_value(current_scope->PopTempConstants());
                          }
                          *output_file << ":" << endl;
                          global_scope.IncrementScopeLevel();
                      }
                      ycolon  Statement
                      {
                          *output_file << OutputFunctor::make_indent(global_scope.CurrentScopeLevel());
                          *output_file << "break;" << endl;
                          global_scope.DecrementScopeLevel();
                      }
                   ;
CaseLabelList      :  ConstExpression  
                   |  CaseLabelList  ycomma  ConstExpression   
                   ;
WhileStatement     :  ywhile  Expression
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          Variable* var = current_scope->PopTempExpressions();
                          IsVarTypeCheck(var, VarTypes::BOOLEAN);
                          *output_file << OutputFunctor::make_indent(global_scope.CurrentScopeLevel());
                          *output_file << "while(";
                          while(!expression_deque.empty())
                          {
                              *output_file << expression_deque.front() << " ";
                              expression_deque.pop_front();
                          }
                          *output_file << ")" << endl;
                          *output_file << OutputFunctor::make_indent(global_scope.CurrentScopeLevel());
                          *output_file << "{" << endl;
                          global_scope.IncrementScopeLevel();
                      }
                      ydo  Statement
                      {
                          global_scope.DecrementScopeLevel();
                          *output_file << OutputFunctor::make_indent(global_scope.CurrentScopeLevel());
                          *output_file << "}" << endl;
                      }
                   ;
RepeatStatement    :  yrepeat
                      {
                          *output_file << OutputFunctor::make_indent(global_scope.CurrentScopeLevel());
                          *output_file << "do" << endl;
                          *output_file << OutputFunctor::make_indent(global_scope.CurrentScopeLevel());\
                          *output_file << "{" << endl;
                          global_scope.IncrementScopeLevel();
                      }
                      StatementSequence  yuntil  Expression
                      {
                          global_scope.DecrementScopeLevel();
                          *output_file << OutputFunctor::make_indent(global_scope.CurrentScopeLevel());
                          *output_file << "} while(";
                          while(!expression_deque.empty())
                          {
                              *output_file << expression_deque.front() << " ";
                              expression_deque.pop_front();
                          }
                          *output_file << ");";
                      }
                   ;
ForStatement       :  yfor  yident
                      {
                          global_scope.GetCurrentScope()->PushTempStrings(s);
                      }
                      yassign  Expression
                      {
                          string temp = "";
                          while(!expression_deque.empty())
                          {
                              temp += expression_deque.front();
                              expression_deque.pop_front();
                          }
                          global_scope.GetCurrentScope()->PushTempStrings(temp);
                      }
                      WhichWay  Expression
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          string up_to_str = current_scope->PopTempStrings();
                          string left_side = current_scope->PopTempStrings();
                          string identifier = current_scope->PopTempStrings();
                          string right_side = "";
                          Variable* left_side_var = current_scope->PopTempExpressions();
                          Variable* right_side_var = current_scope->PopTempExpressions();
                          while(!expression_deque.empty())
                          {
                              right_side += expression_deque.front();
                              expression_deque.pop_front();
                          }
                          Variable* new_var = new Variable(identifier);
                          new_var->SetVarType(left_side_var->GetVarType());
                          bool up_to = up_to_str == "to";
                          ForStatementOutput generate_output(global_scope.CurrentScopeLevel(),
                              new_var, left_side, right_side, true);
                          *output_file << generate_output() << endl;
                          *output_file << OutputFunctor::make_indent(global_scope.CurrentScopeLevel());
                          *output_file << "{" << endl;
                          expression_deque.clear();
                          global_scope.IncrementScopeLevel();
                      }
                      ydo  Statement
                      {
                          global_scope.DecrementScopeLevel();
                          *output_file << OutputFunctor::make_indent(global_scope.CurrentScopeLevel());
                          *output_file << "}" << endl;
                      }
                   ;
WhichWay           :  yto
                      {
                          global_scope.GetCurrentScope()->PushTempStrings("to");
                      }
                   |  ydownto
                      {
                          global_scope.GetCurrentScope()->PushTempStrings("downto");
                      }
                   ;

/***************************  Designator Stuff  ******************************/

Designator         :  yident
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          if(IsInScopeCheck(current_scope, s)())
                          {
                              MetaType* metatype = current_scope->IsInScope(s) ? current_scope->Get(s) : current_scope->Get(s+"_");
                              current_scope->PushTempDesignators(metatype);
                              if(metatype->GetType() == VARIABLE && ((Variable*)metatype)->IsOutput())
                              {
                                  designator_deque.push_back("(*" + metatype->GetName() + ")");
                              }
                              else if(metatype->GetType() == VARIABLE_TYPE)
                              {
                                  designator_deque.push_back(OutputFunctor::get_c_func_type((VariableType*)metatype));
                              }
                              else
                              {
                                  designator_deque.push_back(metatype->GetName());
                              }
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
                                  designator_deque.push_back("." + s);
                              }
                          }
                          
                      }
                   |  yleftbracket
                      {
                          designator_deque.push_back("[");
                          expression_deque.push_back("[");
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
                              string expression_str = "";
                              while(expression_deque.back() != "[")
                              {
                                  string next_expr = expression_deque.back();
                                  if(next_expr == ",")
                                  {
                                      next_expr = "][";
                                  }
                                  expression_str = next_expr + expression_str;
                                  expression_deque.pop_back();
                              }
                              expression_deque.pop_back();
                              designator_deque.push_back(expression_str);
                              designator_deque.push_back("]");
                          }
                      }
                   |  ycaret
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          MetaType* metatype = current_scope->PopTempDesignators();
                          VariableType* type;
                          if(metatype->GetType() == VARIABLE)
                          {
                              type = ((Variable*)metatype)->GetVarType();
                          }
                          else
                          {
                              type = (VariableType*)type;
                          }
                          if(IsMetatypeCheck(type, VARIABLE_TYPE)() && IsVarTypeCheck(type, VarTypes::POINTER)())
                          {
                              current_scope->PushTempDesignators(((Pointer*)type)->GetTypePtr());
                              //string before = designator_deque.back();
                              //designator_deque.pop_back();
                              designator_deque.push_front("(*");
                              designator_deque.push_back(")");
                          }
                      }
                   ;
ActualParameters   :  yleftparen  ExpList  yrightparen
                   ;
ExpList            :  Expression   
                   |  ExpList  ycomma
                      {
                          expression_deque.push_back(",");
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
                   |  SimpleExpression  yin  SimpleExpression
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          string right_side = expression_deque.back();
                          expression_deque.pop_back();
                          Variable* right_side_expr = current_scope->PopTempVars();
                          string left_side = expression_deque.back();
                          expression_deque.pop_back();
                          Variable* left_side_expr = current_scope->PopTempVars();
                          
                          if(IsVarTypeCheck(right_side_expr, VarTypes::ARRAY)())
                          {
                              ArrayType* array = (ArrayType*)((Variable*)right_side_expr)->GetVarType();
                              if(IsVarTypeCheck(left_side_expr, array->GetArrayType()->GetEnumType())())
                              {
                                  expression_deque.push_back("count(");
                                  expression_deque.push_back(right_side);
                                  expression_deque.push_back(",");
                                  stringstream ss;
                                  if(array->ranges[0].rangeType == AcceptedTypes::INT)
                                      ss << right_side << "+" << array->ranges[0].intHigh + 1;
                                  else
                                      ss << right_side << "+" << (int)array->ranges[0].charHigh + 1;
                                  expression_deque.push_back(ss.str());
                                  expression_deque.push_back(",");
                                  expression_deque.push_back(left_side);
                                  expression_deque.push_back(") != 0");
                              }
                          }
                      }
                   ;
SimpleExpression   :  TermExpr
                   |  UnaryOperator  TermExpr
                   ;
TermExpr           :  Term  
                   |  TermExpr yplus
                      {
                          expression_deque.push_back("+");
                      }
                      Term
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          Variable* newvar = current_scope->PopTempVars();
                          VarTypes::Type types[] = {VarTypes::INTEGER, VarTypes::REAL};
                          if(IsOneOfVarTypesCheck(newvar, 2, types)())
                          {
                              if(!current_scope->TempVarsEmpty())
                              {
                                  Variable* oldvar = current_scope->PopTempVars();
                                  VarTypes::Type newvartype = newvar->GetVarType()->GetEnumType();
                                  VarTypes::Type oldvartype = oldvar->GetVarType()->GetEnumType();
                                  if(IsOneOfVarTypesCheck(oldvar, 2, types)())
                                  {
                                      VarTypes::Type newvar_type = newvar->GetVarType()->GetEnumType();
                                      VarTypes::Type oldvar_type = oldvar->GetVarType()->GetEnumType();
                                      if(newvar_type == VarTypes::REAL || oldvar_type == VarTypes::REAL)
                                      {
                                          RealType* real = new RealType("");
                                          double sum = 0.0;
                                          if(newvar_type == VarTypes::REAL)
                                          {
                                              sum += ((RealType*)newvar->GetVarType())->GetValue();
                                          }
                                          else
                                          {
                                              sum += ((IntegerType*)newvar->GetVarType())->GetValue();
                                          }
                                          if(oldvar_type == VarTypes::REAL)
                                          {
                                              sum += ((RealType*)oldvar->GetVarType())->GetValue();
                                          }
                                          else
                                          {
                                              sum += ((IntegerType*)oldvar->GetVarType())->GetValue();
                                          }
                                          real->SetValue(sum);
                                          Variable* next = new Variable("");
                                          next->SetVarType(real);
                                          current_scope->PushTempVars(next);
                                      }
                                      else
                                      {
                                          IntegerType* integer = new IntegerType("");
                                          int sum = ((IntegerType*)newvar->GetVarType())->GetValue() + ((IntegerType*)oldvar->GetVarType())->GetValue();
                                          integer->SetValue(sum);
                                          Variable* next = new Variable("");
                                          next->SetVarType(integer);
                                          current_scope->PushTempVars(next);
                                      }
                                  }
                              }
                              else
                              {
                                  current_scope->PushTempVars(newvar);
                              }
                          }
                      }
                   |  TermExpr yminus
                      {
                          expression_deque.push_back("-");
                      }
                      Term
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          Variable* newvar = current_scope->PopTempVars();
                          VarTypes::Type types[] = {VarTypes::INTEGER, VarTypes::REAL};
                          if(IsOneOfVarTypesCheck(newvar, 2, types)())
                          {
                              if(!current_scope->TempVarsEmpty())
                              {
                                  Variable* oldvar = current_scope->PopTempVars();
                                  VarTypes::Type newvartype = newvar->GetVarType()->GetEnumType();
                                  VarTypes::Type oldvartype = oldvar->GetVarType()->GetEnumType();
                                  if(IsOneOfVarTypesCheck(oldvar, 2, types)())
                                  {
                                      VarTypes::Type newvar_type = newvar->GetVarType()->GetEnumType();
                                      VarTypes::Type oldvar_type = oldvar->GetVarType()->GetEnumType();
                                      if(newvar_type == VarTypes::REAL || oldvar_type == VarTypes::REAL)
                                      {
                                          RealType* real = new RealType("");
                                          double sum = 0.0;
                                          if(newvar_type == VarTypes::REAL)
                                          {
                                              sum -= ((RealType*)newvar->GetVarType())->GetValue();
                                          }
                                          else
                                          {
                                              sum -= ((IntegerType*)newvar->GetVarType())->GetValue();
                                          }
                                          if(oldvar_type == VarTypes::REAL)
                                          {
                                              sum += ((RealType*)oldvar->GetVarType())->GetValue();
                                          }
                                          else
                                          {
                                              sum += ((IntegerType*)oldvar->GetVarType())->GetValue();
                                          }
                                          real->SetValue(sum);
                                          Variable* next = new Variable("");
                                          next->SetVarType(real);
                                          current_scope->PushTempVars(next);
                                      }
                                      else
                                      {
                                          IntegerType* integer = new IntegerType("");
                                          int sum = ((IntegerType*)oldvar->GetVarType())->GetValue() - ((IntegerType*)newvar->GetVarType())->GetValue();
                                          integer->SetValue(sum);
                                          Variable* next = new Variable("");
                                          next->SetVarType(integer);
                                          current_scope->PushTempVars(next);
                                      }
                                  }
                              }
                              else
                              {
                                  current_scope->PushTempVars(newvar);
                              }
                          }
                      }
                   |  TermExpr yor
                      {
                          expression_deque.push_back("||");
                      }
                      Term
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          Variable* newvar = current_scope->PopTempVars();
                          if(IsVarTypeCheck(newvar, VarTypes::BOOLEAN)())
                          {
                              if(!current_scope->TempVarsEmpty())
                              {
                                  Variable* oldvar = current_scope->PopTempVars();
                                  IsVarTypeCheck(newvar, VarTypes::BOOLEAN)();
                              }
                              else
                              {
                                  current_scope->PushTempVars(newvar);
                              }
                          }
                      }
                   ;
Term               :  Factor  
                   |  Term  ymultiply
                      {
                          expression_deque.push_back("*");
                      }
                      Factor
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          Variable* newvar = current_scope->PopTempVars();
                          VarTypes::Type types[] = {VarTypes::INTEGER, VarTypes::REAL};
                          if(IsOneOfVarTypesCheck(newvar, 2, types)())
                          {
                              if(!current_scope->TempVarsEmpty())
                              {
                                  Variable* oldvar = current_scope->PopTempVars();
                                  VarTypes::Type newvartype = newvar->GetVarType()->GetEnumType();
                                  VarTypes::Type oldvartype = oldvar->GetVarType()->GetEnumType();
                                  if(IsOneOfVarTypesCheck(oldvar, 2, types)())
                                  {
                                      VarTypes::Type newvar_type = newvar->GetVarType()->GetEnumType();
                                      VarTypes::Type oldvar_type = oldvar->GetVarType()->GetEnumType();
                                      if(newvar_type == VarTypes::REAL || oldvar_type == VarTypes::REAL)
                                      {
                                          RealType* real = new RealType("");
                                          double product = 1.0;
                                          if(newvar_type == VarTypes::REAL)
                                          {
                                              product *= ((RealType*)newvar->GetVarType())->GetValue();
                                          }
                                          else
                                          {
                                              product *= ((IntegerType*)newvar->GetVarType())->GetValue();
                                          }
                                          if(oldvar_type == VarTypes::REAL)
                                          {
                                              product *= ((RealType*)oldvar->GetVarType())->GetValue();
                                          }
                                          else
                                          {
                                              product *= ((IntegerType*)oldvar->GetVarType())->GetValue();
                                          }
                                          real->SetValue(product);
                                          Variable* next = new Variable("");
                                          next->SetVarType(real);
                                          current_scope->PushTempVars(next);
                                      }
                                      else
                                      {
                                          IntegerType* integer = new IntegerType("");
                                          int product = ((IntegerType*)newvar->GetVarType())->GetValue() * ((IntegerType*)oldvar->GetVarType())->GetValue();
                                          integer->SetValue(product);
                                          Variable* next = new Variable("");
                                          next->SetVarType(integer);
                                          current_scope->PushTempVars(next);
                                      }
                                  }
                              }
                              else
                              {
                                  current_scope->PushTempVars(newvar);
                              }
                          }
                      }
                   |  Term ydiv Factor
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          Variable* newvar = current_scope->PopTempVars();
                          if(IsVarTypeCheck(newvar, VarTypes::INTEGER)())
                          {
                              if(!current_scope->TempVarsEmpty())
                              {
                                  Variable* oldvar = current_scope->PopTempVars();
                                  VarTypes::Type newvartype = newvar->GetVarType()->GetEnumType();
                                  VarTypes::Type oldvartype = oldvar->GetVarType()->GetEnumType();
                                  if(IsVarTypeCheck(oldvar, VarTypes::INTEGER)())
                                  {
                                      current_scope->PushTempVars(newvar);
                                      string expression_right = expression_deque.back();
                                      expression_deque.pop_back();
                                      string expression_left = expression_deque.back();
                                      expression_deque.pop_back();
                                      expression_deque.push_back(expression_left);
                                      expression_deque.push_back("/");
                                      expression_deque.push_back(expression_right);
                                  }
                              }
                              else
                              {
                                  current_scope->PushTempVars(newvar);
                              }
                          }
                      }
                   |  Term ydivide Factor
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          Variable* newvar = current_scope->PopTempVars();
                          VarTypes::Type types[] = {VarTypes::INTEGER, VarTypes::REAL};
                          if(IsOneOfVarTypesCheck(newvar, 2, types)())
                          {
                              if(!current_scope->TempVarsEmpty())
                              {
                                  Variable* oldvar = current_scope->PopTempVars();
                                  VarTypes::Type newvartype = newvar->GetVarType()->GetEnumType();
                                  VarTypes::Type oldvartype = oldvar->GetVarType()->GetEnumType();
                                  if(IsOneOfVarTypesCheck(oldvar, 2, types)())
                                  {
                                      current_scope->PushTempVars(newvar);
                                      string expression_right = expression_deque.back();
                                      expression_deque.pop_back();
                                      string expression_left = expression_deque.back();
                                      expression_deque.pop_back();
                                      expression_deque.push_back("(");
                                      expression_deque.push_back("(double)");
                                      expression_deque.push_back(expression_left);
                                      expression_deque.push_back("/");
                                      expression_deque.push_back("(double)");
                                      expression_deque.push_back(expression_right);
                                      expression_deque.push_back(")");
                                  }
                              }
                              else
                              {
                                  current_scope->PushTempVars(newvar);
                              }
                          }
                      }
                   |  Term ymod 
                      {
                          expression_deque.push_back("%");
                      }
                      Factor
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          Variable* newvar = current_scope->PopTempVars();
                          if(IsVarTypeCheck(newvar, VarTypes::INTEGER)())
                          {
                              if(!current_scope->TempVarsEmpty())
                              {
                                  Variable* oldvar = current_scope->PopTempVars();
                                  IsVarTypeCheck(newvar, VarTypes::INTEGER)();
                              }
                              else
                              {
                                  current_scope->PushTempVars(newvar);
                              }
                          }
                      }
                   |  Term yand
                      {
                          expression_deque.push_back("&&");
                      }
                      Factor
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          Variable* newvar = current_scope->PopTempVars();
                          if(IsVarTypeCheck(newvar, VarTypes::BOOLEAN)())
                          {
                              if(!current_scope->TempVarsEmpty())
                              {
                                  Variable* oldvar = current_scope->PopTempVars();
                                  IsVarTypeCheck(newvar, VarTypes::BOOLEAN)();
                              }
                              else
                              {
                                  current_scope->PushTempVars(newvar);
                              }
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
                              IntegerType* Int = new IntegerType("integer", (int)temp_int);
                              Variable* var  = new Variable(s);
                              var->SetVarType(Int);
                              global_scope.GetCurrentScope()->PushTempVars(var);
                              IntOutput generate_output(global_scope.CurrentScopeLevel(), Int->GetValue());
                              expression_deque.push_back(generate_output());
                          }
                          else
                          {
                              RealType* Real = new RealType("real", temp);
                              Variable* var  = new Variable(s);
                              var->SetVarType(Real);
                              global_scope.GetCurrentScope()->PushTempTypes(Real);
                              RealOutput generate_output(global_scope.CurrentScopeLevel(), Real->GetValue());
                              expression_deque.push_back(generate_output());
                          }
                      }
                   |  ynil
                      {
                          Variable* var = new Variable("nil");
                          var->SetVarType(new NilType());
                          global_scope.GetCurrentScope()->PushTempVars(var);
                          expression_deque.push_back("NULL");
                      }
                   |  ystring
                      {
                          StringType* String = new StringType("char", s);
                          Variable* var = new Variable("");
                          var->SetVarType(String);
                          global_scope.GetCurrentScope()->PushTempVars(var);
                          StringOutput generate_output(global_scope.CurrentScopeLevel(), String->GetValue());
                          expression_deque.push_back(generate_output());
                      }
                   |  Designator
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          MetaType* var = current_scope->PopTempDesignators();
                          if(var->GetType() == VARIABLE_TYPE)
                          {
                              Variable* newvar = new Variable("");
                              newvar->SetVarType((VariableType*)var);
                              current_scope->PushTempVars(newvar);
                          }
                          else if(var->GetType() == VARIABLE)
                          {
                              current_scope->PushTempVars((Variable*)var);
                              
                          }
                          else if(var->GetType() == PROCEDURE)
                          {
                              current_scope->PushTempVars(((Procedure*)var)->GetReturnType());
                          }
                          DesignatorOutput generate_output(global_scope.CurrentScopeLevel(), designator_deque);
                          expression_deque.push_back(generate_output());
                          designator_deque.clear();
                      }
                   |  yleftparen
                      {
                          expression_deque.push_back("(");
                      }
                      Expression
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          current_scope->PushTempVars(current_scope->PopTempExpressions());
                          string expression_str = ")";
                          while(expression_deque.back() != "(")
                          {
                              expression_str = expression_deque.back() + " " + expression_str;
                              expression_deque.pop_back();
                          }
                          expression_deque.pop_back();
                          expression_deque.push_back("(" + expression_str);
                      }
                      yrightparen
                   |  ynot
                      {
                          expression_deque.push_back("!");
                      }
                      Factor
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
                          if(IsInScopeCheck(current_scope, s)())
                          {
                              MetaType* proc = current_scope->IsInScope(s) ? current_scope->Get(s) : current_scope->Get(s+"_");
                              if(IsMetatypeCheck(proc, PROCEDURE)())
                              {
                                  current_scope->PushTempVars(((Procedure*)proc)->GetReturnType());
                                  if(proc->GetName() == "writeln")
                                  {
                                      *output_file << "cout << endl";
                                  }
                                  else if(proc->GetName() == "write")
                                  {
                                      *output_file << "cout";
                                  }
                                  else
                                  {
                                      *output_file << proc->GetName() << "(";
                                  }
                                  expression_deque.push_back("(");
                              }
                          }
                      }
                      ActualParameters
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          Procedure* proc = current_scope->procedure_call;
                          // Kyle says fight fire with fire AGAIN, so here we go AGAIN!
                          deque<string> temp;
                          while(!expression_deque.empty() && expression_deque.back() != "(")
                          {
                              temp.push_back(expression_deque.back());
                              expression_deque.pop_back();
                          }
                          if(!expression_deque.empty())
                              expression_deque.pop_back();
                          while(!temp.empty())
                          {
                              string next_expr = temp.back();
                              *output_file << next_expr;
                              temp.pop_back();
                          }
                          *output_file << ")";
                      }
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
                          Variable* var = new Variable("");
                          var->SetVarType(array);
                          current_scope->PushTempVars(var);
                          *output_file << "}";
                      }
                   |  yleftbracket yrightbracket
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          ArrayType* array = new ArrayType("");
                          Variable* var = new Variable("");
                          var->SetVarType(array);
                          current_scope->PushTempVars(var);
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
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          string identifier = current_scope->PopTempStrings();
                          Procedure* proc = (Procedure*)current_scope->Get(identifier);
                          SubprogDefOutput generate_output(global_scope.CurrentScopeLevel(), proc, false);
                          *output_file << generate_output() << endl;
                          *output_file << generate_output.BeginBlock() << endl;
                          is_main = false;
                          CreateNewScope();
                      }
                      Block 
                      {
                          global_scope.PopCurrentScope();
                          *output_file << SubprogDefOutput::EndBlock(global_scope.CurrentScopeLevel()) << endl;
                          if(global_scope.CurrentScopeLevel() == 0)
                              is_main = true;
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
                              current_scope->current_procedure = func;
                              
                              SubprogDefOutput generate_output(global_scope.CurrentScopeLevel(), func, true);
                              *output_file << generate_output() << endl;
                              *output_file << generate_output.BeginBlock() << endl;
                              CreateNewScope();
                              VarDefOutput retval_output(global_scope.CurrentScopeLevel(), retval);
                              *output_file << retval_output() << endl;
                              is_main = false;
                          }
                          
                      }
                      ysemicolon  Block
                      {
                          global_scope.PopCurrentScope();
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          if(current_scope->current_procedure != NULL)
                          {
                              global_scope.IncrementScopeLevel();
                              Variable* retval = current_scope->current_procedure->GetReturnType();
                              *output_file << OutputFunctor::make_indent(global_scope.CurrentScopeLevel());
                              *output_file << "return " << retval->GetName() << ";" << endl;
                              current_scope->current_procedure = NULL;
                              global_scope.DecrementScopeLevel();
                              *output_file << SubprogDefOutput::EndBlock(global_scope.CurrentScopeLevel()) << endl;
                              if(global_scope.CurrentScopeLevel() == 0)
                                  is_main = true;
                          }
                      }
                   ;
ProcedureHeading   :  yprocedure  yident  
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          NotIsInScopeCheck(current_scope, s)();
                          Procedure* procedure = new Procedure(s + "_");
                          current_scope->Insert(s + "_", procedure);
                          current_scope->PushTempStrings(s+"_");
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
                              current_scope->PushTempStrings(identifier);
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
                                      param->ToggleOutput();
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
                          expression_deque.push_back("-");
                      }
Relation           :  yequal
                      {
                          expression_deque.push_back("==");
                      }
                   |  ynotequal
                      {
                          expression_deque.push_back("!=");
                      }
                   |  yless
                      {
                          expression_deque.push_back("<");
                      }
                   |  ygreater
                      {
                          expression_deque.push_back(">");
                      }
                   |  ylessequal
                      {
                          expression_deque.push_back("<=");
                      }
                   |  ygreaterequal
                      {
                          expression_deque.push_back(">=");
                      }
                   ;
%%
