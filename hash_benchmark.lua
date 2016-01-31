--benchmark for the included hash functions.
local ffi = require'ffi'
local time = require'time'

local function benchmark(s, hash, iter)
	if not hash then return end
	local t0 = time.clock()
	local sz = 1024^2
	local iter = iter or 1024
	local key = ffi.new('uint8_t[?]', sz)
	for i=0,sz-1 do key[i] = i % 256 end
	local h = 0
	for i=1,iter do
		h = hash(key, sz, h)
	end
	print(string.format('%s  %8.2f MB/s (%s)', s,
		(sz * iter) / 1024^2 / (time.clock() - t0),
		type(h) == 'string' and (#h * 8)..' bits' or type(h)))
end

benchmark('murmurhash3 Lua', require'murmurhash3')
benchmark('murmurhash3 C  ', require'pmurhash', 2048)
benchmark('md4 C          ', require'md4'.sum)
benchmark('md5 C          ', require'md5'.sum)
benchmark('crc32 C        ', require'zlib'.crc32)
benchmark('crc32 Lua      ', require'crc32', 256)
benchmark('xxHash32 C     ', require'xxhash'.hash32, 4096)
benchmark('xxHash64 C     ', require'xxhash'.hash64, 4096)
benchmark('adler32 C      ', require'zlib'.adler32, 2048)
benchmark('sha256 C       ', require'sha2'.sha256, 256)
benchmark('sha384 C       ', require'sha2'.sha384, 256)
benchmark('sha512 C       ', require'sha2'.sha512, 256)
