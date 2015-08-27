---
tagline: threads support
---

> **NOTE:** This is just a distribution of Lanes. Lanes is developed [here][lanes site].

## `local lanes = require'lanes'`

## Documentation

There's up-to-date Lanes documentation [here][lanes doc]. Ignore the [old site].

## LuaJIT notes

To use ffi inside lanes you have to require the ffi module inside the lane,
since the ffi module cannot be transferred as an upvalue to your lane
(you will get an error about "destination transfer database").
This also means that *other modules* that depend on ffi cannot be upvalues
and must be required explicitly inside the lane or luajit will crash.


[lanes site]:     http://github.com/LuaLanes/lanes
[lanes doc]:      https://rawgithub.com/LuaLanes/lanes/master/docs/index.html
[old site]:       http://kotisivu.dnainternet.net/askok/bin/lanes/
