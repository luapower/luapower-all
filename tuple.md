---
tagline: real tuples
---

## `local tuple = require'tuple'`

Tuples are immutable lists that can be used as table keys because they have
value semantics, that is, the tuple constructor returns the same identity
for the exact same list of identities. If you don't need this property,
[vararg.pack] is a more memory efficient way to store small lists of values.

[vararg.pack]: vararg.html#pack

---------------------------------- -------------------------------------------
`tuple(e1,...) -> t`					  get a tuple
`tuple.narg(n,e1,...) -> t`        get a tuple with a fixed number of elements
`tuple.from_array{n=,e1,...} -> t` get a tuple from a (sparse) array
`t([i[, j]) -> e1,...`				  unpack elements
`t[i] -> ei`							  access elements
`t.n`										  number of elements
`tostring(t) -> s`					  string representation
`pp.format(t) -> s`					  serialization with [pp]
`tuple.space([weak]) -> tuple`	  create a new (weak or strong) tuple space
---------------------------------- -------------------------------------------

> __NOTE:__ Tuple elements can be anything, including `nil` and `NaN`.

### Example

~~~{.lua}
local tuple = require'tuple'

local T = tuple('a', 0/0, 2, nil)
local t = {}
t[T] = 'here'
assert(t[tuple('a', 0/0, 2, nil)] == 'here')
assert(t[tuple('a', 0/0, 2)] == nil)
print(T())
> a	nan	2	nil
~~~

> __NOTE:__ all the tuple elements of all the tuples created with this
function are indexed internally with a global weak hash tree. Creating a
tuple thus takes N hash lookups and M table creations, where N+M is the
number of elements in the tuple. Lookup time depends on how dense the tree is
on the search path, which depends on how many existing tuples share a first
sequence of elements with the tuple being created. In particular, creating
tuples out of all permutations of a certain set of values hits the worst case
for lookup time, but creates the minimum amount of tables relative to the
number of tuples.

__TIP:__ Create tuple spaces that don't use weak tables for better gc
performance. When no longer needed, release the tuple space to free all
the dead tuples and associated index tables.
