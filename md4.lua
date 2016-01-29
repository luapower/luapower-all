--md4 hash and digest
local ffi = require "ffi"
local C = ffi.load'md4'

ffi.cdef[[
/* Any 32-bit or wider unsigned integer data type will do */
typedef unsigned int MD4_u32plus;

typedef struct {
	uint32_t lo, hi;
	uint32_t a, b, c, d;
	uint8_t buffer[64];
	uint32_t block[16];
} MD4_CTX;

void MD4_Init(MD4_CTX *ctx);
void MD4_Update(MD4_CTX *ctx, const void *data, unsigned long size);
void MD4_Final(unsigned char *result, MD4_CTX *ctx);
]]

local function digest()
	local ctx = ffi.new'MD4_CTX'
	local result = ffi.new'uint8_t[16]'
	C.MD4_Init(ctx)
	return function(data, size)
		if data then
			C.MD4_Update(ctx, data, size or #data)
		else
			C.MD4_Final(result, ctx)
			return ffi.string(result, 16)
		end
	end
end

local function sum(data, size)
	local d = digest(); d(data, size); return d()
end

if not ... then require'md4_test' end

return {
	digest = digest,
	sum = sum,
	C = C,
}

