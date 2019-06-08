--[[

	LRU cache for Terra, size-limited and count-limited.
	Written by Cosmin Apreutesei. Public Domain.

	* Pair pointers are not valid between put() calls, use indices!
	* Breaks if trying to put a key that's already in the cache.
	* Cache items are ref-counted, get() and put() both increase the refcount
	and forget() decreases it. Ref'ed items never get removed from the cache,
	instead the cache grows beyond max_size and/or max_count.

	local C = cache{key_t=,val_t=,...}        create type from Lua
	var c = cache(key_t,val_t,[size_t=int])   create value from Terra
	c:init()                                  initialize (for struct members)
	c:free()                                  free
	c:clear()                                 clear (but preserve memory)
	c.min_capacity = n                        (write/only) preallocate a number of items
	c:shrink(max_size, max_count)             shrink (but don't free memory)
	c.max_size                                (read/write) max bytesize
	c.max_count                               (read/write) max number of items
	c.size                                    (read/only) current size
	c.count                                   (read/only) current number of items

	c:get(k) -> i,&val | -1,nil               get k/v pair by key
	c:put(k,v) -> i,&val                      put k/v pair
	c:pair(i) -> &pair                        lookup pair
	c:forget(i)                               forget pair

]]

if not ... then require'lrucache_test'; return end

setfenv(1, require'low')
require'linkedlist'

local function cache_type(key_t, val_t, size_t, context_t, hash, equal)

	val_t = val_t or tuple()

	local struct pair {
		key: key_t;
		val: val_t;
		refcount: size_t;
	}

	local pair_list = arraylinkedlist{T = pair, context_t = context_t}

	local deref = macro(function(self, i)
		return `&self.state:link(@i).item.key
	end)

	local indices_set = set{
		key_t = size_t,
		hash = hash, equal = equal,
		deref = deref, deref_key_t = key_t,
		state_t = &pair_list,
		own_keys = false,
		context_t = context_t,
	}

	local struct cache (gettersandsetters) {
		max_size: size_t;
		max_count: size_t;
		size: size_t;
		count: size_t;
		pairs: pair_list; --linked list of key/val pairs
		indices: indices_set; --set of indices hashed by key_t through deref().
		first_active_index: size_t; --first pair that got refcount > 0.
	}

	cache.key_t = key_t
	cache.val_t = val_t
	cache.size_t = size_t

	addmethods(cache, function()

		local pair_memsize = macro(function(k, v)
			return `sizeof(pair) + sizeof(size_t) + memsize(k) + memsize(v)
		end)

		if cancall(key_t, 'free') or cancall(val_t, 'free') then
			if context_t then
				terra pair:free(context: context_t)
					call(&self.key, 'free', 1, context)
					call(&self.val, 'free', 1, context)
				end
			else
				terra pair:free()
					call(&self.key, 'free')
					call(&self.val, 'free')
				end
			end
		end

		--storage

		local init = macro(function(self, context)
			return quote
				fill(self)
				self.max_count = [size_t:max()]
				escape if context_t then emit quote
					self.pairs:init(context)
					self.indices:init(context)
				end else emit quote
					self.pairs:init()
					self.indices:init()
				end end end
				self.indices.state = &self.pairs
				self.first_active_index = -1
			end
		end)
		if context_t then
			terra cache:init(context: context_t) init(self, context) end
		else
			terra cache:init() init(self) end
		end

		terra cache:clear()
			self.pairs:clear()
			self.indices:clear()
			self.size = 0
			self.count = 0
			self.first_active_index = -1
		end

		terra cache:free()
			self:clear()
			self.pairs:free()
			self.indices:free()
		end

		terra cache:setcapacity(n: size_t)
			return self.pairs:setcapacity(n)
				and self.indices:resize(n)
		end
		terra cache:set_capacity(n: size_t)
			self.pairs.capacity = n
			self.indices.capacity = n
		end
		terra cache:set_min_capacity(n: size_t)
			self.pairs.min_capacity = n
			self.indices.min_capacity = n
		end

		--operation

		cache.methods.pair = macro(function(self, i)
			return `&self.pairs:link(i).item
		end)

		terra cache:get(k: key_t)
			var ki = self.indices:index(k, -1)
			if ki ~= -1 then
				var i = self.indices:noderef_key_at_index(ki)
				self.pairs:move_before(self.pairs.first, i)
				var item = &self.pairs:link(i).item
				inc(item.refcount)
				if self.first_active_index == -1 then
					self.first_active_index = i
				end
				return i, item
			else
				return -1, nil
			end
		end

		terra cache:shrink(max_size: size_t, max_count: size_t)
			while self.size > max_size or self.count > max_count do
				var i = self.pairs.last
				if i == -1 then break end --cache empty
				var pair = &self.pairs:link(i).item
				if pair.refcount > 0 then break end --can't shrink beyond this point
				var pair_size = pair_memsize(pair.key, pair.val)
				assert(self.indices:remove(pair.key))
				self.pairs:remove(i)
				self.size = self.size - pair_size
				self.count = self.count - 1
			end
		end

		terra cache:put(k: key_t, v: val_t)
			var pair_size = pair_memsize(k, v)
			self:shrink(self.max_size - pair_size, self.max_count - 1)
			var i, link = self.pairs:insert_before(self.pairs.first)
			link.item.key = k
			link.item.val = v
			link.item.refcount = 1
			assert(self.indices:add(i) ~= -1) --fails if the key is present!
			self.size = self.size + pair_size
			self.count = self.count + 1
			if self.first_active_index == -1 then
				self.first_active_index = i
			end
			return i, &link.item
		end

		terra cache:forget(i: size_t)
			var pair = &self.pairs:link(i).item
			assert(pair.refcount > 0)
			dec(pair.refcount)
			if pair.refcount == 0 and self.first_active_index ~= -1 then
				if self.first_active_index == i then
					self.first_active_index = -1
				else
					self.pairs:move_after(self.first_active_index, i)
				end
			end
		end

	end)

	return cache
end
cache_type = terralib.memoize(cache_type)

local cache_type = function(key_t, val_t, size_t)
	local context_t, hash, equal
	if terralib.type(key_t) == 'table' then
		local t = key_t
		key_t, val_t, size_t = t.key_t, t.val_t, t.size_t
		context_t, hash, equal = t.context_t, t.hash, t.equal
	end
	return cache_type(key_t, val_t or nil, size_t or int, context_t or nil, hash, equal)
end

lrucache = macro(
	--calling it from Terra returns a new cache object.
	function(key_t, val_t, size_t)
		local cache_type = cache_type(key_t, val_t, size_t)
		return quote var c: cache; c:init() in c end
	end,
	--calling it from Lua or from an escape or in a type declaration returns
	--just the type, and you can also pass a custom C namespace.
	cache_type
)

return _M
