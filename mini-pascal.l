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

{plus}              { return yplus; }
{minus}             { return yminus; }
{multiply}          { return ymultiply; }
{divide}            { return ydivide; }
{assignment}        { return yassign; }
{div}               { return ydiv; }
{mod}               { return ymod; }
{equal}             { return yequal; }
{unequal}           { return ynotequal; }
{less}              { return yless; }
{less_equal}        { return ylessequal; }
{greater}           { return ygreater; }
{greater_equal}     { return ygreaterequal; }

{semicolon}         { return ysemicolon; }
{double_dot}        { return ydotdot; }
{dot}               { return ydot; }
{comma}             { return ycomma; }
{colon}             { return ycolon; }
{caret}             { return ycaret; }

{left_parentheses}  { return yleftparen; }
{right_parentheses} { return yrightparen; }
{left_bracket}      { return yleftbracket; }
{right_bracket}     { return yrightbracket; }

%{
/* Keywords come next. They are string literals, so they are applied before
   any dynamic rules. */
%}

{and}               { return yand; }
{array}             { return yarray; }
{begin}             { return ybegin; }
{case}              { return ycase; }
{const}             { return yconst; }
{do}                { return ydo; }
{downto}            { return ydownto; }
{else}              { return yelse; }
{end}               { return yend; }
{for}               { return yfor; }
{function}          { return yfunction; }
{if}                { return yif; }
{in}                { return yin; }
{nil}               { return ynil; }
{not}               { return ynot; }
{of}                { return yof; }
{or}                { return yor; }
{procedure}         { return yprocedure; }
{program}           { return yprogram; }
{record}            { return yrecord; }
{repeat}            { return yrepeat; }
{set}               { return yset; }
{then}              { return ythen; }
{to}                { return yto; }
{type}              { return ytype; }
{until}             { return yuntil; }
{var}               { return yvar; }
{while}             { return ywhile; }

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
