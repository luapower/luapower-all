local ffi = require'ffi'
local C = ffi.load'boxblur'

ffi.cdef[[
void boxblur_8888(uint8_t* pix, int32_t w, int32_t h, int32_t radius, int32_t times);
]]

local function boxblur_8888(pix, w, h, radius, times)
	C.boxblur_8888(pix, w, h, radius, times or 2)
end

if not ... then require'im_blur_test' end

return {
	blur_8888 = boxblur_8888,
}
