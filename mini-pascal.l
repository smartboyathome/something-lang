%{
#include "y.tab.h"
#include <iostream>
#include <string>
using namespace std;
#define YY_DECL extern "C" int yylex()
string s;
int line_num = 1;

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
   This ugly mess makes all the keywords case insensitive manually. Unfortunately,
   the Linux lab's flex library doesn't support the case insensitive option. */
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

{plus}              { s = ""; return yplus; }
{minus}             { s = ""; return yminus; }
{multiply}          { s = ""; return ymultiply; }
{divide}            { s = ""; return ydivide; }
{assignment}        { s = ""; return yassign; }
{div}               { s = ""; return ydiv; }
{mod}               { s = ""; return ymod; }
{equal}             { s = ""; return yequal; }
{unequal}           { s = ""; return ynotequal; }
{less}              { s = ""; return yless; }
{less_equal}        { s = ""; return ylessequal; }
{greater}           { s = ""; return ygreater; }
{greater_equal}     { s = ""; return ygreaterequal; }

{semicolon}         { s = ""; return ysemicolon; }
{double_dot}        { s = ""; return ydotdot; }
{dot}               { s = ""; return ydot; }
{comma}             { s = ""; return ycomma; }
{colon}             { s = ""; return ycolon; }
{caret}             { s = ""; return ycaret; }

{left_parentheses}  { s = ""; return yleftparen; }
{right_parentheses} { s = ""; return yrightparen; }
{left_bracket}      { s = ""; return yleftbracket; }
{right_bracket}     { s = ""; return yrightbracket; }

%{
/* Keywords come next. They are string literals, so they are applied before
   any dynamic rules. */
%}

{and}               { s = ""; return yand; }
{array}             { s = ""; return yarray; }
{begin}             { s = ""; return ybegin; }
{case}              { s = ""; return ycase; }
{const}             { s = ""; return yconst; }
{do}                { s = ""; return ydo; }
{downto}            { s = ""; return ydownto; }
{else}              { s = ""; return yelse; }
{end}               { s = ""; return yend; }
{for}               { s = ""; return yfor; }
{function}          { s = ""; return yfunction; }
{if}                { s = ""; return yif; }
{in}                { s = ""; return yin; }
{nil}               { s = ""; return ynil; }
{not}               { s = ""; return ynot; }
{of}                { s = ""; return yof; }
{or}                { s = ""; return yor; }
{procedure}         { s = ""; return yprocedure; }
{program}           { s = ""; return yprogram; }
{record}            { s = ""; return yrecord; }
{repeat}            { s = ""; return yrepeat; }
{set}               { s = ""; return yset; }
{then}              { s = ""; return ythen; }
{to}                { s = ""; return yto; }
{type}              { s = ""; return ytype; }
{until}             { s = ""; return yuntil; }
{var}               { s = ""; return yvar; }
{while}             { s = ""; return ywhile; }

%{
/* These are the special functions/values mentioned above. I'm not a fan of
   including these here rather than the symbol table, but they are needed
   for the grader so I have included them. */
%}

{dispose}           { s = ""; return ydispose; }
{false}             { s = ""; return yfalse; }
{new}               { s = ""; return ynew; }
{read}              { s = ""; return yread; }
{readln}            { s = ""; return yreadln; }
{true}              { s = ""; return ytrue; }
{write}             { s = ""; return ywrite; }
{writeln}           { s = ""; return ywriteln; }

%{
/* Here are where the rules for the basic types like numbers and identifiers
   are applied. */
%}

{number}            { s = yytext; return ynumber; }
{identifier}        { s = yytext; for(int i = 0; i < s.length(); ++i) s[i] = tolower(s[i]); return yident; }

%{
/* Strings start with either a single or double quote, therefore these start
   with either a single or double quote before switching to the string rules. */
%}

{single_quote}      { s = ""; BEGIN(IN_SINGLE_QUOTE_STRING); }
{double_quote}      { s = ""; BEGIN(IN_DOUBLE_QUOTE_STRING); }

%{
/* These define how comments are structured. BEGIN switches the rules to those
   for inside a comment instead (as defined below). */
%}

{left_curly}        { s = ""; BEGIN(IN_CURLY_COMMENT); }
{left_comment}      { s = ""; BEGIN(IN_PARENS_COMMENT); }

%{
/* Finally, these catch anything that is whitespace or unknown. Whitespace does
   nothing, newline increments the line count, and unknown returns the unknown
   characters to the parser. */
%}

{whitespace}        ;
{newline}           { ++line_num; }
{unknown}           { s = yytext; return yunknown; }

}

%{
/* These are the rules for when we are inside strings. None of the rules from
   either INITIAL or IN_*_COMMENT will be applied. */
%}

<IN_SINGLE_QUOTE_STRING>{

{esc_single_quote}  { s = s + "'"; }
{single_quote}      { BEGIN(INITIAL); return ystring; }
<<EOF>>				{ BEGIN(INITIAL); return ystring; }
{inside_single}     { s = s + yytext; }
{newline}           { ++line_num; s = s + yytext; }

}

<IN_DOUBLE_QUOTE_STRING>{

{esc_double_quote}  { s = s + "\""; }
{double_quote}      { BEGIN(INITIAL); return ystring; }
<<EOF>>				{ BEGIN(INITIAL); return ystring; }
{inside_double}     { s = s + yytext; }
{newline}           { ++line_num; s = s + yytext; }

}

%{
/* These are the rules for when we are inside comments. None of the rules from
   either INITIAL or IN_*_STRING will be applied. */
%}

<IN_PARENS_COMMENT>{

{right_comment}     { BEGIN(INITIAL); }
<<EOF>>             { BEGIN(INITIAL); }
{inside_comment}    { s = s + yytext; }
{comment_star}      { s = s + yytext; }
{newline}           { ++line_num; s = s + yytext; }

}

<IN_CURLY_COMMENT>{

{right_curly}       { BEGIN(INITIAL); }
<<EOF>>             { BEGIN(INITIAL); }
{inside_curly}      { s = s + yytext; }
{newline}           { ++line_num; s = s + yytext; }

}

%{
/* END OF RULES. */
%}

%%
