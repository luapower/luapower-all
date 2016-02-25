local bmp = require'bmp'
local ffi = require'ffi'
local glue = require'glue'
local lfs = require'lfs'

local function open(f)
	local s = glue.readfile(f)
	assert(#s > 0)
	--print('> '..f, #s)
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

for i,d in ipairs{'good', 'bad', 'questionable'} do
	for f in lfs.dir('media/bmp/'..d) do
		if f:find'%.bmp$' then
			local ok, bmp = xpcall(open, debug.traceback, 'media/bmp/'..d..'/'..f)
			if not ok then
				print(bmp)
			else
				local ok, err = xpcall(bmp.load, debug.traceback, bmp)
				if not ok then print(err) end
			end
		end
	end
end

