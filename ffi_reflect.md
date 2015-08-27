---
tagline: luajit ffi reflection
---

> **NOTE**: This is a fork of the reflect module by Peter Cawley, developed [here][reflect site].

Quick examples:
```lua
local ffi = require "ffi"
local reflect = require "ffi_reflect"

ffi.cdef 'int sc(const char*, const char*) __asm__("strcmp");'
print(reflect.typeof(ffi.C.sc).sym_name) --> "strcmp"

for refct in reflect.typeof"int(*)(int x, int y)".element_type:arguments() do
  print(refct.name)
end --> x, y

t = {}
assert(reflect.getmetatable(ffi.metatype("struct {}", t)) == t)
```

For the full API reference, see [http://corsix.github.io/ffi-reflect/](http://corsix.github.io/ffi-reflect/).

[reflect site]: https://github.com/corsix/ffi-reflect
