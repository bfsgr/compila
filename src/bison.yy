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
%token <std::string> gt ">"
%token <std::string> lt "<"
%token <std::string> ge ">="
%token <std::string> le "<="
%token <std::string> eq "=="
%token <std::string> ne "!="

%type <int> EXP
%type <int> LITERAL
%type <std::vector<int>> EXP_LIST
%type <int> STATEMENT
%type <int> IF
%type <int> WHILE
%type <std::vector<int>> INPUT
%type <int> FN
%type <std::vector<std::pair<Token, Token>>> ARGS
%type <int> FUNCTIONS
%type <int> ROUTINE
%type <int> GLOBAL_SCOPE

%token <std::string> type
%token <std::string> id
%token <int> integer
%token <float> floating_point
%token <std::string> string
%token <std::string> character
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
    $$ = driver.add_node(Node {NodeType::routine, $2, std::nullopt, std::nullopt, "void", driver.loc(@$)});
  }

GLOBAL_SCOPE:
  ROUTINE begin_tk FN {
    $$ = $1;
    driver.add_child($$, $3);
  } | 
  ROUTINE FUNCTIONS begin_tk FN  {
    $$ = $1;

    driver.add_child($$, $2);
    driver.add_child($$, $4);
  }
; 

/* Grupo de funções globais */
FUNCTIONS:
  FN {
    $$ = driver.add_node(Node {NodeType::definitions,std::monostate(), std::nullopt, std::nullopt, "void", driver.loc(@$)});
    driver.add_child($$, $1);
  } |
  FUNCTIONS FN {
    $$ = $1;
    driver.add_child($$, $2);
  }

/* Argumentos para funções, pode ser nada, um argumento ou N */
ARGS:
  %empty {
    $$ = std::vector<std::pair<Token, Token>>();
  } |
  type id {
    $$ = std::vector<std::pair<Token, Token>>();
    $$.push_back({$1, $2});
  } |
  ARGS ',' type id  {
    $$ = $1;
    $$.push_back({$3, $4});
  }


/* Função, pode ou não ter argumentos, tem um marcador de tipo de retorno */
FN:
  fn_tk id '(' ARGS ')' arrow_tk type  '{' INPUT '}' {
    auto n = Node {NodeType::function, $2, std::nullopt, $4, $7, driver.loc(@$)};

    $$ = driver.add_node(n);

    for (auto& smt : $9) {
      driver.add_child($$, smt);
    }

    driver.add_symbol(n);
  }

/* Marca dados crus como strings, ints, vetores */
LITERAL:
 integer { $$ = driver.add_node(
    Node {NodeType::literal, $1, std::nullopt, std::nullopt, "int", driver.loc(@$)});
 } |
 floating_point { 
    $$ = driver.add_node(Node {NodeType::literal, $1, std::nullopt, std::nullopt, "float", driver.loc(@$)});
 } |
 string { 
  $$ = driver.add_node(Node {NodeType::literal, $1, std::nullopt, std::nullopt, "string", driver.loc(@$)});
  } |
 boolean { 
  $$ = driver.add_node(Node {NodeType::literal, $1, std::nullopt, std::nullopt, "bool", driver.loc(@$)});
  } |
 character { 
  $$ = driver.add_node(Node {NodeType::literal, $1, std::nullopt, std::nullopt, "char", driver.loc(@$)}); 
  } |
 '[' EXP_LIST ']' {
    std::optional<Node> cur = std::nullopt;
    int count = 0;
    
    for (auto& exp : $2) {
      count++;
      auto node = driver.get_node(exp);
      if(!cur.has_value()) {
        cur = node;
      } else if(cur.value().own_type != node.own_type) {
        throw yy::parser::syntax_error(driver.location, "Semantic error: type mismatch: " + cur.value().own_type + " and " + node.own_type);
      }
    }


    $$ = driver.add_node(Node {NodeType::exp_list, std::monostate(), count, std::nullopt, (cur.has_value() ? cur.value().own_type : "void"), driver.loc(@$)});
    for (auto& exp : $2) {
      driver.add_child($$, exp);
    }
  }

/* Bloco de código, tem 0 ou N declarações  */
INPUT:
  %empty {
    $$ = std::vector<int>();
  } |
  INPUT STATEMENT {
    $$ = $1;
    $$.push_back($2);
  }
;

/* Declarações podem ser de tipo, de tipo e inicialização, de atribuição, if, while ou retorno  */
STATEMENT:
  type id ';' {
    auto check = driver.find_symbol_by_value($2);

    if (check.has_value()) {
      throw yy::parser::syntax_error(driver.location, "Semantic error: symbol already defined: " + $2);
    }

    auto n = Node {NodeType::declaration, $2, std::nullopt, std::nullopt, $1, driver.loc(@$)};
    $$ = driver.add_node(n);
    driver.add_symbol(n);
  } |
  type '[' integer ']' id  ';' {
    auto check = driver.find_symbol_by_value($5);

    if (check.has_value()) {
      throw yy::parser::syntax_error(driver.location, "Semantic error: symbol already defined: " + $5);
    }

    auto n = Node {NodeType::declaration, $5, $3, std::nullopt, $1, driver.loc(@$)};
    $$ = driver.add_node(n);
    driver.add_symbol(n);
  } |
  type id assign_tk EXP ';' {
    auto check = driver.find_symbol_by_value($2);

    if (check.has_value()) {
      throw yy::parser::syntax_error(driver.location, "Semantic error: symbol already defined: " + $2);
    }

    auto exp = driver.get_node($4);

    if($1 != exp.own_type) {
      throw yy::parser::syntax_error(driver.location, "Semantic error: cannot assign " + exp.own_type + " to " + $1);
    }

    auto n = Node {NodeType::declaration_assignment, $2, std::nullopt, std::nullopt, $1, driver.loc(@$)};
    $$ = driver.add_node(n);
    driver.add_child($$, $4);
    driver.add_symbol(n);
  } |
  type '[' integer ']' id assign_tk EXP ';' {
    auto check = driver.find_symbol_by_value($5);

    if (check.has_value()) {
      throw yy::parser::syntax_error(driver.location, "Semantic error: symbol already defined: " + $5);
    }

    auto exp = driver.get_node($7);

    if($1 != exp.own_type) {
      throw yy::parser::syntax_error(driver.location, "Semantic error: cannot assign "  + exp.own_type + " to " + $1);
    }


    if (std::get<int>(exp.qualifier.value()) != $3) {
      throw yy::parser::syntax_error(driver.location, "Semantic error: cannot assing array of size " + std::to_string(std::get<int>(exp.qualifier.value())) + " to size " + std::to_string($3));
    }

    auto n = Node {NodeType::declaration_assignment, $5, $3, std::nullopt, $1, driver.loc(@$)};
    $$ = driver.add_node(n);
    driver.add_child($$, $7);
    driver.add_symbol(n);
  } |
  id assign_tk EXP ';' {
    auto maybe_node = driver.find_symbol_by_value($1);

    if(!maybe_node) {
      throw yy::parser::syntax_error(driver.location, "Semantic error: symbol not found: " + $1);
    }

    Node n = maybe_node.value();

    auto exp = driver.get_node($3);

    if(n.own_type != exp.own_type) {
      throw yy::parser::syntax_error(driver.location, "Semantic error: cannot assign " + exp.own_type + " to " + n.own_type);
    }

    if(n.qualifier.has_value() && exp.qualifier.has_value()) {
      if(std::get<int>(n.qualifier.value()) != std::get<int>(exp.qualifier.value())) {
        throw yy::parser::syntax_error(driver.location, "Semantic error: cannot assign array of size " + std::to_string(std::get<int>(exp.qualifier.value())) + " to size " + std::to_string(std::get<int>(n.qualifier.value())));
      }
    }

    

    $$ = driver.add_node(Node {NodeType::assign, $1, std::nullopt, std::nullopt, "void", driver.loc(@$)});
    driver.add_child($$, $3);
  } |
  IF {
    $$ = $1;
  } |
  WHILE {
    $$ = $1;
  } |
  return_tk EXP ';' { 
    auto n = driver.get_node($2);

    $$ = driver.add_node(Node {NodeType::return_,std::monostate(), std::nullopt, std::nullopt, n.own_type, driver.loc(@$)});
    driver.add_child($$, $2);
  }
;

/* If, aceita qualquer expressão como argumento, pode ou não ter o else */
IF: 
  if_tk '(' EXP ')' '{' INPUT '}' {
    $$ = driver.add_node(Node {NodeType::if_,std::monostate(), std::nullopt, std::nullopt, "void", driver.loc(@$)});
    driver.add_child($$, $3);
    for (auto& smt : $6) {
      driver.add_child($$, smt);
    }
  } |
  if_tk '(' EXP ')' '{' INPUT '}' else_tk '{' INPUT '}' {
    $$ = driver.add_node(Node {NodeType::if_,std::monostate(), std::nullopt, std::nullopt, "void", driver.loc(@$)});
    driver.add_child($$, $3);
    for (auto& smt : $6) {
      driver.add_child($$, smt);
    }
    for (auto& smt : $10) {
      driver.add_child($$, smt);
    }
  }

/* While, aceita qualquer expressão como argumento */
WHILE:
  while_tk '(' EXP ')' '{' INPUT '}' {
    $$ = driver.add_node(Node {NodeType::while_,std::monostate(), std::nullopt, std::nullopt, "void", driver.loc(@$)});
    driver.add_child($$, $3);
    for (auto& smt : $6) {
      driver.add_child($$, smt);
    }
  }

/* Não terminal auxiliar para uma lista de expressões em chamadas de função */
EXP_LIST:
  %empty { $$ = std::vector<int>(); } |
  EXP { 
    $$ = std::vector<int>();
    $$.push_back($1);
  } |
  EXP_LIST ',' EXP   {
    $$ = $1;
    $$.push_back($3);
  } 

/* 
  Expressões, podem ser um id, uma chamada de função, um literal,
  uma operação aritimética, uma operação lógica, ou um agrupamento de expressões [evidência/precedência]
*/
EXP:
  id { 
    auto maybe_node = driver.find_symbol_by_value($1);

    if(!maybe_node) {
      throw yy::parser::syntax_error(driver.location, "Semantic error: symbol not found: " + $1);
    }

    Node n = maybe_node.value();

    $$ = driver.add_node(Node {NodeType::identifier, $1, std::nullopt, std::nullopt, n.own_type, driver.loc(@$)});
   }  |
  id '(' EXP_LIST ')' {
    auto maybe_node = driver.find_symbol_by_value($1);

    if(!maybe_node) {
      throw yy::parser::syntax_error(driver.location, "Semantic error: undefined function: " + $1);
    }

    Node n = maybe_node.value();

    $$ = driver.add_node(Node {NodeType::call, $1, std::nullopt, std::nullopt, n.own_type, driver.loc(@$)});
    for (auto& exp : $3) {
      driver.add_child($$, exp);
    }
  } |
  LITERAL |
  EXP '+' EXP {
    auto a = driver.get_node($1);
    auto b = driver.get_node($3);

    if(a.own_type != b.own_type) {
      throw yy::parser::syntax_error(driver.location, "Semantic error: cannot sum: " + a.own_type + " and " + b.own_type);
    }

    if(a.own_type != "int" && a.own_type != "float") {
      throw yy::parser::syntax_error(driver.location, "Semantic error: invalid type for addition: " + a.own_type);
    }

    $$ = driver.add_node(Node {NodeType::binary_op, "+", std::nullopt, std::nullopt, a.own_type, driver.loc(@$)});
    driver.add_child($$, $1);
    driver.add_child($$, $3);
  } |
  EXP '-' EXP {
    auto a = driver.get_node($1);
    auto b = driver.get_node($3);

    if(a.own_type != b.own_type) {
      throw yy::parser::syntax_error(driver.location, "Semantic error: cannot subtract: " + a.own_type + " and " + b.own_type);
    }

    if(a.own_type != "int" && a.own_type != "float") {
      throw yy::parser::syntax_error(driver.location, "Semantic error: invalid type for subtraction: " + a.own_type);
    }

    $$ = driver.add_node(Node {NodeType::binary_op, "-", std::nullopt, std::nullopt, a.own_type, driver.loc(@$)});
    driver.add_child($$, $1);
    driver.add_child($$, $3);
  } |
  EXP '*' EXP {
    auto a = driver.get_node($1);
    auto b = driver.get_node($3);

    if(a.own_type != b.own_type) {
      throw yy::parser::syntax_error(driver.location, "Semantic error: cannot multiply: " + a.own_type + " and " + b.own_type);
    }

    if(a.own_type != "int" && a.own_type != "float") {
      throw yy::parser::syntax_error(driver.location, "Semantic error: invalid type for multiplication: " + a.own_type);
    }

    $$ = driver.add_node(Node {NodeType::binary_op, "*", std::nullopt, std::nullopt, a.own_type, driver.loc(@$)});
    driver.add_child($$, $1);
    driver.add_child($$, $3);
  } |
  EXP '/' EXP {
    auto a = driver.get_node($1);
    auto b = driver.get_node($3);

    if(a.own_type != b.own_type) {
      throw yy::parser::syntax_error(driver.location, "Semantic error: cannot divide: " + a.own_type + " and " + b.own_type);
    }

    if(a.own_type != "int" && a.own_type != "float") {
      throw yy::parser::syntax_error(driver.location, "Semantic error: invalid type for division: " + a.own_type);
    }

    $$ = driver.add_node(Node {NodeType::binary_op, "/", std::nullopt, std::nullopt, "float", driver.loc(@$)});
    driver.add_child($$, $1);
    driver.add_child($$, $3);
  } |
  EXP gt EXP {
    auto a = driver.get_node($1);
    auto b = driver.get_node($3);

    if(a.own_type != b.own_type) {
      throw yy::parser::syntax_error(driver.location, "Semantic error: cannot compare: " + a.own_type + " and " + b.own_type);
    }

    if(a.own_type != "int" && a.own_type != "float") {
      throw yy::parser::syntax_error(driver.location, "Semantic error: invalid type for comparison: " + a.own_type);
    }

    $$ = driver.add_node(Node {NodeType::binary_op, $2, std::nullopt, std::nullopt, "bool", driver.loc(@$)});
    driver.add_child($$, $1);
    driver.add_child($$, $3);
  } |
  EXP lt EXP {
    auto a = driver.get_node($1);
    auto b = driver.get_node($3);

    if(a.own_type != b.own_type) {
      throw yy::parser::syntax_error(driver.location, "Semantic error: cannot compare: " + a.own_type + " and " + b.own_type);
    }

    if(a.own_type != "int" && a.own_type != "float") {
      throw yy::parser::syntax_error(driver.location, "Semantic error: invalid type for comparison: " + a.own_type);
    }

    $$ = driver.add_node(Node {NodeType::binary_op, $2, std::nullopt, std::nullopt, "bool", driver.loc(@$)});
    driver.add_child($$, $1);
    driver.add_child($$, $3);
  } |
  EXP ge EXP {
    auto a = driver.get_node($1);
    auto b = driver.get_node($3);

    if(a.own_type != b.own_type) {
      throw yy::parser::syntax_error(driver.location, "Semantic error: cannot compare: " + a.own_type + " and " + b.own_type);
    }

    if(a.own_type != "int" && a.own_type != "float") {
      throw yy::parser::syntax_error(driver.location, "Semantic error: invalid type for comparison: " + a.own_type);
    }

    $$ = driver.add_node(Node {NodeType::binary_op, $2, std::nullopt, std::nullopt, "bool", driver.loc(@$)});
    driver.add_child($$, $1);
    driver.add_child($$, $3);
  } |
  EXP le EXP {
    auto a = driver.get_node($1);
    auto b = driver.get_node($3);

    if(a.own_type != b.own_type) {
      throw yy::parser::syntax_error(driver.location, "Semantic error: cannot compare: " + a.own_type + " and " + b.own_type);
    }

    if(a.own_type != "int" && a.own_type != "float") {
      throw yy::parser::syntax_error(driver.location, "Semantic error: invalid type for comparison: " + a.own_type);
    }

    $$ = driver.add_node(Node {NodeType::binary_op, $2, std::nullopt, std::nullopt, "bool", driver.loc(@$)});
    driver.add_child($$, $1);
    driver.add_child($$, $3);
  } |
  EXP eq EXP {
    auto a = driver.get_node($1);
    auto b = driver.get_node($3);

    if(a.own_type != b.own_type) {
      throw yy::parser::syntax_error(driver.location, "Semantic error: cannot compare: " + a.own_type + " and " + b.own_type);
    }

    if(a.own_type != "int" && a.own_type != "float" && a.own_type != "bool") {
      throw yy::parser::syntax_error(driver.location, "Semantic error: invalid type for comparison: " + a.own_type);
    }

    $$ = driver.add_node(Node {NodeType::binary_op, $2, std::nullopt, std::nullopt, "bool", driver.loc(@$)});
    driver.add_child($$, $1);
    driver.add_child($$, $3);
  } |
  EXP ne EXP  {
    auto a = driver.get_node($1);
    auto b = driver.get_node($3);

    if(a.own_type != b.own_type) {
      throw yy::parser::syntax_error(driver.location, "Semantic error: cannot compare: " + a.own_type + " and " + b.own_type);
    }

    if(a.own_type != "int" && a.own_type != "float" && a.own_type != "bool") {
      throw yy::parser::syntax_error(driver.location, "Semantic error: invalid type for comparison: " + a.own_type);
    }

    $$ = driver.add_node(Node {NodeType::binary_op, $2, std::nullopt, std::nullopt, "bool", driver.loc(@$)});
    driver.add_child($$, $1);
    driver.add_child($$, $3);
  } |
  '(' EXP ')' {
    Node exp = driver.get_node($2);

    $$ = driver.add_node(Node {NodeType::precedence, std::monostate(), std::nullopt, std::nullopt, exp.own_type, driver.loc(@$)});
    driver.add_child($$, $2);
  }
; 

%%

/* --- User code --- */
void yy::parser::error (const location_type& l, const std::string& m) {
  std::cerr << l << ": " << m << '\n';
}


