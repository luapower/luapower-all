
local ffi = require'ffi'
local llvm = require'llvm'

print('default_target_triple:', llvm.default_target_triple())
local target1 = assert(llvm.target_from_triple'x86_64')
local target = assert(llvm.target())
local machine = assert(target:machine())
print('triple      :', machine:triple())
print('cpu         :', machine:cpu())
print('features    :', machine:features())
print('data layout :', machine:data_layout():tostring())

--local target = assert(llvm.target_from_triple'x86_64-w64-windows-gnu')
--print(target:tostring())

local mod = llvm.module'my_module'

local sum_fn = mod:fn('sum', llvm.fn(llvm.int32, llvm.int32, llvm.int32))
local entry = sum_fn:block'entry'

local builder = llvm.builder()

builder:position_at_end(entry)

builder:ret(builder:add(sum_fn:param(0), sum_fn:param(1), 'tmp'))

assert(mod:verify())

--TODO: print(machine:compile(mod))

local engine = mod:exec_engine'interpreter' --mcjit can't marshall params

local x = 6
local y = 42

local ret = engine:run(sum_fn, llvm.values(
	llvm.intval(llvm.int32, x),
	llvm.intval(llvm.int32, y))):toint()

assert(ret == x + y)

print()
print'*** Module IR: ***************************************************'
print()
print(mod:ir())
--print(mod:inline_asm())

assert(llvm.parse_bitcode(mod:bitcode()))
assert(llvm.parse_ir(mod:ir()))

--assert(engine:run(m2:get_fn()))

local t = llvm.type_from_ctype(ffi.typeof'int')
print(t:tostring())

local mod2 = assert(llvm.parse_ir[[
	define i32 @f(i32) {
		block:
			ret i32 1234
	}
]])

local orc = assert(llvm.orc(machine))
assert(orc:add_module(mod2))
local p = ffi.cast('int(*)(int)', orc:sym_addr'f')
print(p(1))

builder:free()
engine:free() --frees the module
machine:free()
orc:free()

print'test ok'
