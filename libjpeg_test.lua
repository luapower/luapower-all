local libjpeg = require'libjpeg'
local ffi = require'ffi'
local stdio = require'stdio'

local function test_save()
	print('ffi.sizeof\'jpeg_decompress_struct\'', ffi.sizeof'jpeg_decompress_struct')
	local infile = 'media/jpeg/progressive.jpg'
	local outfile = 'media/jpeg/temp.jpg'
	local f = io.open(infile, 'rb')
	local bmp = libjpeg.load(stdio.reader(infile))
	f:close()
	local function write(buf, sz)
		--TODO
	end
	local jpg = libjpeg.save{bitmap = bmp}
	libjpeg.save{bitmap = bmp, write = write}
	assert(jpg == glue.readfile(outfile))
	assert(os.remove(outfile))
	print'ok'
end


test_save()

