%{
#include <cstdio>
#include <cstring>
#include <iostream>
#include <stack>
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
                                  Range range = current_scope->PopTempRanges() << endl;
                                  ss << "RANGE LOW " << range.low << " HIGH " << range.high << endl;
                              }
                              yyerror(ss.str().c_str());
                              YYERROR;
                          }
                          else
                          {
                              global_scope.CreateNewScope();
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
ConstantDef        :  yident  yequal  ConstExpression
                   ;
TypeDef            :  yident
                      {
                          global_scope.GetCurrentScope()->PushTempStrings(s);
                      }
                      yequal  Type
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          string identifier = current_scope->PopTempStrings();
                          if(current_scope->IsInLocalScope(string))
                          {
                              yyerror("REDEFINED: " + identifier);
                              YYERROR;
                          }
                          else
                          {
                              VariableType* type = current_scope->PopTempTypes();
                              type->SetName(identifier);
                              current_scope->Insert(identifier, type);
                          }
                      }
                   ;
VariableDecl       :  IdentList  ycolon  Type
                   ;

/***************************  Const/Type Stuff  ******************************/

ConstExpression    :  UnaryOperator ConstFactor
                   |  ConstFactor
                   |  ystring
                   ;
ConstFactor        :  yident
                      {
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          if(!current_scope->IsInScope(s))
                          {
                              yyerror("UNDEFINED: " + s);
                              YYERROR;
                          }
                          else 
                          {
                              MetaType* var = current_scope->Get(s);
                              if(var->GetType() != INTEGER)
                              {
                                  yyerror("WRONG TYPE: " + s);
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
                          LocalScope* current_scope = global_scope.GetCurrentScope();
                          if(!current_scope->IsInScope(s))
                          {
                              yyerror("UNDEFINED: " + s);
                              YYERROR;
                          }
                          else
                          {
                              LocalScope* current_scope = global_scope.GetCurrentScope();
                              VariableType* type = current_scope->Get(s);
                              current_scope->PushTempTypes(temp);
                          }
                      }
                   |  ArrayType
                      {
                          Array* array = new Array("");
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
                              array->AddDimension(range.low, range.high);
                          }
                          current_scope->PushTempTypes(array);
                      }
                   |  PointerType
                   |  RecordType
                   |  SetType
                      {
                          Array* array = new Array("");
                          // We can do this without a loop like above since there's
                          // only one range.
                          Range range = current_scope->PopTempRanges();
                          array->AddDimension(range.low, range.high);
                          global_scope.GetCurrentScope()->PushTempTypes(array);
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
                              yyerror("BAD SUBRANGE: '" + a + "'..'" + b + "'");
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
                   |  yident IOParameters
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

DesignatorList     :  Designator
                   |  DesignatorList  ycomma  Designator 
                   ;
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
IOParameters       :  yleftparen  DesignatorList  yrightparen
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
                   |  ynil
                   |  ystring
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
                   |  yleftbracket yrightbracket
                   ;
ElementList        :  Element  
                   |  ElementList  ycomma  Element
                   ;
Element            :  ConstExpression  
                   |  ConstExpression  ydotdot  ConstExpression 
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

UnaryOperator      :  yplus | yminus
                   ;
MultOperator       :  ymultiply | ydivide | ydiv | ymod | yand 
                   ;
AddOperator        :  yplus | yminus | yor
                   ;
Relation           :  yequal  | ynotequal | yless | ygreater 
                   |  ylessequal | ygreaterequal | yin
                   ;
%%
