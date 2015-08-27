
--XSETTINGS decoder.
--see http://standards.freedesktop.org/xsettings-spec/xsettings-0.5.html

local ffi = require'ffi'
local bit = require'bit'

local XSETTINGS_TYPE_INT     = 0
local XSETTINGS_TYPE_STRING  = 1
local XSETTINGS_TYPE_COLOR   = 2

local abis = {[0] = 'le', 'be'}

local function bswap16(x)
	local lo = bit.band(x, 0xff)
	local hi = bit.rshift(x, 8)
	return lo * 0xff + hi
end

local function pass(x) return x end

local function decode(buf, sz)
	assert(sz >= 12)
	local bbuf = ffi.cast('int8_t*', buf)
	local sbuf = ffi.cast('int16_t*', buf)
	local ibuf = ffi.cast('int32_t*', buf)
	local byte_order = bbuf[0]
	local native = ffi.abi(abis[byte_order])
	local iswap = native and pass or bit.bswap
	local sswap = native and pass or bswap16
	local serial = iswap(ibuf[1])
	local n = iswap(ibuf[2])
	local iofs = 3 --32bit-step offset
	local t = {serial = serial}
	for i=1,n do
		local stype = bbuf[iofs * 4]
		local sz = sswap(sbuf[iofs * 2 + 1])
		iofs = iofs + 1
		local name = ffi.string(ibuf + iofs, sz)
		iofs = iofs + math.ceil(sz / 4)
		local serial = iswap(ibuf[iofs])
		iofs = iofs + 1
		sz = sz - 12
		if stype == XSETTINGS_TYPE_INT then
			local val = ibuf[iofs]
			t[name] = {type = 'int', value = val, serial = serial}
			iofs = iofs + 1
		elseif stype == XSETTINGS_TYPE_STRING then
			local sz = iswap(ibuf[iofs])
			iofs = iofs + 1
			local val = ffi.string(ibuf + iofs, sz)
			t[name] = {type = 'string', value = val, serial = serial}
			iofs = iofs + math.ceil(sz / 4)
		elseif stype == XSETTINGS_TYPE_COLOR then
			local r = sswap(sbuf[iofs * 2 + 0])
			local g = sswap(sbuf[iofs * 2 + 1])
			local b = sswap(sbuf[iofs * 2 + 2])
			local a = sswap(sbuf[iofs * 2 + 3])
			t[name] = {type = 'color', r = r, g = g, b = b, a = a, serial = serial}
			iofs = iofs + 2
		end
	end
	return t
end

return {
	decode = decode,
}
