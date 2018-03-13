
--Robert Penner's equations for easing
--Written by Cosmin Apreutesei. Public Domain.

if not ... then require'easing_demo'; return end

local easing = {}

function easing.reverse(f, t, ...)
	return 1 - f(1 - t, ...)
end

function easing.inout(f, t, ...)
	if t < .5 then
		return .5 * f(t * 2, ...)
	else
		t = 1 - t
		return .5 * (1 - f(t * 2, ...)) + .5
	end
end

function easing.outin(f, t, ...)
	if t < .5 then
		return .5 * (1 - f(1 - t * 2, ...))
	else
		t = 1 - t
		return .5 * (1 - (1 - f(1 - t * 2, ...))) + .5
	end
end

--ease any interpolation function
function easing.ease(f, way, t, ...)
	f = easing[f] or f
	if way == 'out' then
		return easing.reverse(f, t, ...)
	elseif way == 'inout' then
		return easing.inout(f, t, ...)
	elseif way == 'outin' then
		return easing.outin(f, t, ...)
	else
		return f(t, ...)
	end
end

--auto-updating names table sorted in insert order (for listing)

easing.names = {}
function easing:__newindex(name, func)
	table.insert(self.names, name)
	rawset(self, name, func)
end
setmetatable(easing, easing)

--actual easing functions

function easing.linear(t) return t end
function easing.quad  (t) return t^2 end
function easing.cubic (t) return t^3 end
function easing.quart (t) return t^4 end
function easing.quint (t) return t^5 end
function easing.expo  (t) return 2^(10 * (t - 1)) end
function easing.sine  (t) return -math.cos(t * (math.pi * .5)) + 1 end
function easing.circ  (t) return -(math.sqrt(1 - t^2) - 1) end
function easing.back  (t) return t^2 * (2.7 * t - 1.7) end

function easing.steps (t, steps)
	steps = steps or 10
	return math.floor(t * steps) / (steps - 1)
end

-- a: amplitude, p: period
function easing.elastic(t, a, p)
	if t == 0 then return 0 end
	if t == 1 then return 1 end
	p = p or 0.3
	local s
	if not a or a < 1 then
		a = 1
		s = p / 4
	else
		s = p / (2 * math.pi) * math.asin(1 / a)
	end
	t = t - 1
	return -(a * 2^(10 * t) * math.sin((t - s) * (2 * math.pi) / p))
end

function easing.bounce(t)
	if t < 1 / 2.75 then
		return 7.5625 * t^2
	elseif t < 2 / 2.75 then
		t = t - 1.5 / 2.75
		return 7.5625 * t^2 + 0.75
	elseif t < 2.5 / 2.75 then
		t = t - 2.25 / 2.75
		return 7.5625 * t^2 + 0.9375
	else
		t = t - 2.625 / 2.75
		return 7.5625 * t^2 + 0.984375
	end
end

function easing.slowmo(t, power, ratio, yoyo)
	power = power or .8
	ratio = math.min(ratio or .7, 1)
	local p = ratio ~= 1 and power or 0
	local p1 = (1 - ratio) / 2
	local p2 = ratio
	local p3 = p1 + p2
	local r = t + (.5 - t) * p
	if t < p1 then
		local pt = 1 - (t / p1)
		return yoyo and 1 - pt^2 or r - pt^4 * r
	elseif t > p3 then
		local pt = (t - p3) / p1
		return yoyo and (t == 1 and 0 or 1 - pt^2) or r + ((t - r) * pt^4)
	else
		return yoyo and 1 or r
	end
end

return easing
