local eq = require'eq'
local pp = require'pp'

local function assert_approx(a,b)
	print(string.format("approximation error:\t%g",math.abs(a-b)))
	assert(math.abs(a-b) <= 1e-14, a..' ~= '..b)
end

local function assert_sol(a, b, c, s1, s2)
	local t = {eq.solve2(a, b, c)}
	local s = {s1, s2}
	assert(#t == #s, pp.format(t))
	table.sort(t)
	table.sort(s)
	for i=1,#t do
		assert_approx(t[i],s[i])
	end
end
assert_sol(0, 0, 1       )   --degree 1, c ~= 0
assert_sol(0, 1, -2,    2)   --degree 1, -c/b
assert_sol(1, -1, 2      )   --D < 0
assert_sol(1, 2, 1,    -1)   --D > 0
assert_sol(2, 2, 0, -1, 0)   --D == 0


local function assert_sol(a, b, c, d, s1, s2, s3)
	local t = {eq.solve3(a, b, c, d)}
	local s = {s1, s2, s3}
	assert(#t == #s, pp.format(t))
	table.sort(t)
	table.sort(s)
	for i=1,#t do
		assert_approx(t[i],s[i])
	end
end
assert_sol(1, -4, -9, 36,    4, -3, 3) --D < 0
assert_sol(1, -6, 11, -6,    1, 2, 3) --D < 0
assert_sol(1, -3,  3, -1,    1) --D == 0, u == 0
assert_sol(1,  1,  1, -3,    1) --D > 0
assert_sol(1, -5,  8, -4,    1, 2) --D == 0, u ~= 0
assert_sol(1, -5,  8, -4,    1, 2) --D == 0, u ~= 0
assert_sol(1,  0, -7, -6,    3, -2, -1) --D < 0
assert_sol(1, -6, -6, -7,    7) -- D > 0
assert_sol(1,  7,  17, 15,  -3)
assert_sol(0,  1, -7, 12,    3, 4) --2nd degree
assert_sol(2, -4, -22, 24,   4, -3, 1)
assert_sol(2, -4, -22, 24,   4, -3, 1)
assert_sol(4, -3, -25, -6,   3, -1/4, -2)
