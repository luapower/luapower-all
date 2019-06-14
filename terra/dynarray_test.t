
setfenv(1, require'terra/low')

local struct S {x: int}
local p = global(int, 0)
local n = global(int, 0)
terra S:init() p = p + 1 end
terra S:free() n = n + 1 end
local terra test_own()
	var a = arr(S)
	a:add(S{})
	a:add(S{})
	a.len = 5
	a:free()
	assert(n == 5)
	assert(p == 0) --init() wasn't called
end
test_own()

local cmp = terra(a: &int, b: &int): int32
	return iif(@a < @b, -1, iif(@a > @b, 1, 0))
end

local terra test_dynarray()
	var a0 = arr(int); a0:free() --test the macro
	var a: arr(int); a:init()
	a:set(15, 1234, 0) --sparse array
	assert(a(15) == 1234)
	assert(a.len == 16)
	assert(a.capacity >= a.len)
	a:set(19, 4321, 0)
	assert(a(19) == 4321)
	var x = -1
	for i,v in a:sub(0, 15) do
		@v = x
		x = x * 2
	end
	x = 2000
	for i,v in a:sub(16, 19) do
		@v = x
		x = x + 100
	end
	a:sort(cmp)
	--for i,v in a do print(i, @v) end
	assert(a:binsearch(-maxint) == 0)
	assert(a:binsearch(maxint) == a.len)
	assert(a:binsearch(1234) == 15)
	assert(a:binsearch(4321) == 19)
	a:free()
end
test_dynarray()

local terra test_forward_methods()
	var a = arr(int)
	assert(a:at(0, nil) == nil)
	a.len = 5
end
test_forward_methods()

local terra test_autogrow()
	var a = arr(int)
	for i = 0,10000 do
		a:set(i, i, 0)
	end
	assert(a.len == 10000)
	assert(a.capacity == 16384)
end
test_autogrow()

local terra test_stack()
	var a = arr(int)
	for i = 0, 10000 do
		a:push(i)
	end
	for i, v in a:backwards() do
		assert(a:pop() == i)
	end
	assert(a.len == 0)
	assert(a.capacity > 0)
	a.capacity = a.len
	assert(a.capacity == 0)
end
test_stack()

local S = arr(int8)
local terra test_arrayofstrings()
	var a = arr(S)
	var s = S'Hello'
	a:add(s)
	a:add(S'World!')
	a:call'free'
	assert(a(0).capacity == 0)
	assert(a(0).len == 0)
	a:free()
	assert(a.capacity == 0)
	assert(a.len == 0)
end
test_arrayofstrings()

local terra test_wrap()
	var len = 10
	var buf = alloc(int8, len); fill(buf, len)
	buf[5] = 123
	var a = arr(buf, len)
	assert(a(5) == 123)
	a:free()

	var s = tostring('hello')
	print(s.len, s.elements)
	s:free()
end
test_wrap()
