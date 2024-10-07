%option noyywrap nounput noinput debug

%top{
#include <compiler.hh>
#include <bison.hh>
using namespace yy;
}

%{
  /* Update location column each time a pattern is matched  */
  #define YY_USER_ACTION loc.columns(yyleng);
%}

/* --- Definitions --- */
INTEGER [0-9]+


%%
  /* --- Code run in each yylex call --- */
  location& loc = driver.location;
  loc.step ();

  /* --- Rules --- */

[\n]+ { 
  loc.lines(yyleng);
  loc.step();
  return parser::symbol_type('\n', loc);  
}

[[:blank:]] { 
  loc.step();
}

{INTEGER} { return parser::make_NUM(atoi(yytext), loc); }

. {
  throw parser::syntax_error(loc, "syntax error: invalid character: " + std::string(yytext));
}

<<EOF>> { return parser::make_YYEOF(loc); }
