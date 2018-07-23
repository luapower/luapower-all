local utf8 = require'utf8'
local time = require'time'
local ffi = require'ffi'

--add some invalid chars
local s = ''
s = s .. '\xC2\xC0'
s = s .. '\xE0\x80'
s = s .. '\xED\xA0'
s = s .. '\xF0\x80'
s = s .. '\xF4\x90'
s = s .. '\xFF\xFF'
local invalid = s

local valid = [[


هذه هي بعض النصوص العربي
Hello there!
ᚠᛇᚻ᛫ᛒᛦᚦ᛫ᚠᚱᚩᚠᚢᚱ᛫ᚠᛁᚱᚪ᛫ᚷᛖᚻᚹᛦᛚᚳᚢᛗ
Sîne klâwen durh die wolken sint geslagen,
Τη γλώσσα μου έδωσαν ελληνική
На берегу пустынных волн
ვეპხის ტყაოსანი შოთა რუსთაველი
யாமறிந்த மொழிகளிலே தமிழ்மொழி போல் இனிதாவது எங்கும் காணோம்,
我能吞下玻璃而不伤身体
나는 유리를 먹을 수 있어요. 그래도 아프지 않아요

]]

local n, p = utf8.decode(valid, nil, false)
assert(n == 300)
assert(p == 0)

local n1, p = utf8.decode(invalid, nil, false)
assert(n1 == 0)
assert(p == #invalid)

local s = valid .. invalid
local n1, p1 = utf8.decode(s, nil, false)
assert(n1 == n)
assert(p1 == p)
local n2, p2 = utf8.decode(s, nil, false, nil, 0)
assert(n2 == n1 + p1)
assert(p2 == p1)

local rep = math.floor(5 * 1024^2 / #s)
s = s:rep(rep)
local outbuf, n, p = utf8.decode(s)
assert(n == rep * n1)
assert(p == rep * p1)

local t0 = time.clock()
local bytes = 0
for i = 1, 10 do
	local outbuf, len = utf8.decode(s, #s, outbuf, n)
	assert(len == n)
	bytes = bytes + #s
end
print(string.format('decode: %.2f Mbytes -> %.2f Mchars, %d MB/s',
	#s / 1024^2, n / 1024^2, bytes / (time.clock() - t0) / 1024^2))

local slen = utf8.encode(outbuf, n, false)
assert(slen == #valid * rep)
local sbuf = ffi.new('uint8_t[?]', slen)
local t0 = time.clock()
local bytes = 0
for i = 1, 10 do
	local outbuf, len = utf8.encode(outbuf, n, sbuf, slen)
	assert(len == #valid * rep)
	bytes = bytes + len
end
print(string.format('encode: %.2f Mchars -> %.2f Mbytes, %d MB/s',
	n / 1024^2, slen / 1024^2, bytes / (time.clock() - t0) / 1024^2))


local t0 = time.clock()
local bytes = 0
for i = 1, 1 do
	local len = 0
	local i = slen
	while true do
		i = utf8.prev(sbuf, slen, i)
		if not i then break end
		len = len + 1
	end
	assert(len == n)
	bytes = bytes + slen
end
print(string.format('prev:   %.2f Mbytes -> %.2f Mchars, %d MB/s',
	#s / 1024^2, n / 1024^2, bytes / (time.clock() - t0) / 1024^2))


--test the string API
local ts = '我能吞下玻璃而不伤身体'
local t = {}
for _,c,b in utf8.chars(ts) do
	t[#t+1] = c or b
end
assert(utf8.encode_chars(unpack(t)) == ts)
assert(utf8.encode_chars(t) == ts)

--compare speed to fribidi's implementation.
--the Lua variant is 5x slower but still pretty fast at 200M/s.

local fb = require'fribidi'

local outbuf, len = fb.charset_to_unicode('utf-8', s, #s)
assert(len == n + p / 4 + 3)
local t0 = time.clock()
local bytes = 0
for i = 1, 20 do
	local _, len = fb.charset_to_unicode('utf-8', s, #s, outbuf, len)
	assert(len == n + p / 4 + 3)
	bytes = bytes + #s
end
print(string.format('fb-dec: %.2f Mbytes -> %.2f Mchars, %d MB/s',
	#s / 1024^2, n / 1024^2, bytes / (time.clock() - t0) / 1024^2))

