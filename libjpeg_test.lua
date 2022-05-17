local libjpeg = require'libjpeg'
local ffi = require'ffi'
local fs = require'fs'

local function test_load_save()
	local infile = 'media/jpeg/progressive.jpg'
	local outfile = 'media/jpeg/temp.jpg'
	local f = assert(fs.open(infile))
	local img = assert(libjpeg.open(function(buf, sz)
		return assert(f:read(buf, sz))
	end))
	local bmp = assert(img:load())
	assert(f:close())

	local f2 = assert(fs.open(outfile, 'w'))
	local function write(buf, sz)
		return f2:write(buf, sz)
	end
	libjpeg.save{bitmap = bmp, write = write}
	img:free()
	assert(f2:close())

	local f = assert(fs.open(outfile))
	local img = assert(libjpeg.open{
		read = function(buf, sz)
			return assert(f:read(buf, sz))
		end,
		partial_loading = false, --break on errors
	})
	local bmp2 = assert(img:load())
	img:free()
	assert(f:close())
	assert(os.remove(outfile))
	assert(bmp.w == bmp2.w)
	assert(bmp.h == bmp2.h)
	print'ok'
end


test_load_save()

