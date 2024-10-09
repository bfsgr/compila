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

%token routine_tk
%token begin_tk
%token fn_tk
%token assign_tk
%token arrow_tk
%token if_tk
%token return_tk
%token gt
%token lt
%token ge
%token le
%token eq
%token ne


%token <std::string> type
%token <std::string> id
%token <int> integer
%token <float> floating_point
%token <std::string> string
%token <bool> boolean

%right assign_tk
%left '-' '+'
%left '*' '/'

%%
/* --- Grammar rules --- */
%start ROUTINE;

ROUTINE:
  routine_tk id ';' begin_tk FN |
  routine_tk id ';' FUNCTIONS begin_tk FN;
;

FUNCTIONS:
  FN |
  FUNCTIONS FN

FN:
  fn_tk id '(' ')' arrow_tk type '{' INPUT '}'

LITERAL:
  integer
| floating_point
| string
| boolean

COMPARISON:
  EXP gt EXP |
  EXP lt EXP |
  EXP ge EXP |
  EXP le EXP |
  EXP eq EXP |
  EXP ne EXP |
  COMPARISON eq boolean |
  COMPARISON ne boolean
;

INPUT:
  %empty
  | INPUT STATEMENT
;

STATEMENT:
  type id ';' |
  type id assign_tk EXP ';' |
  id assign_tk EXP ';' |
  if_tk '(' COMPARISON ')' '{' INPUT '}' |
  return_tk EXP ';'
;

EXP:
  id |
  LITERAL |
  EXP '+' EXP |
  EXP '-' EXP |
  EXP '*' EXP |
  EXP '/' EXP |
  '(' EXP ')'
;

%%

/* --- User code --- */
void yy::parser::error (const location_type& l, const std::string& m) {
  std::cerr << l << ": " << m << '\n';
}


