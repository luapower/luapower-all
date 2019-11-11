--[[

	Hashmap type for Terra.
	Written by Cosmin Apreutesei. Public Domain.

	Port of khash.h v0.2.8 from github.com/attractivechaos/klib (MIT License).

	local M = map(key_t,val_t,[size_t=int])     create a map type
	local M = map{key_t=,val_t=...}             create a map type
	var m   = map(key_t,val_t,[size_t=int])     create a map object
	var m   = M(nil)                            nil-cast (for use in global())

	local S = set(key_t,[size_t=int])           create a set type
	local S = set{key_t=,...}                   create a set type
	var s   = set(key_t,[size_t=int])           create a set object
	var s   = S(nil)                            nil-cast (for use in global())

	m|s:init() | fill(&m|&s)                    initialize (for struct members)
	m|s:free()                                  free the hashmap
	m|s:clear()                                 clear but keep the buffers

	m|s.count                                   (read/only) number of pairs
	m|s.capacity                                (read/write) grow/shrink hashmap
	m|s.min_capacity                            (write/only) grow hashmap

	m|s:index(k[,default]) -> i                 lookup key and return pair index
	m|s:setkey(k) -> m.PRESENT|ABSENT|DELETED|-1, i|-1  occupy a key
	m|s:remove_at_index(i) -> found?            remove/free pair at i
	m|s:has_at_index(i) -> found?               check if index is occupied
	m|s:key_at_index(i) -> k                    (unchecked!) get key at i
	m|s:noderef_key_at_index(i) -> k            (unchecked!) get no-deref key at i
	m:val_at_index(i) -> v                      (unchecked!) get value at i
	m|s:next_index([last_i]) -> i|-1            next occupied index

	m|s:has(k) -> found?                        check if key is in map
	m:at(k[,default]) -> &v                     get &value for key
	m[:get](k[,default]) -> v                   get value for key
	m:set(k,v) -> i                             add or get key and set value
	m:set(k) -> &v                              add or get key and get &value
	m:add(k,v) -> i|-1                          add key/val pair if key doesn't exist
	m:add(k) -> &v|nil                          add key if doesn't exist and get &value
	m:remove(k) -> found?                       remove/free pair
	s:set(k) -> i                               add or get key
	s:add(k) -> i|-1                            add key if doesn't exist

	for &k,&v in m do ... end                   iterate key/val pairs in a map
	for &k in s do ... end                      iterate keys in a set

	m|s:merge(m|s)                              add new pairs/keys from another map/set
	m|s:update(m|s)                             update pairs/keys, overriding values

]]

if not ... then require'terra.hashmap_test'; return end

setfenv(1, require'terra.low')

--interface to the 2-bit flags bitmap

local function getflag(flags, i, which)
	return `((flags[i>>4] >> ((i and 0xfU) << 1)) and which) ~= 0
end
local isempty  = macro(function(flags, i) return getflag(flags, i, 2) end)
local isdel    = macro(function(flags, i) return getflag(flags, i, 1) end)
local iseither = macro(function(flags, i) return getflag(flags, i, 3) end)
local function setflag_false(flags, i, which)
	return quote
		flags[i>>4] = flags[i>>4] and not ([uint64](which) << ((i and 0xfU) << 1))
	end
end
local function setflag_true(flags, i, which)
	return quote
		flags[i>>4] = flags[i>>4] or ([uint64](which)) << ((i and 0xfU) << 1)
	end
end
local set_isdel_false   = macro(function(flags, i) return setflag_false(flags, i, 1) end)
local set_isempty_false = macro(function(flags, i) return setflag_false(flags, i, 2) end)
local set_isboth_false  = macro(function(flags, i) return setflag_false(flags, i, 3) end)
local set_isdel_true    = macro(function(flags, i) return setflag_true (flags, i, 1) end)

local fsize = macro(function(m) return `iif(m < 16, 1, m >> 4) end)

local UPPER = 0.77

local realloc = macro(function(p, len)
	return `_M.realloc(p, len, 'hashmap')
end)

local map_type = memoize(function(
	key_t, val_t, user_hash, user_equal, size_t,
	deref, deref_key_t, state_t, context_t, own_keys, own_vals
)
	local is_map = sizeof(val_t) > 0
	local hash  = user_hash  or hash
	local equal = user_equal or equal

	local struct map (gettersandsetters) {
		n_buckets: size_t;
		count: size_t;      --number of pairs
		n_occupied: size_t; --number of live + deleted pairs
		upper_bound: size_t;
		flags: &int32;
		keys: &key_t;
		vals: &val_t;
		state: state_t; --to be used by deref
		context: context_t; --to be used by free
	}

	local st = state_t.empty
	st = st or state_t:ispointer() and `nil
	st = st or state_t:isarithmetic() and 0
	st = st or state_t:istuple() and `{}
	assert(st, 'state missing initializer')

	map.key_t   = key_t
	map.val_t   = val_t
	map.size_t  = size_t
	map.state_t = state_t

	map.empty = `map{
		n_buckets = 0;
		count = 0;
		n_occupied = 0;
		upper_bound = 0;
		flags = nil;
		keys = nil;
		vals = nil;
		state = st;
	}

	function map.metamethods.__typename(self)
		if is_map then
			return 'map('..tostring(key_t)..'->'..tostring(val_t)..')'
		else
			return 'set('..tostring(key_t)..')'
		end
	end

	function map.metamethods.__cast(from, to, exp)
		if to == map then
			if from == niltype then --makes [map(...)](nil) work in a constant()
				return map.empty
			end
		end
		assert(false, 'invalid cast from ', from, ' to ', to, ': ', exp)
	end

	--publish enums as virtual fields of map
	addproperties(map)
	map.properties.PRESENT =  0 --key was already present
	map.properties.ABSENT  =  1 --key was added
	map.properties.DELETED =  2 --key was previously deleted
	map.properties.ERROR   = -1 --allocation error

	map.metamethods.__apply = macro(function(self, i, default)
		if default then return `self:get(i, default) else return `self:get(i) end
	end)

	function map.metamethods.__for(h, body)
		if h:islvalue() then h = `&h end
		if is_map then
			return quote
				var h = h --workaround for terra issue #368
				for i = 0, h.n_buckets do
					if h:has_at_index(i) then
						[ body(`&h.keys[i], `&h.vals[i]) ]
					end
				end
			end
		else
			return quote
				var h = h --workaround for terra issue #368
				for i = 0, h.n_buckets do
					if h:has_at_index(i) then
						[ body(`&h.keys[i]) ]
					end
				end
			end
		end
	end

	addmethods(map, function()

		local own_keys = own_keys and cancall(deref_key_t, 'free')
		local own_vals = is_map and own_vals and cancall(val_t, 'free')

		--ctor & dtor

		if context_t ~= tuple() then
			terra map.methods.init(h: &map, context: context_t)
				@h = [map.empty]
				h.context = context
			end
		else
			terra map.methods.init(h: &map)
				@h = [map.empty]
			end
		end

		--these are implemented later because they use has_at_index().
		terra map.methods.free_keys :: {&map} -> {}
		terra map.methods.free_vals :: {&map} -> {}
		terra map.methods.free_key  :: {&map, &deref_key_t} -> {}
		terra map.methods.free_val  :: {&map, &val_t} -> {}

		terra map:free() --can be reused after free
			if own_keys then self:free_keys() end
			if own_vals then self:free_vals() end
			self.keys  = realloc(self.keys , 0)
			self.flags = realloc(self.flags, 0)
			self.vals  = realloc(self.vals , 0)
			self.n_buckets = 0
			self.n_occupied = 0
			self.upper_bound = 0
			self.count = 0
		end

		terra map.methods.clear(h: &map)
			if h.flags == nil then return end
			fill(h.flags, fsize(h.n_buckets), 0xaa)
			h.count = 0
			h.n_occupied = 0
		end

		local pair_size = sizeof(key_t) + sizeof(val_t) + 1.0/4
		terra map:__memsize(): intptr
			return self.count * pair_size
		end

		terra map:__rawmemsize(): intptr
			return self.n_buckets * (sizeof(key_t) + sizeof(val_t) + 0.25)
		end

		--low level (slot-based) API (and the actual algorithm).
		map.methods.index = overload'index'

		map.methods.index:adddefinition(terra(h: &map, key: deref_key_t, default: size_t): size_t
			if h.n_buckets == 0 then return default end
			var mask: size_t = h.n_buckets - 1
			var k: size_t = hash(size_t, &key)
			var i: size_t = k and mask
			var last: size_t = i
			var step: size_t = 0
			while not isempty(h.flags, i) and (isdel(h.flags, i)
				or not equal(deref(h, &h.keys[i]), &key))
			do
				inc(step)
				i = (i + step) and mask
				if i == last then return default end
			end
			return iif(iseither(h.flags, i), default, i)
		end)
		map.methods.index:adddefinition(terra(h: &map, key: deref_key_t): size_t
			var i = h:index(key, -1)
			assert(i ~= -1)
			return i
		end)

		terra map.methods.resize(h: &map, new_n_buckets: size_t): bool
			-- This function uses 0.25*n_buckets bytes of working space
			-- instead of (sizeof(key_t+val_t)+.25)*n_buckets.
			var new_flags: &int32 = nil
			var j: size_t = 1
			new_n_buckets = max(4, nextpow2(new_n_buckets))
			if h.count >= [size_t](new_n_buckets * UPPER + 0.5) then
				j = 0 -- requested size is too small
			else -- hash table size to be changed (shrink or expand); rehash
				new_flags = alloc(int32, fsize(new_n_buckets))
				if new_flags == nil then
					return false
				end
				fill(new_flags, fsize(new_n_buckets), 0xaa)
				if h.n_buckets < new_n_buckets then -- expand
					var new_keys = realloc(h.keys, new_n_buckets)
					if new_keys == nil then
						realloc(new_flags, 0)
						return false
					end
					if is_map then
						var new_vals = realloc(h.vals, new_n_buckets)
						if new_vals == nil then
							realloc(new_keys, 0)
							realloc(new_flags, 0)
							return false
						end
						h.vals = new_vals
					end
					h.keys = new_keys
				end -- otherwise shrink
			end
			if j ~= 0 then -- rehashing is needed
				j = 0
				while j ~= h.n_buckets do
					if not iseither(h.flags, j) then
						var key: key_t = h.keys[j]
						var val: val_t
						var new_mask: size_t = new_n_buckets - 1
						if is_map then val = h.vals[j] end
						set_isdel_true(h.flags, j)
						while true do -- kick-out process; sort of like in Cuckoo hashing
							var k: size_t = hash(size_t, deref(h, &key))
							var i: size_t = k and new_mask
							var step: size_t = 0
							while not isempty(new_flags, i) do
								inc(step)
								i = (i + step) and new_mask
							end
							set_isempty_false(new_flags, i)
							if i < h.n_buckets and not iseither(h.flags, i) then
								-- kick out the existing element
								swap(h.keys[i], key)
								if is_map then swap(h.vals[i], val) end
								set_isdel_true(h.flags, i) -- mark it as deleted in the old hash table
							else -- write the element and jump out of the loop
								h.keys[i] = key
								if is_map then h.vals[i] = val end
								break
							end
						end
					end
					inc(j)
				end
				if h.n_buckets > new_n_buckets then -- shrink the hash table
					var new_keys = realloc(h.keys, new_n_buckets)
					if new_keys == nil then
						realloc(new_flags, 0)
						return false
					end
					if is_map then
						var new_vals = realloc(h.vals, new_n_buckets)
						if new_vals == nil then
							realloc(new_keys, 0)
							realloc(new_flags, 0)
							return false
						end
						h.vals = new_vals
					end
					h.keys = new_keys
				end
				realloc(h.flags, 0) -- free the working space
				h.flags = new_flags
				h.n_buckets = new_n_buckets
				h.n_occupied = h.count
				h.upper_bound = h.n_buckets * UPPER + 0.5
			end
			return true
		end

		map.methods.get_capacity = macro(function(self) return `self.n_buckets end)

		terra map.methods.set_capacity(h: &map, n_buckets: size_t)
			return h:resize(max(h.count, n_buckets))
		end

		terra map.methods.set_min_capacity(h: &map, n_buckets: size_t)
			assert(h:resize(max(h.n_buckets, n_buckets)))
		end

		terra map.methods.setkey(h: &map, key: key_t): {int8, size_t}
			if h.n_occupied >= h.upper_bound then -- update the hash table
				if h.n_buckets > h.count * 2 then
					if not h:resize(h.n_buckets - 1) then -- clear "deleted" elements
						return -1, -1
					end
				elseif not h:resize(h.n_buckets + 1) then -- expand the hash table
					return -1, -1
				end
			end -- TODO: implement automatic shrinking; resize() already supports shrinking
			var x = h.n_buckets
			var site = x
			var mask = x - 1
			var k = hash(size_t, deref(h, &key))
			var i = k and mask
			if isempty(h.flags, i) then
				x = i -- for speed up
			else
				var step: size_t = 0
				var last = i
				while not isempty(h.flags, i)
					and (isdel(h.flags, i)
						or not equal(deref(h, &h.keys[i]), deref(h, &key)))
				do
					if isdel(h.flags, i) then site = i end
					inc(step)
					i = (i + step) and mask
					if i == last then x = site; break; end
				end
				if x == h.n_buckets then
					x = iif(isempty(h.flags, i) and site ~= h.n_buckets, site, i)
				end
			end
			if isempty(h.flags, x) then -- not present at all
				h.keys[x] = key
				set_isboth_false(h.flags, x)
				inc(h.count)
				inc(h.n_occupied)
				return h.ABSENT, x
			elseif isdel(h.flags, x) then -- deleted
				h.keys[x] = key
				set_isboth_false(h.flags, x)
				inc(h.count)
				return h.DELETED, x
			else -- present and not deleted, _not_ replacing
				return h.PRESENT, x
			end
		end

		terra map.methods.remove_at_index(h: &map, i: size_t)
			if i ~= h.n_buckets and not iseither(h.flags, i) then
				set_isdel_true(h.flags, i)
				h.count = h.count - 1
				if own_keys then h:free_key(deref(h, &h.keys[i])) end
				if own_vals then h:free_val(&h.vals[i]) end
				return true
			end
			return false
		end

		map.methods.has_at_index = terra(h: &map, i: size_t)
			return i >= 0 and i < h.n_buckets and not iseither(h.flags, i)
		end
		map.methods.key_at_index = terra(h: &map, i: size_t) return @deref(h, &h.keys[i]) end
		map.methods.val_at_index = terra(h: &map, i: size_t) return h.vals[i] end
		map.methods.noderef_key_at_index = terra(h: &map, i: size_t) return h.keys[i] end

		--returns -1 on eof, which is also the start index which can be omitted.
		map.methods.next_index = macro(function(h, i)
			i = i or -1
			return quote
				var r: size_t = -1
				var i: size_t = i
				while i < h.n_buckets do
					inc(i)
					if h:has_at_index(i) then
						r = i
						break
					end
				end
				in r
			end
		end)

		--implement these here because they need has_at_index() defined...

		if cancall(deref_key_t, 'free') then
			if context_t ~= tuple() then
				terra map:free_key(k: &deref_key_t) (@k):free(self.context) end
			else
				terra map:free_key(k: &deref_key_t) (@k):free() end
			end
			if is_map then
				terra map:free_keys()
					for k,_ in self do
						self:free_key(deref(self, k))
					end
				end
			else
				terra map:free_keys()
					for k in self do
						self:free_key(deref(self, k))
					end
				end
			end
		else
			terra map:free_keys() end
			terra map:free_key(k: &deref_key_t) end
		end

		if cancall(val_t, 'free') and is_map then
			if context_t ~= tuple() then
				terra map:free_val(v: &val_t) (@v):free(self.context) end
			else
				terra map:free_val(v: &val_t) (@v):free() end
			end
			terra map:free_vals()
				for _,v in self do
					self:free_val(v)
				end
			end
		else
			terra map:free_vals() end
			terra map:free_val(v: &val_t) end
		end

		--hi-level (key/value pair-based) API

		terra map.methods.has(h: &map, key: deref_key_t)
			return h:index(key, -1) ~= -1
		end

		if is_map then
			map.methods.at = overload'at'
			map.methods.at:adddefinition(terra(h: &map, key: deref_key_t, default: &val_t): &val_t
				var i = h:index(key, -1)
				return iif(i ~= -1, &h.vals[i], default)
			end)
			map.methods.at:adddefinition(terra(h: &map, key: deref_key_t): &val_t
				return &h.vals[h:index(key)]
			end)

			map.methods.get = overload'get'
			map.methods.get:adddefinition(terra(h: &map, key: deref_key_t, default: val_t): val_t
				var i = h:index(key, -1)
				return iif(i ~= -1, h.vals[i], default)
			end)
			map.methods.get:adddefinition(terra(h: &map, key: deref_key_t): val_t
				return h.vals[h:index(key)]
			end)

			map.methods.set = overload'set'
			map.methods.set:adddefinition(terra(h: &map, key: key_t, val: val_t)
				var ret, i = h:setkey(key); assert(i ~= -1)
				h.vals[i] = val
				return i
			end)
			map.methods.set:adddefinition(terra(h: &map, key: key_t)
				var ret, i = h:setkey(key); assert(i ~= -1)
				return &h.vals[i]
			end)

			map.methods.add = overload'add'
			map.methods.add:adddefinition(terra(h: &map, key: key_t, val: val_t)
				var ret, i = h:setkey(key); assert(i ~= -1)
				if ret ~= h.PRESENT then
					h.vals[i] = val
					return i
				else
					return -1
				end
			end)
			map.methods.add:adddefinition(terra(h: &map, key: key_t)
				var ret, i = h:setkey(key); assert(i ~= -1)
				return iif(ret ~= h.PRESENT, &h.vals[i], nil)
			end)
		else
			terra map.methods.set(h: &map, key: key_t)
				var _, i = h:setkey(key); assert(i ~= -1)
				return i
			end

			terra map.methods.add(h: &map, key: key_t)
				var ret, i = h:setkey(key); assert(i ~= -1)
				return iif(ret ~= h.PRESENT, i, -1)
			end
		end

		terra map.methods.remove(h: &map, key: deref_key_t): bool
			var i = h:index(key, -1)
			if i == -1 then return false end
			h:remove_at_index(i)
			return true
		end

		if is_map then
			terra map:merge(m: &map) for k,v in m do self:add(@k,@v) end end
			terra map:update(m: &map) for k,v in m do self:set(@k,@v) end end
		else
			terra map:merge(m: &map) for k in m do self:add(@k) end end
			terra map:update(m: &map) for k in m do self:set(@k) end end
		end

		setinlined(map.methods, function(name)
			return name ~= 'resize'
		end)

	end) --addmethods()

	return map
end)

--specialization for different key and value types ---------------------------

local keytype = {}

local identity_hash = macro(function(n) return `@n end)

keytype[int32] = {
	hash32 = identity_hash,
	hash64 = identity_hash,
}
keytype[uint32] = keytype[int32]

local K = 2654435769ULL --Knuth's
keytype[int64] = {
	hash32 = macro(function(n)
		return `([int32](@n) * K + [int32](@n >> 32) * K) >> 31
	end),
	hash64 = identity_hash,
}
keytype[uint64] = keytype[int64]

local deref_pass = macro(function(self, k) return k end)

local map_type = function(key_t, val_t, size_t)
	local hash, equal, deref, deref_key_t, state_t, context_t, own_keys, own_vals
	if terralib.type(key_t) == 'table' then
		local t = key_t
		key_t, val_t, size_t = t.key_t, t.val_t, t.size_t
		hash, equal, deref, deref_key_t, state_t, context_t, own_keys, own_vals =
			t.hash, t.equal, t.deref, t.deref_key_t, t.state_t, t.context_t, t.own_keys, t.own_values
	end
	assert(key_t, 'key type missing')
	val_t = val_t or tuple()
	deref = deref or deref_pass
	deref_key_t = deref_key_t or key_t
	size_t = size_t or int --it's faster to use 64bit hashes for 64bit keys
	state_t = state_t or tuple()
	context_t = context_t or tuple()
	if own_keys then assert(cancall(T, 'free'), 'own_keys specified but ', T, ' has no free method') end
	if own_vals then assert(cancall(T, 'free'), 'own_values specified but ', T, ' has no free method') end
	own_keys = own_keys ~= false
	own_vals = own_vals ~= false
	return map_type(
		key_t, val_t, hash, equal, size_t,
		deref, deref_key_t, state_t, context_t, own_keys, own_vals)
end

map = macro(
	--calling it from Terra returns a new map.
	function(key_t, val_t, size_t)
		key_t = key_t and key_t:astype()
		val_t = val_t and val_t:astype()
		size_t = size_t and size_t:astype()
		local map = map_type(key_t, val_t, size_t)
		return `map(nil)
	end,
	--calling it from Lua or from an escape or in a type declaration returns
	--just the type, and you can also pass a custom C namespace.
	map_type
)

set = macro(function(key_t, size_t)
	return map.fromterra(key_t, nil, size_t)
end, function(key_t, size_t)
	return map.fromlua(key_t, nil, size_t)
end)
