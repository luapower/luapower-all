--[[

	Minimal Perfect Hash Function Generator for Lua/Terra.
	Written by Cosmin Apreutesei. Public Domain.

	Generation at compile-time in Lua, lookup at runtime in Terra.
	Supports Lua string keys and any-fixed-size-type keys and values.
	It's particularly fast with (u)int32 keys.
	Algorithm from http://stevehanov.ca/blog/index.php?id=119.

	TODO: generate C switch code see if LLVM converts it to phf and check speed.
	TODO: generate Terra if/else code and see if LLVM can see it as a switch.
	TODO: test/compare all with binsearch and linear-search-with-a-sentinel.

]]

if not ... then require'terra.phf_test'; return end

setfenv(1, require'terra.low')

local hash = {} --{name->hash(data: &opaque, len: int32, d: uint32)}

--31-bit FNV-1A hash. Good for strings, too slow for integers.
terra hash.fnv_1a(s: &opaque, len: int32, d: uint32): uint32
	if d == 0 then d = 0x811C9DC5 end
	for i = 0, len do
		d = ((d ^ [&uint8](s)[i]) * 16777619) and 0x7fffffff
	end
	return d
end

--Knuth's multiplicative hash for (u)int32 keys.
terra hash.mul_int32(n: &opaque, len: int32, d: uint32): uint32
	return (@[&uint32](n) * 2654435769ULL) >> (32 - d)
end

--Generate a O(1) `lookup(k: ktype) -> vtype` for a const table `t = {k->v}`.
--NOTE: One value must be specified as invalid and not used (defaults to 0/nil)!
--NOTE: The lookup function should not be used with a missing key (it will
--return a random value from the initial set). See `phf_nofp` below for that.
local function phf_fp(t, ktype, vtype, invalid_value, thash)
	thash = thash
		or ((ktype == int32 or ktype == uint32) and 'mul_int32' or 'fnv_1a')
	thash = hash[thash] or thash
	if invalid_value == nil and not vtype:ispointer() then
		invalid_value = 0
	end
	local hash
	if ktype == 'string' then
		hash = function(s, d)
			return thash(cast('void*', s), #s, d or 0)
		end
	else
		local valbuf = terralib.new(ktype[1])
		hash = function(v, d)
			valbuf[0] = v
			return thash(valbuf, sizeof(ktype), d or 0)
		end
	end

	local n = 0
	for k,v in pairs(t) do
		assert(v ~= invalid_value)
		n = n + 1
	end

	--Optimization: by increasing n to the next number that is a power of 2
	--we enable the strength reduction compiler optimization that transforms
	--the 10x slower modulo into bit shifting. NOTE: this only works when
	--dividing an unsigned type by a literal!
	n = nextpow2(n)

	local G = terralib.new(int32[n]) --{slot -> d|-d-1}
	local V = terralib.new(vtype[n], invalid_value) --{d|-d-1 -> val}

	--place all keys into buckets and sort the buckets
	--so that the buckets with most keys are processed first.
	local buckets = {} --{hash -> {k1, ...}}
	for i = 1, n do
		buckets[i] = {}
	end
	for k in pairs(t) do
		push(buckets[(hash(k) % n) + 1], k)
	end
	table.sort(buckets, function(a, b) return #a > #b end)

	local tries = 0
	local maxtries = 0
	for b = 1, n do
		local bucket = buckets[b]
		if #bucket > 1 then
			--bucket has multiple keys: try different values of d until
			--a perfect hash function is found for those keys.
			local d = 1
			local slots = {} --{slot1,...}
			local i = 1
			while i <= #bucket do
				local slot = hash(bucket[i], d) % n
				if V[slot] ~= invalid_value or indexof(slot, slots) then
					if d >= 32 then
						error('could not find a phf in '..d..' tries for key '..bucket[i])
					end
					d = d + 1
					tries = tries + 1
					i = 1
					slots = {}
				else
					push(slots, slot)
					i = i + 1
				end
			end
			maxtries = math.max(d, maxtries)
			G[hash(bucket[1]) % n] = d
			for i = 1, #bucket do
				V[slots[i]] = t[bucket[i]]
			end
		else
			--place all buckets with one key directly into a free slot.
			--use a negative value of d to indicate that.
			local freelist = {} --{slot1, ...}
			for slot = 0, n-1 do
				if V[slot] == invalid_value then
					push(freelist, slot)
				end
			end
			for b = b, n do
				local bucket = buckets[b]
				if #bucket == 0 then
					break
				end
				local slot = pop(freelist)
				G[hash(bucket[1]) % n] = -slot-1
				V[slot] = t[bucket[1]]
			end
			break
		end
	end

	local G = constant(G)
	local V = constant(V)
	local hash = thash
	local lookup
	if ktype == 'string' then
		terra lookup(k: rawstring, len: int32)
			var d = G[hash(k, len, 0) % n]
			if d < 0 then
				return V[-d-1]
			else
				return V[hash(k, len, d) % n]
			end
		end
	else
		terra lookup(k: ktype)
			var d = G[hash(&k, sizeof(ktype), 0) % n]
			if d < 0 then
				return V[-d-1]
			else
				return V[hash(&k, sizeof(ktype), d) % n]
			end
		end
	end

	return lookup, tries, maxtries
end

--PHF that can report missing keys by keeping the keys and validating them.
--TODO: create a const string array for string keys.
local function phf_nofp(t, ktype, vtype, invalid_value, thash)
	if invalid_value == nil and not vtype:ispointer() then
		invalid_value = 0
	end
	local n = count(t)
	local it = {} --{key -> index_in_vt}
	local str = ktype == 'string'
	local Ktype = str and rawstring or ktype
	local K = terralib.new(Ktype[n]) --{index -> key}
	local V = terralib.new(vtype[n]) --{index -> val}
	local i = 0
	for k,v in pairs(t) do
		it[k] = i
		K[i] = k
		V[i] = v
		i = i + 1
	end
	local lookup_fp, tries, maxtries = phf_fp(it, ktype, int32, -1, thash)
	local K = constant(K)
	local V = constant(V)
	local lookup
	if str then
		local C = terralib.includec'string.h'
		lookup = terra(k: rawstring, len: int32)
			var i = lookup_fp(k, len)
			if C.memcmp(k, K[i], len) == 0 then
				return V[i]
			else
				return invalid_value
			end
		end
	else
		lookup = terra(k: ktype)
			var i = lookup_fp(k)
			if K[i] == k then
				return V[i]
			else
				return invalid_value
			end
		end
	end
	return lookup, tries, maxtries
end

phf = function(t, ktype, vtype, invalid_value, complete_set, thash)
	local phf = complete_set and phf_fp or phf_nofp
	return phf(t, ktype, vtype, invalid_value, thash)
end
