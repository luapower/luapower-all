--[[

	Tausworthe PRNG in Terra.
	Written by Cosmin Apreutesei. Public Domain.
	Translated from LuaJIT's lib_math.c Copyright (C) 2005-2017 Mike Pall.

	TODO: how to use thread-local vars in Terra for the global RandomState?

	This implements a Tausworthe PRNG with period 2^223. Based on:
		Tables of maximally-equidistributed combined LFSR generators,
		Pierre L'Ecuyer, 1991, table 3, 1st entry.
	Full-period ME-CF generator with L=64, J=4, k=223, N1=49.

]]

if not ... then require'terra.random_test'; return end

setfenv(1, require'terra.low')

-- PRNG state.
local struct RandomState {
	gen: uint64[4]; -- State of the 4 LFSR generators.
	valid: bool;    -- State is valid.
};

local rs = global(`RandomState {gen = arrayof(uint64, 0, 0, 0, 0), valid = false})

-- Union needed for bit-pattern conversion between uint64 and double.
local struct U64double { union { u64: uint64; d: double } }

-- Update generator i and compute a running xor of all states.
local TW223_GEN = macro(function(z, r, i, k, q, s)
	return quote
		z = rs.gen[i]
		z = (((z<<q)^z) >> (k-s)) ^ ((z and ([uint64]([int64](-1)) << (64-k)))<<s)
		r = r ^ z; rs.gen[i] = z
	end
end)
-- PRNG step function. Returns a double in the range 1.0 <= d < 2.0.
local terra random_step(): uint64
	var z: uint64
	var r: uint64 = 0
	TW223_GEN(z, r, 0, 63, 31, 18)
	TW223_GEN(z, r, 1, 58, 19, 28)
	TW223_GEN(z, r, 2, 55, 24,  7)
	TW223_GEN(z, r, 3, 47, 21,  8)
	return (r and 0x000fffffffffffffULL) or 0x3ff0000000000000ULL
end

-- PRNG initialization/seed function.
local terra randomseed(d: double)
	var r: uint32 = 0x11090601 -- 64-k[i] as four 8 bit constants.
	for i = 0, 4 do
		var u: U64double
		var m: uint32 = 1u << (r and 255)
		r = r >> 8
		d = d * 3.14159265358979323846 + 2.7182818284590452354
		u.d = d
		if u.u64 < m then
			u.u64 = u.u64 + m -- Ensure k[i] MSB of gen[i] are non-zero.
		end
		rs.gen[i] = u.u64
	end
	rs.valid = true
	for i = 0, 10 do
		random_step()
	end
end

-- PRNG extract function.
local terra random(): double
	if not rs.valid then randomseed(0.0) end
	var u: U64double; u.u64 = random_step()
	return u.d - 1.0 -- d is a double in range [0, 1]
end

_M.random = macro(function(n, m)
	if n and m then -- integer range [n, m]
		return quote
			var n = n
			in floor(random()*(m-n+1.0)) + n
		end
	elseif n then -- integer range [1, n-1]
		return `floor(random()*n)
	else -- double range [0, 1)
		return `random()
	end
end, math.random)

_M.randomseed = macro(function(n)
	n = n or 0
	return `randomseed(n)
end, math.randomseed)
