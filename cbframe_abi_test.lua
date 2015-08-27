--NOTE: this is work-in-progress.
local cbframe = require'cbframe'
local ffi = require'ffi'
local reflect = require'ffi_reflect'
local pp = require'pp'

local test = {}

ffi.cdef'typedef struct __attribute__((__packed__)) S1 { int8_t f1;              } SS1'
ffi.cdef'typedef struct __attribute__((__packed__)) S2 { int16_t f1;             } SS2'
ffi.cdef'typedef struct __attribute__((__packed__)) S3 { int16_t f1; int8_t f2;  } SS3'
ffi.cdef'typedef struct __attribute__((__packed__)) S4 { int32_t f1;             } SS4'
ffi.cdef'typedef struct __attribute__((__packed__)) S5 { int32_t f1; int8_t  f2; } SS5'
ffi.cdef'typedef struct __attribute__((__packed__)) S6 { int32_t f1; int16_t f2; } SS6'
local S1 = ffi.new('SS1', string.byte'x')
local S2 = ffi.new('SS2', string.byte'x')
local S3 = ffi.new('SS3', string.byte'x')
local S4 = ffi.new('SS4', string.byte'x')
local S5 = ffi.new('SS5', string.byte'x')
local S6 = ffi.new('SS6', string.byte'x')

function eq(t1, t2, prefix, level)
	prefix = prefix or ''
	level = level or 2
	if type(t1)=='table' and type(t2)=='table' then
		for k,v in pairs(t1) do
			eq(t2[k], v, prefix .. '.' .. tostring(k), level + 1)
		end
		for k,v in pairs(t2) do
			eq(t1[k], v, prefix .. '.' .. tostring(k), level + 1)
		end
	elseif type(t1) ~= type(t2) then
		error(type(t1) .. ' ~= ' .. type(t2))
	elseif type(t1) == 'cdata' then
		local ct1 = reflect.typeof(t1)
		local ct2 = reflect.typeof(t2)
		eq(ct1, ct2, prefix, level)
		if ct1.what == 'struct' or ct1.what == 'union' then
			for rct in ct1:members() do
				eq(t1[rct.name], t2[rct.name])
			end
		end
	else
		if (t1 == t1 and t1 ~= t2) or (t1 ~= t1 and t2 == t2) then
			error(tostring(t1) .. " ~= " .. tostring(t2) ..
								" [" .. prefix .. "]", level)
		end
	end
end

local function test_sig(sig, testargs)
	local rargs, ret
	local cb = cbframe.cast(sig, function(...)
		rargs = {n = select('#', ...), ...}
		return ret
	end)
	local cbf = ffi.cast(sig, cb.p)
	for i,args in ipairs(testargs) do
		args.n = args.n or #args
		ret = args.ret
		local rret = cbf(unpack(args, 1, args.n))
		pp(args)
		pp(rargs)
		eq(args, rargs)
		eq(ret, rret)
	end
	cb:free()
end

function test.bool_arg()
	test_sig('void(*)(bool, SS1, SS2)', {{true, S1, S2}, {false, S1, S2}})
	--[[
	local ct = 'void(*)(bool, S)'
	local cb = cbframe.cast(ct, function(b,S) print(b) end)
	ffi.cast(ct, cb.p)(15,S)
	ffi.cast(ct, cb.p)(0,S)
	cb:free()
	]]
end

--local ct = 'typedef union S1 {int x, y;} S1;
--typedef struct S2 {int a, b, c;} S2;

for k,f in pairs(test) do
	print(k)
	f()
end
