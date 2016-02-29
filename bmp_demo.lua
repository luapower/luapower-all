local bmp_format = require'bmp'
local ffi = require'ffi'
local glue = require'glue'
local lfs = require'lfs'
local nw = require'nw'
local stdio = require'stdio'
local bitmap = require'bitmap'

local app = nw:app()
local win = app:window{w = 1150, h = 650, visible = false}

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
		return size
	end
	return bmp_format.open(read)
end

function win:repaint()
	local wbmp = win:bitmap()
	local x, y = 10, 10
	local maxh = 0

	local function show(f)
		local bmp, err = open(f)
		if not bmp then
			print(f, err)
		else
			if x + bmp.w + 10 > wbmp.w then
				x = 10
				y = y + maxh + 10
			end
			local ok, err = bmp:load(wbmp, x, y)
			if not ok then
				print(f, err)
			else
				--save a copy of the bitmap so we test the saving API too
				local f1 = io.open(f:gsub('%.bmp', '-saved.bmp'), 'w')
				local function write(buf, sz)
					assert(stdio.write(f1, buf, sz))
				end
				local bmp_cut = bitmap.sub(wbmp, x, y, bmp.w, bmp.h)
				bmp_format.save(bmp_cut, write)
				f1:close()

				x = x + bmp.w + 10
				maxh = math.max(maxh, bmp.h)
			end
		end
	end

	for i,d in ipairs{'good', 'bad', 'questionable'} do
		for f in lfs.dir('media/bmp/'..d) do
			if f:find'%.bmp$' and not f:find'%-saved' then
				show('media/bmp/'..d..'/'..f)
			end
		end
		y = y + maxh + 40
		x = 10
	end

end

win:show()
app:run()
