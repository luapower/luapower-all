local pp = require'pp'
local fs = require'fs'
local spng = require'libspng'

local function load(file)
	local f = assert(fs.open(file))
	local img = assert(spng.open{read = f:buffered_read()})
	local bmp = assert(img:load{accept = {bgra8 = true}})
	assert(f:close())
	return img, bmp
end

local function save(bmp, file)
	local f = assert(fs.open(file, 'w'))
	assert(spng.save{
		bitmap = bmp,
		write = function(buf, sz)
			return f:write(buf, sz)
		end,
	})
	assert(f:close())
end

local img, bmp = load'media/png/good/z09n2c08.png'
save(bmp, 'media/png/good/z09n2c08_1.png')
local img2, bmp2 = pp(load'media/png/good/z09n2c08_1.png')
assert(os.remove'media/png/good/z09n2c08_1.png')
assert(bmp.size == bmp2.size)
for i=0,bmp.size-1 do
	assert(bmp.data[i] == bmp2.data[i])
end
print'ok'
