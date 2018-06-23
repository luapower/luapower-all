
--colors in HSL and RGB(A)
--Written by Cosmin Apreutesei. Public Domain.
--Originated from Sputnik by Yuri Takhteyev (MIT/X License).

local function clamp(x)
	return math.min(math.max(x, 0), 1)
end

local function clamp_hsl(h, s, L)
	return h % 360, clamp(s), clamp(L)
end

local function clamp_rgb(r, g, b)
	return clamp(r), clamp(g), clamp(b)
end

local function clamp_rgba(r, g, b, a)
	return clamp(r), clamp(g), clamp(b), clamp(a)
end

local function round(x)
	return math.floor(x + 0.5)
end

--HSL <-> RGB conversion

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

--hsl is clamped to (0..360, 0..1, 0..1); rgb is (0..1, 0..1, 0..1)
local function hsl_to_rgb(h, s, L)
	h, s, L = clamp_hsl(h, s, L)
	h = h / 360
	local m1, m2
	if L<=0.5 then
		m2 = L*(s+1)
	else
		m2 = L+s-L*s
	end
	m1 = L*2-m2
	return
		h2rgb(m1, m2, h+1/3),
		h2rgb(m1, m2, h),
		h2rgb(m1, m2, h-1/3)
end

--rgb is clamped to (0..1, 0..1, 0..1); hsl is (0..360, 0..1, 0..1)
local function rgb_to_hsl(r, g, b)
	r, g, b = clamp_rgb(r, g, b)
	local min = math.min(r, g, b)
	local max = math.max(r, g, b)
	local delta = max - min

	local h, s, l = 0, 0, ((min+max)/2)

	if l > 0 and l < 0.5 then s = delta/(max+min) end
	if l >= 0.5 and l < 1 then s = delta/(2-max-min) end

	if delta > 0 then
		if max == r and max ~= g then h = h + (g-b)/delta end
		if max == g and max ~= b then h = h + 2 + (b-r)/delta end
		if max == b and max ~= r then h = h + 4 + (r-g)/delta end
		h = h / 6
	end

	if h < 0 then h = h + 1 end
	if h > 1 then h = h - 1 end

	return h * 360, s, l
end

--string parsing

local rgb = '^rgb%s*%(([^,]+),([^,]+),([^,]+)%)$'
local rgba = '^rgba%s*%(([^,]+),([^,]+),([^,]+),([^,]+)%)$'

local function rgb_string_to_rgba(s)
	local r, g, b, a
	if s:sub(1,1) == '#' then
		if #s == 4 or #s == 5 then -- '#rgb' or '#rgba'
			r = tonumber(s:sub(2, 2), 16)
			g = tonumber(s:sub(3, 3), 16)
			b = tonumber(s:sub(4, 4), 16)
			if #s == 5 then
				a = tonumber(s:sub(5, 5), 16)
			else
				a = 15
			end
			if not (r and g and b and a) then return end
			r = r * 16 + r
			g = g * 16 + g
			b = b * 16 + b
			a = a * 16 + a
		elseif #s == 7 or #s == 9 then -- '#rrggbb' or '#rrggbbaa'
			r = tonumber(s:sub(2, 3), 16)
			g = tonumber(s:sub(4, 5), 16)
			b = tonumber(s:sub(6, 7), 16)
			if #s == 9 then
				a = tonumber(s:sub(8, 9), 16)
			else
				a = 255
			end
			if not (r and g and b and a) then return end
		else
			return
		end
	else --`rgba(r, g, b, a)` or `rgb(r, g, b)`
		r, g, b, a = s:match(rgba)
		if not r then
			r, g, b = s:match(rgb)
			a = 1
		end
		r = tonumber(r)
		g = tonumber(g)
		b = tonumber(b)
		a = tonumber(a)
		if not (r and g and b and a) then return end
		a = a * 255
	end
	return r / 255, g / 255, b / 255, a / 255
end

local hsl = '^hsl%s*%(([^,]+),([^,]+),([^,]+)%)$'
local hsla = '^hsla%s*%(([^,]+),([^,]+),([^,]+),([^,]+)%)$'

local function np(s)
	local p = s and tonumber((s:match'^([^%%]+)%%%s*$'))
	return p and p * .01 or tonumber(s)
end

local function hsl_string_to_hsla(str)
	local h, s, l, a = str:match(hsla)
	if not h then
		h, s, l = str:match(hsl)
		a = 1
	end
	h = tonumber(h)
	s = np(s)
	l = np(l)
	a = tonumber(a)
	if not (h and s and l and a) then return nil end
	return h, s, l, a
end

local function string_to_rgba(str)
	local r, g, b, a = rgb_string_to_rgba(str)
	if r then return r, g, b, a end
	local h, s, l, a = hsl_string_to_hsla(str)
	if not h then return nil end
	local r, g, b = hsl_to_rgb(h, s, l)
	return r, g, b, a
end

local function string_to_hsla(str)
	local h, s, l, a = hsl_string_to_hsla(str)
	if h then return h, s, l, a end
	local r, g, b, a = rgb_string_to_rgba(str)
	if not r then return nil end
	local h, s, l = rgb_to_hsl(r, g, b)
	return h, s, l, a
end

local function string_to_hsl(str)
	local h, s, l = string_to_hsla(str)
	if not h then return nil end
	return h, s, l
end

local function string_to_rgb(str)
	local r, g, b = string_to_rgba(str)
	if not r then return nil end
	return r, g, b
end

--string formatting

local function rgba_to_rgb_string(r, g, b, a, fmt)
	if fmt == 'hexa' or fmt == 'hex' then
		return string.format(
			fmt == 'hexa' and '#%02x%02x%02x%02x' or '#%02x%02x%02x',
				round(r * 255),
				round(g * 255),
				round(b * 255),
				round(a * 255))
	elseif fmt == 'hexa1' or fmt == 'hex1' then
		return string.format(
			fmt == 'hexa1' and '#%1x%1x%1x%1x' or '#%1x%1x%1x',
				round(r * 15),
				round(g * 15),
				round(b * 15),
				round(a * 15))
	elseif fmt == 'rgba' or fmt == 'rgb' then
		return string.format(
			fmt == 'rgba' and 'rgba(%d,%d,%d,%.2g)' or 'rgb(%d,%d,%g)',
				round(r * 255),
				round(g * 255),
				round(b * 255),
				a)
	else
		error('invalid format '..tostring(fmt))
	end
end

local function hsla_to_hsl_string(h, s, l, a, fmt)
	if fmt == 'hsla%' or fmt == 'hsl%' then
		return string.format(
			fmt == 'hsla%' and 'hsla(%d,%d%%,%d%%,%.2g)' or 'hsl(%d,%d%%,%d%%)',
				round(h),
				round(s * 100),
				round(l * 100),
				a)
	elseif fmt == 'hsla' or fmt == 'hsl' then
		return string.format(
			fmt == 'hsla' and 'hsla(%d,%.2g,%.2g,%.2g)' or 'hsl(%d,%.2g,%.2g)',
				round(h), s, l, a)
	else
		error('invalid format '..tostring(fmt))
	end
end

local hsl_fmt = {hsla=1, hsl=1, ['hsla%']=1, ['hsl%']=1}

local function rgba_to_string(r, g, b, a, fmt)
	fmt = fmt or 'hexa'
	if hsl_fmt[fmt] then
		local h, s, l = rgb_to_hsl(r, g, b)
		return hsla_to_hsl_string(h, s, l, a, fmt)
	else
		return rgba_to_rgb_string(r, g, b, a, fmt)
	end
end

local function hsla_to_string(h, s, l, a, fmt)
	fmt = fmt or 'hsla%'
	if not hsl_fmt[fmt] then
		local r, g, b = hsl_to_rgb(h, s, l)
		return rgba_to_rgb_string(r, g, b, a, fmt)
	else
		return hsla_to_hsl_string(h, s, l, a, fmt)
	end
end

local function rgb_to_string(r, g, b, fmt)
	return rgba_to_string(r, g, b, 1, fmt)
end

local function hsl_to_string(h, s, l, fmt)
	return hsla_to_string(h, s, l, 1, fmt)
end

--color class

local color = {}
local color_mt = {__index = color}

--either H, S, L (0..360, 0..1, 0..1) or RGB(A) or HSL(A) string or table.
local function new(h, s, L)
	if type(h) == 'table' then
		h, s, L = clamp_hsl(h[1], h[2], h[3])
	elseif type(h) == 'string' then
		h, s, L = string_to_hsl(h)
		if not h then
			h, s, L = rgb_to_hsl(string_to_rgb(h))
		else
			h, s, L = clamp_hsl(h, s, L)
		end
	else
		h, s, L = clamp_hsl(h, s, L)
	end
	return setmetatable({h = h, s = s, L = L}, color_mt)
end

--either R, G, B (0..1, 0..1, 0..1) or RGB(A) string or HSL(A) string or table.
local function new_from_rgb(r, g, b)
	local h, s, L
	if type(r) == 'table' then
		h, s, L = rgb_to_hsl(r[1], r[2], r[3])
	elseif type(r) == 'string' then
		h, s, L = string_to_hsl(r)
		if not h then
			h, s, L = rgb_to_hsl(string_to_rgb(r))
		else
			h, s, L = clamp_hsl(h, s, L)
		end
	else
		h, s, L = rgb_to_hsl(r, g, b)
	end

	return setmetatable({h = h, s = s, L = L}, color_mt)
end

function color:hsl()
	return self.h, self.s, self.L
end

color_mt.__call = color.hsl

function color:rgb()
	return hsl_to_rgb(self())
end

function color:rgba()
	local r, g, b = hsl_to_rgb(self())
	return r, g, b, 1
end

function color:tostring()
	return rgb_to_string(self:rgb())
end

color_mt.__tostring = color.tostring

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

local color_module = {
	hsl_to_rgb = hsl_to_rgb,
	rgb_to_hsl = rgb_to_hsl,

	string_to_rgba = string_to_rgba,
	string_to_rgb  = string_to_rgb,
	rgba_to_string = rgba_to_string,
	rgb_to_string  = rgb_to_string,

	string_to_hsla = string_to_hsla,
	string_to_hsl  = string_to_hsl,

	hsla_to_string = hsla_to_string,
	hsl_to_string  = hsl_to_string,

	hsl = new,
	rgb = new_from_rgb,
}

setmetatable(color_module, {__call = function(self, ...) return new(...) end})

if not ... then
	print(string_to_rgba'#fff')
	print(string_to_rgba'#808080')
	print(string_to_rgba'#0000')
	print(string_to_rgba'#80808080')
	print(string_to_rgba'rgb (128, 128, 128      )')
	print(string_to_rgba'rgba(128, 128, 128, 0.42)')
	print(string_to_rgb 'rgba(128, 128, 128, 0.42)')
	print(string_to_hsla'hsla(360,  42.3%, 42.3%, 0.423)')
	print(string_to_hsla'hsla(360, .432,  .432,   0.42 )')
	print(string_to_hsla'hsl (360,  42.3%, 42.3%       )')
	print(string_to_hsla'hsl (360, .432,  .432         )')
	print(string_to_hsl 'hsla(360, .432,  .432, 0.42   )')
	print(rgba_to_string(.533, .533, .533, .533))
	print(rgba_to_string(.533, .533, .533, .533, 'hex'))
	print(rgba_to_string(.533, .533, .533, .533, 'hexa1'))
	print(rgba_to_string(.5,   .5,   .5,   .5,   'hex1'))
	print(rgba_to_string(.5,   .5,   .5,   .5,   'rgba'))
	print(rgba_to_string(.5,   .5,   .5,   .5,   'rgb'))
	print(rgb_to_string (.5,   .5,   .5,          'rgba'))
	print(hsla_to_string(360, .5, .5, .5))
	print(hsla_to_string(360, .5, .5, .5, 'hsla'))
	print(hsl_to_string (360, .5, .5))
	print(string_to_rgba'hsla(180, 1, .5, .5)')
	print(string_to_hsla'rgba(128, 128, 128, .5)')
end

return color_module
