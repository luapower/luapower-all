
## `local lx = require'lx'`

Lua lexer in C with
[extensible](http://terralang.org/api.html#embedding-new-languages-inside-lua)
Lua parser in Lua.

Used as the lexer & parser for [terra2].

Can be used to create embedded DSLs that:

  * have Lua syntax(1), but have their own grammar and keywords.
  * can reference Lua local variables from the outer Lua lexical scope.
  * can contain full Lua expressions that are evaluated in the outer Lua lexical scope.

(1): extended with `>>`, `<<`, `->` operators.

## Status

<warn>Work in progress.</warn>
