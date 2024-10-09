#include <compiler.hh>
#include <flex.hh>
#include <iostream>
#include <termcolors.hh>

using namespace std;

int main(int argc, char* argv[]) {
  if (argc < 2) {
    cout << "Usage: " << argv[0] << " <filename>" << endl;
    return 1;
  }

  Compiler driver = Compiler();
  string filename;

  for (int i = 1; i < argc; i++) {
    auto arg = string(argv[i]);

    if (arg == "-p") {
      driver.set_trace_parsing(true);
    } else if (arg == "-s") {
      driver.set_trace_scanning(true);
    } else {
      filename = arg;
    }
  }

  bool result = driver.compile(filename);

  if (result) {
    cout << term(Color::GREEN) << "Compilation successful" << term(Color::RESET)
         << endl;
  } else {
    cout << term(Color::RED) << "Compilation failed" << term(Color::RESET)
         << endl;
  }

  return 0;
}