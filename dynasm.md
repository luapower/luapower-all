---
tagline: DynASM with Lua mode
---

## `local dynasm = require'dynasm'`

This is a modified version of [DynASM](http://luajit.org/dynasm.html) that allows generating,
compiling, and running x86 and x86-64 assembly code directly from Lua. It also exposes the DynASM assembler
and linker to be used as Lua modules.

Jump To: [Examples](#examples) | [DynASM API](#dynasm-api) | [DASM API](#dasm-api) |
			[Changes to DynASM](#changes-to-dynasm) |
			[List of Instructions](http://corsix.github.io/dynasm-doc/instructions.html) |
			[List of Directives](http://corsix.github.io/dynasm-doc/reference.html#directives)

## Features

  * translate, compile and run Lua/ASM code from Lua (no C glue)
  * load Lua/ASM (.dasl) files with `require()`
  * works with file, string and stream inputs and outputs

## Before you start

1. DynASM is [not an inline assembler](http://www.corsix.org/content/what-is-dynasm), it's a code generator.
	The following code:

	~~~{.lua}
	function codegen(Dst)
		for i = 1, 3 do
			| mov ax, i
		end
	end
	~~~

	does _not_ run the assembly instruction 3 times when codegen is called, instead, it merely adds the
	instruction sequence `mov ax, 1; mov ax, 2; mov ax, 3` to the dynasm state `Dst` when codegen is called.
	Mixing Lua and ASM code like this has the effect of generating code, not running it.

2. DynASM has two parts: the assembler/preprocessor, written in Lua, and the the linker/encoder, written in C.
`dynasm.lua` is the preprocessor. It takes mixed C/ASM code as input (from a file, string or file-like object)
and generates C code (to a file, string, or file-like object). Alternatively, it can take mixed Lua/ASM
code (like the above example) and generate Lua code, which is what the "Lua mode" part is all about.
`dasm.lua` is the binding to the C part of DynASM (the linker/encoder) which deals with building the code into
executable memory that can be called into.

3. `.dasl` files refer to Lua/ASM files, `.dasc` files refer to C/ASM files. dasl files can be used transparently
as Lua modules (they are translated on-the-fly).

## Examples

### 1. Self-contained module

This simple, self-contained module publishes the function multiply(x, y) -> x * y.

#### `multiply_x86.dasl:`

~~~{.lua}
local ffi = require'ffi'               --required
local dasm = require'dasm'             --required

|.arch x86                             --must be the first instruction
|.actionlist actions                   --make an action list called `actions`

local Dst = dasm.new(actions)          --make a dasm state

-- the next chunk of asm code will be added to the action list, and a call
-- to `dasm.put(Dst, 0)` will be generated in its place, which will be copying
-- the code from the start of the action list into the Dst state.

|  mov eax, [esp+4]
|  imul dword [esp+8]
|  ret

local code = Dst:build()               --check, link and encode the code
local fptr = ffi.cast('int32_t __cdecl (*) (int32_t x, int32_t y)', code) --take a callable pointer to it

return function(x, y)
	local _ = code                      --pin the code buffer so it doesn't get collected
	return fptr(x, y)
end
~~~

The best way to understand how the above code is supposed to work is to translate it:

	> lua dynasm.lua multiply_x86.dasl

#### `main.lua`:

~~~{.lua}
require'dynasm'                           --hook in the `require` loader for .dasl files
local multiply = require'multiply_x86'    --translate, load and run `multiply_x86.dasl`
assert(multiply(-7, 5) == -35)
~~~

### 2. Code gen / build split

This is an idea on how you can keep your asm code separated from the plumbing required to build it,
and also how you can make separate functions out of different asm chunks from the same dasl file.

#### `funcs_x86.dasl`:

~~~{.lua}
local ffi = require'ffi'
local dasm = require'dasm'

|.arch x86
|.actionlist actions
|.globalnames globalnames

local gen = {}

function gen.mul(Dst)                  --function which generates code into the dynasm state called `Dst`
   |->mul:                             --and returns a "make" function which gets a dasm.globals() map
   |  mov eax, [esp+4]                 --and returns a function that knows how to call into its code.
   |  imul dword [esp+8]
   |  ret
   return function(globals)
     return ffi.cast('int32_t __cdecl (*) (int32_t x, int32_t y)', globals.mul)
   end
end

function gen.add(Dst)
   |->add:
   |  mov eax, [esp+4]
   |  add eax, dword [esp+8]
   |  ret
   return function(globals)
     return ffi.cast('int32_t __cdecl (*) (int32_t x, int32_t y)', globals.add)
   end
end

return {gen = gen, actions = actions, globalnames = globalnames}
~~~

#### `funcs.lua`:

~~~{.lua}
local dynasm = require'dynasm'
local dasm   = require'dasm'
local funcs  = require'funcs_x86'

local state, globals = dasm.new(funcs.actions)     --create a dynasm state with the generated action list

local M = {}                                       --generate the code, collecting the make functions
for name, gen in pairs(funcs.gen) do
   M[name] = gen(state)
end

local buf, size = state:build()                    --check, link and encode the code
local globals = dasm.globals(globals, funcs.globalnames)   --get the map of global_name -> global_addr

for name, make in pairs(M) do                      --make the callable functions
   M[name] = make(globals)
end

M.__buf = buf                                      --pin buf so it doesn't get collected

return M
~~~

#### `main.lua`

~~~{.lua}
local funcs = require'funcs'

assert(funcs.mul(-7, 5) == -35)
assert(funcs.add(-7, 5) == -2)
~~~

### 3. Load code from a string

~~~{.lua}
local dynasm = require'dynasm'

local gencode, actions = dynasm.loadstring([[
local ffi  = require'ffi'
local dasm = require'dasm'

|.arch x86
|.actionlist actions

local function gencode(Dst)
	|  mov ax, bx
end

return gencode, actions
]])()
~~~

### 4. Translate from Lua

~~~{.lua}
local dynasm = require'dynasm'
print(dynasm.translate_tostring'multiply_x86.dasl')
~~~

The above is equivalent to the command line:

	> lua dynasm.lua multiply_x86.dasl

> __Tip__: You can pre-assemble `foo.dasl` into `foo.lua` -- `require()` will then choose `foo.lua`
over `foo.dasl`, so you basically get transparent caching for free. This speeds up app loading a bit,
and you can ship your app without the assembler (you still need to ship the linker/encoder for
all the platforms that you support).


### 5. Included demo/tutorial

Check out the included [dynasm_demo_x86.dasl] and [dynasm_demo.lua] modules for more in-depth knowledge
about DynASM/Lua interaction. It works on Windows, Linux and OSX, both x86 and x64.

[dynasm_demo.lua]:      https://github.com/luapower/dynasm/blob/master/dynasm_demo.lua
[dynasm_demo_x86.dasl]: https://github.com/luapower/dynasm/blob/master/dynasm_demo_x86.dasl


### 6. Brainfuck JIT compiler

The examples above don't do DynASM enough justice, because DynASM was after all made for building JIT compilers.
The [bf project](https://github.com/luapower/bf) contains a Lua/ASM translation of the code from Josh Haberman's
[tutorial](http://blog.reverberate.org/2012/12/hello-jit-world-joy-of-simple-jits.html) on DynASM and JITs,
and probably the simplest JIT compiler you could write. It too works on Windows, Linux and OSX, x86 and x64.

## DynASM API

----------------------------------------------------- --------------------------------------------------
__hi-level__

dynasm.loadfile(infile[, opt]) -> chunk					load a dasl file and return it as a Lua chunk

dynasm.loadstring(s[, opt]) -> chunk						load a dasl string and return it as a Lua chunk

__low-level__

dynasm.translate(infile, outfile[, opt])					translate a dasc or dasl file

dynasm.string_infile(s) -> infile							use a string as an infile to translate()

dynasm.func_outfile(func) -> outfile						make an outfile that calls func(s) for each piece

dynasm.table_outfile(t) -> outfile							make an outfile that writes pieces to a table

dynasm.translate_tostring(infile[, opt]) -> s			translate to a string

dynasm.translate_toiter(infile[, opt]) -> iter() -> s	translate to an iterator of string pieces
----------------------------------------------------- --------------------------------------------------


## DASM API

----------------------------------------------------- --------------------------------------------------
__hi-level__

dasm.new(\                                            make a dasm state for an action list. \
	actionlist, \                                      -> per `.actionlist` directive. \
	[externnames], \												-> per `.externnames` directive. \
   [sectioncount], \												-> DASM_MAXSECTION from `.sections` directive. \
 	[globalcount],	\												-> DASM_MAXGLOBAL from `.globals` directive. \
	[externget], \													-> `func(externname) -> addr`, for solving `extern`s \
	[globals]) -> state, globals								-> `void*[DASM_MAXGLOBAL]`, to hold globals

state:build() -> buf, size										check, link, alloc, encode and mprotect the code

dasm.dump(buf, size)												dump the code using the included disassembler in luajit

dasm.globals(globals, globalnames) -> {name -> addr}	given the globals array returned by dasm.new() and
																		the globalnames list per `.globalnames` directive,
																		return a table that maps the names to their address.

__low-level__

state:init(maxsection)											init a state

state:free()														free the state

state:setupglobal(globals, globalcount)					set up the globals buffer

state:growpc(maxpc)												grow the number of available pc labels

state:setup(actionlist)											set up the state with an action list

state:put(state, ...)											the assembler generates these calls

state:link() -> size												link the code and get its size

state:encode(buf)													encode the code into a buffer

state:getpclabel(pclabel[, buf])								get pc label offset, or pointer if buf is passed

state:checkstep(secmatch)										check code before encoding

state:setupextern(externnames, getter)						set up a new `extern` handler
----------------------------------------------------- --------------------------------------------------


## Changes to DynASM

The [source code changes] made to DynASM were kept to a minimum in order
to preserve DynASM semantics, make it easy to merge back changes
from upstream, and to make it easy to add the Lua mode to other
architectures supported by DynASM in the future.
As for the user-facing changes, the list is again small:

  * added `-l, --lang C|Lua` command line option (set automatically for dasl and dasc files).
  * asm comments can start with both `--` and `//` in Lua mode.
  * the defines ARCH, OS, X86, X64, WINDOWS, LINUX, OSX are available by default in Lua mode.
  * the `.globals` directive generates DASM_MAXGLOBAL in Lua mode.
  * `.type` usage is limited in Lua mode: `FOO.field`, `FOO[expr]` and `FOO[expr].field`
  are ok, but arbitrary expressions like `FOO[5].bar[2].baz` are not.
  * `extern foo` resolves to `ffi.C.foo` by default; if foo has no cdef,
  `ffi.cdef'void foo()'` is called (i.e. a dummy cdef is made for it - caveat emptor).

[source code changes]: https://github.com/luapower/dynasm/compare/7d7e130...master

## Assembler tutorials & ref docs

  * [x64 tutorial](https://software.intel.com/en-us/articles/introduction-to-x64-assembly/)
  * [SSE tutorial](http://neilkemp.us/src/sse_tutorial/sse_tutorial.html)
  * [SSE quick ref](http://softpixel.com/~cwright/programming/simd/sse.php)
  * [FPU tutorial & ref](http://www.website.masmforum.com/tutorials/fptute/index.html)
  * [Agner Fog - Calling Conventions](http://www.agner.org/optimize/calling_conventions.pdf)
  * [Agner Fog - CPU Internals](http://www.agner.org/optimize/microarchitecture.pdf)
  * [Agner Fog - Optimization Guide](http://www.agner.org/optimize/optimizing_assembly.pdf)
  * [Agner Fog - Instruction Tables](http://www.agner.org/optimize/instruction_tables.pdf)

