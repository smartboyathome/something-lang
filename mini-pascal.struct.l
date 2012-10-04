%{
#include "tokenconsts.h"
#include <iostream>
using namespace std;
// This defines the main return type for a token. It matches up exactly with
// the typedef in main.cpp.
typedef struct token { int token; string extra; int line_number; } token;
#define YY_DECL extern "C" token *yylex()
// Initialize our token to some sane defaults.
token t = (token) { 0, "", 1 };
%}

%{
/* Basic charsets */
%}
digit               [0-9]
letter              [a-zA-Z]
whitespace          [ \t]
newline             \n
unknown             .

%{
/* Numbers */
%}

integer             {digit}+
floating_point      {integer}\.{integer}
expchar             [eE]
exponent            {expchar}[+-]?{integer}
real                {floating_point}({exponent})?
number              ({integer}|{real})

%{
/* Operators */
%}

plus                "+"
minus               "-"
multiply            "*"
divide              "/"
assignment          ":="
equal               "="
unequal             "<>"
less                "<"
less_equal          "<="
greater             ">"
greater_equal       ">="

left_parentheses    "("
right_parentheses   ")"
left_bracket        "["
right_bracket       "]"

semicolon           ";"
dot                 "."
double_dot          ".."
comma               ","
colon               ":"
caret               "^"

%{
/* Keywords 
   The (?i:*) triggers a case insensitive search. (?i:and) is equivalent to
   the regex [aA][nN][dD], but less ugly. */
%}

and                 [aA][nN][dD]
array               [aA][rR][rR][aA][yY]
begin               [bB][eE][gG][iI][nN]
case                [cC][aA][sS][eE]
const               [cC][oO][nN][sS][tT]
div                 [dD][iI][vV]
do                  [dD][oO]
downto              [dD][oO][wW][nN][tT][oO]
else                [eE][lL][sS][eE]
end                 [eE][nN][dD]
file                [fF][iI][lL][eE]
for                 [fF][oO][rR]
function            [fF][uU][nN][cC][tT][iI][oO][nN]
goto                [gG][oO][tT][oO]
if                  [iI][fF]
in                  [iI][nN]
label               [lL][aA][bB][eE][lL]
mod                 [mM][oO][dD]
nil                 [nN][iI][lL]
not                 [nN][oO][tT]
of                  [oO][fF]
or                  [oO][rR]
packed              [pP][aA][cC][kK][eE][dD]
procedure           [pP][rR][oO][cC][eE][dD][uU][rR][eE]
program             [pP][rR][oO][gG][rR][aA][mM]
record              [rR][eE][cC][oO][rR][dD]
repeat              [rR][eE][pP][eE][aA][tT]
set                 [sS][eE][tT]
then                [tT][hH][eE][nN]
to                  [tT][oO]
type                [tT][yY][pP][eE]
until               [uU][nN][tT][iI][lL]
var                 [vV][aA][rR]
while               [wW][hH][iI][lL][eE]
with                [wW][iI][tT][hH]

%{
/* These are not keywords, but special functions or values. I thought they were
   not supposed to be put in here, but the expected output has them, so I will
   put them in anyway. */
%}

dispose             [dD][iI][sS][pP][oO][sS][eE]
false               [fF][aA][lL][sS][eE]
new                 [nN][eE][wW]
read                [rR][eE][aA][dD]
readln              [rR][eE][aA][dD][lL][nN]
true                [tT][rR][uU][eE]
write               [wW][rR][iI][tT][eE]
writeln             [wW][rR][iI][tT][eE][lL][nN]

%{
/* Identifiers */
%}

identifier          {letter}({letter}|{digit})*

%{
/* Strings */
%}

single_quote        "'"
double_quote        "\""
esc_single_quote    "''"
esc_double_quote    "\"\""
inside_single       [^'\n]+
inside_double       [^\"\n]+

%{
/* Comments */
%}

left_curly          "{"
right_curly         "}"
inside_curly        [^}\n]+

left_comment        "(*"
right_comment       "*)"
inside_comment      [^*\n]+
comment_star        "*"
comment_newline     \n

%{
/* The "%s *" defines the start condition for when we enter comments and
   strings. */
%}

%s IN_PARENS_COMMENT
%s IN_CURLY_COMMENT
%s IN_SINGLE_QUOTE_STRING
%s IN_DOUBLE_QUOTE_STRING
%%

%{
/* INITIAL is a predefined (default) start condition, and allows us to
   separate the rules for inside and outside comments. */
%}

<INITIAL>{

%{
/* Operator rules come first. Rules are checked from top to bottom. */
%}

{plus}              { t.extra = ""; t.token = yplus; return &t; }
{minus}             { t.extra = ""; t.token = yminus; return &t; }
{multiply}          { t.extra = ""; t.token = ymultiply; return &t; }
{divide}            { t.extra = ""; t.token = ydivide; return &t; }
{assignment}        { t.extra = ""; t.token = yassign; return &t; }
{div}        		{ t.extra = ""; t.token = ydiv; return &t; }
{mod}       		{ t.extra = ""; t.token = ymod; return &t; }
{equal}             { t.extra = ""; t.token = yequal; return &t; }
{unequal}           { t.extra = ""; t.token = ynotequal; return &t; }
{less}              { t.extra = ""; t.token = yless; return &t; }
{less_equal}        { t.extra = ""; t.token = ylessequal; return &t; }
{greater}           { t.extra = ""; t.token = ygreater; return &t; }
{greater_equal}     { t.extra = ""; t.token = ygreaterequal; return &t; }

{semicolon}         { t.extra = ""; t.token = ysemicolon; return &t; }
{double_dot}        { t.extra = ""; t.token = ydotdot; return &t; }
{dot}               { t.extra = ""; t.token = ydot; return &t; }
{comma}             { t.extra = ""; t.token = ycomma; return &t; }
{colon}             { t.extra = ""; t.token = ycolon; return &t; }
{caret}             { t.extra = ""; t.token = ycaret; return &t; }

{left_parentheses}  { t.extra = ""; t.token = yleftparen; return &t; }
{right_parentheses} { t.extra = ""; t.token = yrightparen; return &t; }
{left_bracket}      { t.extra = ""; t.token = yleftbracket; return &t; }
{right_bracket}     { t.extra = ""; t.token = yrightbracket; return &t; }

%{
/* Keywords come next. They are string literals, so they are applied before
   any dynamic rules. */
%}

{and}               { t.extra = ""; t.token = yand; return &t; }
{array}             { t.extra = ""; t.token = yarray; return &t; }
{begin}             { t.extra = ""; t.token = ybegin; return &t; }
{case}              { t.extra = ""; t.token = ycase; return &t; }
{const}             { t.extra = ""; t.token = yconst; return &t; }
{do}                { t.extra = ""; t.token = ydo; return &t; }
{downto}            { t.extra = ""; t.token = ydownto; return &t; }
{else}              { t.extra = ""; t.token = yelse; return &t; }
{end}               { t.extra = ""; t.token = yend; return &t; }
{for}               { t.extra = ""; t.token = yfor; return &t; }
{function}          { t.extra = ""; t.token = yfunction; return &t; }
{if}                { t.extra = ""; t.token = yif; return &t; }
{in}                { t.extra = ""; t.token = yin; return &t; }
{nil}               { t.extra = ""; t.token = ynil; return &t; }
{not}               { t.extra = ""; t.token = ynot; return &t; }
{of}                { t.extra = ""; t.token = yof; return &t; }
{or}                { t.extra = ""; t.token = yor; return &t; }
{procedure}         { t.extra = ""; t.token = yprocedure; return &t; }
{program}           { t.extra = ""; t.token = yprogram; return &t; }
{record}            { t.extra = ""; t.token = yrecord; return &t; }
{repeat}            { t.extra = ""; t.token = yrepeat; return &t; }
{set}               { t.extra = ""; t.token = yset; return &t; }
{then}              { t.extra = ""; t.token = ythen; return &t; }
{to}                { t.extra = ""; t.token = yto; return &t; }
{type}              { t.extra = ""; t.token = ytype; return &t; }
{until}             { t.extra = ""; t.token = yuntil; return &t; }
{var}               { t.extra = ""; t.token = yvar; return &t; }
{while}             { t.extra = ""; t.token = ywhile; return &t; }
{with}              { t.extra = ""; t.token = yunknown; return &t; }

%{
/* These are the special functions/values mentioned above. I'm not a fan of
   including these here rather than the symbol table, but they are needed
   for the grader so I have included them. */
%}

{dispose}           { t.extra = ""; t.token = ydispose; return &t; }
{false}             { t.extra = ""; t.token = yfalse; return &t; }
{new}               { t.extra = ""; t.token = ynew; return &t; }
{read}              { t.extra = ""; t.token = yread; return &t; }
{readln}            { t.extra = ""; t.token = yreadln; return &t; }
{true}              { t.extra = ""; t.token = ytrue; return &t; }
{write}             { t.extra = ""; t.token = ywrite; return &t; }
{writeln}           { t.extra = ""; t.token = ywriteln; return &t; }

%{
/* Here are where the rules for the basic types like numbers and identifiers
   are applied. */
%}

{number}            { t.extra = yytext; t.token = ynumber; return &t; }
{identifier}        { t.extra = yytext; t.token = yident; return &t; }

%{
/* Strings start with either a single or double quote, therefore these start
   with either a single or double quote before switching to the string rules. */
%}

{single_quote}      { t.extra = ""; BEGIN(IN_SINGLE_QUOTE_STRING); }
{double_quote}      { t.extra = ""; BEGIN(IN_DOUBLE_QUOTE_STRING); }

%{
/* These define how comments are structured. BEGIN switches the rules to those
   for inside a comment instead (as defined below). */
%}

{left_curly}        { t.extra = ""; BEGIN(IN_CURLY_COMMENT); }
{left_comment}      { t.extra = ""; BEGIN(IN_PARENS_COMMENT); }

%{
/* Finally, these catch anything that is whitespace or unknown. Whitespace does
   nothing, newline increments the line count, and unknown returns the unknown
   characters to the parser. */
%}

{whitespace}        ;
{newline}           { ++t.line_number; }
{unknown}           { t.extra = yytext; t.token = yunknown; return &t; }

}

%{
/* These are the rules for when we are inside strings. None of the rules from
   either INITIAL or IN_*_COMMENT will be applied. */
%}

<IN_SINGLE_QUOTE_STRING>{

{esc_single_quote}  { t.extra = t.extra + "'"; }
{single_quote}      { BEGIN(INITIAL); t.token = ystring; return &t; }
{inside_single}     { t.extra = t.extra + yytext; }
{newline}           { ++t.line_number; t.extra = t.extra + yytext; }

}

<IN_DOUBLE_QUOTE_STRING>{

{esc_double_quote}  { t.extra = t.extra + "\""; }
{double_quote}      { BEGIN(INITIAL); t.token = ystring; return &t; }
{inside_double}     { t.extra = t.extra + yytext; }
{newline}           { ++t.line_number; t.extra = t.extra + yytext; }

}

%{
/* These are the rules for when we are inside comments. None of the rules from
   either INITIAL or IN_*_STRING will be applied. */
%}

<IN_PARENS_COMMENT>{

{right_comment}     { cout << "/*" << t.extra << "*/" << endl; BEGIN(INITIAL); }
{inside_comment}    { t.extra = t.extra + yytext; }
{comment_star}      { t.extra = t.extra + yytext; }
{newline}           { ++t.line_number; t.extra = t.extra + yytext; }

}

<IN_CURLY_COMMENT>{

{right_curly}       { cout << "/*" << t.extra << "*/" << endl; BEGIN(INITIAL); }
{inside_curly}      { t.extra = t.extra + yytext; }
{newline}           { ++t.line_number; t.extra = t.extra + yytext; }

}

%{
/* END OF RULES. */
%}

%%
