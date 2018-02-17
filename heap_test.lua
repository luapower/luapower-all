local heap = require'heap'
local time = require'time'
local ffi = require'ffi'

local function test_example1()
	local h = heap.cdataheap{
		size = 100,
		ctype = [[
			struct {
				int priority;
				int order;
			}
		]],
		cmp = function(a, b)
			if a.priority == b.priority then
				return a.order > b.order
			end
			return a.priority < b.priority
		end}
	h:push{priority = 20, order = 1}
	h:push{priority = 10, order = 2}
	h:push{priority = 10, order = 3}
	h:push{priority = 20, order = 4}
	assert(h:pop().order == 3)
	assert(h:pop().order == 2)
	assert(h:pop().order == 4)
	assert(h:pop().order == 1)
end

local function test_example2()
	local h = heap.valueheap{cmp = function(a, b)
	      return a.priority < b.priority
	   end}
	h:push{priority = 20, etc = 'bar'}
	h:push{priority = 10, etc = 'foo'}
	assert(h:pop().priority == 10)
	assert(h:pop().priority == 20)
end

local function aeq(h, t)
	assert(#h == #t)
	for i=1,#t do assert(h[i] == t[i]) end
end

local function test_remove()
	local h = heap.valueheap{1, 2, 100, 3, 4, 200, 300} -- 1-(2-(3, 4), 100-(200, 300))
	h:pop(2)
	aeq(h, {1, 3, 100, 300, 4, 200}) --2 replaced by 300; 300 swapped with 3
end

local function test_replace()
	local h = heap.valueheap{1, 10, 10, 100, 100, 100, 100}
	h:replace(2, 300)
	aeq(h, {1, 100, 10, 300, 100, 100, 100}) --moved down
	local h = heap.valueheap{1, 10, 10, 100, 100, 100, 100}
	h:replace(4, 5)
	aeq(h, {1, 5, 10, 10, 100, 100, 100}) --moved up
end

local function bench(type, h, size, valgen)
	local cmp = h.cmp or function(a, b) return a < b end
	local t0 = time.clock()
	for i=1,size do
	    h:push(valgen(h))
	end
	print(string.format('push speed: %-12s: %6d Ke/s', type, size / 10^3 / (time.clock() - t0)))
	t0 = time.clock()
	local v0 = h:pop()
	for i=2,size do
		local v = h:pop()
		assert(not cmp(v, v0))
		v0 = v
	end
	print(string.format('pop  speed: %-12s: %6d Ke/s', type, size / 10^3 / (time.clock() - t0)))
end

local function benchmark()
	local size = 100000
	local function ngen(h) return math.random(1, h.size) end
	bench('Lua values',  heap.valueheap{size=size}, size, ngen)
	bench('int32',       heap.cdataheap{ctype = 'int32_t', size = size+1}, size, ngen)
	local v3t = ffi.typeof'struct { double x, y, z; }'
	local v3 = v3t()
	local function vgen(h) v3.x = ngen(h); return v3 end
	local function vcmp(v1, v2) return v1.x < v2.x end
	bench('vector3', heap.cdataheap{ctype = v3t, size = size+1, cmp = vcmp}, size, vgen)
end

local h = heap.valueheap()

h:push(5)
h:push(12)
h:push(3)
h:push(2)
h:push(1)
h:push(10)
h:push(11)
h:push(7)

pp(h)


do return end

test_example1()
test_example2()
test_remove()
test_replace()
benchmark()
