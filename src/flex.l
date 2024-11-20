%option noyywrap nounput noinput debug

%top{
#include <compiler.hh>
#include <bison.hh>
#include <vector>
#include <iostream>
#include <limits>
#include <sstream>
using namespace yy;
}

%{
  /* Update location column each time a pattern is matched  */
  #define YY_USER_ACTION loc.columns(yyleng);
%}

/* --- Definitions --- */
INTEGER [0-9]+
FLOAT {INTEGER}+\.{INTEGER}+
BOOL true|false
STRING \"[^\"]*\" 
CHAR \'[^\']\'

LITERAL {INTEGER}|{FLOAT}|{BOOL}|{STRING}|{CHAR}

LIST \[({LITERAL}(?:,{LITERAL})*)?\]


IDENTIFIER [a-zA-Z_][a-zA-Z0-9_]*
TYPE int|float|string|bool|char|int<{INTEGER}>|float<{INTEGER}>|string<{INTEGER}>|bool<{INTEGER}>|char<{INTEGER}>


%%
  /* --- Code run in each yylex call --- */
  location& loc = driver.location;
  loc.step ();

  /* --- Rules --- */

[\n]+ { 
  loc.lines(yyleng);
  loc.step();
}

[[:blank:]]+ { 
  loc.step();
}

; { return parser::symbol_type(';', loc); }


routine { return parser::make_routine_tk(loc); }
fn { return parser::make_fn_tk(loc); }
begin { return parser::make_begin_tk(loc); }
-> { return parser::make_arrow_tk(loc); }
== { return parser::make_eq(loc); }
!= { return parser::make_ne(loc); }
\> { return parser::make_gt(loc); }
\< { return parser::make_lt(loc); }
\>= { return parser::make_ge(loc); }
\<= { return parser::make_le(loc); }
= { return parser::make_assign_tk(loc); }
- { return parser::symbol_type('-', loc); }
\+ { return parser::symbol_type('+', loc); }
\* { return parser::symbol_type('*', loc); }
\/ { return parser::symbol_type('/', loc); }
\( { return parser::symbol_type('(', loc); }
\) { return parser::symbol_type(')', loc); }
\{ { return parser::symbol_type('{', loc); }
\} { return parser::symbol_type('}', loc); }
if { return parser::make_if_tk(loc); }
return { return parser::make_return_tk(loc); }


{TYPE} { return parser::make_type(yytext, loc); }
{INTEGER} { 
  int parsed = atoi(yytext);

  if(parsed > std::numeric_limits<int>::max() || parsed < std::numeric_limits<int>::min()) {
    throw parser::syntax_error(loc, "Lexical error: integer overflow");
  }


  return parser::make_integer(atoi(yytext), loc);
}
{FLOAT} { return parser::make_floating_point(atof(yytext), loc); }
{BOOL} { return parser::make_boolean(std::string(yytext) == "true", loc); }
{STRING} { 
  auto parsed = std::string(yytext);
  return parser::make_string(parsed.substr(1, parsed.size() - 2), loc);
}
{CHAR} { 
  auto parsed = std::string(yytext);

  if(parsed.size() != 3) {
    throw parser::syntax_error(loc, "Lexical error: invalid char " + parsed);
  }

  return parser::make_character(parsed.substr(1, parsed.size() - 2), loc);
}
{LIST} { 
  auto parsed = std::string(yytext).substr(1, std::string(yytext).size() - 2);

  std::stringstream ss(parsed);
  std::string item;
  std::vector<std::string> result;

  while (std::getline(ss, item, ',')) {
      result.push_back(item);
  }

  return parser::make_list(result, loc);

}

{IDENTIFIER} { return parser::make_id(yytext, loc); }

. {
  throw parser::syntax_error(loc, "Lexical error: invalid symbol " + std::string(yytext));
}

<<EOF>> { return parser::make_YYEOF(loc); }
