
--UNIX permissions string parser and formatter.
--Written by Cosmin Apreutesei. Public Domain.

local bit = require'bit'

local function oct(s)
	return tonumber(s, 8)
end

local function octs(n)
	return string.format('%05o', n)
end

local bitmasks = {
	ox = 2^0,
	ow = 2^1,
   ['or'] = 2^2,
	gx = 2^3,
	gw = 2^4,
	gr = 2^5,
	ux = 2^6,
	uw = 2^7,
	ur = 2^8,
	ot = 2^9 + 2^0,
	oT = 2^9,
	gs = 2^10 + 2^3,
	gS = 2^10,
	us = 2^11 + 2^6,
	uS = 2^11,
}

local masks = {o = oct'01007', g = oct'02070', u = oct'04700'}
local function bits(who, what)
	local bits, mask = 0, 0
	for c1 in who:gmatch'.' do
		for c2 in what:gmatch'.' do
			bits = bit.bor(bits, bitmasks[c1..c2] or 0)
		end
		mask = bit.bor(mask, masks[c1])
	end
	return bits, mask
end

--set one or more bits of a value without affecting other bits.
local function setbits(bits, mask, over)
	return bit.bor(bits, bit.band(over, bit.bnot(mask)))
end

local all = oct'07777'
local function string_parser(s)
	if s:find'^0[0-7]+$' then --octal, don't compose
		local n = oct(s)
		return function(base)
			return n, false
		end
	end
	assert(not s:find'[^-+=ugorwxstST0, ]', 'invalid permissions string')
	local t, push = {}, table.insert
	s:gsub('([ugo]*)([-+=]?)([rwxstST0]+)', function(who, how, what)
		if who == '' then
			if what:find'[rwx0]'
				or (what:find'[sS]' and what:find'[tT]')
			then
				who = 'ugo'
			elseif what:find'[sS]' then
				who = 'ug'
			elseif what:find'[tT]' then
				who = 'o'
			else
				assert(false)
			end
		end
		local bits1, mask1 = bits(who, what)
		if how == '' or how == '=' then
			push(t, function(mode, mask)
				mode = setbits(bits1, mask1, mode)
				mask = bit.bor(mask1, mask)
				return mode, mask
			end)
		elseif how == '-' then
			push(t, function(mode, mask)
				return bit.band(bit.bnot(bits1), mode), mask
			end)
		elseif how == '+' then
			push(t, function(mode, mask)
				return bit.bor(bits1, mode), mask
			end)
		end
	end)
	return function(base)
		local mode, mask = base, 0
		for i=1,#t do
			local f = t[i]
			mode, mask = f(mode, mask)
		end
		return mode, mask ~= all
	end
end

local cache = {} -- {s -> parse(base)}

local function parse_string(s, base)
	local parse = cache[s]
	if not parse then
		parse = string_parser(s)
		cache[s] = parse
	end
	return parse(base)
end

local function parse(s, base)
	base = oct(base or 0)
	if type(s) == 'string' then
		return parse_string(s, base)
	else --number, pass-through
		return s, false
	end
end

local function s(b, suid, Suid)
	local x = bit.band(b, 1) ~= 0
		and (suid or 'x')
		or (Suid or '-')
	local w = bit.band(b, 2) ~= 0 and 'w' or '-'
	local r = bit.band(b, 4) ~= 0 and 'r' or '-'
	return string.format('%s%s%s', r, w, x)
end
local function long(mode)
	local o = bit.band(bit.rshift(mode, 0), 7)
	local g = bit.band(bit.rshift(mode, 3), 7)
	local u = bit.band(bit.rshift(mode, 6), 7)
	local st = bit.band(bit.rshift(mode, 9), 1) ~= 0
	local sg = bit.band(bit.rshift(mode, 10), 1) ~= 0
	local su = bit.band(bit.rshift(mode, 11), 1) ~= 0
	return string.format('%s%s%s',
		s(u, su and 's', su and 'S'),
		s(g, sg and 's', sg and 'S'),
		s(o, st and 't', st and 'T'))
end

local function format(mode, style)
	return
		(not style or style:find'^o') and octs(mode)
		or style:find'^l' and long(mode)
end

--unit test

if not ... then

	local function test(s, octal, base, rel2)
		local m1, rel1 = parse(s, base)
		local m2 = oct(octal)
		print(
			string.format('%-10s', s),
			format(m1, 'l') .. ' ' .. format(m1), rel1,
			format(m2, 'l') .. ' ' .. format(m2), rel2)
		assert(m1 == m2)
		assert(rel1 == rel2)
	end

	test('0666',  '0666', '0777', false)
	test('0644',  '0644', '0777', false)

	test('ux',    '0105', '0005', true)
	test('uw',    '0205', '0005', true)
	test('ur',    '0405', '0005', true)
	test('urw',   '0605', '0005', true)
	test('urwx',  '0705', '0005', true)

	test('gx',    '0313', '0303', true)
	test('gw',    '0323', '0303', true)
	test('gr',    '0343', '0303', true)
	test('grw',   '0363', '0303', true)
	test('grwx',  '0373', '0303', true)

	test('ox',    '0661', '0660', true)
	test('ow',    '0662', '0660', true)
	test('or',    '0664', '0660', true)
	test('orw',   '0666', '0660', true)
	test('orwx',  '0667', '0660', true)

	test('x',     '0111', '0000', false)
	test('w',     '0222', '0111', false)
	test('r',     '0444', '0222', false)
	test('rw',    '0666', '0333', false)
	test('rwx',   '0777', '0444', false)

	test('u-x',   '0675', '0775', true)
	test('u-w',   '0575', '0775', true)
	test('u-r',   '0375', '0775', true)
	test('u-rw',  '0175', '0775', true)
	test('u-rwx', '0075', '0775', true)

	test('g-x',   '0261', '0271', true)
	test('g-w',   '0251', '0271', true)
	test('g-r',   '0231', '0271', true)
	test('g-rw',  '0211', '0271', true)
	test('g-rwx', '0201', '0271', true)

	test('o-x',   '0126', '0127', true)
	test('o-w',   '0125', '0127', true)
	test('o-r',   '0123', '0127', true)
	test('o-rw',  '0121', '0127', true)
	test('o-rwx', '0120', '0127', true)

	test('ugo+x',   '0333', '0222', true)
	test('ugo+w',   '0333', '0111', true)
	test('ugo+r',   '0555', '0111', true)
	test('ugo+rw',  '0777', '0111', true)
	test('ugo+rwx', '0777', '0000', true)
	test('ugo+rwx', '0777', '0777', true)

	test('u+x g-w o=rwx', '0157', '0070', true)

	test('01000',  '01000', '00000', false)
	test('02000',  '02000', '00000', false)
	test('03000',  '03000', '00000', false)
	test('04000',  '04000', '00000', false)
	test('05000',  '05000', '00000', false)
	test('06000',  '06000', '00000', false)
	test('07000',  '07000', '00000', false)

	test('t',      '01001', '00000', true)
	test('T',      '01000', '00000', true)
	test('xT',     '01111', '00000', false)
	test('o=xT',   '01001', '00000', true)
	test('o=xt',   '01001', '00000', true)
	test('u=s',    '04100', '00000', true)
	test('g=s',    '02010', '00000', true)
	test('u=S',    '04000', '00000', true)
	test('g=S',    '02000', '00000', true)
	test('ug=S',   '06000', '00000', true)
	test('o+x,+t', '01001', '00000', true)

	test('01100',  '01100', '00000', false)
	test('02010',  '02010', '00000', false)
	test('03110',  '03110', '00000', false)

	print(format(oct'04100', 'l'))
	print(format(oct'04000', 'l'))
	print(format(oct'02010', 'l'))
	print(format(oct'02000', 'l'))
	print(format(oct'01001', 'l'))
	print(format(oct'01000', 'l'))
	print(format(oct'07111', 'l'))
	print(format(oct'07000', 'l'))

end

return {
	parse = parse,
	format = format,
}
