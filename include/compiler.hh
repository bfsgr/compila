
#ifndef COMPILER_HH
#define COMPILER_HH

#include <bison.hh>
#include <iostream>

// Update Flex yylex signature to match Bison
// Make the compiler class available to the scanner
#define YY_DECL yy::parser::symbol_type yylex(Compiler& driver)

class Compiler {
 public:
  Compiler();
  yy::location location;

  bool compile(const std::string& f);

  void set_trace_parsing(bool b) { this->trace_parsing = b; }
  void set_trace_scanning(bool b) { this->trace_scanning = b; }

 private:
  std::string file;
  bool trace_parsing = false;
  bool trace_scanning = false;
};

YY_DECL;
#endif
