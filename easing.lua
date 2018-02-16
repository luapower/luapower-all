
--Robert Penner's equations for easing
--Written by Cosmin Apreutesei. Public Domain.

if not ... then require'easing_demo'; return end

local easing = {}

--turn an `in` function into an `out` function or viceversa
function easing.reverse(f)
	return function(p, a1, a2)
		return 1 - f(1 - p, a1, a2)
	end
end

--turn an `in` function into `in_out` or an `out` function into `out_in`
function easing.in_out(f)
	return function(p, a1, a2)
		p = p * 2
		if p < 1 then
			return .5 * f(p, a1, a2)
		else
			p = 2 - p
			return .5 * (1 - f(p, a1, a2)) + .5
		end
	end
end

--expression-based easing functions

easing.expr = {}
setmetatable(easing.expr, easing.expr)

function easing.expr:__newindex(name, expr)
	local load = loadstring or load
	local func = load('return function(p) return ' .. expr .. ' end')()
	easing[name] = func
end

--auto-updating names table sorted in insert order (for listing)

easing.names = {}

function easing:__newindex(name, func)
	table.insert(self.names, name)
	rawset(self, name, func)
end

setmetatable(easing, easing)

--some actual easing functions and expressions

function easing.linear(p) return p end

local e = easing.expr
e.quad    = 'p^2'
e.cubic   = 'p^3'
e.quart   = 'p^4'
e.quint   = 'p^5'
e.expo    = '2^(10 * (p - 1))'
e.sine    = '-math.cos(p * (math.pi * .5)) + 1'
e.circ    = '-(math.sqrt(1 - p^2) - 1)'
e.back    = 'p^2 * (2.7 * p - 1.7)'
e.elastic = '-(2^(10 * (p - 1)) * math.sin((p - 1.075) * (math.pi * 2) / .3))'

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

return easing
