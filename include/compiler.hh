
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

  Graph::vertex_descriptor add_node(Node n);
  void add_child(Graph::vertex_descriptor v1, Graph::vertex_descriptor v2);
  void add_symbol(Node n) { ast.add_symbol(n); }
  std::optional<Node> find_symbol_by_value(Token v) {
    return ast.find_symbol_by_value(v);
  }

  Node get_node(Graph::vertex_descriptor v) { return ast.get_node(v); }

  std::string loc(yy::location loc) {
    ostringstream oss;
    oss << loc;
    return oss.str();
  }

 private:
  std::string file;
  bool trace_parsing = false;
  bool trace_scanning = false;
  AST ast;
};

YY_DECL;
#endif
