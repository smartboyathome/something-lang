%{
#include <cstdio>
#include <iostream>
using namespace std;

// stuff from flex that bison needs to know about:
extern "C" int yylex();
extern "C" FILE *yyin;
void yyerror(const char *s) {
    count << "ERROR: " << s << endl;
}
%}

%start CompilationUnit
%token yand yarray yassign ybegin ycaret ycase ycolon ycomma yconst ydispose
       ydiv ydivide ydo ydot ydotdot ydownto yelse yend yequal yfalse yfor
       yfunction ygreater ygreaterequal yident yif yin yleftbracket yleftparen
       yless ylessequal yminus ymod ymultiply ynew ynil ynot ynotequal ynumber
       yof yor yplus yprocedure yprogram yread yreadln yrecord yrepeat
       yrightbracket yrightparen ysemicolon yset ystring ythen yto ytrue ytype
       yuntil yvar ywhile ywrite ywriteln yunknown

%union {
	char *sval;
}

%%
/************************** Overall program rules ****************************/

CompilationUnit     : ProgramModule;

ProgramModule       : yprogram yident ProgramParameters ysemicolon Block ydot;

ProgramParameters   : yleftparen IdentList yrightparen;

IdentList           : yident ycomma IdentList
                    | yident;

Block               : Declarations ybegin StatementSequence yend
                    | ybegin StatementSequence yend;

/***************************** Declaration rules *****************************/

Declarations        : ConstantDefBlock TypeDefBlock VariableDeclBlock SubprogDeclList
                    | ConstantDefBlock TypeDefBlock VariableDeclBlock
                    | ConstantDefBlock TypeDefBlock SubprogDeclList
                    | ConstantDefBlock VariableDeclBlock SubprogDeclList
                    | TypeDefBlock VariableDeclBlock SubprogDeclList
                    | ConstantDefBlock TypeDefBlock
                    | ConstantDefBlock VariableDeclBlock
                    | ConstantDefBlock SubprogDeclList
                    | TypeDefBlock VariableDeclBlock
                    | TypeDefBlock SubprogDeclList
                    | VariableDeclBlock SubprogDeclList
                    | ConstantDefBlock
                    | TypeDefBlock
                    | VariableDeclBlock
                    | SubprogDeclList;

/************************ Constant declaration rules *************************/

ConstantDefBlock    : yconst ConstantDefList;

ConstantDefList     : ConstantDef ysemicolon ConstantDefList
                    | ConstantDef ysemicolon;

ConstantDef         : yident yequal ConstExpression;

ConstExpression     : UnaryOperator ConstFactor
                    | ConstFactor
                    | ystring
                    | ynil;

ConstFactor         : yident
                    | ynumber
                    | ytrue
                    | yfalse
                    | ynil;

/************************** Type declaration rules ***************************/

TypeDefBlock        : ytype TypeDefList;

TypeDefList         : TypeDef ysemicolon TypeDefList
                    | TypeDef ysemicolon;

TypeDef             : yident yequal Type;

Type                : yident
                    | ArrayType
                    | PointerType
                    | RecordType
                    | SetType;

ArrayType           : yarray yleftbracket SubrangeList yrightbracket yof Type;

SubrangeList        : Subrange ycomma SubrangeList
                    | Subrange;

Subrange            : ConstFactor ydotdot ConstFactor
                    | ystring ydotdot ystring;

PointerType         : ycaret yident;

RecordType          : yrecord FieldListSequence yend;

FieldListSequence   : FieldList ysemicolon FieldListSequence
                    | FieldList;

FieldList           : IdentList ysemicolon Type;

SetType             : yset yof Subrange;

/************************ Variable declaration rules *************************/

VariableDeclBlock   : yvar VariableDeclList;

VariableDeclList    : VariableDecl ysemicolon VariableDeclList
                    | VariableDecl ysemicolon;

VariableDecl        : IdentList ycolon Type;

/************************ Subprog declaration rules **************************/

SubprogDeclList     : ProcedureDecl ysemicolon SubprogDeclList
                    | ProcedureDecl ysemicolon
                    | FunctionDecl ysemicolon SubprogDeclList
                    | FunctionDecl ysemicolon;

ProcedureDecl       : ProcedureHeading ysemicolon Block;

ProcedureHeading    : yprocedure yident FormalParameters
                    | yprocedure yident;

FormalParameters    : yleftparen OneFormalParamList;

OneFormalParamList  : OneFormalParam ysemicolon OneFormalParamList
                    | OneFormalParam;

OneFormalParam      : yvar IdentList ycolon yident
                    | IdentList ycolon yident;

FunctionDecl        : FunctionHeading ycolon yident ysemicolon Block;

FunctionHeading     : yfunction yident FormalParameters
                    | yfunction yident;

/***************************** Statement rules *******************************/

StatementSequence   : StatementList;

StatementList       : Statement ysemicolon Statement
                    | Statement;

Statement           : Assignment
                    | ProcedureCall
                    | IfStatement
                    | CaseStatement
                    | WhileStatement
                    | RepeatStatement
                    | ForStatement
                    | IOStatement
                    | MemoryStatement
                    | StatementSequence
                    | /* apparently this is an empty rule */
                    ;

Assignment          : Designator yassign Expression;

Designator          : yident DesignatorStuff
                    | yident;

DesignatorStuffList : DesignatorStuff DesignatorStuffList
                    | DesignatorStuff;

DesignatorStuff     : ydot yident
                    | yleftbracket ExpList yrightbracket
                    | ycaret;

ExpList             : Expression ExpList
                    | Expression;

Expression          : SimpleExpression Relation SimpleExpression
                    | SimpleExpression;

SimpleExpression    : UnaryOperator TermList
                    | TermList;

TermList            : Term AddOperator TermList
                    | Term;

Term                : FactorList;

FactorList          : Factor MultOperator FactorList
                    | Factor;

Factor              : ynumber
                    | ystring                    
                    | ytrue
                    | yfalse
                    | ynil
                    | Designator
                    | yleftparen Expression yrightparen
                    | ynot Factor
                    | Setvalue
                    | FunctionCall;

Setvalue            : yleftbracket ElementList yrightbracket
                    | yleftbracket yrightbracket;

ElementList         : Element ycomma ElementList
                    | Element;

Element             : ConstExpression ydotdot ConstExpression
                    | ConstExpression;

FunctionCall        : yident ActualParameters;

ActualParameters    : yleftparen ExpList yrightparen;

ProcedureCall       : yident ActualParameters
                    | yident;

IfStatement         : yif Expression ythen Statement yelse Statement
                    | yif Expression ythen Statement;

CaseStatement       : ycase Expression yof CaseList yend;

CaseList            : Case ysemicolon CaseList
                    : Case;

Case                : CaseLabelList ycolon Statement;

CaseLabelList       : ConstExpression ycomma CaseLabelList
                    | ConstExpression;

WhileStatement      : ywhile Expression ydo Statement;

RepeatStatement     : yrepeat StatementSequence yuntil Expression;

ForStatement        : yfor yident yassign Expression WhichWay Expression ydo Statement;

WhichWay            : yto
                    | ydownto;

IOStatement         : yread yleftparen DesignatorList yrightparen
                    | yreadln yleftparen DesignatorList yrightparen
                    | yreadln
                    | ywrite yleftparen ExpList yrightparen
                    | ywriteln yleftparen ExpList yrightparen
                    | ywriteln;

DesignatorList      : Designator ycomma DesignatorList
                    | Designator;

MemoryStatement     : ynew yleftparen yident yrightparen
                    | ydispose yleftparen yident yrightparen;



/****************************** Operator rules *******************************/

UnaryOperator       : yplus
                    | yminus;

MultOperator        : ymultiply
                    | ydivide
                    | ydiv
                    | ymod
                    | yand;

AddOperator         : yplus
                    | yminus
                    | yor;

Relation            : yequal
                    | ynotequal
                    | yless
                    | ylessequal
                    | ygreater
                    | ygreaterequal
                    | yin;
%%
