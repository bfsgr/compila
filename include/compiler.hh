
#ifndef COMPILER_HH
#define COMPILER_HH

#include <ast.hh>
#include <bison.hh>
#include <iostream>
#include <list>

// Update Flex yylex signature to match Bison
// Make the compiler class available to the scanner
#define YY_DECL yy::parser::symbol_type yylex(Compiler& driver)

class Compiler {
 public:
  Compiler() { ast = AST(); };
  yy::location location;

  bool compile(const std::string& f);

  void set_trace_parsing(bool b) { this->trace_parsing = b; }
  void set_trace_scanning(bool b) { this->trace_scanning = b; }

  Graph::vertex_descriptor add_binary_op(Token op, Graph::vertex_descriptor a,
                                         Graph::vertex_descriptor b);
  Graph::vertex_descriptor add_identifier(Token id);
  Graph::vertex_descriptor add_ret_type(Token id);
  Graph::vertex_descriptor add_type(Token id);
  Graph::vertex_descriptor add_type(Token id, Token qualifier);
  Graph::vertex_descriptor add_literal(Token lit);
  Graph::vertex_descriptor add_call(Token id, Graph::vertex_descriptor args);
  Graph::vertex_descriptor add_node(Node n);
  void add_child(Graph::vertex_descriptor v1, Graph::vertex_descriptor v2);

 private:
  std::string file;
  bool trace_parsing = false;
  bool trace_scanning = false;
  AST ast;
};

YY_DECL;
#endif
