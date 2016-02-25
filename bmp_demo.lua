local bmp = require'bmp'
local ffi = require'ffi'
local glue = require'glue'
local lfs = require'lfs'
local nw = require'nw'

local app = nw:app()
local win = app:window{w = 1200, h = 600, visible = false}

local function open(f)
	local s = glue.readfile(f)
	assert(#s > 0)
	local function read(buf, size)
		assert(#s >= size, 'file too short')
		if buf then
			local s1 = s:sub(1, size)
			ffi.copy(buf, s1, size)
		end
		s = s:sub(size + 1)
	end
	return bmp.open(read)
end

function win:repaint()
	local wbmp = win:bitmap()
	local x, y = 10, 10
	local maxh = 0

	local function show(f)
		local ok, bmp = pcall(open, f)
		if not ok then
			print(f, bmp)
		else
			if x + bmp.w + 10 > wbmp.w then
				x = 10
				y = y + maxh + 10
			end
			local ok, err = pcall(bmp.load, bmp, wbmp, x, y)
			if not ok then
				print(f, err)
			else
				x = x + bmp.w + 10
				maxh = math.max(maxh, bmp.h)
			end
		end
	end

	for i,d in ipairs{'good', 'bad', 'questionable'} do
		for f in lfs.dir('media/bmp/'..d) do
			if f:find'%.bmp$' then
				show('media/bmp/'..d..'/'..f)
			end
		end
		y = y + maxh + 40
		x = 10
	end

end

win:show()
app:run()
