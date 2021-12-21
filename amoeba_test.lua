local amoeba = require "amoeba"

local S = amoeba.new()
print(S)
local xl, xm, xr =
   S:var "xl", S:var "xm", S:var "xr"
print(xl)
print(xm)
print(xr)
print(S:constraint()
      :add(xl):add(10)
      :relation "le" -- or "<="
      :add(xr))
S:addconstraint((xm*2) :eq (xl + xr))
S:addconstraint(
   S:constraint()
      :add(xl):add(10)
      :relation "le" -- or "<="
      :add(xr)) -- (xl + 10) :le (xr)
S:addconstraint(
   S:constraint()(xr) "<=" (100)) -- (xr) :le (100)
S:addconstraint((xl) :ge (0))
print(S)
print(xl)
print(xm)
print(xr)

print('suggest xm to 0')
S:suggest(xm, 0)
print(S)
print(xl)
print(xm)
print(xr)

print('suggest xm to 70')
S:suggest(xm, 70)
print(S)
print(xl)
print(xm)
print(xr)

print('delete edit xm')
S:deledit(xm)
print(S)
print(xl)
print(xm)
print(xr)

--speed test
local now = require'time'.clock

local S = amoeba.new()
local vars = {}
for i=1,20 do
	vars[i] = S:var('x'..i)
end
for i=1,20 do
	local c = S:constraint():add(vars[i]):relation(i < 20 and '>=' or '<='):add(1)
	if i > 1 then
		c:add(vars[i-1])
	end
	S:addconstraint(c)
	print(c)
end

local n = 100000
print(('\nstarting benchmark (%d iterations)'):format(n))
local start = now()
S:suggest(vars[20], 0)
for i = 1, n do
  S:suggest(vars[1], i)
end
print(vars[1])
print(vars[2])
print(vars[19])
print(vars[20])
local stop = now()
--print(S)
print(('solved in %fms'):format((stop-start)*1000/n))
