project(
  'compiler',
  ['c', 'cpp'],
  version: '0.1.0',
  default_options: ['c_std=c11', 'cpp_std=c++17'],
)

flex_bin = find_program('flex', version: '>=2.6.0 && < 3')
bison_bin = find_program('bison', version: '>=3.8.0 && < 4')

lexer = custom_target(
  'flex.c',
  input: 'src/flex.l',
  output: ['flex.cc', 'flex.hh'],
  command: [flex_bin, '-o', 'flex.cc', '--header-file=flex.hh', '@INPUT@'],
)

parser = custom_target(
  'bison.cc',
  input: 'src/bison.yy',
  output: ['bison.cc', 'bison.hh'],
  command: [bison_bin, '-o', 'bison.cc', '-H', '@INPUT@'],
)

includes = [
  include_directories('./include'),
]

sources = ['src/main.cc', 'src/compiler.cc', lexer, parser]

executable(
  'compiler',
  sources,
  include_directories: includes,
)