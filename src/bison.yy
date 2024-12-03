%require "3.2"
%language "c++"
%locations

%define api.token.constructor 
%define api.value.type variant

%define parse.assert
%define parse.trace
%define parse.error detailed
%define parse.lac full
%define lr.type ielr

%param { Compiler& driver }

%code requires {
  #include <iostream>
  #include <string>
  #include <vector>
  #include <ast.hh>
  class Compiler;
}

%code {
  #include <compiler.hh>
}


/* --- Tokens --- */

%token routine_tk "routine declaration"
%token begin_tk "begin"
%token fn_tk "function declaration"
%token assign_tk "assignment"
%token arrow_tk "return type declaration"
%token if_tk "if"
%token else_tk "else"
%token while_tk "while"
%token return_tk "return"
%token gt ">"
%token lt "<"
%token ge ">="
%token le "<="
%token eq "=="
%token ne "!="

%type <int> EXP
%type <int> LITERAL
%type <int> EXP_LIST
%type <int> STATEMENT
%type <int> IF
%type <int> WHILE
%type <int> INPUT
%type <int> FN
%type <int> FN_DEF
%type <int> ARGS
%type <int> FUNCTIONS
%type <int> ROUTINE
%type <int> GLOBAL_SCOPE
%type <int> DECL_ASSIGN
%type <int> ASSIGN
%type <int> RET
%type <int> FN_RET_TYPE

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
%start GLOBAL_SCOPE;

/* Início do programa, pode ou não tem funções globais seguindos da begin fn main() */
ROUTINE:
  routine_tk id ';' {
    $$ = driver.add_node(Node {NodeType::routine,std::monostate()});
    auto idn = driver.add_identifier($2);
    driver.add_child($$, idn);
  }

GLOBAL_SCOPE:
  ROUTINE begin_tk FN {
    auto begin = driver.add_node(Node{NodeType::begin,std::monostate()});

    $$ = $1;

    driver.add_child($$, begin);
    driver.add_child(begin, $3);
  } | 
  ROUTINE FUNCTIONS begin_tk FN  {
    $$ = $1;
    auto begin = driver.add_node(Node{NodeType::begin,std::monostate()});

    driver.add_child($$, $2);
    driver.add_child($$, begin);
    driver.add_child(begin, $4);
  }
; 



/* Grupo de funções globais */
FUNCTIONS:
  FN {
    $$ = driver.add_node(Node {NodeType::definitions,std::monostate()});
    driver.add_child($$, $1);
  } |
  FN FUNCTIONS {
    $$ = $2;
    driver.add_child($$, $1);
  }

/* Argumentos para funções, pode ser nada, um argumento ou N */
ARGS:
  %empty {
    $$ = driver.add_node(Node {NodeType::args,std::monostate()});
  } |
  type id {
    auto idn = driver.add_identifier($2);
    auto type = driver.add_type($1);

    $$ = driver.add_node(Node {NodeType::args, std::monostate()});
    driver.add_child($$, idn);
    driver.add_child($$, type);
  } |
  ARGS ',' type id  {
    auto idn = driver.add_identifier($4);
    auto type = driver.add_type($3);

    $$ = $1;
    driver.add_child($$, idn);
    driver.add_child($$, type);
  }

FN_DEF:
  fn_tk id {
    $$ = driver.add_node(Node {NodeType::function,std::monostate()}); 
    auto idn = driver.add_identifier($2);
    driver.add_child($$, idn);
  }

/* Função, pode ou não ter argumentos, tem um marcador de tipo de retorno */
FN:
  FN_DEF '(' ARGS ')' FN_RET_TYPE '{' INPUT '}' {
    $$ = $1;

    driver.add_child($$, $3);
    driver.add_child($$, $5);
    driver.add_child($$, $7);
  }

FN_RET_TYPE:
  arrow_tk type {
    $$ = driver.add_type($2);
  }

/* Marca dados crus como strings, ints, vetores */
LITERAL:
 integer { $$ = driver.add_literal($1); } |
 floating_point { $$ = driver.add_literal($1); } |
 string { $$ = driver.add_literal($1); } |
 boolean { $$ = driver.add_literal($1); } |
 character { $$ = driver.add_literal($1); } |
 list { $$ = driver.add_literal($1); } |
 '[' EXP_LIST ']' {
    $$ = $2;
  }

/* Bloco de código, tem 0 ou N declarações  */
INPUT:
  %empty {
    $$ = driver.add_node(Node {NodeType::block, std::monostate()});
  } |
  INPUT STATEMENT {
    $$ = $1;
    driver.add_child($$, $2);
  }
;

/* Declarações podem ser de tipo, de tipo e inicialização, de atribuição, if, while ou retorno  */
STATEMENT:
  type id ';' {
    auto idn = driver.add_identifier($2);
    auto type = driver.add_type($1);

    $$ = driver.add_node(Node {NodeType::declaration,std::monostate()});
    driver.add_child($$, type);
    driver.add_child($$, idn);
  } |
  type '[' integer ']' id  ';' {
    auto idn = driver.add_identifier($5);
    auto type = driver.add_type($1, $3);

    $$ = driver.add_node(Node {NodeType::declaration,std::monostate()});
    driver.add_child($$, type);
    driver.add_child($$, idn);
  } |
  DECL_ASSIGN EXP ';' {
    $$ = $1;
    driver.add_child($$, $2);
  } |
  ASSIGN EXP ';' {
    $$ = $1;
    driver.add_child($$, $2);
  } |
  IF {
    $$ = $1;
  } |
  WHILE {
    $$ = $1;
  } |
  RET EXP ';' { 
    $$ = $1;
    driver.add_child($$, $2);
  }
;

RET: 
  return_tk {
    $$ = driver.add_node(Node {NodeType::return_,std::monostate()});
  }

ASSIGN:
  id assign_tk {
    auto idn = driver.add_identifier($1);

    $$ = driver.add_node(Node {NodeType::assign, std::monostate()});
    driver.add_child($$, idn);
  }

DECL_ASSIGN:
  type id assign_tk {
    auto idn = driver.add_identifier($2);
    auto type = driver.add_type($1);

    $$ = driver.add_node(Node {NodeType::declaration_assignment, std::monostate()});
    driver.add_child($$, type);
    driver.add_child($$, idn);
  } |
  type '[' integer ']' id assign_tk {
    auto idn = driver.add_identifier($5);
    auto type = driver.add_type($1, $3);

    $$ = driver.add_node(Node {NodeType::declaration_assignment, std::monostate()});
    driver.add_child($$, type);
    driver.add_child($$, idn);
  }


/* If, aceita qualquer expressão como argumento, pode ou não ter o else */
IF: 
  if_tk '(' EXP ')' '{' INPUT '}' {
    $$ = driver.add_node(Node {NodeType::if_,std::monostate()});
    driver.add_child($$, $3);
    driver.add_child($$, $6);
  } |
  if_tk '(' EXP ')' '{' INPUT '}' else_tk '{' INPUT '}' {
    $$ = driver.add_node(Node {NodeType::if_,std::monostate()});
    driver.add_child($$, $3);
    driver.add_child($$, $6);
    driver.add_child($$, $10);
  }

/* While, aceita qualquer expressão como argumento */
WHILE:
  while_tk '(' EXP ')' '{' INPUT '}' {
    $$ = driver.add_node(Node {NodeType::while_,std::monostate()});
    driver.add_child($$, $3);
    driver.add_child($$, $6);
  }

/* Não terminal auxiliar para uma lista de expressões em chamadas de função */
EXP_LIST:
  %empty { $$ = driver.add_node(Node{NodeType::exp_list,std::monostate()}); } |
  EXP { 
    $$ = driver.add_node(Node {NodeType::exp_list, std::monostate()});
    driver.add_child($$, $1);
  } |
  EXP ',' EXP_LIST  {
    $$ = $3;
    driver.add_child($$, $1);
  } 

/* 
  Expressões, podem ser um id, uma chamada de função, um literal,
  uma operação aritimética, uma operação lógica, ou um agrupamento de expressões [evidência/precedência]
*/
EXP:
  id { $$ = driver.add_identifier($1); }  |
  id '(' EXP_LIST ')' {
    $$ = driver.add_call($1, $3);
  } |
  LITERAL |
  EXP '+' EXP {
    $$ = driver.add_binary_op("+", $1, $3);
  } |
  EXP '-' EXP {
    $$ = driver.add_binary_op("-", $1, $3);
  } |
  EXP '*' EXP {
    $$ = driver.add_binary_op("*", $1, $3);
  } |
  EXP '/' EXP {
    $$ = driver.add_binary_op("/", $1, $3);
  } |
  EXP gt EXP {
    $$ = driver.add_binary_op(">", $1, $3);
  } |
  EXP lt EXP {
    $$ = driver.add_binary_op("<", $1, $3);
  } |
  EXP ge EXP {
    $$ = driver.add_binary_op(">=", $1, $3);
  } |
  EXP le EXP {
    $$ = driver.add_binary_op("<=", $1, $3);
  } |
  EXP eq EXP {
    $$ = driver.add_binary_op("==", $1, $3);
  } |
  EXP ne EXP  {
    $$ = driver.add_binary_op("!=", $1, $3);
  } |
  '(' EXP ')' {
    $$ = driver.add_node(Node {NodeType::precedence, std::monostate()});
    driver.add_child($$, $2);
  }
; 

%%

/* --- User code --- */
void yy::parser::error (const location_type& l, const std::string& m) {
  std::cerr << l << ": " << m << '\n';
}


