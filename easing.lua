
--Robert Penner's equations for easing by Emmanuel Oga (BSD license).
--Modified by Cosmin Apreutesei. Public Domain.

if not ... then require'easing_demo'; return end

local easing = {}

function easing.linear(t, b, c, d)
	return c * t / d + b
end

function easing.in_quad(t, b, c, d)
	t = t / d
	return c * t^2 + b
end

function easing.out_quad(t, b, c, d)
	t = t / d
	return -c * t * (t - 2) + b
end

function easing.in_out_quad(t, b, c, d)
	t = t / d * 2
	if t < 1 then
		return c / 2 * t^2 + b
	else
		return -c / 2 * ((t - 1) * (t - 3) - 1) + b
	end
end

function easing.out_in_quad(t, b, c, d)
	if t < d / 2 then
		return easing.out_quad(t * 2, b, c / 2, d)
	else
		return easing.in_quad((t * 2) - d, b + c / 2, c / 2, d)
	end
end

function easing.in_cubic(t, b, c, d)
	t = t / d
	return c * t^3 + b
end

function easing.out_cubic(t, b, c, d)
	t = t / d - 1
	return c * (t^3 + 1) + b
end

function easing.in_out_cubic(t, b, c, d)
	t = t / d * 2
	if t < 1 then
		return c / 2 * t * t * t + b
	else
		t = t - 2
		return c / 2 * (t * t * t + 2) + b
	end
end

function easing.out_in_cubic(t, b, c, d)
	if t < d / 2 then
		return easing.out_cubic(t * 2, b, c / 2, d)
	else
		return easing.in_cubic((t * 2) - d, b + c / 2, c / 2, d)
	end
end

function easing.in_quart(t, b, c, d)
	t = t / d
	return c * t^4 + b
end

function easing.out_quart(t, b, c, d)
	t = t / d - 1
	return -c * (t^4 - 1) + b
end

function easing.in_out_quart(t, b, c, d)
	t = t / d * 2
	if t < 1 then
		return c / 2 * t^4 + b
	else
		t = t - 2
		return -c / 2 * (t^4 - 2) + b
	end
end

function easing.out_in_quart(t, b, c, d)
	if t < d / 2 then
		return easing.out_quart(t * 2, b, c / 2, d)
	else
		return easing.in_quart((t * 2) - d, b + c / 2, c / 2, d)
	end
end

function easing.in_quint(t, b, c, d)
	t = t / d
	return c * t^5 + b
end

function easing.out_quint(t, b, c, d)
	t = t / d - 1
	return c * (t^5 + 1) + b
end

function easing.in_out_quint(t, b, c, d)
	t = t / d * 2
	if t < 1 then
		return c / 2 * t^5 + b
	else
		t = t - 2
		return c / 2 * (t^5 + 2) + b
	end
end

function easing.out_in_quint(t, b, c, d)
	if t < d / 2 then
		return easing.out_quint(t * 2, b, c / 2, d)
	else
		return easing.in_quint((t * 2) - d, b + c / 2, c / 2, d)
	end
end

function easing.in_sine(t, b, c, d)
	return -c * math.cos(t / d * (math.pi / 2)) + c + b
end

function easing.out_sine(t, b, c, d)
	return c * math.sin(t / d * (math.pi / 2)) + b
end

function easing.in_out_sine(t, b, c, d)
	return -c / 2 * (math.cos(math.pi * t / d) - 1) + b
end

function easing.out_in_sine(t, b, c, d)
	if t < d / 2 then
		return easing.out_sine(t * 2, b, c / 2, d)
	else
		return easing.in_sine((t * 2) -d, b + c / 2, c / 2, d)
	end
end

function easing.in_expo(t, b, c, d)
	if t == 0 then
		return b
	else
		return c * 2^(10 * (t / d - 1)) + b - c * 0.001
	end
end

function easing.out_expo(t, b, c, d)
	if t == d then
		return b + c
	else
		return c * 1.001 * (-2^(-10 * t / d) + 1) + b
	end
end

function easing.in_out_expo(t, b, c, d)
	if t == 0 then return b end
	if t == d then return b + c end
	t = t / d * 2
	if t < 1 then
		return c / 2 * 2^(10 * (t - 1)) + b - c * 0.0005
	else
		t = t - 1
		return c / 2 * 1.0005 * (-2^(-10 * t) + 2) + b
	end
end

function easing.out_in_expo(t, b, c, d)
	if t < d / 2 then
		return easing.out_expo(t * 2, b, c / 2, d)
	else
		return easing.in_expo((t * 2) - d, b + c / 2, c / 2, d)
	end
end

function easing.in_circ(t, b, c, d)
	t = t / d
	return(-c * (math.sqrt(1 - t^2) - 1) + b)
end

function easing.out_circ(t, b, c, d)
	t = t / d - 1
	return(c * math.sqrt(1 - t^2) + b)
end

function easing.in_out_circ(t, b, c, d)
	t = t / d * 2
	if t < 1 then
		return -c / 2 * (math.sqrt(1 - t * t) - 1) + b
	else
		t = t - 2
		return c / 2 * (math.sqrt(1 - t * t) + 1) + b
	end
end

function easing.out_in_circ(t, b, c, d)
	if t < d / 2 then
		return easing.out_circ(t * 2, b, c / 2, d)
	else
		return easing.in_circ((t * 2) - d, b + c / 2, c / 2, d)
	end
end

function easing.in_elastic(t, b, c, d, a, p)
	if t == 0 then return b end

	t = t / d

	if t == 1  then return b + c end

	if not p then p = d * 0.3 end

	local s

	if not a or a < math.abs(c) then
		a = c
		s = p / 4
	else
		s = p / (2 * math.pi) * math.asin(c/a)
	end

	t = t - 1

	return -(a * 2^(10 * t) * math.sin((t * d - s) * (2 * math.pi) / p)) + b
end

-- a: amplitud
-- p: period
function easing.out_elastic(t, b, c, d, a, p)
	if t == 0 then return b end

	t = t / d

	if t == 1 then return b + c end

	if not p then p = d * 0.3 end

	local s

	if not a or a < math.abs(c) then
		a = c
		s = p / 4
	else
		s = p / (2 * math.pi) * math.asin(c/a)
	end

	return a * 2^(-10 * t) * math.sin((t * d - s) * (2 * math.pi) / p) + c + b
end

-- p = period
-- a = amplitud
function easing.in_out_elastic(t, b, c, d, a, p)
	if t == 0 then return b end

	t = t / d * 2

	if t == 2 then return b + c end

	if not p then p = d * (0.3 * 1.5) end
	if not a then a = 0 end

	local s
	if not a or a < math.abs(c) then
		a = c
		s = p / 4
	else
		s = p / (2 * math.pi) * math.asin(c / a)
	end

	if t < 1 then
		t = t - 1
		return -0.5 * (a * 2^(10 * t) * math.sin((t * d - s) * (2 * math.pi) / p)) + b
	else
		t = t - 1
		return a * 2^(-10 * t) * math.sin((t * d - s) * (2 * math.pi) / p ) * 0.5 + c + b
	end
end

-- a: amplitud
-- p: period
function easing.out_in_elastic(t, b, c, d, a, p)
	if t < d / 2 then
		return easing.out_elastic(t * 2, b, c / 2, d, a, p)
	else
		return easing.in_elastic((t * 2) - d, b + c / 2, c / 2, d, a, p)
	end
end

function easing.in_back(t, b, c, d, s)
	if not s then s = 1.70158 end
	t = t / d
	return c * t * t * ((s + 1) * t - s) + b
end

function easing.out_back(t, b, c, d, s)
	if not s then s = 1.70158 end
	t = t / d - 1
	return c * (t * t * ((s + 1) * t + s) + 1) + b
end

function easing.in_out_back(t, b, c, d, s)
	if not s then s = 1.70158 end
	s = s * 1.525
	t = t / d * 2
	if t < 1 then
		return c / 2 * (t * t * ((s + 1) * t - s)) + b
	else
		t = t - 2
		return c / 2 * (t * t * ((s + 1) * t + s) + 2) + b
	end
end

function easing.out_in_back(t, b, c, d, s)
	if t < d / 2 then
		return easing.out_back(t * 2, b, c / 2, d, s)
	else
		return easing.in_back((t * 2) - d, b + c / 2, c / 2, d, s)
	end
end

function easing.out_bounce(t, b, c, d)
	t = t / d
	if t < 1 / 2.75 then
		return c * (7.5625 * t * t) + b
	elseif t < 2 / 2.75 then
		t = t - (1.5 / 2.75)
		return c * (7.5625 * t * t + 0.75) + b
	elseif t < 2.5 / 2.75 then
		t = t - (2.25 / 2.75)
		return c * (7.5625 * t * t + 0.9375) + b
	else
		t = t - (2.625 / 2.75)
		return c * (7.5625 * t * t + 0.984375) + b
	end
end

function easing.in_bounce(t, b, c, d)
	return c - easing.out_bounce(d - t, 0, c, d) + b
end

function easing.in_out_bounce(t, b, c, d)
	if t < d / 2 then
		return easing.in_bounce(t * 2, 0, c, d) * 0.5 + b
	else
		return easing.out_bounce(t * 2 - d, 0, c, d) * 0.5 + c * .5 + b
	end
end

function easing.out_in_bounce(t, b, c, d)
	if t < d / 2 then
		return easing.out_bounce(t * 2, b, c / 2, d)
	else
		return easing.in_bounce((t * 2) - d, b + c / 2, c / 2, d)
	end
end

return easing
