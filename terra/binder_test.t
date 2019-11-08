setfenv(1, require'terra.low'.module())
local binder = require'terra.binder'

local function test_cdefs()
	local h = binder.cdefs()

	--cascade typedef, struct field
	struct T1 { x: int; }
	struct S1 { t: &T1; }
	h(S1) --T1 does not need to be defined, only declared.

	--cascade typedef, pointer-to-struct field
	struct T2 { x: int; }
	struct S2 { t: T2; }
	--T2.opaque = true --uncomment to trigger error
	h(S2) --T2 does need to be defined.

	--cascade typedef, function pointer
	struct S
	struct T { s: S; }
	struct S { t: &T; }
	terra _M.f :: {S} -> {}
	fp = &f.type
	h(T) --need to add T manually before fp (see note in binder.lua)
	h(fp)

	Sint = tuple(S, int)

	--name shortened
	fp1 = {Sint, Sint, Sint} -> {int, S}
	h(fp1)

	--name clash
	fp2 = {S, int} -> {int, S}; h(fp2)
	fp3 = {Sint} -> {int, S}; h(fp3)
	assert(fp2 ~= fp3)

	--void args/retval
	fp4 = {} -> Sint
	h(fp4)
	fp5 = {Sint} -> {}
	h(fp5)

	--pointer args/retval
	h({&&S} -> {&&opaque})

	--rawstring args/retval
	h({rawstring, rawstring} -> rawstring)

	--terra function
	h(f)

	--globals must be named and set as extern
	g1 = global(int, 5, 'g1', true) --remove name and/or extern flag to trigger error
	h(g1)

	--anon functions must be named
	f = terra() end
	f.cname = 'my_f' --uncomment to trigger error
	h(f)

	--anon structs can be left unnamed
	local S = struct {}
	h(S)

	--enum match and prefix
	h({
		[1] = 2,
		[false] = 5,
		ENUM1 = 12,
		ENUM2 = 5ULL,
		ENUM3 = 'hello',
		ENUMX = 21,
		enum4 = 32,
	}, {
		ENUM = 'E_';
		enum = 'E_SMALL_';
	})

	h{} --no enums
	h{a=1, b=2, Z=3} --not uppercase
	h({pa=1, pb=2}, 'p', 'P_')

	--overloaded funcs: automatic names
	local f = overload'OverloadedFunc'
	f:adddefinition(terra(a: int) end)
	f:adddefinition(terra(): int end)
	h(f)

	local f = overload'AnotherOverloadedFunc'
	f.cname = {'func_a', 'func_b'} --custom names
	f:adddefinition(terra(x: int) end)
	f:adddefinition(terra() end)
	h(f)

	print(h())
	ffi.cdef(h())
end

local function test_lib()
	setfenv(1, require'terra.low'.module())
	local mylib = binder.lib'publish_test'

	struct S (gettersandsetters) {
		_x: int;
	}

	terra S:m1() end

	terra f(s: &S) end

	mylib(S, {cname = 's_t', opaque = true})
	mylib(f)

	print'-------------------------------------------------------'
	print(mylib:c_header())

	print'-------------------------------------------------------'
	print(mylib:ffi_binding())

	--[[

	mylib(anon)
	struct S (mylib) {
		x: int;
		union {
			a: &&&S;
			union {
				b: &opaque;
				s1: anon;
				s2: anon;
			};
		};
		y: double;
	}
	gettersandsetters(S)

	terra f(x: anon): S end; mylib(f)
	terra g(x: &opaque, s: rawstring, b: bool) end; mylib(g)

	local bool2 = tuple(bool, bool)
	terra S:f(x: {int, int}, y: {int8, int8, bool2}): {num, num, bool}
		return
			x._0 + x._1,
			y._0 + y._1,
			y._2._0 and y._2._1
	end
	local whoa = {bool, int} -> {bool2, int, S}
	terra S:g(z: whoa): S end

	lib:build()

	--print(lib:bindingcode())

	local p = require'publish_test_h'
	local s = ffi.new'S'
	local r = s:f({3, 4}, {5, 6, {true, true}})
	assert(r._0 == 7)
	assert(r._1 == 11)
	assert(r._2 == true)
	]]
end

--test_cdefs()
test_lib()
