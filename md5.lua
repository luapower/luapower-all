--md5 hash and digest
local ffi = require "ffi"
local C = ffi.load'md5'

if not ... then
	require'md5_test'
	require'md5_hmac_test'
	return
end

ffi.cdef[[
typedef struct {
	uint32_t lo, hi;
	uint32_t a, b, c, d;
	uint8_t buffer[64];
	uint32_t block[16];
} MD5_CTX;

void MD5_Init(MD5_CTX *ctx);
void MD5_Update(MD5_CTX *ctx, const uint8_t *data, uint32_t size);
void MD5_Final(const uint8_t *result, MD5_CTX *ctx);
]]

local function digest()
	local ctx = ffi.new'MD5_CTX'
	local result = ffi.new'uint8_t[16]'
	C.MD5_Init(ctx)
	return function(data, size)
		if data then
			C.MD5_Update(ctx, data, size or #data)
		else
			C.MD5_Final(result, ctx)
			return ffi.string(result, 16)
		end
	end
end

local function sum(data, size)
	local d = digest(); d(data, size); return d()
end

local md5 = {
	digest = digest,
	sum = sum,
	C = C,
}

function md5.hmac(message, key)
   local hmac = require'hmac'
   md5.hmac = hmac.new(sum, 64)
   return md5.hmac(message, key)
end

return md5
