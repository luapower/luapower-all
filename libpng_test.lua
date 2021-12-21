local libpng = require'libpng'
local glue = require'glue'
local ffi = require'ffi'

local function test_save()
	local infile = 'media/png/good/basi0g01.png'
	local outfile = 'media/png/temp.png'
	local bmp = libpng.load(infile)
	local png = libpng.save{bitmap = bmp}
	libpng.save{bitmap = bmp, path = outfile}
	assert(png == glue.readfile(outfile))
	assert(os.remove(outfile))
	print'ok'
end


test_save()

