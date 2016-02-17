
--BLAKE2 ffi binding.
--Writen by Cosmin Apreutesei. Public Domain.

local ffi = require'ffi'
local C = ffi.load'blake2'
local M = {C = C}

ffi.cdef[[
enum {
	BLAKE2S_BLOCKBYTES = 64,
	BLAKE2S_OUTBYTES   = 32,
	BLAKE2S_KEYBYTES   = 32,
	BLAKE2S_SALTBYTES  = 8,
	BLAKE2S_PERSONALBYTES = 8,
	BLAKE2B_BLOCKBYTES = 128,
	BLAKE2B_OUTBYTES   = 64,
	BLAKE2B_KEYBYTES   = 64,
	BLAKE2B_SALTBYTES  = 16,
	BLAKE2B_PERSONALBYTES = 16
};

#pragma pack(push, 1)
typedef struct __blake2s_param
{
	uint8_t  digest_length; // 1
	uint8_t  key_length;    // 2
	uint8_t  fanout;        // 3
	uint8_t  depth;         // 4
	uint32_t leaf_length;   // 8
	uint8_t  node_offset[6];// 14
	uint8_t  node_depth;    // 15
	uint8_t  inner_length;  // 16
	// uint8_t  reserved[0];
	uint8_t  salt[BLAKE2S_SALTBYTES]; // 24
	uint8_t  personal[BLAKE2S_PERSONALBYTES];  // 32
} blake2s_param;

typedef struct __blake2s_state
{
	uint32_t h[8];
	uint32_t t[2];
	uint32_t f[2];
	uint8_t  buf[2 * BLAKE2S_BLOCKBYTES];
	uint32_t buflen;
	uint8_t  outlen;
	uint8_t  last_node;
} blake2s_state;

typedef struct __blake2b_param
{
	uint8_t  digest_length; // 1
	uint8_t  key_length;    // 2
	uint8_t  fanout;        // 3
	uint8_t  depth;         // 4
	uint32_t leaf_length;   // 8
	uint64_t node_offset;   // 16
	uint8_t  node_depth;    // 17
	uint8_t  inner_length;  // 18
	uint8_t  reserved[14];  // 32
	uint8_t  salt[BLAKE2B_SALTBYTES]; // 48
	uint8_t  personal[BLAKE2B_PERSONALBYTES];  // 64
} blake2b_param;

typedef struct __blake2b_state
{
	uint64_t h[8];
	uint64_t t[2];
	uint64_t f[2];
	uint8_t  buf[2 * BLAKE2B_BLOCKBYTES];
	uint32_t buflen;
	uint8_t  outlen;
	uint8_t  last_node;
} blake2b_state;

typedef struct __blake2sp_state
{
	blake2s_state S[8][1];
	blake2s_state R[1];
	uint8_t  buf[8 * BLAKE2S_BLOCKBYTES];
	uint32_t buflen;
	uint8_t  outlen;
} blake2sp_state;

typedef struct __blake2bp_state
{
	blake2b_state S[4][1];
	blake2b_state R[1];
	uint8_t  buf[4 * BLAKE2B_BLOCKBYTES];
	uint32_t buflen;
	uint8_t  outlen;
} blake2bp_state;
#pragma pack(pop)

// Streaming API

int blake2s_init       ( blake2s_state *S, size_t outlen );
int blake2s_init_key   ( blake2s_state *S, size_t outlen, const void *key, size_t keylen );
int blake2s_init_param ( blake2s_state *S, const blake2s_param *P );
int blake2s_update     ( blake2s_state *S, const uint8_t *in, size_t inlen );
int blake2s_final      ( blake2s_state *S, uint8_t *out, size_t outlen );

int blake2b_init       ( blake2b_state *S, size_t outlen );
int blake2b_init_key   ( blake2b_state *S, size_t outlen, const void *key, size_t keylen );
int blake2b_init_param ( blake2b_state *S, const blake2b_param *P );
int blake2b_update     ( blake2b_state *S, const uint8_t *in, size_t inlen );
int blake2b_final      ( blake2b_state *S, uint8_t *out, size_t outlen );

int blake2sp_init      ( blake2sp_state *S, size_t outlen );
int blake2sp_init_key  ( blake2sp_state *S, size_t outlen, const void *key, size_t keylen );
int blake2sp_update    ( blake2sp_state *S, const uint8_t *in, size_t inlen );
int blake2sp_final     ( blake2sp_state *S, uint8_t *out, size_t outlen );

int blake2bp_init      ( blake2bp_state *S, size_t outlen );
int blake2bp_init_key  ( blake2bp_state *S, size_t outlen, const void *key, size_t keylen );
int blake2bp_update    ( blake2bp_state *S, const uint8_t *in, size_t inlen );
int blake2bp_final     ( blake2bp_state *S, uint8_t *out, size_t outlen );

// Simple API

int blake2s  ( uint8_t *out, const void *in, const void *key, size_t outlen, size_t inlen, size_t keylen );
int blake2b  ( uint8_t *out, const void *in, const void *key, size_t outlen, size_t inlen, size_t keylen );
int blake2sp ( uint8_t *out, const void *in, const void *key, size_t outlen, size_t inlen, size_t keylen );
int blake2bp ( uint8_t *out, const void *in, const void *key, size_t outlen, size_t inlen, size_t keylen );
]]

local _ = string.format

local function check(ret)
	if ret == 0 then return end
	error('blake2 error '..ret)
end

local outlens = {
	s  = C.BLAKE2S_OUTBYTES,
	b  = C.BLAKE2B_OUTBYTES,
	sp = C.BLAKE2S_OUTBYTES,
	bp = C.BLAKE2B_OUTBYTES,
}
local blocklens = {
	s  = C.BLAKE2S_BLOCKBYTES,
	b  = C.BLAKE2B_BLOCKBYTES,
	sp = C.BLAKE2S_BLOCKBYTES,
	bp = C.BLAKE2B_BLOCKBYTES,
}
local parambufs = {
	s = ffi.new'blake2s_param',
	b = ffi.new'blake2b_param',
}
parambufs.sp = parambufs.s
parambufs.bp = parambufs.b

local outbuf = ffi.new('uint8_t[?]', C.BLAKE2B_BLOCKBYTES)

local function copystr(buf, s, maxsz)
	ffi.fill(buf, maxsz)
	if s and #s > 0 then
		ffi.copy(buf, s, math.min(#s, maxsz))
	end
end

local function mkdigest(V)

	local P          = not V:find'p'
	local state_ct   = ffi.typeof(_('blake2%s_state', V))
	local init       = C[_('blake2%s_init', V)]
	local init_key   = C[_('blake2%s_init_key', V)]
	local init_param = P and C[_('blake2%s_init_param', V)]
	local update     = C[_('blake2%s_update', V)]
	local final      = C[_('blake2%s_final', V)]
	local param      = P and parambufs[V]
	local max_outlen = outlens[V]
	local blocklen   = blocklens[V]

	local state = {}
	state.__index = state

	function state.reset(S, key, outlen)
		if type(key) == 'table' then
			if not P then
				error(_('options table not supported with blake2%s', V))
			end
			local t = key
			param.digest_length = t.hash_length or max_outlen
			param.key_length = t.key and #t.key or 0
			param.fanout = t.fanout or 1
			param.depth = t.depth or 1
			param.leaf_length = t.leaf_length or 0
			if ffi.istype('uint64_t', param.node_offset) then
				param.node_offset = t.node_offset or 0
			else --48-bit uint
				ffi.cast('uint64_t*', outbuf)[0] = t.node_offset or 0
				ffi.copy(param.node_offset, outbuf, 6) --assuming little endian
			end
			param.node_depth = t.node_depth or 0
			param.inner_length = t.inner_length or 0
			copystr(param.salt, t.salt, ffi.sizeof(param.salt))
			copystr(param.personal, t.personal, ffi.sizeof(param.personal))
			check(init_param(S, param))
			if t.key then
				copystr(outbuf, t.key, blocklen)
				update(S, outbuf, blocklen)
				copystr(outbuf, nil, blocklen)
			end
		elseif key then
			check(init_key(S, outlen or max_outlen, key, #key))
		else
			check(init(S, outlen or max_outlen))
		end
	end

	function state.update(S, data, size)
		check(update(S, data, size or #data))
	end

	function state.final(S)
		check(final(S, outbuf, S.outlen))
		return ffi.string(outbuf, S.outlen)
	end

	function state:__call(data, size)
		if data then
			self:update(data, size)
		else
			return self:final()
		end
	end

	ffi.metatype(state_ct, state)

	return function(key)
		local S = state_ct()
		S:reset(key)
		return S
	end
end

local function mksum(V)
	local sum = C[_('blake2%s', V)]
	local max_outlen = outlens[V]
	return function(data, size, key, outlen)
		outlen = outlen or max_outlen
		check(sum(outbuf, data, key, outlen, size or #data, key and #key or 0))
		return ffi.string(outbuf, outlen)
	end
end

for i,V in ipairs{'s', 'b', 'sp', 'bp'} do
	M[_('blake2%s_digest', V)] = mkdigest(V)
	M[_('blake2%s', V)] = mksum(V)
end


if not ... then

	local blake2 = M
	local glue = require'glue'

	for _,V in ipairs{'s', 'b', 'sp', 'bp'} do
		local d, k, h
		local n = 0
		for s in io.lines(string.format('media/blake2/blake2%s-test.txt', V)) do
			d = s:match'^in:%s*(.*)' or d
			k = s:match'^key:%s*(.*)' or k
			h = s:match'^hash:%s*(.*)' or h
			if s:match'^hash:' then
				d = glue.fromhex(d)
				k = glue.fromhex(k)
				h = glue.fromhex(h:gsub('ok', ''))

				--test simple API
				assert(blake2['blake2'..V](d, nil, k) == h)

				--test streaming API / blake2x_init_key() branch
				local digest = blake2['blake2'..V..'_digest'](k); digest(d)
				assert(digest() == h)

				--test streaming API / blake2x_init_param() branch
				if not V:find'p' then
					local digest = blake2['blake2'..V..'_digest']({key = k}); digest(d)
					assert(digest() == h)
				end

				n = n + 1
			end
		end
		print(V, n..' tests passed')
	end

end


return M
