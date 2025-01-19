# Trabalho de compiladores 9797-01

Alunos: <br>
Bruno Fusieger RA: 112646<br>
Samuel Bispo RA: 103643

## Como executar:

O trabalho foi desenvolvido em C++ usando o [Meson build system](https://mesonbuild.com/), para executar é necessário instala-lo.

São dependências do projeto:
- [flex](https://github.com/westes/flex), versão mínima testada: 2.6.4
- [bison](https://www.gnu.org/software/bison/), versão mínima testada: 3.8.2
- [boost](https://www.boost.org/), versão mínima testada: 1.83.0

O meson irá apontar se alguma dependência não estiver instalada.

Para compilar o projeto, execute os seguintes comandos:

```bash
mkdir builddir
meson setup builddir
cd builddir
meson compile 
```

Depois para executar é só usar (dentro da pasta builddir)

```bash
./compilador <caminho para o arquivo>
```

Existem exemplos de erros léxicos, sintáticos e semânticos na pasta exemplos, para testar basta executar o comando acima com o caminho para o arquivo desejado.

Também existem exemplos sem erros na pasta de exemplos, sendo eles "good.txt" e "simple.txt"

Depois de executar o compilador, será gerado um arquivo "ast.dot" que é a representação da árvore sintática abstrata do programa, para visualizar pode-se usar o link [GraphvizOnline](https://dreampuf.github.io/GraphvizOnline/) e colar o conteúdo do arquivo.

Também será escrita na tela a tabela de símbolos do programa, incluindo as funções padrão print e input.

---

# Linguagem

A linguagem modelada é uma simplificação da linguagem C, com algumas restrições e adições.

Os tipos primitivos são: bool, int, float, char e string

São funções built-in: print e input.

Algumas restrições são: ausência de ponteiros e matrizes, não se pode passar array's para funções, não há cast de tipos entre float e int, não existem operadores binários, de incremento e decremento, além de não existirem operadores lógicos como && e ||.

A linguagem aceita operações aritméticas e relacionais, além de estruturas de controle como if, else e while.

## Exemplo de código

```c
routine exemplo;

fn foo() -> bool {
  return true;
}

begin
fn main() -> int {
  print("Hello, World!");

  bool a = foo();

  return 1;
}
```

Todo programa começa com a declaração "routine \<nome\>;" e a função principal leva um marcador begin antes de sua definição. Não são permitidas funções aninhadas.

