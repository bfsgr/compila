
#include <string>

using namespace std;

enum class Color { BLACK, RED, GREEN, YELLOW, WHITE, RESET };

constexpr const char* term(Color c) {
  switch (c) {
    case Color::BLACK:
      return "\033[30m";
    case Color::RED:
      return "\033[31m";
    case Color::GREEN:
      return "\033[32m";
    case Color::YELLOW:
      return "\033[33m";
    case Color::WHITE:
      return "\033[37m";
    case Color::RESET:
      return "\033[0m";
    default:
      return "\033[0m";
  }
}
