---
tagline: callback frames for luajit
---

## `local cbframe = require'cbframe'`

Cbframe is a low-level helper module for the luajit ffi for creating ABI-agnostic callbacks.
I made it as a workaround for the problem of creating callbacks with pass-by-value struct
args and return values in [objc].

Works with x86 and x64 Windows, Linux and OSX.

The idea is simple: your callbacks receive the [full state of the CPU] (all registers, and CPU flags even),
you can modify the state any way you want, and the CPU will be set with the modified state before the
callback returns. It's up to you to pick the function arguments from the right registers and/or stack,
and to put the return value into the right registers and/or stack, according to the calling convention
rules for your platform/compiler.

[full state of the CPU]: https://github.com/luapower/cbframe/blob/master/cbframe_x86_h.lua

You can use it to implement a full ABI in pure Lua by leveraging [ffi_reflect].
Or, if you only have a few problematic callbacks that you need to work out, like I do, you can
discover where the arguments are on a case-by-case basis by inspecting the CPU state via
`cbframe.dump()`.

ABI manuals:

  * [Windows / x86](http://msdn.microsoft.com/en-us/library/k2b2ssfy.aspx)
  * [Windows / x64](http://msdn.microsoft.com/en-us/library/7kcdt6fy.aspx)
  * [OSX / x86](https://developer.apple.com/library/mac/documentation/DeveloperTools/Conceptual/LowLevelABI/130-IA-32_Function_Calling_Conventions/IA32.html)
  * [Linux & OSX / x64](http://www.x86-64.org/documentation/abi.pdf)

If in doubt, use [Agner Fog](http://www.agner.org/optimize/calling_conventions.pdf) (ABIs are a bitch).

Like ffi callbacks, cbframes are limited resources. You can create up to 1024
simultaneous cbframe objects (you can change that limit in the code - callback slots must be pre-allocated;
each callback slot is 7 bytes).

The API is simple. You don't even have to provide the function signature :)

~~~{.lua}
local foo = cbframe.new(function(cpu)
	cbframe.dump(cpu)          --inspect the CPU state
	local arg1 = cpu.RDI.lo.i  --Linux/x64 ABI: int32 arg#1 in RDI
	cpu.RAX.u = arg1^2         --Linux/x64 ABI: uint64 return value in RAX
end)

--foo is the callback object, foo.p is the actual function pointer to use.
set_foo_callback(foo.p)

--cbframes are permanent by default just like ffi callbacks. tie them to the gc if you want.
ffi.gc(foo, foo.free)

--release the callback slot (or reuse it with foo:set(func)).
foo:free()
~~~

**NOTE**: In this implementation, the cpu arg is a 64-deep global stack,
which limits callback recursion depth to 64. There's no protection against
stack overflows.
