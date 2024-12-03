#include <compiler.hh>
#include <flex.hh>

using namespace std;

Graph::vertex_descriptor Compiler::add_binary_op(Token op,
                                                 Graph::vertex_descriptor a,
                                                 Graph::vertex_descriptor b) {
  auto v = this->add_node(Node{NodeType::binary_op, op});
  this->add_child(v, a);
  this->add_child(v, b);

  return v;
}

Graph::vertex_descriptor Compiler::add_identifier(Token id) {
  return this->add_node(Node{NodeType::identifier, id});
}

Graph::vertex_descriptor Compiler::add_type(Token id) {
  return this->add_node(Node{NodeType::type, id});
}

Graph::vertex_descriptor Compiler::add_type(Token id, Token qualifier) {
  auto v = this->add_node(Node{NodeType::type, id});
  auto q = this->add_node(Node{NodeType::qualifier, qualifier});

  this->add_child(v, q);

  return v;
}

Graph::vertex_descriptor Compiler::add_literal(Token lit) {
  return this->add_node(Node{NodeType::literal, lit});
}

Graph::vertex_descriptor Compiler::add_call(Token id,
                                            Graph::vertex_descriptor args) {
  auto idn = this->add_identifier(id);
  auto v = this->add_node(Node{NodeType::call, std::monostate()});
  this->add_child(v, args);
  this->add_child(v, idn);
  return v;
}

Graph::vertex_descriptor Compiler::add_node(Node n) {
  return this->ast.add_node(n);
}

void Compiler::add_child(Graph::vertex_descriptor v1,
                         Graph::vertex_descriptor v2) {
  this->ast.add_child(v1, v2);
}

bool Compiler::compile(const string &f) {
  file = f;

  this->location.initialize(&file);

  FILE *fp = fopen(file.c_str(), "r");

  if (!fp) {
    cerr << "Unable to open file: " << file << endl;
    return false;
  }

  yyin = fp;

  yy::parser bparser = yy::parser(*this);

  yyset_debug(this->trace_scanning);

  bparser.set_debug_level(this->trace_parsing);

  bool successful = bparser.parse() == 0;

  this->ast.preorder();

  fclose(fp);

  return successful;
}
