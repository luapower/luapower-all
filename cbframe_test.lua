local ffi = require'ffi'
local cbframe = require'cbframe'

--test float converters
local function test_conv()
	local f80 = ffi.new'uint8_t[10]'
	cbframe.float64to80(1/8, f80)
	local f64 = cbframe.float80to64(f80)
	assert(f64 == 1/8)
end

local function test_multiple(cpu)
	local function f1(cpu)
		cbframe.dump(cpu)
		cpu.RAX.u = 7654321
	end
	local cb1 = cbframe.new(f1)

	local cb2 = cbframe.new(function(cpu)
		cbframe.dump(cpu)
		cpu.RAX.u = 4321
	end)

	local cf1 = ffi.cast('int(__cdecl*)(float, int, int, int, int, int)', cb1.p)
	local ret = cf1(12345.6, 0x3333, 0x4444, 0x5555, 0x6666, 0x7777)
	assert(ret == 7654321)

	local f2 = ffi.cast('int(__cdecl*)(float, int, int, int, int, int)', cb2.p)
	local ret = f2(12345.6, 0x3333, 0x4444, 0x5555, 0x6666, 0x7777)
	assert(ret == 4321)

	cb1:free()
	cb2:free()
end

local function test_speed()
	local swap
	if ffi.abi'64bit' then
		if ffi.os == 'Windows' then return end --TODO: test win64
		swap = function(cpu)
			local w = cpu.XMM[0].lo.f
			local h = cpu.XMM[1].lo.f
			cpu.XMM[0].lo.f = h
			cpu.XMM[1].lo.f = w
		end
	else
		swap = function(cpu)
			local w = cpu.ESP.dp[4].f
			local h = cpu.ESP.dp[5].f
			cpu.EAX.f = h
			cpu.EDX.f = w
		end
	end
	local cb = cbframe.new(swap)
	if ffi.abi'64bit' then
		ffi.cdef'typedef struct NSSize {double w, h;} NSSize'
	else
		ffi.cdef'typedef struct NSSize {float w, h;} NSSize'
	end
	local NSSize = ffi.typeof'NSSize'
	local cf = ffi.cast('NSSize(__cdecl*)(void*, void*, void*, NSSize)', cb.p)

	local sz = NSSize(149, 49)
	local p1 = ffi.cast('void*', 0x123)
	local p2 = ffi.cast('void*', 0x456)
	local p3 = ffi.cast('void*', 0x789)
	local ret = NSSize()
	for i = 1,10^6 do
		local ret = cf(p1, p2, p3, sz)
		assert(ret.w == sz.h)
		assert(ret.h == sz.w)
	end
	print'10^6 calls + checks'
end

test_conv()
test_multiple()
test_speed()
