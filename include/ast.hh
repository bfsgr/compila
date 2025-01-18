#ifndef AST_HH
#define AST_HH

#include <boost/graph/adjacency_list.hpp>
#include <boost/graph/depth_first_search.hpp>
#include <boost/graph/graphviz.hpp>
#include <iostream>
#include <termcolors.hh>
#include <variant>
#include <vector>

using Token = std::variant<int, bool, float, char, std::string,
                           std::vector<std::string>, std::monostate>;

enum class NodeType {
  identifier,
  precedence,
  binary_op,
  literal,
  call,
  exp_list,
  qualifier,
  args,
  while_,
  if_,
  return_,
  return_type,
  assign,
  block,
  declaration,
  declaration_assignment,
  type,
  function,
  definitions,
  routine,
  begin
};

std::string NodeTypeToString(NodeType type);

typedef struct InnerNode {
  NodeType type;
  Token value;
  std::optional<Token> qualifier;
  std::optional<std::vector<std::pair<Token, Token>>> args;
  std::string own_type;
  std::string location;
  InnerNode* scope;
} Node;

typedef boost::adjacency_list<boost::vecS, boost::vecS, boost::bidirectionalS,
                              Node>
    Graph;

class AST {
 public:
  AST();
  Graph::vertex_descriptor add_node(Node n);
  void add_child(Graph::vertex_descriptor v1, Graph::vertex_descriptor v2);
  void add_symbol(Node n);
  Node get_node(Graph::vertex_descriptor v) { return g[v]; }
  std::optional<Node> find_symbol_by_value(Token v, Node* scope);

  void print_tree();
  bool semantic_analysis();

 private:
  Graph g;
  std::vector<Node> symbol_table = {
      Node{NodeType::function, "printf", std::nullopt,
           std::vector<std::pair<Token, Token>>(), "void", "<stdio>"},
      Node{NodeType::function, "scanf", std::nullopt,
           std::vector<std::pair<Token, Token>>(), "void", "<stdio>"},
  };
};

// ostream overloads
std::ostream& operator<<(std::ostream& os, const std::vector<std::string>& vec);
std::ostream& operator<<(std::ostream& os, const std::monostate&);
std::ostream& operator<<(std::ostream& os, const Token& var);
std::ostream& operator<<(
    std::ostream& os,
    const std::optional<std::vector<std::pair<Token, Token>>>& args);
std::ostream& operator<<(std::ostream& os, const std::optional<Token>& args);
std::ostream& operator<<(std::ostream& os, const NodeType& nt);
std::ostream& operator<<(std::ostream& os, const std::optional<Node>& n);
std::ostream& operator<<(std::ostream& os, const Node& n);

namespace boost {
std::ostream& operator<<(std::ostream& os, const std::monostate&);
std::ostream& operator<<(std::ostream& os, const std::vector<std::string>& vec);
std::ostream& operator<<(
    std::ostream& os,
    const std::optional<std::vector<std::pair<Token, Token>>>& args);
std::ostream& operator<<(std::ostream& os, const std::optional<Token>& args);
std::ostream& operator<<(std::ostream& os, const Token& t);

template <>
std::string lexical_cast<std::string, Token>(const Token& b);

template <>
std::string lexical_cast<std::string, NodeType>(const NodeType& b);
}  // namespace boost

#endif