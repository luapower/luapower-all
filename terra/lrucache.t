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

	c:get(k) -> i,&pair | -1,nil              get k/v pair by key
	c:put(k,v) -> i,&pair                     put k/v pair
	c:pair(i) -> &pair                        lookup pair
	c:forget(i)                               forget pair

]]

if not ... then require'terra/lrucache_test'; return end

setfenv(1, require'terra/low')
require'terra/linkedlist'

local function cache_type(key_t, val_t, size_t, context_t, hash, equal, own_keys, own_vals)

	val_t = val_t or tuple()

	local struct pair {
		key: key_t;
		val: val_t;
		refcount: size_t;
	}

	own_keys = own_keys and cancall(key_t, 'free')
	own_vals = own_vals and cancall(val_t, 'free')

	if own_keys or own_vals then
		if context_t then
			terra pair:free(context: context_t)
				optcall(self.key, 'free', 1, context)
				optcall(self.val, 'free', 1, context)
			end
		else
			terra pair:free()
				optcall(self.key, 'free')
				optcall(self.val, 'free')
			end
		end
	end

	local pair_list = arraylinkedlist{
		T = pair,
		size_t = size_t,
		context_t = context_t,
		own_elements = own_keys or own_vals,
	}

	local deref = macro(function(self, i)
		return `&self.state:link(@i).item.key
	end)

	local indices_set = set{
		key_t = size_t,
		size_t = size_t,
		hash = hash,
		equal = equal,
		deref = deref,
		deref_key_t = key_t,
		state_t = &pair_list,
		own_keys = false,
		context_t = context_t,
	}

	local struct cache (gettersandsetters) {
		_max_size: size_t;
		_max_count: size_t;
		size: size_t;
		count: size_t;
		pairs: pair_list; --linked list of key/val pairs
		indices: indices_set; --set of indices hashed by key_t through deref().
		first_active_index: size_t; --first pair that got refcount > 0.
	}

	cache.key_t = key_t
	cache.val_t = val_t
	cache.size_t = size_t
	cache.pair_t = pair

	addmethods(cache, function()

		local pair_memsize = macro(function(k, v)
			return `sizeof(pair) + sizeof(size_t) + memsize(k) + memsize(v)
		end)

		--storage

		local init = macro(function(self, context)
			return quote
				fill(self)
				self._max_count = [size_t:max()]
				self._max_size  = [size_t:max()]
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
			self:shrink(self._max_size - pair_size, self._max_count - 1)
			var i, link = self.pairs:insert_before(self.pairs.first)
			link.item.key = k
			link.item.val = v
			link.item.refcount = 1
			assert(self.indices:add(i) ~= -1) --wrong API usage if the key is present!
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
			if pair.refcount == 0 then
				if self.first_active_index ~= -1 then
					if self.first_active_index == i then
						self.first_active_index = -1
					else
						self.pairs:move_after(self.first_active_index, i)
					end
				end
				--TODO: we should shrink here, but tr's Span:free() calls
				--forget_font() which can trigger Font:free() which triggers
				--font_unload() which is a Lua callback and that could trigger
				--"bad callback" and the fix for that is jit.off()-wrapping all
				--the span-editing API. I fucking hate this bad callback situation
				--I mean look at the lengths one has to go to to avoid that shit.
				--self:shrink(self._max_size, self._max_count)
			end
		end

		--configuration

		terra cache:get_max_size() return self._max_size end
		terra cache:get_max_count() return self._max_count end

		terra cache:set_max_size(v: size_t)
			self._max_size = v
			self:shrink(self._max_size, self._max_count)
		end

		terra cache:set_max_count(v: size_t)
			self._max_count = v
			self:shrink(self._max_size, self._max_count)
		end

	end)

	return cache
end
cache_type = terralib.memoize(cache_type)

local cache_type = function(key_t, val_t, size_t)
	local context_t, hash, equal, own_keys, own_vals
	if terralib.type(key_t) == 'table' then
		local t = key_t
		key_t, val_t, size_t = t.key_t, t.val_t, t.size_t
		context_t, hash, equal, own_keys, own_vals =
			t.context_t, t.hash, t.equal, t.own_keys, t.own_values
	end
	if own_keys then assert(cancall(key_t, 'free'), 'own_keys specified but ', key_t, ' has no free method') end
	if own_vals then assert(cancall(val_t, 'free'), 'own_values specified but ', val_t, ' has no free method') end
	own_keys = own_keys ~= false
	own_vals = own_vals ~= false
	return cache_type(key_t, val_t or nil, size_t or int64, context_t or nil, hash, equal, own_keys, own_vals)
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
