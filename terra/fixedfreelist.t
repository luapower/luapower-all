--[[

	Fixed-capacity freelist for Terra.
	Written by Cosmin Apreutesei. Public Domain.

	Provides O(1) dynamic allocation and freeing for a fixed number of
	fixed-size elements. This is actually a mempool but with a freelist API.

]]

setfenv(1, require'terra/low')

local freelist_type = function(T, size_t, C)

	local items = arr{T = T, size_t = size_t}
	local indices = arr(size_t)

	local struct freelist (gettersandsetters) {
		items    : items;   --{item1, ...}
		freelist : indices; --{free_item_index1, ...}
	}

	freelist.empty = `freelist{
		items    = items(nil);
		freelist = indices(nil);
	}

	--storage

	terra freelist:init()
		@self = [freelist.empty]
	end

	terra freelist:free()
		self.items    :free()
		self.freelist :free()
	end

	terra freelist:set_min_capacity(cap: size_t)
		assert(self.items.len == 0) --can't resize while in use
		self.items   .min_capacity = cap
		self.freelist.min_capacity = cap
	end

	--alloc/release

	terra freelist:alloc()
		if self.freelist.len > 0 then
			return self.items:at(self.freelist:pop())
		elseif self.items.len < self.items.capacity then --prevent realloc!
			return self.items:push()
		end
		return nil
	end
	terra freelist:new()
		var p = self:alloc()
		return iif(p ~= nil, fill(p), nil)
	end

	terra freelist:release(pv: &T)
		var i: size_t = pv - self.items.elements
		assert(i >= 0 and i < self.items.len)
		if self.freelist.len > 0 then --poorman's double-release protection.
			if self.freelist(self.freelist.len-1) == i then
				return
			end
		end
		self.freelist:push(i)
	end

	return freelist
end
freelist_type = terralib.memoize(freelist_type)

local freelist_type = function(T, size_t)
	if terralib.type(T) == 'table' then
		T, size_t = T.T, T.size_t
	end
	size_t = size_t or int
	return freelist_type(T, size_t)
end

fixedfreelist = macro(
	--calling it from Terra returns a new freelist.
	function(T,size_t)
		T = T and T:astype()
		size_t = size_t and size_t:astype()
		local freelist = freelist_type(T, size_t)
		return quote var fl: freelist; fl:init() in fl end
	end,
	--calling it from Lua or from an escape or in a type declaration returns
	--just the type, and you can also pass a custom C namespace.
	freelist_type
)

if not ... then --self-test
	local struct S { x: int; y: int; }
	local terra test()
		var fl = fixedfreelist(S)
		fl.min_capacity = 2
		var p1 = fl:alloc(); assert(p1 ~= nil)
		var p2 = fl:alloc(); assert(p2 ~= nil)
		var p3 = fl:alloc(); assert(p3 == nil)
		fl:release(p2)
		fl:release(p2) --prevented, but that's the only case covered
		fl:release(p1)
		assert(fl.freelist.len == 2)
	end
	test()
end

return _M
