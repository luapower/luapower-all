
--xxhash binding

local ffi = require'ffi'
local bit = require'bit'
local C = ffi.load'xxhash'
local M = {C = C}
ffi.cdef[[
unsigned XXH_versionNumber(void);

typedef union {
	uint64_t u64[2];
	uint32_t u32[4];
	uint8_t u8[16];
} XXH128_hash_t;

uint32_t      XXH32 (const void* input, size_t length, uint32_t seed);
uint64_t      XXH64 (const void* input, size_t length, uint64_t seed);
XXH128_hash_t XXH128(const void* input, size_t length, uint64_t seed);

XXH128_hash_t XXH3_128bits_withSecret(const void* data, size_t len, const void* secret, size_t secretSize);

typedef enum { XXH_OK=0, XXH_ERROR } XXH_errorcode;

typedef struct XXH3_state_s XXH3_state_t;
XXH3_state_t* XXH3_createState(void);
XXH_errorcode XXH3_freeState(XXH3_state_t* statePtr);
void XXH3_copyState(XXH3_state_t* dst_state, const XXH3_state_t* src_state);

XXH_errorcode XXH3_128bits_reset(XXH3_state_t* statePtr);
XXH_errorcode XXH3_128bits_reset_withSeed(XXH3_state_t* statePtr, uint64_t seed);
XXH_errorcode XXH3_128bits_reset_withSecret(XXH3_state_t* statePtr, const void* secret, size_t secretSize);

XXH_errorcode XXH3_128bits_update (XXH3_state_t* statePtr, const void* input, size_t length);
XXH128_hash_t XXH3_128bits_digest (const XXH3_state_t* statePtr);
]]

M.version = C.XXH_versionNumber

function M.hash32 (data, sz, seed) return C.XXH32 (data, sz or #data, seed or 0) end
function M.hash64 (data, sz, seed) return C.XXH64 (data, sz or #data, seed or 0) end
function M.hash128(data, sz, seed) return C.XXH128(data, sz or #data, seed or 0) end

local h = {}

function h:bin()
	return ffi.string(self, 16)
end

function h:hex()
	local h = bit.tohex
	return
		h(self.u32[0])..
		h(self.u32[1])..
		h(self.u32[2])..
		h(self.u32[3])
end

ffi.metatype('XXH128_hash_t', {__index = h})

local st = {}
local st_meta = {__index = st}

function st:free()
	assert(C.XXH3_freeState(self) == 0)
end
st_meta.__gc = st.free

function st:reset(seed)
	assert(C.XXH3_128bits_reset_withSeed(self, seed or 0) == 0)
	return self
end

function st:update(s, len)
	assert(C.XXH3_128bits_update(self, s, len or #s) == 0)
	return self
end

function st:digest()
	return C.XXH3_128bits_digest(self)
end

function M.hash128_digest(seed)
	local st = C.XXH3_createState()
	assert(st ~= nil)
	return st:reset(seed)
end

ffi.metatype('XXH3_state_t', st_meta)

if not ... then
	local st = M.hash128_digest()
	st:update('abcd')
	st:update('1324')
	assert(st:digest():bin() == M.hash128('abcd1324'):bin())
	assert(st:digest():hex() == M.hash128('abcd1324'):hex())
end

return M

