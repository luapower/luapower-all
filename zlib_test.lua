local zlib = require'zlib'
local glue = require'glue'
local ffi = require'ffi'
require'unit'

test(zlib.version():match'^1.2.7', '1.2.7')
test(zlib.uncompress(zlib.compress('aaa'), nil, 1024), 'aaa')

test(glue.tohex(zlib.adler32'The game done changed.'), '587507ba')
test(glue.tohex(zlib.crc32'Game\'s the same, just got more fierce.'), '2c40120a')

local function gztest(file, content)
	local gz = zlib.open(file)
	test(gz:read(#content), content)
	test(#gz:read(1), 0)
	test(gz:eof(), true)
	gz:close()
end

local gz = zlib.open('media/gzip/test1.txt.gz', 'w')
test(gz:write'The game done changed.', #'The game done changed.')
gz:close()

gztest('media/gzip/test.txt.gz', 'The game done changed.')
gztest('media/gzip/test1.txt.gz', 'The game done changed.')
os.remove('media/gzip/test1.txt.gz')

local function gen(n)
	local t = {}
	for i=1,n do
		t[i] = string.format('dude %x\r\n', i)
	end
	return table.concat(t)
end

local function reader(s)
	local done
	return function()
		if done then return end
		done = true
		return s
	end
end

local function writer()
	local t = {}
	return function(data, sz)
		if not data then return table.concat(t) end
		t[#t+1] = ffi.string(data, sz)
	end
end

local function test(format)
	local src = gen(100000)
	local write = writer()
	zlib.deflate(reader(src), write, nil, format)
	local dst = write()
	local write = writer()
	zlib.inflate(reader(dst), write, nil, format)
	local src2 = write()
	assert(src == src2)
	print(string.format('size: %dK, ratio: %d%%', #src/1024, #dst / #src * 100))
end
test'gzip'
test'zlib'
test'deflate'
