#include <compiler.hh>
#include <flex.hh>

using namespace std;

Compiler::Compiler() {}

void Compiler::compile(const string &f) {
  file = f;

  this->location.initialize(&file);

  FILE *fp = fopen(file.c_str(), "r");

  yyin = fp;

  yy::parser bparser = yy::parser(*this);

  yyset_debug(this->trace_scanning);

  bparser.set_debug_level(this->trace_parsing);

  bparser.parse();

  fclose(fp);
}
