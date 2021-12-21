
--Priority queue implemented as a binary heap.
--Written by Cosmin Apreutesei. Public Domain.

if not ... then require'heap_test'; return end

local assert, floor = assert, math.floor

--heap algorithm working over abstract API that counts from one.

local function heap(add, remove, swap, length, cmp)

	local function moveup(child)
		local parent = floor(child / 2)
		while child > 1 and cmp(child, parent) do
			swap(child, parent)
			child = parent
			parent = floor(child / 2)
		end
		return child
	end

	local function movedown(parent)
		local last = length()
		local child = parent * 2
		while child <= last do
			if child + 1 <= last and cmp(child + 1, child) then
				child = child + 1 --sibling is smaller
			end
			if not cmp(child, parent) then break end
			swap(parent, child)
			parent = child
			child = parent * 2
		end
		return parent
	end

	local function push(v)
		add(v)
		return moveup(length())
	end

	local function pop(i)
		swap(i, length())
		remove()
		movedown(i)
	end

	local function rebalance(i)
		if moveup(i) == i then
			movedown(i)
		end
	end

	return push, pop, rebalance
end

--common methods for both cdata and value heaps.

function heap_mixin(h, INDEX)

	function h:find(v)
		for i,v1 in ipairs(self) do
			if v1 == v then
				return i
			end
		end
		return nil
	end

	if INDEX ~= nil then
		function h:find(v) --O(1..logN)
			return v[INDEX]
		end
	else
		function h:find(v) --O(n)
			for i,v1 in ipairs(self) do
				if v1 == v then
					return i
				end
			end
			return nil
		end
	end

end

--cdata heap working over a cdata dynamic array.

local function cdataheap(h)

	local ffi = require'ffi'

	local ctype = ffi.typeof(h.ctype)
	local arr = h.dynarray
		or require'glue'.dynarray(ffi.typeof('$[?]', ctype), h.min_capacity)
	local t, n = nil, 0

	local add, rem, swap
	local INDEX = h.index_key
	if INDEX ~= nil then --for O(n) removal.
		function add(v)
			n = n + 1
			t = arr(n + 1) --elem 0 is temp space for swapping.
			t[n] = v
			t[n][INDEX] = n
		end
		function rem()
			t[n][INDEX] = 0
			n = n - 1
		end
		function swap(i, j)
			t[0]=t[i]; t[i]=t[j]; t[j]=t[0]
			t[i][INDEX] = i
			t[j][INDEX] = j
		end
	else
		function add(v)
			n = n + 1
			t = arr(n + 1) --elem 0 is temp space for swapping.
			t[n] = v
		end
		function rem()
			n = n - 1
		end
		function swap(i, j)
			t[0]=t[i]; t[i]=t[j]; t[j]=t[0]
		end
	end
	local function length()
		return n
	end
	local cmp = h.cmp
		and function(i, j) return h.cmp(t[i], t[j]) end
		or  function(i, j) return t[i] < t[j] end

	local push, pop, rebalance = heap(add, rem, swap, length, cmp)

	heap_mixin(h, INDEX)

	local function get(i, box)
		if not (i >= 1 and i <= n) then
			return nil
		end
		if box then
			box[0] = t[i]
		else
			return ffi.new(ctype, t[i])
		end
	end
	function h:push(v)
		push(v)
	end
	function h:pop(i, box)
		assert(n > 0, 'buffer underflow')
		local v = get(i or 1, box)
		pop(i or 1)
		return v
	end
	function h:peek(i, box)
		return get(i or 1, box)
	end
	function h:replace(i, v)
		assert(i >= 1 and i <= n, 'invalid index')
		t[i] = v
		rebalance(i)
	end
	h.length = length
	function h:remove(v)
		local i = self:find(v)
		if i then
			self:pop(i)
			return true
		else
			return false
		end
	end

	return h
end

--value heap working over a Lua table

local function valueheap(h)
	h = h or {}
	local t, n = h, #h
	local add, rem, swap
	local INDEX = h.index_key
	if INDEX ~= nil then --for O(log n) removal.
		function add(v) n=n+1; t[n]=v; v[INDEX] = n end
		function rem() t[n][INDEX] = nil; t[n]=nil; n=n-1 end
		function swap(i, j)
			t[i], t[j] = t[j], t[i]
			t[i][INDEX] = i
			t[j][INDEX] = j
		end
	else
		function add(v) n=n+1; t[n]=v end
		function rem() t[n]=nil; n=n-1 end
		function swap(i, j) t[i], t[j] = t[j], t[i] end
	end
	local function length() return n end
	local cmp = h.cmp
		and function(i, j) return h.cmp(t[i], t[j]) end
		or  function(i, j) return t[i] < t[j] end
	local push, pop, rebalance = heap(add, rem, swap, length, cmp)

	heap_mixin(h, INDEX)

	function h:push(v)
		assert(v ~= nil, 'invalid value')
		push(v)
	end
	function h:pop(i)
		assert(n > 0, 'buffer underflow')
		local v = t[i or 1]
		pop(i or 1)
		return v
	end
	function h:peek(i)
		return t[i or 1]
	end
	function h:replace(i, v)
		assert(i >= 1 and i <= n, 'invalid index')
		t[i] = v
		rebalance(i)
	end
	h.length = length
	function h:remove(v)
		local i = self:find(v)
		if i then
			self:pop(i)
			return true
		else
			return false
		end
	end
	return h
end

return {
	heap = heap,
	valueheap = valueheap,
	cdataheap = cdataheap,
}
