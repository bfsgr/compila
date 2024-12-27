#include <ast.hh>
#include <fstream>
#include <cstdlib>

std::string print_array(const std::vector<std::string>& vec) {
  std::ostringstream oss;
  oss << "[";
  for (size_t i = 0; i < vec.size(); ++i) {
    std::cout << "Teste";
    std::cout << vec[i];
    oss << vec[i];
    if (i != vec.size() - 1) {
      oss << ", ";
    }
  }
  oss << "]";
  return oss.str();
}

std::string NodeTypeToString(NodeType type) {
  switch (type) {
    case NodeType::identifier:
      return "id";
    case NodeType::precedence:
      return "preced";
    case NodeType::binary_op:
      return "bin-op";
    case NodeType::literal:
      return "literal";
    case NodeType::call:
      return "call";
    case NodeType::exp_list:
      return "exp_list";
    case NodeType::args:
      return "args";
    case NodeType::while_:
      return "while";
    case NodeType::if_:
      return "if";
    case NodeType::return_:
      return "return";
    case NodeType::assign:
      return "assign";
    case NodeType::block:
      return "block";
    case NodeType::declaration:
      return "decl";
    case NodeType::declaration_assignment:
      return "decl-assign";
    case NodeType::type:
      return "type";
    case NodeType::function:
      return "function";
    case NodeType::definitions:
      return "defs";
    case NodeType::routine:
      return "routine";
    case NodeType::begin:
      return "begin";
    case NodeType::qualifier:
      return "qualifier";
    case NodeType::return_type:
      return "return_type";
    default:
      throw std::runtime_error("Invalid NodeType");
  }
}

std::ostream& operator<<(std::ostream& os,
                         const std::vector<std::string>& vec) {
  os << print_array(vec);
  return os;
}

std::ostream& boost::operator<<(std::ostream& os,
                                const std::vector<std::string>& vec) {
  os << print_array(vec);
  return os;
}

std::ostream& operator<<(std::ostream& os, const std::monostate& m) {
  os << "<>";
  return os;
}

std::ostream& boost::operator<<(std::ostream& os, const std::monostate& m) {
  os << "<>";
  return os;
}

std::ostream& operator<<(std::ostream& os, const Token& var) {
  std::visit([&os](auto&& value) { os << value; }, var);
  return os;
}

std::ostream& operator<<(std::ostream& os, const Node& n) {
  std::visit(
      [&n, &os](auto&& value) {
        os << "Node(" << n.type << ", " << value << ")";
      },
      n.value);
  return os;
}

std::ostream& boost::operator<<(std::ostream& os, const Token& var) {
  std::visit([&os](auto&& value) { os << value; }, var);
  return os;
}

std::ostream& operator<<(std::ostream& os, const NodeType& nt) {
  os << NodeTypeToString(nt);
  return os;
}

// std::ostream& boost::operator<<(std::ostream& os, const NodeType& var) {
//   os << NodeTypeToString(var);
//   return os;
// }

template <>
std::string boost::lexical_cast<std::string, Token>(const Token& b) {
  std::ostringstream ss;
  ss << b;
  return ss.str();
}

template <>
std::string boost::lexical_cast<std::string, NodeType>(const NodeType& b) {
  std::ostringstream ss;
  ss << b;
  return ss.str();
}

class NodeLabelWriter {
 public:
  explicit NodeLabelWriter(const Graph& g) : graph(g) {}

  template <typename Vertex>
  void operator()(std::ostream& out, const Vertex& v) const {
    const Node& node = graph[v];
    out << "[label=\"" << node.type << ": " << node.value << "\"]";
  }

 private:
  const Graph& graph;
};

AST::AST() { g = Graph(); }

Graph::vertex_descriptor AST::add_node(Node n) {
  return boost::add_vertex(n, g);
}

void AST::add_child(Graph::vertex_descriptor v1, Graph::vertex_descriptor v2) {
  boost::add_edge(v1, v2, g);
}

class MyVisitor : public boost::default_dfs_visitor {
 public:
  void discover_vertex(Graph::vertex_descriptor v, const Graph& g) const {
    std::cout << g[v] << std::endl;
  }
};

void AST::preorder() {
  std::ofstream dot_file("graph.dot");
  boost::write_graphviz(dot_file, g, NodeLabelWriter(g)); // Escreve em um arquivo o grafo
  system("dot -Tpng graph.dot -o graph.png"); // Transforma o arquivo salvo para uma imagem
  //boost::write_graphviz(std::cout, g, NodeLabelWriter(g)); // Exibe no terminal o grafo

  std::cout << term(Color::RED) << "Preorder" << term(Color::RESET)
            << std::endl;
  MyVisitor vis;

  boost::depth_first_search(g, boost::visitor(vis));
}
