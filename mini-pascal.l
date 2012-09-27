%{
#include "tokenconsts.h"
#include <iostream>
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
/* Keywords */
%}

and                 "and"
array               "array"
begin               "begin"
case                "case"
const               "const"
int_divide          "div"
do                  "do"
downto              "downto"
else                "else"
end                 "end"
file                "file"
for                 "for"
function            "function"
goto                "goto"
if                  "if"
in                  "in"
label               "label"
int_modulus         "mod"
nil                 "nil"
not                 "not"
of                  "of"
or                  "or"
packed              "packed"
procedure           "procedure"
program             "program"
record              "record"
repeat              "repeat"
set                 "set"
then                "then"
to                  "to"
type                "type"
until               "until"
var                 "var"
while               "while"
with                "with"

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

{plus}              { s = yytext; return yplus; }
{minus}             { s = yytext; return yminus; }
{multiply}          { s = yytext; return ymultiply; }
{divide}            { s = yytext; return ydivide; }
{assignment}        { s = yytext; return yassign; }
{int_divide}        { s = yytext; return ydiv; }
{int_modulus}       { s = yytext; return ymod; }
{equal}             { s = yytext; return yequal; }
{unequal}           { s = yytext; return ynotequal; }
{less}              { s = yytext; return yless; }
{less_equal}        { s = yytext; return ylessequal; }
{greater}           { s = yytext; return ygreater; }
{greater_equal}     { s = yytext; return ygreaterequal; }

{semicolon}         { s = yytext; return ysemicolon; }
{double_dot}        { s = yytext; return ydotdot; }
{dot}               { s = yytext; return ydot; }
{comma}             { s = yytext; return ycomma; }
{colon}             { s = yytext; return ycolon; }
{caret}             { s = yytext; return ycaret; }

{left_parentheses}  { s = yytext; return yleftparen; }
{right_parentheses} { s = yytext; return yrightparen; }
{left_bracket}      { s = yytext; return yleftbracket; }
{right_bracket}     { s = yytext; return yrightbracket; }

%{
/* Keywords come next. They are string literals, so they are applied before
   any dynamic rules. */
%}

{and}               { s = yytext; return yand; }
{array}             { s = yytext; return yarray; }
{begin}             { s = yytext; return ybegin; }
{case}              { s = yytext; return ycase; }
{const}             { s = yytext; return yconst; }
{do}                { s = yytext; return ydo; }
{downto}            { s = yytext; return ydownto; }
{else}              { s = yytext; return yelse; }
{end}               { s = yytext; return yend; }
{for}               { s = yytext; return yfor; }
{function}          { s = yytext; return yfunction; }
{if}                { s = yytext; return yif; }
{in}                { s = yytext; return yin; }
{nil}               { s = yytext; return ynil; }
{not}               { s = yytext; return ynot; }
{of}                { s = yytext; return yof; }
{or}                { s = yytext; return yor; }
{procedure}         { s = yytext; return yprocedure; }
{program}           { s = yytext; return yprogram; }
{record}            { s = yytext; return yrecord; }
{repeat}            { s = yytext; return yrepeat; }
{set}               { s = yytext; return yset; }
{then}              { s = yytext; return ythen; }
{to}                { s = yytext; return yto; }
{type}              { s = yytext; return ytype; }
{until}             { s = yytext; return yuntil; }
{var}               { s = yytext; return yvar; }
{while}             { s = yytext; return ywhile; }
{with}              { s = yytext; return yunknown; }

%{
/* Here are where the rules for the basic types like strings, numbers, and
   identifiers are applied. */
%}

{number}            { s = yytext; return ynumber; }
{identifier}        { s = yytext; return yident; }

%{
/* Strings start with either a single or double quote, therefore these start
   with either a single or double quote before switching to the string rules. */
%}

{single_quote}      { s = yytext; BEGIN(IN_SINGLE_QUOTE_STRING); }
{double_quote}      { s = yytext; BEGIN(IN_DOUBLE_QUOTE_STRING); }

%{
/* These define how comments are structured. BEGIN switches the rules to those
   for inside a comment instead (as defined below). */
%}

{left_curly}        { s = yytext; BEGIN(IN_CURLY_COMMENT); }
{left_comment}      { s = yytext; BEGIN(IN_PARENS_COMMENT); }

%{
/* Finally, these catch anything that is whitespace or unknown. Whitespace does
   nothing, newline increments the line count, and unknown returns the unknown
   characters to the parser. */
%}

{whitespace}        ;
{newline}           { ++line_num; }
{unknown}           { s = yytext; return yunknown; }

}

<IN_SINGLE_QUOTE_STRING>{

{esc_single_quote}  { s = s + yytext; }
{single_quote}      { s = s + yytext; BEGIN(INITIAL); return ystring; }
{inside_single}     { s = s + yytext; }
{newline}           { ++line_num; s = s + yytext; }

}

<IN_DOUBLE_QUOTE_STRING>{

{esc_double_quote}  { s = s + yytext; }
{double_quote}      { s = s + yytext; BEGIN(INITIAL); return ystring; }
{inside_double}     { s = s + yytext; }
{newline}           { ++line_num; s = s + yytext; }

}

%{
/* These are the rules for when we are inside comments. None of the rules from
   INITIAL will be applied. */
%}

<IN_PARENS_COMMENT>{

{right_comment}     { s = s + yytext; cout <<"COMMENT: " << s << endl; BEGIN(INITIAL); }
{inside_comment}    { s = s + yytext; }
{comment_star}      { s = s + yytext; }
{newline}           { ++line_num; s = s + yytext; }

}

<IN_CURLY_COMMENT>{

{right_curly}       { s = s + yytext; cout <<"COMMENT: " << s << endl; BEGIN(INITIAL); }
{inside_curly}      { s = s + yytext; }
{newline}           { ++line_num; s = s + yytext; }

}

%{
/* END OF RULES. */
%}

%%
