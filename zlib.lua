
--zlib binding.
--Written by Cosmin Apreutesei. Public Domain.

local ffi = require'ffi'
require'zlib_h'
local C = ffi.load'z'

local function version()
	return ffi.string(C.zlibVersion())
end

local function checkz(ret)
	if ret == 0 then return end
	error(ffi.string(C.zError(ret)))
end

local function flate(api)
	return function(...)
		local ret = api(...)
		if ret == 0 then return true end
		if ret == C.Z_STREAM_END then return false end
		checkz(ret)
	end
end

local deflate = flate(C.deflate)
local inflate = flate(C.inflate)

--FUN TIME: windowBits is range 8..15 (default = 15) but can also be -8..15
--for raw deflate with no zlib header or trailer and can also be greater than
--15 which reads/writes a gzip header and trailer instead of a zlib wrapper.
--so I added a format parameter which can be 'deflate', 'zlib', 'gzip'
--(default = 'zlib') to cover all the cases so that windowBits can express
--only the window bits in the initial 8..15 range. additionally for inflate,
--windowBits can be 0 which means use the value in the zlib header of the
--compressed stream.

local function format_windowBits(format, windowBits)
	if format == 'gzip' then windowBits = windowBits + 16 end
	if format == 'deflate' then windowBits = -windowBits end
	return windowBits
end

local function init_deflate(format, level, method, windowBits, memLevel, strategy)
	level = level or C.Z_DEFAULT_COMPRESSION
	method = method or C.Z_DEFLATED
	windowBits = format_windowBits(format, windowBits or C.Z_MAX_WBITS)
	memLevel = memLevel or 8
	strategy = strategy or C.Z_DEFAULT_STRATEGY

	local strm = ffi.new'z_stream'
	checkz(C.deflateInit2_(strm, level, method, windowBits, memLevel, strategy, version(), ffi.sizeof(strm)))
	ffi.gc(strm, C.deflateEnd)
	return strm, deflate
end

local function init_inflate(format, windowBits)
	windowBits = format_windowBits(format, windowBits or C.Z_MAX_WBITS)

	local strm = ffi.new'z_stream'
	checkz(C.inflateInit2_(strm, windowBits, version(), ffi.sizeof(strm)))
	ffi.gc(strm, C.inflateEnd)
	return strm, inflate
end

local function inflate_deflate(init)
	return function(read, write, bufsize, ...)
		bufsize = bufsize or 16384

		local strm, flate = init(...)

		local buf = ffi.new('uint8_t[?]', bufsize)
		strm.next_out, strm.avail_out = buf, bufsize
		strm.next_in, strm.avail_in = nil, 0

		if type(read) == 'string' then
			local s = read
			local done
			read = function()
				if done then return end
				done = true
				return s
			end
		elseif type(read) == 'table' then
			local t = read
			local i = 0
			read = function()
				i = i + 1
				return t[i]
			end
		end

		local t
		local asstring = write == ''
		if type(write) == 'table' or asstring then
			t = asstring and {} or write
			write = function(data, sz)
				t[#t+1] = ffi.string(data, sz)
			end
		end

		local function flush()
			local sz = bufsize - strm.avail_out
			if sz == 0 then return end
			write(buf, sz)
			strm.next_out, strm.avail_out = buf, bufsize
		end

		local data, size --data must be anchored as an upvalue!
		while true do
			if strm.avail_in == 0 then --input buffer empty: refill
				data, size = read()
				if not data then --eof: finish up
					local ret
					repeat
						flush()
					until not flate(strm, C.Z_FINISH)
					flush()
					break
				end
				strm.next_in, strm.avail_in = data, size or #data
			end
			flush()
			if not flate(strm, C.Z_NO_FLUSH) then
				flush()
				break
			end
		end

		if asstring then
			return table.concat(t)
		else
			return t
		end
	end
end

--inflate(read, write[, bufsize][, format][, windowBits])
local inflate = inflate_deflate(init_inflate)
--deflate(read, write[, bufsize][, format][, level][, windowBits][, memLevel][, strategy])
local deflate = inflate_deflate(init_deflate)

--utility functions

local function compress_tobuffer(data, size, level, buf, sz)
	level = level or -1
	sz = ffi.new('unsigned long[1]', sz)
	checkz(C.compress2(buf, sz, data, size, level))
	return sz[0]
end

local function compress(data, size, level)
	size = size or #data
	local sz = C.compressBound(size)
	local buf = ffi.new('uint8_t[?]', sz)
	sz = compress_tobuffer(data, size, level, buf, sz)
	return ffi.string(buf, sz)
end

local function uncompress_tobuffer(data, size, buf, sz)
	sz = ffi.new('unsigned long[1]', sz)
	checkz(C.uncompress(buf, sz, data, size))
	return sz[0]
end

local function uncompress(data, size, sz)
	local buf = ffi.new('uint8_t[?]', sz)
	sz = uncompress_tobuffer(data, size or #data, buf, sz)
	return ffi.string(buf, sz)
end

--gzip file access functions

local function checkz(ret) assert(ret == 0) end
local function checkminus1(ret) assert(ret ~= -1); return ret end
local function ptr(o) return o ~= nil and o or nil end

local function gzclose(gzfile)
	checkz(C.gzclose(gzfile))
	ffi.gc(gzfile, nil)
end

local function gzopen(filename, mode, bufsize)
	local gzfile = ptr(C.gzopen(filename, mode or 'r'))
	if not gzfile then
		return nil, string.format('errno %d', ffi.errno())
	end
	ffi.gc(gzfile, gzclose)
	if bufsize then C.gzbuffer(gzfile, bufsize) end
	return gzfile
end

local flush_enum = {
	none    = C.Z_NO_FLUSH,
	partial = C.Z_PARTIAL_FLUSH,
	sync    = C.Z_SYNC_FLUSH,
	full    = C.Z_FULL_FLUSH,
	finish  = C.Z_FINISH,
	block   = C.Z_BLOCK,
	trees   = C.Z_TREES,
}

local function gzflush(gzfile, flush)
	checkz(C.gzflush(gzfile, flush_enum[flush]))
end

local function gzread_tobuffer(gzfile, buf, sz)
	return checkminus1(C.gzread(gzfile, buf, sz))
end

local function gzread(gzfile, sz)
	local buf = ffi.new('uint8_t[?]', sz)
	return ffi.string(buf, gzread_tobuffer(gzfile, buf, sz))
end

local function gzwrite(gzfile, data, sz)
	sz = C.gzwrite(gzfile, data, sz or #data)
	if sz == 0 then return nil,'error' end
	return sz
end

local function gzeof(gzfile)
	return C.gzeof(gzfile) == 1
end

local function gzseek(gzfile, ...)
	local narg = select('#',...)
	local whence, offset
	if narg == 0 then
		whence, offset = 'cur', 0
	elseif narg == 1 then
		if type(...) == 'string' then
			whence, offset = ..., 0
		else
			whence, offset = 'cur',...
		end
	else
		whence, offset = ...
	end
	whence = assert(whence == 'set' and 0 or whence == 'cur' and 1)
	return checkminus1(C.gzseek(gzfile, offset, whence))
end

local function gzoffset(gzfile)
	return checkminus1(C.gzoffset(gzfile))
end

ffi.metatype('gzFile_s', {__index = {
	close = gzclose,
	read = gzread,
	write = gzwrite,
	flush = gzflush,
	eof = gzeof,
	seek = gzseek,
	offset = gzoffset,
}})

--checksum functions

local function adler32(data, sz, adler)
	adler = adler or C.adler32(0, nil, 0)
	return tonumber(C.adler32(adler, data, sz or #data))
end

local function crc32(data, sz, crc)
	crc = crc or C.crc32(0, nil, 0)
	return tonumber(C.crc32(crc, data, sz or #data))
end

if not ... then require'zlib_test' end

return {
	C = C,
	version = version,
	inflate = inflate,
	deflate = deflate,
	uncompress_tobuffer = uncompress_tobuffer,
	uncompress = uncompress,
	compress_tobuffer = compress_tobuffer,
	compress = compress,
	open = gzopen,
	adler32 = adler32,
	crc32 = crc32,
}
