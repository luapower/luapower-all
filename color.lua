
--Color conversions.
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

--HSL <-> RGB

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

--RGB(A) <-> string

local rgba_colors = setmetatable({}, {__mode = 'kv'})

local function string_to_rgba(s)
	if rgba_colors[s] then
		return unpack(rgba_colors[s])
	end
	if s:sub(1,1) ~= '#' then return end
	local r, g, b, a
	if #s == 4 or #s == 5 then -- '#rgb' or '#rgba'
		r = tonumber(s:sub(2, 2), 16)
		g = tonumber(s:sub(3, 3), 16)
		b = tonumber(s:sub(4, 4), 16)
		a = tonumber(s:sub(5, 5), 16) or 15
		if not r or not g or not b then return end
		r = r * 16 + r
		g = g * 16 + g
		b = b * 16 + b
		a = a * 16 + a
	else -- '#rrggbb' or '#rrggbbaa'
		r = tonumber(s:sub(2, 3), 16)
		g = tonumber(s:sub(4, 5), 16)
		b = tonumber(s:sub(6, 7), 16)
		a = tonumber(s:sub(8, 9), 16) or 255
		if not r or not g or not b then return end
	end
	r = r / 255
	g = g / 255
	b = b / 255
	a = a / 255
	rgba_colors[s] = {r, g, b, a} --memoize for speed
	return r, g, b, a
end

local function string_to_rgb(s)
	local r, g, b = string_to_rgba(s)
	if not r then return end
	return r, g, b
end

local function rgb_to_string(r, g, b)
	return string.format('#%02x%02x%02x',
		math.floor(r*255 + 0.5),
		math.floor(g*255 + 0.5),
		math.floor(b*255 + 0.5))
end

local function rgba_to_string(r, g, b, a)
	return rgb_to_string(r, g, b) ..
		string.format('%02x', math.floor(a*255 + 0.5))
end

--color class

local color = {}
local color_mt = {__index = color}

local function new(h, s, L) --either H, S, L (0..360, 0..1, 0..1) or RGB string '#rrggbb'
	if type(h) == 'string' then
		h, s, L = rgb_to_hsl(string_to_rgb(h))
	else
		h, s, L = clamp_hsl(h, s, L)
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

	string_to_rgb = string_to_rgb,
	rgb_to_string = rgb_to_string,

	string_to_rgba = string_to_rgba,
	rgba_to_string = rgba_to_string,
}

setmetatable(color_module, {__call = function(self, ...) return new(...) end})

return color_module
