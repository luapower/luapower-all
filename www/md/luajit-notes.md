---
title:   LuaJIT notes
tagline: assumptions, gotchas, tricks
---

## LuaJIT assumptions

  * LuaJIT hoists table accesses with constant keys  out of loops, so caching
  module functions in locals is no longer (that much) needed.
  * LuaJIT hoists constant branches out of loops so it's ok to specialize
  loop kernels with `if/else` or with `and/or` inside the loops.
  * LuaJIT inlines functions (except when using `...` and `select()` with
  non-constant indices), so it's ok to specialize loop kernels with function
  composition.
  * multiplications and additions are cheaper than memory access, so storing
  the results of these operations in temporary variables might actually harm
  performance (more register spills).
  * there's no difference between using `if/else` statements and using
  `and/or` expressions -- they generate the same pipeline-trashing branch code
  (so avoid expressions with non-constant `and/or` operators in tight loops).
  * divisions are 4x slower than multiplications on x86, so when dividing by
  a constant, it helps turning `x / c` into `x * (1 / c)` since the constant
  expression is folded -- LuaJIT does this already for power-of-2
  constants where the semantics are equivalent.
  * the `%` operator is slow (it's implemented in terms of `math.floor()`
  and division) and really kills hot loops; `math.fmod()` is even slower;
  I don't have a solution for this except for `x % powers-of-two` which
  can be computed with bit ops.
  * `__newindex` and `__index` metamethods must check the hash part of the
  table, so it's best to avoid adding keys on the hash part of an array
  that uses these metamethods.
  * pointers and 64bit numbers are allocated on the heap unless sunk by
  allocation sinking, but that requires a small and predictable code path
  between pointer creation and usage so it's not a general solution.
  So APIs that need to be fast should work with (base-pointer, offset) pairs
  instead of just pointers.

> These are assumptions that I use throughout my code, so if any of them are
wrong, please correct me.

## LuaJIT gotchas

### Nil equality of pointers

`ptr == nil` evaluates to true for a NULL pointer. As innocent as this looks,
this is actually a language extension because in Lua 5.1 world, objects of
different types can't ever be equal, so a cdata cannot be equal to nil.

This has two implications:

1. Lua-ffi cannot implement this for Lua 5.1, so compatibility with Lua
cannot be acheived if this idiom is used.
2. The `if ptr then` idiom doesn't work, although you'd expect that anything
that `== nil` to pass the `if` test too.

Both problems can be solved easily with a NULL->nil converter which must be
applied on all pointers that flow into Lua (so mostly in constructors):

~~~{.lua}
local NULL = ffi.new'void*'
function ptr(p)
	return p ~= NULL and p or nil
end
~~~

### Reference semantics vs value semantics

The result of a[i] for an array of structs is a reference type,
not a copy of the struct object. This is different than with arrays
of scalars which have value semantics (scalars being immutable).
This shows when trying to implement data structures that generalize
on the element type. Because value semantics cannot be assumed,
you can't just use a[i] to pop a value out or for swapping values
(the idiom `a[i], a[j] = a[j], a[i]` doesn't work anymore).

### Callbacks and JIT

JIT must be disabled on any Lua function that calls a C function that can
trigger a ffi callback or you might get a "bad callback" exception. LuaJIT
takes great pains to ensure that you won't, but there's no guarantee. This
can turn into a "99% is worse than 0%" situation, because you might forget
to disable the jit for a particular callback-triggering function only to get
a crash in production.

There is no way that I know of to disable these jit barriers.

### Callbacks and passing structs by value

Currently, passing structs by value or returning structs by value is not
supported with callbacks. This is generally not a problem, as most APIs
don't do that, with the notable exception of OSX APIs which do that _a lot_.
[cbframe] can be used as a workaround if you only have a few functions to fix,
but it's not a general solution yet.

### CData finalizer call order

Finalizers for cdata objects are called in undefined order. This means that
objects anchored in a finalizer are not guaranteed to not be already finalized
when that finalizer is called.

Consider this:

~~~{.lua}
local heap = ffi.gc(CreateHeap(), FreeHeap)

local mem = ffi.gc(CreateMem(heap, size), function(mem)
	FreeMem(heap, mem) -- heap anchored in mem's finalizer
end)
~~~

When the program exits, sometimes the heap's finalizer is called before
mem's finalizer, even though mem's finalizer holds a reference to heap.
So it's ok and useful to anchor objects in finalizers, but don't _use_ them
in finalizers unless you can ensure that they're still alive by other means.

There is no way to fix this with the current garbage collector.

### Floating point numbers from outside

In places where an arbitrary bit pattern can be injected in place of a double
or float, you have to normalize these to a standard NaN pattern
(`0xffc00000` for floats and `0xfff8000000000000` for doubles), or check for
NaN before accessing them. Failing to do so will get you a crash.

> The bit pattern for NaN is: exponent is all '1', mantissa non-zero,
sign ignored.

Here's a handy NaN checker for doubles:

~~~{.lua}
local cast, band, bor = ffi.cast, bit.band, bit.bor
local lohi_p = ffi.typeof("struct { int32_t "..(
  ffi.abi("le") and "lo, hi" or "hi, lo").."; } *")

local function double_isnan(p)
   local q = cast(lohi_p, p)
   return band(q.hi, 0x7ff00000) == 0x7ff00000 and
	        bor(q.lo, band(q.hi, 0xfffff)) ~= 0
end
~~~

### LuaJIT memory restrictions

LuaJIT must be in the lowest 2G of address space on x64. This applies to all
GC-managed memory, including `ffi.new` allocations. Use malloc, mmap, etc.
to access all memory without restrictions. Keep the low 2G of your address
space free for LuaJIT (this might be hard depending on how you integrate
LuaJIT in your app). Keep in mind that that if your memory usage on x86 is
above 2G, your app is already not portable to x64. If you use malloc to fix
this, watch out for problems with finalization order: finalization and
freeing are the same thing now.

## LuaJIT tricks

Pointer to number conversion that turns into a no-op when compiled:

	tonumber(ffi.cast('intptr_t', ffi.cast('void *', ptr)))

Switching endianness of a 64bit integer (to use in conjunction with
`ffi.abi'le'` and `ffi.abi'be'`):

	local p = ffi.cast('uint32*', int64_buffer)
	p[0], p[1] = bit.bswap(p[1]), bit.bswap(p[0])
