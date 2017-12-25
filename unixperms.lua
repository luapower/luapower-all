
--UNIX permissions string parser and formatter.
--Written by Cosmin Apreutesei. Public Domain.

local bit = require'bit'

local function oct(s)
	return tonumber(s, 8)
end

local function octs(n)
	return string.format('%04o', n)
end

local t = {x = 1, w = 2, r = 4}
local function access(what)
	local bits = 0
	for c in what:gmatch'.' do
		bits = bits + t[c]
	end
	return bits
end

local t = {o = 8^2, g = 8^1, u = 8^0}
local function bits(who, what)
	local access = access(what)
	local bits, mask = 0, 0
	for c in who:gmatch'.' do
		bits = bits + t[c] * access
		mask = mask + t[c] * 7
	end
	return bits, mask
end

--set one or more bits of a value without affecting other bits.
local function setbits(bits, mask, over)
	return bit.bor(bits, bit.band(over, bit.bnot(mask)))
end

local all = oct'777'
local function parse(s, base)
	base = oct(base or 0)
	local mode, mask
	if type(s) == 'string' then
		if s:find'^0[0-7]+$' then --octal, don't compose
			mode, mask = oct(s), all
		else
			assert(not s:find'[^-+=ugorwx ]', 'invalid permissions string')
			mode, mask = base, 0
			s:gsub('([ugo]*)([-+=]?)([rwx]+)', function(who, how, what)
				if who == '' then who = 'ugo' end
				local bits1, mask1 = bits(who, what)
				if how == '' or how == '=' then
					mode = setbits(bits1, mask1, mode)
					mask = bit.bor(mask1, mask)
				elseif how == '-' then
					mode = bit.band(bit.bnot(bits1), mode)
				elseif how == '+' then
					mode = bit.bor(bits1, mode)
				end
			end)
		end
	else --numeric, pass through
		mode, mask = s, all
	end
	return mode, mask ~= all
end

local function s(b)
	local x = bit.band(b, 1) ~= 0 and 'x' or '-'
	local w = bit.band(b, 2) ~= 0 and 'w' or '-'
	local r = bit.band(b, 4) ~= 0 and 'r' or '-'
	return string.format('%s%s%s', r, w, x)
end
local function long(mode)
	local u = bit.band(bit.rshift(mode, 0), 7)
	local g = bit.band(bit.rshift(mode, 3), 7)
	local o = bit.band(bit.rshift(mode, 6), 7)
	return string.format('%s%s%s', s(u), s(g), s(o))
end

local function format(mode, style)
	return
		(not style or style:find'^o') and octs(mode)
		or style:find'^l' and long(mode)
end

if not ... then

	local function test(s, octal, base, rel2)
		local m1, rel1 = parse(s, base)
		local m2 = oct(octal)
		print(
			format(m1, 'l') .. ' ' .. format(m1), rel1,
			format(m2, 'l') .. ' ' .. format(m2), rel2)
		assert(m1 == m2)
		assert(rel1 == rel2)
	end

	test('0666',  '0666', '0777', false)

	test('ux',    '0501', '0500', true)
	test('uw',    '0502', '0500', true)
	test('ur',    '0504', '0500', true)
	test('urw',   '0506', '0500', true)
	test('urwx',  '0507', '0500', true)

	test('gx',    '0313', '0303', true)
	test('gw',    '0323', '0303', true)
	test('gr',    '0343', '0303', true)
	test('grw',   '0363', '0303', true)
	test('grwx',  '0373', '0303', true)

	test('ox',    '0166', '0066', true)
	test('ow',    '0266', '0066', true)
	test('or',    '0466', '0066', true)
	test('orw',   '0666', '0066', true)
	test('orwx',  '0766', '0066', true)

	test('x',     '0111', '0000', false)
	test('w',     '0222', '0111', false)
	test('r',     '0444', '0222', false)
	test('rw',    '0666', '0333', false)
	test('rwx',   '0777', '0444', false)

	test('u-x',   '0756', '0757', true)
	test('u-w',   '0755', '0757', true)
	test('u-r',   '0753', '0757', true)
	test('u-rw',  '0751', '0757', true)
	test('u-rwx', '0750', '0757', true)

	test('g-x',   '0261', '0271', true)
	test('g-w',   '0251', '0271', true)
	test('g-r',   '0231', '0271', true)
	test('g-rw',  '0211', '0271', true)
	test('g-rwx', '0201', '0271', true)

	test('o-x',   '0612', '0712', true)
	test('o-w',   '0512', '0712', true)
	test('o-r',   '0312', '0712', true)
	test('o-rw',  '0112', '0712', true)
	test('o-rwx', '0012', '0712', true)

	test('ugo+x',   '0333', '0222', true)
	test('ugo+w',   '0333', '0111', true)
	test('ugo+r',   '0555', '0111', true)
	test('ugo+rw',  '0777', '0111', true)
	test('ugo+rwx', '0777', '0000', true)
	test('ugo+rwx', '0777', '0777', true)

	test('u+x g-w o=rwx', '0751', '0070', true)
end

return {
	parse = parse,
	format = format,
}
