
local mp = require 'msgpack'
local glue = require'glue'
local ffi = require'ffi'
local N = mp.N
local repl = glue.repl

local data = {
    false,              "false",
    true,               "true",
    nil,                "nil",
    0,                  "0 Positive FixNum",
    0,                  "0 uint8",
    0,                  "0 uint16",
    0,                  "0 uint32",
    0,                  "0 int8",
    0,                  "0 int16",
    0,                  "0 int32",
    -1,                 "-1 Negative FixNum",
    -1,                 "-1 int8",
    -1,                 "-1 int16",
    -1,                 "-1 int32",
    127,                "127 Positive FixNum",
    127,                "127 uint8",
    255,                "255 uint16",
    65535,              "65535 uint32",
    -32,                "-32 Negative FixNum",
    -32,                "-32 int8",
    -128,               "-128 int16",
    -32768,             "-32768 int32",
    0.0,                "0.0 float",
    -0.0,               "-0.0 float",
    "a",                "\"a\" FixStr",
    "a",                "\"a\" str 8",
    "a",                "\"a\" str 16",
    "a",                "\"a\" str 32",
    "",                 "\"\" FixStr",
    "",                 "\"\" str 8",
    "",                 "\"\" str 16",
    "",                 "\"\" str 32",
    "a",                "\"a\" bin 8",
    "a",                "\"a\" bin 16",
    "a",                "\"a\" bin 32",
    "",                 "\"\" bin 8",
    "",                 "\"\" bin 16",
    "",                 "\"\" bin 32",
    {[N] = true, 0 },              "[0] FixArray",
    {[N] = true, 0 },              "[0] array 16",
    {[N] = true, 0 },              "[0] array 32",
    {[N] = true},                 "[] FixArray",
    {[N] = true},                 "[] array 16",
    {[N] = true},                 "[] array 32",
    {},                 "{} FixMap",
    {},                 "{} map 16",
    {},                 "{} map 32",
    { a=97 },           "{\"a\"=>97} FixMap",
    { a=97},            "{\"a\"=>97} map 16",
    { a=97 },           "{\"a\"=>97} map 32",
    { [N] = true, {[N] = true} },             "[[]]",
    { [N] = true, {[N] = true, "a"} },          "[[\"a\"]]",
	 glue.fromhex('01                        ', true), "fixext 1",
    glue.fromhex('02 01                     ', true), "fixext 2",
    glue.fromhex('04 03 02 01               ', true), "fixext 4",
    glue.fromhex('08 07 06 05 04 03 02 01   ', true), "fixext 8",
    glue.fromhex('10 0f 0e 0d 0c 0b 0a 09 08 07 06 05 04 03 02 01', true), "fixext 16",
    glue.fromhex('61', true), "ext 8",
    glue.fromhex('61', true), "ext 16",
    glue.fromhex('61', true), "ext 32",
    ffi.cast('uint64_t', 0),                  "0 uint64",
    ffi.cast('int64_t' , 0),                  "0 int64",
    ffi.cast('int64_t',  -1),                 "-1 int64",
    ffi.cast('uint64_t', 4294967295),         "4294967295 uint64",
    ffi.cast('int64_t' , -2147483648),        "-2147483648 int64",
    0.0,                "0.0 double",
    -0.0,               "-0.0 double",
    1.0,                "1.0 double",
    -1.0,               "-1.0 double",
}

local function process(s)
	s = s:gsub('#[^\n]+', '')
	local t = {}
	for v in s:gmatch'%x%x' do
		 t[#t+1] = string.char(tonumber(v, 16))
	end
	return table.concat(t)
end

-- see https://github.com/msgpack/msgpack/blob/master/test/cases_gen.rb
local mpac = process[===[
c2                              # false
c3                              # true
c0                              # nil
00                              # 0 Positive FixNum
cc 00                           # 0 uint8
cd 00 00                        # 0 uint16
ce 00 00 00 00                  # 0 uint32
d0 00                           # 0 int8
d1 00 00                        # 0 int16
d2 00 00 00 00                  # 0 int32
ff                              # -1 Negative FixNum
d0 ff                           # -1 int8
d1 ff ff                        # -1 int16
d2 ff ff ff ff                  # -1 int32
7f                              # 127 Positive FixNum
cc 7f                           # 127 uint8
cd 00 ff                        # 255 uint16
ce 00 00 ff ff                  # 65535 uint32
e0                              # -32 Negative FixNum
d0 e0                           # -32 int8
d1 ff 80                        # -128 int16
d2 ff ff 80 00                  # -32768 int32
ca 00 00 00 00                  # 0.0 float
ca 80 00 00 00                  # -0.0 float
a1 61                           # "a" FixStr
d9 01 61                        # "a" str 8
da 00 01 61                     # "a" str 16
db 00 00 00 01 61               # "a" str 32
a0                              # "" FixStr
d9 00                           # "" str 8
da 00 00                        # "" str 16
db 00 00 00 00                  # "" str 32
c4 01 61                        # "a" bin 8
c5 00 01 61                     # "a" bin 16
c6 00 00 00 01 61               # "a" bin 32
c4 00                           # "" bin 8
c5 00 00                        # "" bin 16
c6 00 00 00 00                  # "" bin 32
91 00                           # [0] FixArray
dc 00 01 00                     # [0] array 16
dd 00 00 00 01 00               # [0] array 32
90                              # [] FixArray
dc 00 00                        # [] array 16
dd 00 00 00 00                  # [] array 32
80                              # {} FixMap
de 00 00                        # {} map 16
df 00 00 00 00                  # {} map 32
81 a1 61 61                     # {"a"=>97} FixMap
de 00 01 a1 61 61               # {"a"=>97} map 16
df 00 00 00 01 a1 61 61         # {"a"=>97} map 32
91 90                           # [[]]
91 91 a1 61                     # [["a"]]
d4 01 01                        # fixext 1
d5 02 02 01                     # fixext 2
d6 04 04 03 02 01               # fixext 4
d7 08 08 07 06 05 04 03 02 01   # fixext 8
d8 16 10 0f 0e 0d 0c 0b 0a 09 08 07 06 05 04 03 02 01   # fixext 16
c7 01 08 61                     # ext 8
c8 00 01 16 61                  # ext 16
c9 00 00 00 01 32 61            # ext 32
cf 00 00 00 00 00 00 00 00      # 0 uint64
d3 00 00 00 00 00 00 00 00      # 0 int64
d3 ff ff ff ff ff ff ff ff      # -1 int64
cf 00 00 00 00 ff ff ff ff      # 4294967295 uint64
d3 ff ff ff ff 80 00 00 00      # -2147483648 int64
cb 00 00 00 00 00 00 00 00      # 0.0 double
cb 80 00 00 00 00 00 00 00      # -0.0 double
cb 3f f0 00 00 00 00 00 00      # 1.0 double
cb bf f0 00 00 00 00 00 00      # -1.0 double
]===]

mp.decode_unknown = function(self, p, i, len, typ)
	return ffi.string(p+i, len)
end

mp.decode_i64 = glue.pass
mp.decode_u64 = glue.pass

local i = 1
local function eqs(v1, v0, descr)
	if v1 == v0 then return end
	error(string.format('%s ~= %s (%s)', v1, v0, descr or ''))
end
local function eq(v1, v0, descr)
	eqs(type(v1), type(v0), descr)
	if type(v1) == 'table' then
		if v0[N] then
			eqs(repl(v0[N], true, #v0), repl(v1[N], true, #v1) or #v1, descr)
			for k,v in ipairs(v0) do eq(v0[k], v, descr) end
		else
        eqs(glue.count(v1), glue.count(v0), descr)
			for k,v in pairs(v1) do eq(v0[k], v, descr) end
			for k,v in pairs(v0) do eq(v1[k], v, descr) end
		end
	else
		eqs(v1, v0, descr)
	end
end

local b = mp:encoding_buffer()

for _,v1 in mp:decode_each(mpac) do
	local v0, descr = data[i], data[i+1]
	eq(v1, v0, descr)
	b:encode(v0)
	i = i + 2
end

--TODO: encode larger values so we can test the encoder properly.

local encoded = process[===[
c2                              # false
c3                              # true
c0                              # nil
00                              # 0 Positive FixNum
00                              # 0 uint8
00                              # 0 uint16
00                              # 0 uint32
00                              # 0 int8
00                              # 0 int16
00                              # 0 int32
ff                              # -1 Negative FixNum
ff                              # -1 int8
ff                              # -1 int16
ff                              # -1 int32
7f                              # 127 Positive FixNum
7f                              # 127 uint8
cc ff                           # 255 uint16
cd ff ff                        # 65535 uint32
e0                              # -32 Negative FixNum
e0                              # -32 int8
d0 80                           # -128 int16
d1 80 00                        # -32768 int32
00                              # 0.0 float
cb 80 00 00 00 00 00 00 00      # -0.0 float
a1 61                           # "a" FixStr
a1 61                           # "a" str 8
a1 61                           # "a" str 16
a1 61                           # "a" str 32
a0                              # "" FixStr
a0                              # "" str 8
a0                              # "" str 16
a0                              # "" str 32
a1 61                           # "a" bin 8
a1 61                           # "a" bin 16
a1 61                           # "a" bin 32
a0                              # "" bin 8
a0                              # "" bin 16
a0                              # "" bin 32
91 00                           # [0] FixArray
91 00                           # [0] array 16
91 00                           # [0] array 32
90                              # [] FixArray
90                              # [] array 16
90                              # [] array 32
80                              # {} FixMap
80                              # {} map 16
80                              # {} map 32
81 a1 61 61                     # {"a"=>97} FixMap
81 a1 61 61                     # {"a"=>97} map 16
81 a1 61 61                     # {"a"=>97} map 32
91 90                           # [[]]
91 91 a1 61                     # [["a"]]
a1 01                           # fixext 1
a2 02 01                        # fixext 2
a4 04 03 02 01                  # fixext 4
a8 08 07 06 05 04 03 02 01      # fixext 8
b0 10 0f 0e 0d 0c 0b 0a 09 08 07 06 05 04 03 02 01  # fixext 16
a1 61                           # ext 8
a1 61                           # ext 16
a1 61                           # ext 32
cf 00 00 00 00 00 00 00 00      # 0 uint64
d3 00 00 00 00 00 00 00 00      # 0 int64
d3 ff ff ff ff ff ff ff ff      # -1 int64
cf 00 00 00 00 ff ff ff ff      # 4294967295 uint64
d3 ff ff ff ff 80 00 00 00      # -2147483648 int64
00                              # 0.0 double
cb 80 00 00 00 00 00 00 00      # -0.0 double
01                              # 1.0 double
ff                              # -1.0 double
]===]

local v0 = glue.tohex(encoded)
local v1 = glue.tohex(b:tostring())
assert(v0 == v1)
