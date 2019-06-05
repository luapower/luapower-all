
--color parsing, formatting and computation.
--Written by Cosmin Apreutesei. Public Domain.
--HSL-RGB conversions from Sputnik by Yuri Takhteyev (MIT/X License).

local function clamp01(x)
	return math.min(math.max(x, 0), 1)
end

local function round(x)
	return math.floor(x + 0.5)
end

--clamping -------------------------------------------------------------------

local clamps = {} --{space -> func(x, y, z, a)}

local function clamp_hsx(h, s, x, a)
	return h % 360, clamp01(s), clamp01(x)
end
clamps.hsl = clamp_hsx
clamps.hsv = clamp_hsx

function clamps.rgb(r, g, b)
	return clamp01(r), clamp01(g), clamp01(b)
end

local function clamp(space, x, y, z, a)
	x, y, z = clamps[space](x, y, z)
	if a then return x, y, z, clamp01(a) end
	return x, y, z
end

--conversion -----------------------------------------------------------------

--HSL <-> RGB

--hsl is in (0..360, 0..1, 0..1); rgb is (0..1, 0..1, 0..1)
local function h2rgb(m1, m2, h)
	if h<0 then h = h+1 end
	if h>1 then h = h-1 end
	if h*6<1 then
		return m1+(m2-m1)*h*6
	elseif h*2<1 then
		return m2
	elseif h*3<2 then
		return m1+(m2-m1)*(2/3-h)*6
	else
		return m1
	end
end
local function hsl_to_rgb(h, s, L)
	h = h / 360
	local m2 = L <= .5 and L*(s+1) or L+s-L*s
	local m1 = L*2-m2
	return
		h2rgb(m1, m2, h+1/3),
		h2rgb(m1, m2, h),
		h2rgb(m1, m2, h-1/3)
end

--rgb is in (0..1, 0..1, 0..1); hsl is (0..360, 0..1, 0..1)
local function rgb_to_hsl(r, g, b)
	local min = math.min(r, g, b)
	local max = math.max(r, g, b)
	local delta = max - min

	local h, s, l = 0, 0, (min + max) / 2

	if l > 0 and l < 0.5 then s = delta / (max + min) end
	if l >= 0.5 and l < 1 then s = delta / (2 - max - min) end

	if delta > 0 then
		if max == r and max ~= g then h = h + (g-b) / delta end
		if max == g and max ~= b then h = h + 2 + (b-r) / delta end
		if max == b and max ~= r then h = h + 4 + (r-g) / delta end
		h = h / 6
	end

	if h < 0 then h = h + 1 end
	if h > 1 then h = h - 1 end

	return h * 360, s, l
end

--HSV <-> RGB

local function rgb_to_hsv(r, g, b)
	local K = 0
	if g < b then
		g, b = b, g
		K = -1
	end
	if r < g then
		r, g = g, r
		K = -2 / 6 - K
	end
	local chroma = r - math.min(g, b)
	local h = math.abs(K + (g - b) / (6 * chroma + 1e-20))
	local s = chroma / (r + 1e-20)
	local v = r
	return h * 360, s, v
end

local function hsv_to_rgb(h, s, v)
	if s == 0 then --gray
		return v, v, v
	end
	local H = h / 60
	local i = math.floor(H) --which 1/6 part of hue circle
	local f = H - i
	local p = v * (1 - s)
	local q = v * (1 - s * f)
	local t = v * (1 - s * (1 - f))
	if i == 0 then
		return v, t, p
	elseif i == 1 then
		return q, v, p
	elseif i == 2 then
		return p, v, t
	elseif i == 3 then
		return p, q, v
	elseif i == 4 then
		return t, p, v
	else
		return v, p, q
	end
end

function hsv_to_hsl(h, s, v) --TODO: direct conversion
	return rgb_to_hsl(hsv_to_rgb(h, s, v))
end

function hsl_to_hsv(h, s, l) --TODO: direct conversion
	return rgb_to_hsv(hsl_to_rgb(h, s, l))
end

local converters = {
	rgb = {hsl = rgb_to_hsl, hsv = rgb_to_hsv},
	hsl = {rgb = hsl_to_rgb, hsv = hsl_to_hsv},
	hsv = {rgb = hsv_to_rgb, hsl = hsv_to_hsl},
}
local function convert(dest_space, space, x, y, z, ...)
	if space ~= dest_space then
		x, y, z = converters[space][dest_space](x, y, z)
	end
	return x, y, z, ...
end

--parsing --------------------------------------------------------------------

local hex = {
	[2] = {'#g',        'rgb'},
	[3] = {'#gg',       'rgb'},
	[4] = {'#rgb',      'rgb'},
	[5] = {'#rgba',     'rgb'},
	[7] = {'#rrggbb',   'rgb'},
	[9] = {'#rrggbbaa', 'rgb'},
}
local s3 = {
	hsl = {'hsl', 'hsl'},
	hsv = {'hsv', 'hsv'},
	rgb = {'rgb', 'rgb'},
}
local s4 = {
	hsla = {'hsla', 'hsl'},
	hsva = {'hsva', 'hsv'},
	rgba = {'rgba', 'rgb'},
}
local function string_format(s)
	local t
	if s:sub(1, 1) == '#' then
		t = hex[#s]
	else
		t = s4[s:sub(1, 4)] or s3[s:sub(1, 3)]
	end
	if t then
		return t[1], t[2] --format, colorspace
	end
end

local parsers = {}

local function parse(s)
	local g = tonumber(s:sub(2, 2), 16)
	if not g then return end
	g = (g * 16 + g) / 255
	return g, g, g
end
parsers['#g']  = parse

local function parse(s)
	local r = tonumber(s:sub(2, 2), 16)
	local g = tonumber(s:sub(3, 3), 16)
	local b = tonumber(s:sub(4, 4), 16)
	if not (r and g and b) then return end
	r = (r * 16 + r) / 255
	g = (g * 16 + g) / 255
	b = (b * 16 + b) / 255
	if #s == 5 then
		local a = tonumber(s:sub(5, 5), 16)
		if not a then return end
		return r, g, b, (a * 16 + a) / 255
	else
		return r, g, b
	end
end
parsers['#rgb']  = parse
parsers['#rgba'] = parse

local function parse(s)
	local g = tonumber(s:sub(2, 3), 16)
	if not g then return end
	g = g / 255
	return g, g, g
end
parsers['#gg'] = parse

local function parse(s)
	local r = tonumber(s:sub(2, 3), 16)
	local g = tonumber(s:sub(4, 5), 16)
	local b = tonumber(s:sub(6, 7), 16)
	if not (r and g and b) then return end
	r = r / 255
	g = g / 255
	b = b / 255
	if #s == 9 then
		local a = tonumber(s:sub(8, 9), 16)
		if not a then return end
		return r, g, b, a / 255
	else
		return r, g, b
	end
end
parsers['#rrggbb']  = parse
parsers['#rrggbbaa'] = parse

local rgb_patt = '^rgb%s*%(([^,]+),([^,]+),([^,]+)%)$'
local rgba_patt = '^rgba%s*%(([^,]+),([^,]+),([^,]+),([^,]+)%)$'

local function np(s)
	local p = s and tonumber((s:match'^([^%%]+)%%%s*$'))
	return p and p * .01
end

local function n255(s)
	local n = tonumber(s)
	return n and n / 255
end

local function parse(s)
	local r, g, b, a = s:match(rgba_patt)
	r = np(r) or n255(r)
	g = np(g) or n255(g)
	b = np(b) or n255(b)
	a = np(a) or tonumber(a)
	if not (r and g and b and a) then return end
	return r, g, b, a
end
parsers.rgba = parse

local function parse(s)
	local r, g, b = s:match(rgb_patt)
	r = np(r) or n255(r)
	g = np(g) or n255(g)
	b = np(b) or n255(b)
	if not (r and g and b) then return end
	return r, g, b
end
parsers.rgb = parse

local hsl_patt = '^hsl%s*%(([^,]+),([^,]+),([^,]+)%)$'
local hsla_patt = '^hsla%s*%(([^,]+),([^,]+),([^,]+),([^,]+)%)$'

local hsv_patt = hsl_patt:gsub('hsl', 'hsv')
local hsva_patt = hsla_patt:gsub('hsla', 'hsva')

local function parser(patt)
	return function(s)
		local h, s, x, a = s:match(patt)
		h = tonumber(h)
		s = np(s) or tonumber(s)
		x = np(x) or tonumber(x)
		a = np(a) or tonumber(a)
		if not (h and s and x and a) then return end
		return h, s, x, a
	end
end
parsers.hsla = parser(hsla_patt)
parsers.hsva = parser(hsva_patt)

local function parser(patt)
	return function(s)
		local h, s, x = s:match(patt)
		h = tonumber(h)
		s = np(s) or tonumber(s)
		x = np(x) or tonumber(x)
		if not (h and s and x) then return end
		return h, s, x
	end
end
parsers.hsl = parser(hsl_patt)
parsers.hsv = parser(hsv_patt)

local function parse(s, dest_space)
	local fmt, space = string_format(s)
	if not fmt then return end
	local parse = parsers[fmt]
	if not parse then return end
	if dest_space then
		return convert(dest_space, space, parse(s))
	else
		return space, parse(s)
	end
end

--formatting -----------------------------------------------------------------

local format_spaces = {
	['#'] = 'rgb',
	['#rrggbbaa'] = 'rgb', ['#rrggbb'] = 'rgb',
	['#rgba'] = 'rgb', ['#rgb'] = 'rgb', rgba = 'rgb', rgb = 'rgb',
	hsla = 'hsl', hsl = 'hsl', ['hsla%'] = 'hsl', ['hsl%'] = 'hsl',
	hsva = 'hsv', hsv = 'hsv', ['hsva%'] = 'hsv', ['hsv%'] = 'hsv',
	rgba32 = 'rgb', argb32 = 'rgb',
}

local function loss(x) --...of precision when converting to #rgb
	return math.abs(x * 15 - round(x * 15))
end
local threshold = math.abs(loss(0x89 / 255))
local function short(x)
	return loss(x) < threshold
end

local function format(fmt, space, x, y, z, a)
	fmt = fmt or space --the names match
	local dest_space = format_spaces[fmt]
	if not dest_space then
		error('invalid format '..tostring(fmt))
	end
	x, y, z, a = convert(dest_space, space, x, y, z, a)
	if fmt == '#' then --shortest hex
		if short(x) and short(y) and short(z) and short(a or 1) then
			fmt = a and '#rgba' or '#rgb'
		else
			fmt = a and '#rrggbbaa' or '#rrggbb'
		end
	end
	a = a or 1
	if fmt == '#rrggbbaa' or fmt == '#rrggbb' then
		return string.format(
			fmt == '#rrggbbaa' and '#%02x%02x%02x%02x' or '#%02x%02x%02x',
				round(x * 255),
				round(y * 255),
				round(z * 255),
				round(a * 255))
	elseif fmt == '#rgba' or fmt == '#rgb' then
		return string.format(
			fmt == '#rgba' and '#%1x%1x%1x%1x' or '#%1x%1x%1x',
				round(x * 15),
				round(y * 15),
				round(z * 15),
				round(a * 15))
	elseif fmt == 'rgba' or fmt == 'rgb' then
		return string.format(
			fmt == 'rgba' and 'rgba(%d,%d,%d,%.2g)' or 'rgb(%d,%d,%g)',
				round(x * 255),
				round(y * 255),
				round(z * 255),
				a)
	elseif fmt:sub(-1) == '%' then --hsl|v(a)%
		return string.format(
			#fmt == 5 and '%s(%d,%d%%,%d%%,%.2g)' or '%s(%d,%d%%,%d%%)',
				fmt:sub(1, -2),
				round(x),
				round(y * 100),
				round(z * 100),
				a)
	elseif fmt == 'rgba32' then
		return
			  round(x * 255) * 2^24
			+ round(y * 255) * 2^16
			+ round(z * 255) * 2^8
			+ round(a * 255)
	elseif fmt == 'argb32' then
		return
			  round(a * 255) * 2^24
			+ round(x * 255) * 2^16
			+ round(y * 255) * 2^8
			+ round(z * 255)
	else --hsl|v(a)
		return string.format(
			#fmt == 4 and '%s(%d,%.2g,%.2g,%.2g)' or '%s(%d,%.2g,%.2g)',
				fmt, round(x), y, z, a)
	end
end

--color object ---------------------------------------------------------------

local color = {}

--new([space, ]x, y, z[, a])
--new([space, ]'str')
--new([space, ]{x, y, z[, a]})
local function new(space, x, y, z, a)
	if not (type(space) == 'string' and x) then --shift args
		space, x, y, z, a = 'hsl', space, x, y, z
	end
	local h, s, L
	if type(x) == 'string' then
		h, s, L, a = parse(x, 'hsl')
	else
		if type(x) == 'table' then
			x, y, z, a = x[1], x[2], x[3], x[4]
		end
		h, s, L, a = convert('hsl', space, clamp(space, x, y, z, a))
	end
	local c = {
		h = h, s = s, L = L, a = a,
		__index = color,
		__tostring = color.__tostring,
		__call = color.__call,
	}
	return setmetatable(c, c)
end

local function new_with(space)
	return function(...)
		return new(space, ...)
	end
end

function color:__call() return self.h, self.s, self.L, self.a end
function color:hsl() return self.h, self.s, self.L end
function color:hsla() return self.h, self.s, self.L, self.a or 1 end
function color:hsv() return convert('hsv', 'hsl', self:hsl()) end
function color:hsva() return convert('hsv', 'hsl', self:hsla()) end
function color:rgb() return convert('rgb', 'hsl', self:hsl()) end
function color:rgba() return convert('rgb', 'hsl', self:hsla()) end
function color:convert(space) return convert(space, 'hsl', self:hsla()) end
function color:format(fmt) return format(fmt, 'hsl', self()) end

function color:__tostring()
	return self:format'#'
end

function color:hue_offset(delta)
	return new(self.h + delta, self.s, self.L)
end

function color:complementary()
	return self:hue_offset(180)
end

function color:neighbors(angle)
	local angle = angle or 30
	return self:hue_offset(angle), self:hue_offset(360-angle)
end

function color:triadic()
	return self:neighbors(120)
end

function color:split_complementary(angle)
	return self:neighbors(180-(angle or 30))
end

function color:desaturate_to(saturation)
	return new(self.h, saturation, self.L)
end

function color:desaturate_by(r)
	return new(self.h, self.s*r, self.L)
end

function color:lighten_to(lightness)
	return new(self.h, self.s, lightness)
end

function color:lighten_by(r)
	return new(self.h, self.s, self.L*r)
end

function color:bw(whiteL)
	return new(self.h, self.s, self.L >= (whiteL or .5) and 0 or 1)
end

function color:variations(f, n)
	n = n or 5
	local results = {}
	for i=1,n do
	  table.insert(results, f(self, i, n))
	end
	return results
end

function color:tints(n)
	return self:variations(function(color, i, n)
		return color:lighten_to(color.L + (1-color.L)/n*i)
	end, n)
end

function color:shades(n)
	return self:variations(function(color, i, n)
		return color:lighten_to(color.L - (color.L)/n*i)
	end, n)
end

function color:tint(r)
	return self:lighten_to(self.L + (1-self.L)*r)
end

function color:shade(r)
	return self:lighten_to(self.L - self.L*r)
end

--module ---------------------------------------------------------------------

local color_module = {
	clamp = clamp,
	convert = convert,
	parse = parse,
	format = format,
	hsl = new_with'hsl',
	hsv = new_with'hsv',
	rgb = new_with'rgb',
}

function color_module:__call(...)
	return new(...)
end

setmetatable(color_module, color_module)

--demo -----------------------------------------------------------------------

if not ... then
	print(parse'#fff')
	print(parse'#808080')
	print(parse'#0000')
	print(parse'#80808080')
	print(parse'#80')
	print(parse'#7f')
	print(parse'#88')
	print(parse'#8')
	print()
	print(parse'rgb (128, 128, 128      )')
	print(parse'rgba(128, 128, 128, 0.42)')
	print(parse'rgba(128, 128, 128, 0.42)')
	print(parse'hsla(360,  42.3%, 42.3%, 0.423)')
	print(parse'hsla(360, .432,  .432,   0.42 )')
	print(parse'hsl (360,  42.3%, 42.3%       )')
	print(parse'hsl (360, .432,  .432         )')
	print(parse'hsla(360, .432,  .432, 0.42   )')
	print(parse'hsla(180, 1, .5, .5)')
	print(parse'rgba(128, 128, 128, .5)')
	print(parse'rgba(100%, 0%, 50%, 25%)')
	print()
	print(format(nil,       'rgb', .533, .533, .533, .533))
	print(format('#rrggbb', 'rgb', .533, .533, .533, .533))
	print(format('#rgba',   'rgb', .533, .533, .533, .533))
	print(format('#rgb',    'rgb', .5,   .5,   .5,   .5))
	print(format('rgba',    'rgb', .5,   .5,   .5,   .5))
	print(format('rgb',     'rgb', .5,   .5,   .5,   .5))
	print(format('rgb',     'rgb', .5,   .5,   .5))
	print(format(nil,       'hsl', 360, .5, .5, .5))
	print(format(nil,       'hsl', 360, .5, .5, .5))
	print(format(nil,       'hsl', 360, .5, .5))
	print(format('#',       'rgb', 0x88/255, 0xff/255, 0x22/255))
	print(format('#',       'rgb', 0x88/255, 0xff/255, 0x22/255, 0x55/255))
	print(format('#',       'rgb', 1, 1, 1, 0x89/255))
	print(color_module(180, 1, 1))
	print(color_module'#abcd')
	print(color_module('rgb', 1, 1, 1, .8))
	print(color_module('rgb', 1, 0, 0, .8))
	print(color_module('rgb', 0, 0, 0, .8))
	print(color_module('rgb', 1, 0, .3))
end

return color_module
