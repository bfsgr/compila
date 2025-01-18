#include <ast.hh>
#include <cstdlib>
#include <fstream>

std::string print_array(const std::vector<std::string>& vec) {
  std::ostringstream oss;
  oss << "[";
  for (size_t i = 0; i < vec.size(); ++i) {
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

std::ostream& operator<<(std::ostream& os, const std::optional<Node>& n) {
  if (n) {
    os << n.value();
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

std::optional<Node> AST::find_symbol_by_value(Token v, Node* scope) {
  auto it = std::find_if(symbol_table.begin(), symbol_table.end(), [&](Node s) {
    return s.value == v && s.scope == scope;
  });

  if (it != symbol_table.end()) {
    return *it;
  }

  return std::nullopt;
}

class SemanticAnalyser : public boost::default_dfs_visitor {
 private:
  AST& ast;
  Graph g;
  std::stack<Node*> stack;
  Node* scope;

 public:
  SemanticAnalyser(AST& ast, Graph& g) : ast(ast), g(g) {}

  void discover_vertex(Graph::vertex_descriptor v, const Graph& g) {
    Node& n = const_cast<Node&>(g[v]);

    // Declarações de funções são inseridas na tabela de símbolos
    // já na abertura do vertice para que possam ser referenciadas
    // como escopo
    if (n.type == NodeType::function) {
      auto maybe_node = this->ast.find_symbol_by_value(n.value, nullptr);

      if (maybe_node.has_value()) {
        throw std::runtime_error(
            n.location + ": Semantic error: redeclaration of function " +
            std::get<std::string>(n.value));
      }

      this->scope = &n;

      for (auto arg : n.args.value()) {
        auto type = std::get<string>(arg.first);
        auto name = std::get<string>(arg.second);

        this->ast.add_symbol(Node{NodeType::identifier, name, std::nullopt,
                                  std::nullopt, type, n.location, &n});
      }

      this->ast.add_symbol(n);
    }

    stack.push(&n);
  }

  void finish_vertex(Graph::vertex_descriptor v, const Graph& g) {
    if (stack.size() == 0) {
      return;
    }

    Node* n = stack.top();

    if (stack.size() == 1) {
      return;
    }

    stack.pop();

    Node* last_node = stack.top();

    // Casos onde é necessário adicionar um símbolo na tabela de símbolos
    switch (n->type) {
      case NodeType::routine:
      case NodeType::definitions:
      case NodeType::function:
        return;
      case NodeType::declaration:
      case NodeType::declaration_assignment: {
        auto maybe_node = this->ast.find_symbol_by_value(n->value, this->scope);

        if (maybe_node.has_value()) {
          throw std::runtime_error(
              n->location + ": Semantic error: redeclaration of identifier " +
              std::get<std::string>(n->value));
        }

        n->scope = this->scope;

        this->ast.add_symbol(*n);
        break;
      }
      default:
        break;
    }

    // O nó sendo fechado tem tipo desconhecido, ou seja, ele só pode ser
    // um identificador ou uma chamada de função
    // consulta a tabela de símbolos para descobrir o tipo do nó
    if (n->own_type == "unknown") {
      if (n->type == NodeType::call) {
        auto maybe_node = this->ast.find_symbol_by_value(n->value, nullptr);

        if (maybe_node.has_value()) {
          n->own_type = maybe_node.value().own_type;
        } else {
          throw std::runtime_error(
              n->location + ": Semantic error: use of undeclared identifier " +
              std::get<std::string>(n->value));
        }

        return;
      }

      auto maybe_node = this->ast.find_symbol_by_value(n->value, this->scope);

      if (maybe_node.has_value()) {
        n->own_type = maybe_node.value().own_type;

      } else {
        throw std::runtime_error(
            n->location + ": Semantic error: use of undeclared identifier " +
            std::get<std::string>(n->value));
      }
    }

    // O nó "pai" do nó sendo fechado tem tipo desconhecido, ou seja, devemos
    // verificar se é possível "calcular o tipo" do nó pai com base no nó filho
    if (last_node->own_type == "unknown") {
      if (last_node->type == NodeType::call) {
        auto maybe_node =
            this->ast.find_symbol_by_value(last_node->value, nullptr);

        if (maybe_node.has_value()) {
          last_node->own_type = maybe_node.value().own_type;
        } else {
          throw std::runtime_error(
              last_node->location +
              ": Semantic error: use of undeclared identifier " +
              std::get<std::string>(last_node->value));
        }

      } else {
        last_node->own_type = n->own_type;
      }
      return;
    }

    // Verifica se o tipo de retorno de uma função é compatível com o tipo da
    // função em que ela está contida
    if (n->type == NodeType::return_) {
      if (n->own_type != this->scope->own_type) {
        throw std::runtime_error(last_node->location +
                                 ": Semantic error: return type mismatch " +
                                 n->own_type + " and " + this->scope->own_type);
      }
    }

    // Os tipos agora já são conhecidos, então podemos compará-los
    // para verificar se são compatíveis.
    // Pula atribuição de tipo no if e while, permite comparadores lógicos com
    // números e verifica se o tipo de retorno de uma função é compatível com o
    // tipo da função
    if (n->own_type != last_node->own_type) {
      switch (last_node->type) {
        case NodeType::binary_op: {
          auto op = std::get<std::string>(last_node->value);
          if (op == ">" || op == "<" || op == ">=" || op == "<=" ||
              op == "==") {
            if (n->own_type == "int" || n->own_type == "float") {
              return;
            }
          }
          break;
        }
        case NodeType::while_:
        case NodeType::if_: {
          return;
        }
        case NodeType::function: {
          if (n->type == NodeType::return_) {
            if (n->own_type != last_node->own_type) {
              break;
            }
          }
          return;
        }
        default:
          break;
      }

      throw std::runtime_error(last_node->location +
                               ": Semantic error: type mismatch " +
                               n->own_type + " and " + last_node->own_type);
    }
  }
};

void AST::print_tree() {
  std::ofstream dot_file("../ast.dot");
  boost::write_graphviz(dot_file, g, NodeLabelWriter(g));

  std::cout << "AST written to ast.dot file" << std::endl;
}

bool AST::semantic_analysis() {
  auto vis = SemanticAnalyser(*this, g);
  try {
    boost::depth_first_search(g, boost::visitor(vis));
    return true;
  } catch (std::runtime_error& e) {
    std::cerr << term(Color::RED) << e.what() << term(Color::RESET);

    return false;
  }
}
