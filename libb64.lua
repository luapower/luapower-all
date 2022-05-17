--libb64 ffi binding
local ffi = require'ffi'
local C = ffi.load'b64'

ffi.cdef[[
typedef struct
{
	int step;
	char plainchar;
} base64_decodestate;

void base64_init_decodestate(base64_decodestate* state_in);
int base64_decode_value(char value_in);
int base64_decode_block(const char* code_in, const int length_in, char* plaintext_out, base64_decodestate* state_in);

typedef struct
{
	int step;
	char result;
	int stepcount;
} base64_encodestate;

void base64_init_encodestate(base64_encodestate* state_in);
char base64_encode_value(char value_in);
int base64_encode_block(const char* plaintext_in, int length_in, char* code_out, base64_encodestate* state_in);
int base64_encode_blockend(char* code_out, base64_encodestate* state_in);
]]

local function decode_tobuffer(data, size, buf, sz)
	size = size or #data
	if size == 0 then return 0 end
	assert(sz >= math.floor(size * 3 / 4), 'buffer too small')
	local state_in = ffi.new'base64_decodestate'
	C.base64_init_decodestate(state_in)
	return C.base64_decode_block(data, size, buf, state_in)
end

local function decode(data, size)
	size = size or #data
	if size == 0 then return '' end
	local sz = math.floor(size * 3 / 4)
	local buf = ffi.new('uint8_t[?]', sz)
	sz = decode_tobuffer(data, size, buf, sz)
	return ffi.string(buf, sz)
end

local function encode_tobuffer(data, size, buf, sz)
	size = size or #data
	if size == 0 then return 0 end
	assert(sz >= size * 2 + 3, 'buffer too small')
	local state_in = ffi.new'base64_encodestate'
	C.base64_init_encodestate(state_in)
	local sz = C.base64_encode_block(data, size, buf, state_in)
	sz = sz + C.base64_encode_blockend(buf + sz, state_in)
	buf[sz-1] = 0 --replace \n
	return sz-1
end

local function encode(data, size)
	size = size or #data
	if size == 0 then return '' end
	local sz = size * 2 + 3
	local buf = ffi.new('uint8_t[?]', sz)
	sz = encode_tobuffer(data, size, buf, sz)
	return ffi.string(buf, sz)
end

if not ... then require'libb64_test' end

return {
	decode_tobuffer = decode_tobuffer,
	decode = decode,
	encode_tobuffer = encode_tobuffer,
	encode = encode,
	C = C,
}
