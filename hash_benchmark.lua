--benchmark for the included hash functions.
local ffi = require'ffi'
local time = require'time'

if ... then return end --prevent loading as module

io.stdout:setvbuf'no'
io.stderr:setvbuf'no'

local function benchmark(s, hash, iter)
	if not hash then return end
	local sz = 1024^2 * 10
	local iter = iter or 100
	local key = ffi.new('uint8_t[?]', sz)
	for i=0,sz-1 do key[i] = i % 256 end
	local h = 0
	local t0 = time.clock()
	for i=1,iter do
		h = hash(key, sz, h)
	end
	local t1 = time.clock()
	print(string.format('%s  %8.2f MB/s (%s)', s,
		(sz * iter) / 1024^2 / (t1 - t0),
		type(h) == 'string' and (#h * 8)..' bits' or type(h)))
	collectgarbage()
end

local b2 = require'blake2'
local b2b  = function(buf, sz) return b2.blake2b(buf,  sz) end
local b2s  = function(buf, sz) return b2.blake2s(buf,  sz) end
local b2bp = function(buf, sz) return b2.blake2bp(buf, sz) end
local b2sp = function(buf, sz) return b2.blake2sp(buf, sz) end
benchmark('BLAKE2b        ', b2b)
benchmark('BLAKE2s        ', b2s)
benchmark('BLAKE2bp       ', b2bp)
benchmark('BLAKE2sp       ', b2sp)
--benchmark('murmurhash3 C  ', require'pmurhash', 2048)
benchmark('md5 C          ', require'md5'.sum)
benchmark('crc32 C        ', require'zlib'.crc32)
benchmark('xxHash32 C     ', require'xxhash'.hash32, 4096)
benchmark('xxHash64 C     ', require'xxhash'.hash64, 4096)
benchmark('adler32 C      ', require'zlib'.adler32, 2048)
benchmark('sha256 C       ', require'sha2'.sha256, 256)
benchmark('sha384 C       ', require'sha2'.sha384, 256)
benchmark('sha512 C       ', require'sha2'.sha512, 256)
