setfenv(1, require'terra/low')

local S = arr(int8)
local struct V {x: int}
local n = global(int, 0)
terra V:free() n = n + 1 end
local terra test_own_keys()
	var s1 = S'Hello'
	var s2 = S'World!'
	var h = map([&S], V)
	h:set(&s1, V{5})
	h:set(&s2, V{7})
	h:set(&s2, V{8})
	h:set(&s1, V{3})
	assert(h(&s2).x == 8)
	assert(h(&s1).x == 3)
	assert(h.count == 2)
	h:free()
	assert(s1.len == 0) --freed by h
	assert(s2.len == 0) --freed by h
	assert(n == 2)
end
test_own_keys()

local random_keys = function(key_t, gen_key, n)
	return quote
		var keys = alloc(key_t, n)
		for i = 0, n do
			keys[i] = [gen_key(i)]
		end
	in
		keys
	end
end

local test_speed = function(key_t, val_t, gen_key, n, hash, equal, size_t)
	return quote
		var keys = [random_keys(key_t, gen_key, n)]
		var h: map {key_t = key_t, val_t = val_t, hash = hash, equal = equal,
			size_t = size_t}; h:init()
		var t0 = clock()
		for i = 0, n do
			var k = keys[i]
			var i = h:set(k, 0)
			if i >= 0 then
				inc(h:val_at_index(i))
			end
		end
		pfn('key size: %4d, inserts: %8d, unique keys: %3.0f%%, mil/sec: %8.3f',
			sizeof(key_t), n, (1.0 * h.count / n) * 100, (n / 1000000.0) / (clock() - t0) )

		t0 = clock()
		for i = 0, n do
			assert(h:has(keys[i]))
		end
		pfn('key size: %4d, lookups: %8d, unique keys: %3.0f%%, mil/sec: %8.3f',
			sizeof(key_t), n, (1.0 * h.count / n) * 100, (n / 1000000.0) / (clock() - t0) )

		h:free()
		free(keys)
	end
end

local test_speed_int32 = function(n, u)
	local gen_key = function(i) return `random(u) end
	return test_speed(int32, int32, gen_key, n)
end

C[[
#include <stdint.h>
uint64_t hash_64(uint64_t key)
{
	key = ~key + (key << 21);
	key = key ^ key >> 24;
	key = (key + (key << 3)) + (key << 8);
	key = key ^ key >> 14;
	key = (key + (key << 2)) + (key << 4);
	key = key ^ key >> 28;
	key = key + (key << 31);
	return key;
}
]] --not used (slower than default).

local test_speed_int64 = function(n, u)
	local gen_key = function(i) return `random(u) end
	return test_speed(int64, int32, gen_key, n)
end

local test_speed_int64_large = function(n, u)
	local gen_key = function(i) return `random(u) end
	return test_speed(int64, int32, gen_key, n, nil, nil, int64)
end

require_h'xxhash_h'
linklibrary'xxhash'

local test_speed_large = function(n, u, size, size_t)
	local struct T { a: uint8[size]; }
	local gen_key = function(i)
		return quote
			var key: T
			for i=0,size,8 do
				key.a[i] = random(u)
			end
			in key
		end
	end
	terra T:__hash32(d: uint32) return XXH32(self, sizeof(T), d) end
	terra T:__hash64(d: uint64) return XXH64(self, sizeof(T), d) end
	return test_speed(T, int32, gen_key, n, nil, nil, size_t)
end

local terra test_speed()
	var h = map(int32, int32)
	h:set(6, 7); assert(h:get(6, 0) == 7)
	h:set(7, 8)
	h:set(12, 13)
	assert(h:has(12))
	h:remove(7)
	assert(not h:has(7))
	assert(h:get(7, -1) == -1)
	pfn('count: %d', h.count)
	for k,v in h do
		pfn(' %4d -> %4d', @k, @v)
	end
	h:free()

	[test_speed_int32(1000000, 1000000 * .25)]
	[test_speed_int64(1000000, 1000000 * .25)]
	[test_speed_int64_large(1000000, 1000000 * .25)]
	[test_speed_large(100000, 2, 120, uint32)]
	[test_speed_large(100000, 2, 120, uint64)]
end

test_speed()
