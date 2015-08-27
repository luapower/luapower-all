--benchmark for the included hash functions.
local ffi = require'ffi'
require'unit'

local function benchmark(s, hash)
	if not hash then return end
	timediff()
	local sz = 1024^2
	local iter = 1024
	local key = ffi.new('uint8_t[?]', sz)
	for i=0,sz-1 do key[i] = i % 256 end
	local h = 0
	for i=1,iter do
		h = hash(key, sz, h)
	end
	print(string.format('%s  %8.2f MB/s', s, fps(sz*iter)/sz))
end

benchmark('murmurhash3 Lua', require'murmurhash3')
benchmark('murmurhash3 C  ', require'pmurhash')
benchmark('md5 C          ', require'md5'.sum)
benchmark('crc32 C        ', require'zlib'.crc32)
benchmark('crc32 Lua      ', require'crc32')
benchmark('adler32 C      ', require'zlib'.adler32)
benchmark('sha256 C       ', require'sha2'.sha256)
benchmark('sha384 C       ', require'sha2'.sha384)
benchmark('sha512 C       ', require'sha2'.sha512)
