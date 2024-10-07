%require "3.2"
%language "c++"
%locations

%define api.token.constructor 
%define api.value.type variant

%define parse.assert
%define parse.trace
%define parse.error detailed
%define parse.lac full

%param { Compiler& driver }

%code requires {
  #include <iostream>
  #include <string>
  class Compiler;
}
%code {
  #include <compiler.hh>
}

%printer { yyo << $$; } <*>;

/* --- Tokens --- */

%token <int> NUM
%nterm <int> exp

%%
/* --- Grammar rules --- */
input:
  %empty
| input line
;


line:
  '\n'
| exp '\n'
;

exp:
  NUM
;

%%

/* --- User code --- */
void yy::parser::error (const location_type& l, const std::string& m) {
  std::cerr << l << ": " << m << '\n';
}


