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

typedef struct {
  NodeType type;
  Token value;
} Node;

typedef boost::adjacency_list<boost::vecS, boost::vecS, boost::bidirectionalS,
                              Node>
    Graph;

class AST {
 public:
  AST();
  Graph::vertex_descriptor add_node(Node n);
  void add_child(Graph::vertex_descriptor v1, Graph::vertex_descriptor v2);

  void preorder();

 private:
  Graph g;
};

// ostream overloads
std::ostream& operator<<(std::ostream& os, const std::vector<std::string>& vec);
std::ostream& operator<<(std::ostream& os, const std::monostate&);
std::ostream& operator<<(std::ostream& os, const Token& var);
std::ostream& operator<<(std::ostream& os, const NodeType& nt);
std::ostream& operator<<(std::ostream& os, const Node& n);

namespace boost {
std::ostream& operator<<(std::ostream& os, const std::monostate&);
std::ostream& operator<<(std::ostream& os, const std::vector<std::string>& vec);
// std::ostream& operator<<(std::ostream& os, const NodeType& nt);
std::ostream& operator<<(std::ostream& os, const Token& t);

template <>
std::string lexical_cast<std::string, Token>(const Token& b);

template <>
std::string lexical_cast<std::string, NodeType>(const NodeType& b);
}  // namespace boost
#endif