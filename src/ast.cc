#include <ast.hh>
#include <cstdlib>
#include <fstream>

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

std::ostream& operator<<(std::ostream& os, const std::optional<Token>& args) {
  if (args) {
    os << args.value();
  } else {
    os << "<>";
  }
  return os;
}

std::ostream& operator<<(
    std::ostream& os,
    const std::optional<std::vector<std::pair<Token, Token>>>& args) {
  if (args) {
    os << "[";
    for (size_t i = 0; i < args->size(); ++i) {
      os << "(" << args->at(i).first << ", " << args->at(i).second << ")";
      if (i != args->size() - 1) {
        os << ", ";
      }
    }
    os << "]";
  } else {
    os << "<>";
  }
  return os;
}

std::ostream& operator<<(std::ostream& os, const Node& n) {
  std::visit(
      [&n, &os](auto&& value) {
        os << "Node(" << n.type << ", " << value;
        if (n.qualifier.has_value()) {
          os << ", qual=" << n.qualifier.value();
        }
        if (n.args.has_value()) {
          os << ", args=" << n.args.value();
        }
        os << ", type=" << n.own_type;
        os << ")";
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

std::ostream& boost::operator<<(std::ostream& os,
                                const std::optional<Token>& args) {
  if (args) {
    os << args.value();
  } else {
    os << "<>";
  }
  return os;
}

std::ostream& boost::operator<<(
    std::ostream& os,
    const std::optional<std::vector<std::pair<Token, Token>>>& args) {
  if (args) {
    os << "[";
    for (size_t i = 0; i < args->size(); ++i) {
      os << "(" << args->at(i).first << ", " << args->at(i).second << ")";
      if (i != args->size() - 1) {
        os << ", ";
      }
    }
    os << "]";
  } else {
    os << "<>";
  }
  return os;
}

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
    out << "[label=\"" << node.type << ", " << node.value;

    if (node.args.has_value()) {
      out << ", args=" << node.args;
    }

    if (node.qualifier.has_value()) {
      out << ", qual=" << node.qualifier;
    }

    out << ", type=" << node.own_type;

    out << "\"]";
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

void AST::add_symbol(Node n) { symbol_table.push_back(n); }

class MyVisitor : public boost::default_dfs_visitor {
 private:
  AST ast;
  Graph g;

 public:
  MyVisitor(AST& ast, Graph& g) {
    this->ast = ast;
    this->g = g;
  }

  void finish_vertex(Graph::vertex_descriptor v, const Graph& g) {
    auto n = g[v];

    std::cout << "finishing node: " << n << std::endl;
  }

  void discover_vertex(Graph::vertex_descriptor v, const Graph& g) {
    auto n = g[v];

    std::cout << "Visiting node: " << n << std::endl;

    switch (n.type) {
      case NodeType::assign: {
        auto maybe_sym = this->ast.find_symbol_by_value(n.value);

        if (!maybe_sym.has_value()) {
          ostringstream os;
          os << n.location << ": Semantic error: variable " << n.value
             << " not declared" << std::endl;

          throw std::runtime_error(os.str());
        }

        Node sym = maybe_sym.value();

        break;
      }
      case NodeType::binary_op: {
        std::string val = std::get<std::string>(n.value);

        if (val == "+" || val == "-" || val == "*") {
        }

        break;
      }
      default: {
        break;
      }
    }
  }
};

void AST::print_tree() {
  std::ofstream dot_file("../ast.dot");
  boost::write_graphviz(dot_file, g, NodeLabelWriter(g));

  std::cout << "AST written to ast.dot file" << std::endl;
}

bool AST::semantic_analysis() {
  auto vis = MyVisitor(*this, g);
  try {
    // boost::depth_first_search(g, boost::visitor(vis));
    return true;
  } catch (std::runtime_error& e) {
    std::cerr << term(Color::RED) << e.what() << term(Color::RESET);

    return false;
  }
}
