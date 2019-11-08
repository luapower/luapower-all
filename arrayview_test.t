
setfenv(1, require'low')

--TODO: test failed asserts

local s = 'Hello World!'
local len = #s

terra test()
	var v: arrview(int8)
	v.elements = alloc(char, len)
	copy(v.elements, s, len)
	v.len = len

	assert(v.len == len)

	assert(v(0) == ('H')[0])
	assert(v(v.len-1) == ('!')[0])

	assert(v(v.len-1, 123) == ('!')[0])
	assert(v(v.len, 123) == 123)

	assert(v:at(0) == v.elements)
	assert(v:at(v.len-2) == v.elements + v.len-2)
	assert(v:at(v.len, nil) == nil)

	var n = 0
	for i,e in v do
		assert(e == v.elements+i)
		inc(n)
	end
	assert(n == v.len)

	n = 0
	for i,e in v:backwards() do
		assert(e == v.elements+i)
		inc(n)
	end
	assert(n == v.len)

	assert(v:clamp(minint) == 0)
	assert(v:clamp(maxint) == v.len-1)

	assert(v:index(-1, -123) == -123)
	assert(v:index(maxint, -123) == -123)
	assert(v:index(0, -123) == 0)

	assert(v:next(v:at(0)) == v:at(1))
	assert(v:prev(v:at(1)) == v:at(0))
	assert(v:next(v:at(v.len-1), nil) == nil)
	assert(v:prev(v:at(0), nil) == nil)

	var v2 = v:sub(0, v.len)

	v:sort()
	v:reverse()
	v:sort_desc()
	v:reverse()
	for i,e in v do pf('%c', @e) end; print()

	print(v:__hash32(0))
	print(v:__hash64(0))
	print(v:__memsize())

	assert(v == v2)

	v2.len = v2.len - 1

	assert(v ~= v2)
	assert(v > v2)
	assert(v >= v2)
	assert(not (v < v2))
	assert(not (v <= v2))

	assert(v:count(('l')[0]) == 3)

end
test()

--[[
set(i: size_t, val: T)
range(i: size_t, j: size_t)
sub:adddefinition(terra(self: &view, i: size_t, j: size_t)
sub:adddefinition(terra(self: &view, i: size_t)
copy:adddefinition(terra(self: &view, dst: &T)
copy:adddefinition(terra(self: &view, dst: &view)
__cmp(v: &view)
__memsize()
sort:adddefinition(terra(self: &view, cmp: {&T, &T} -> int32)
sort_desc() return self:sort(cmp_desc) end
find:adddefinition(terra(self: &view, val: T, default: size_t)
find:adddefinition(terra(self: &view, val: T)
binsearch:adddefinition(terra(self: &view, v: T, cmp: {&T, &T} -> bool): size_t
binsearch:adddefinition(terra(self: &view, v: T): size_t
scall
]]
