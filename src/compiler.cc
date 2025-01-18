#include <compiler.hh>
#include <flex.hh>

using namespace std;

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

  if (!successful) {
    fclose(fp);
    return false;
  }

  // cout << term(Color::YELLOW) << "Symbol table (n=" <<
  // ast.symbol_table.size()
  //      << ")" << term(Color::RESET) << endl;

  // cout << "[" << endl;
  // for (auto &s : symbol_table) {
  //   cout << "  " << s << endl;
  // }
  // cout << "]" << endl << endl;

  cout << term(Color::YELLOW) << "Abstract Syntax Tree: (Graphviz notation)"
       << term(Color::RESET) << endl;

  this->ast.print_tree();

  cout << endl;

  cout << term(Color::YELLOW) << "Running semantic analysis"
       << term(Color::RESET) << endl;

  cout << endl;

  fclose(fp);

  return successful;
}
