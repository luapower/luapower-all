---
tagline: vararg manipulation
---

## `local vararg = require'vararg'`

Lua library for manipulating variable arguements (vararg) of functions.
These functions allow you to do things with varargs that cannot be
efficiently done in pure Lua but can be easily done through the C API.

~~~{.lua}
p = vararg.pack(...)
  p()              --> ...
  p("#")           --> select("#", ...)
  p(i)             --> (select(i, ...))
  p(i, j)          --> unpack({...}, i, j)
  for i,v in p do  --> for i,v in apairs(...) do
~~~

----------------------------- --------------------------------------------------------
vararg.range(i, j, ...)       unpack({...}, i, j)
vararg.remove(i, ...)         t={...} table.remove(t,i) return unpack(t,1,select("#",...)-1)
vararg.insert(v, i, ...)      t={...} table.insert(t,i,v) return unpack(t,1,select("#",...)+1)
vararg.replace(v, i, ...)     t={...} t[i]=v return unpack(t,1,select("#",...))
vararg.append(v, ...)         c=select("#",...)+1 return unpack({[c]=val,...},1,c)
vararg.map(f, ...)            t={} n=select("#",...) for i=1,n do t[i]=f((select(i,...))) end return unpack(t,1,n)
vararg.concat(f1,f2,...)      return all the values returned by functions 'f1,f2,...'
----------------------------- --------------------------------------------------------
