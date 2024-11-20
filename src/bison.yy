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
  #include <vector>
  class Compiler;
}
%code {
  #include <compiler.hh>
}

%printer { 
  yyo << "[";
  for (const auto& token : $$) {
    yyo << token << ' ';
  }
  yyo << "]";
 } <std::vector<std::string>>;
%printer { yyo << $$; } <*>;


/* --- Tokens --- */

%token routine_tk
%token begin_tk
%token fn_tk
%token assign_tk
%token arrow_tk
%token if_tk
%token else_tk
%token while_tk
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
%token <std::string> character
%token <std::vector<std::string>> list
%token <bool> boolean

%right assign_tk
%left '-' '+'
%left '*' '/'
%nonassoc gt lt ge le eq ne

%%
/* --- Grammar rules --- */
%start ROUTINE;

/* Início do programa, pode ou não tem funções globais seguindos da begin fn main() */
ROUTINE:
  routine_tk id ';' begin_tk FN |
  routine_tk id ';' FUNCTIONS begin_tk FN;
;

/* Grupo de funções globais */
FUNCTIONS:
  FN |
  FUNCTIONS FN

/* Argumentos para funções, pode ser nada, um argumento ou N */
ARGS:
  %empty |
  type id |
  type id ',' ARGS 

/* Função, pode ou não ter argumentos, tem um marcador de tipo de retorno */
FN:
  fn_tk id '(' ARGS ')' arrow_tk type '{' INPUT '}'

/* Marca dados crus como strings, ints, vetores */
LITERAL:
  integer
| floating_point
| string
| boolean
| character
| list

/* Bloco de código, tem nenhum ou N declarações  */
INPUT:
  %empty
  | INPUT STATEMENT
;

/* Declarações podem ser de tipo, de tipo e inicialização, de atribuição, if, while ou retorno  */
STATEMENT:
  type id ';' |
  type id assign_tk EXP ';' |
  id assign_tk EXP ';' |
  IF |
  WHILE |
  return_tk EXP ';' 
;

/* If, aceita qualquer expressão como argumento, pode ou não ter o else */
IF: 
  if_tk '(' EXP ')' '{' INPUT '}' |
  if_tk '(' EXP ')' '{' INPUT '}' else_tk '{' INPUT '}'

/* While, aceita qualquer expressão como argumento */
WHILE:
  while_tk '(' EXP ')' '{' INPUT '}'

/* Não terminal auxiliar para uma lista de expressões em chamadas de função */
EXP_LIST:
  %empty |
  EXP |
  EXP ',' EXP_LIST

/* 
  Expressões, podem ser um id, uma chamada de função, um literal,
  uma operação aritimética, uma operação lógica, ou um agrupamento de expressões [evidência/precedência]
*/
EXP:
  id |
  id '(' EXP_LIST ')' |
  LITERAL |
  EXP '+' EXP |
  EXP '-' EXP |
  EXP '*' EXP |
  EXP '/' EXP |
  EXP gt EXP |
  EXP lt EXP |
  EXP ge EXP |
  EXP le EXP |
  EXP eq EXP |
  EXP ne EXP  |
  '(' EXP ')' 
;

%%

/* --- User code --- */
void yy::parser::error (const location_type& l, const std::string& m) {
  std::cerr << l << ": " << m << '\n';
}


