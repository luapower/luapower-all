
Terra implementation in Lua based on [lx] and [llvm].

## Status

<warn>Work-in-progress</warn>

## Goals

* fix terra bugs and warts that nobody seem to be able or willing to fix
in the original implementation, and I'm unwilling to touch that C++ mess.
  * make typechecking lazy again.
  * make overloads automatic again.
  * var decl shadowing like Lua.
  * fix __for semantics.
  * macro syntax.
  * make ^ sugar for pow() and add a `xor` operator.

* add some needed features:
  * struct, field & func annotations syntax.
  * nested functions with lexical scoping like gcc would really make life easier.
  * ternary operator syntax? `:` can't be used, and iif() macro is meh...
  * should we add ++, --, +=, -=, *= /=, ^=, >>=, <<= or is it too much?

## TODO

- build libclang into llvm.dll
- extend LLVM/libclang C APIs
- terra parser
- terra typechecker
- llvm code gen
- better compile-time error tracebacks
- terra-C interface
- terra-Lua interface
- build & link API
- debug symbols
- unit tests
- type caching API incl. generated code

