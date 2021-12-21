
--Circular buffer (aka fixed-sized fifo queue) of Lua values.
--Written by Cosmin Apreutesei. Public domain.

--This implementation allows removing a value at any position from the queue.
--For a cdata ringbuffer, look for fs.mirror_map() and lfrb.

local function new(size, INDEX)

	local head = size
	local tail = 1
	local n = 0
	local t = {}
	local q = {}

	function q:size() return size end
	function q:count() return n end

	function q:full() return n >= size end
	function q:empty() return n == 0 end

	local function mi(x) return (x - 1) % size + 1 end

	function q:push(v)
		assert(v ~= nil)
		if n >= size then
			return nil, 'full'
		end
		head = (head % size) + 1
		t[head] = v
		n = n + 1
		if INDEX ~= nil then v[INDEX] = head end
		return true
	end

	function q:pop()
		if n == 0 then
			return nil
		end
		local v = t[tail]
		t[tail] = false
		tail = (tail % size) + 1
		n = n - 1
		if INDEX ~= nil then v[INDEX] = nil end
		return v
	end

	function q:peek()
		if n == 0 then
			return nil
		end
		return t[tail]
	end

	function q:items()
		local i = 0 --last i
		return function()
			if i >= n then
				return nil
			end
			i = i + 1
			return t[mi(tail + i - 1)]
		end
	end

	function q:remove_at(i)
		assert(n > 0)
		local from_head = true
		if tail <= head then --queue not wrapped around (has one segment).
			assert(i >= tail and i <= head)
		elseif i <= head then --queue wrapped; i is in the head's segment.
			assert(i >= 1)
		else --queue wrapped; i is in the tail's segment.
			assert(i >= tail and i <= size)
			from_head = false
		end
		if from_head then --move right of i to left.
			for i = i, head-1 do t[i] = t[i+1]; if INDEX then t[i][INDEX] = i+1 end end
			t[head] = false
			if INDEX ~= nil then t[head][INDEX] = nil end
			head = mi(head - 1)
		else --move left of i to right.
			for i = i-1, tail, -1 do t[i+1] = t[i]; if INDEX then t[i+1][INDEX] = i end end
			t[tail] = false
			if INDEX ~= nil then t[tail][INDEX] = nil end
			tail = mi(tail + 1)
		end
		n = n - 1
	end

	function q:remove(v)
		local i = self:find(v)
		if not i then return false end
		self:remove_at(i)
		return true
	end

	if INDEX ~= nil then
		function q:find(v)
			return v[INDEX]
		end
	else
		function q:find(v)
			for i = 1, n do
				local i = mi(tail + i - 1)
				if t[i] == v then
					return i
				end
			end
		end
	end

	return q
end

if not ... then

	local q = new(4)
	local function test(s)
		local t = {}
		for s in q:items() do t[#t+1] = s end
		local s1 = table.concat(t)
		assert(s1 == s)
		assert(q:count() == #s)
	end
	assert(q:push'a')
	assert(q:push'b')
	assert(q:push'c')
	assert(q:push'd')
	assert(q:full())
	assert(q:pop())
	assert(q:push'e')
	assert(q:pop())
	assert(q:push'f')
	test'cdef'
	q:remove'd'
	test'cef'
	q:remove'e'
	test'cf'
	q:remove'c'
	test'f'
	q:remove'f'
	test''; assert(q:empty())
	assert(q:push'a')
	assert(q:push'b')
	assert(q:push'c')
	assert(q:push'd')
	assert(q:pop())
	assert(q:pop())
	assert(q:push'e')
	assert(q:push'f')
	test'cdef'
	assert(q:find'c' == 3)
	assert(q:find'd' == 4)
	assert(q:find'e' == 1)
	assert(q:find'f' == 2)

end

return {new = new}
