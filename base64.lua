
--Base64 encoding & decoding in Lua
--Written by Cosmin Apreutesei. Public Domain.

--Original code from:
--https://github.com/kengonakajima/luvit-base64/issues/1
--http://lua-users.org/wiki/BaseSixtyFour

if not ... then require'base64_test'; return end

local base64 = {}

local ffi  = require'ffi'
local bit  = require'bit'
local shl  = bit.lshift
local shr  = bit.rshift
local bor  = bit.bor
local band = bit.band
local u8a  = ffi.typeof'uint8_t[?]'
local u8p  = ffi.typeof'uint8_t*'
local u16a = ffi.typeof'uint16_t[?]'
local u16p = ffi.typeof'uint16_t*'

local b64chars_s = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local b64chars = u8a(#b64chars_s + 1)
ffi.copy(b64chars, b64chars_s)

local b64digits = u16a(4096)
for j=0,63,1 do
	for k=0,63,1 do
		b64digits[j*64+k] = bor(shl(b64chars[k], 8), b64chars[j])
	end
end

local EQ = string.byte'='

function base64.encode(s, sn, dbuf, dn)

	local sn = sn or #s
	local min_dn = math.ceil(sn / 3) * 4
	local dn = dn or min_dn
	assert(dn >= min_dn, 'buffer too small')
	local dp  = dbuf and ffi.cast(u8p, dbuf) or u8a(dn)
	local sp  = ffi.cast(u8p, s)
	local dpw = ffi.cast(u16p, dp)
	local si = 0
	local di = 0

	while sn > 2 do
		local n = sp[si]
		n = shl(n, 8)
		n = bor(n, sp[si+1])
		n = shl(n, 8)
		n = bor(n, sp[si+2])
		local c1 = shr(n, 12)
		local c2 = band(n, 0x00000fff)
		dpw[di  ] = b64digits[c1]
		dpw[di+1] = b64digits[c2]
		sn = sn - 3
		di = di + 2
		si = si + 3
	end

	di = di * 2

	if sn > 0 then
		local c1 = shr(band(sp[si], 0xfc), 2)
		local c2 = shl(band(sp[si], 0x03), 4)
		if sn > 1 then
			si = si + 1
			c2 = bor(c2, shr(band(sp[si], 0xf0), 4))
		end
		dp[di  ] = b64chars[c1]
		dp[di+1] = b64chars[c2]
		di = di + 2
		if sn == 2 then
			local c3 = shl(band(sp[si], 0xf), 2)
			si = si + 1
			c3 = bor(c3, shr(band(sp[si], 0xc0), 6))
			dp[di] = b64chars[c3]
			di = di + 1
		end
		if sn == 1 then
			dp[di] = EQ
			di = di + 1
		end
		dp[di] = EQ
	end

	if dbuf then
		return dp, min_dn
	else
		return ffi.string(dp, dn)
	end
end

--TODO: rewrite with ffi.
function base64.decode(s, sn, dbuf, dn)
	s = s:gsub('[^'..b64chars_s..'=]', '')
	return (s:gsub('.', function(x)
		if x == '=' then return '' end
		local r, f = '', b64chars_s:find(x, 1, true)-1
		for i=6,1,-1 do
			r = r .. (f%2^i - f%2^(i-1) > 0 and '1' or '0')
		end
		return r
	end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
		if #x ~= 8 then return '' end
		local c = 0
		for i = 1,8 do
			c = c + (x:sub(i, i) == '1' and 2^(8-i) or 0)
		end
		return string.char(c)
	end))
end

function base64.urlencode(s)
	return base64.encode(s):gsub('/', '_'):gsub('+', '-'):gsub('=*$', '')
end

function base64.urldecode(s)
	return base64.decode(s):gsub('_', '/'):gsub('-', '+'):gsub('=*$', '')
end

return base64
