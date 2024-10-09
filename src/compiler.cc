#include <compiler.hh>
#include <flex.hh>

using namespace std;

Compiler::Compiler() {}

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

  fclose(fp);

  return successful;
}
