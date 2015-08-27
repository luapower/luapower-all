local ffi = require'ffi'
require'unit'

local function benchmark(blurmod, w, h, n)
	local size = w * h * 4
	local img = ffi.new('uint8_t[?]', size)
	local imgcopy = ffi.new('uint8_t[?]', size)
	local blur = require(blurmod:gsub(' ', '')).blur_8888
	timediff()
	for i=1,n do
		ffi.copy(img, imgcopy, size)
		blur(img, w, h, i % 50)
	end
	print(string.format('%s  fps @ %dx%d:  ', blurmod, w, h), fps(n))
end

benchmark('im_stackblur  ', 1920, 1080, 5)
benchmark('im_boxblur_lua', 1920, 1080, 10)
benchmark('im_boxblur    ', 1920, 1080, 10)

benchmark('im_stackblur  ', 800, 450, 20)
benchmark('im_boxblur_lua', 800, 450, 60)
benchmark('im_boxblur    ', 800, 450, 60)

benchmark('im_stackblur  ', 320, 200, 80)
benchmark('im_boxblur_lua', 320, 200, 400)
benchmark('im_boxblur    ', 320, 200, 400)

