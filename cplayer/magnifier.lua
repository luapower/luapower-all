local player = require'cplayer'
local cairo = require'cairo'
local ffi = require'ffi'

function player:magnifier(t)
	local id = assert(t.id, 'id missing')
	local x, y, w, h = self:getbox(t)
	local zoom_level = math.max(1, math.floor(t.zoom_level or 2))

	--by default, capture the box in the center of the magnifier
	local cx = t.cx or math.floor(x + w / 2 * (1 - 1 / zoom_level))
	local cy = t.cy or math.floor(y + h / 2 * (1 - 1 / zoom_level))
	local cw = math.floor(w / zoom_level)
	local ch = math.floor(h / zoom_level)
	w = cw * zoom_level
	h = ch * zoom_level

	local sw = self.surface:get_image_width()
	local sh = self.surface:get_image_height()

	--store the pixels to be magnified in case they overlap with the magnifier itself
	assert(self.surface:get_image_format() == cairo.C.CAIRO_FORMAT_RGB24)
	self.surface:flush()
	local getpixel = self.surface:get_image_pixel_function()
	local bmp = ffi.new('uint8_t[?]', cw * ch * 3)
	local ofs = 0
	for j = cy, cy + ch-1 do
		for i = cx, cx + cw-1 do
			if j >= 0 and j < sh and i >= 0 and i < sw then
				local r,g,b = getpixel(i, j)
				bmp[ofs+0] = r
				bmp[ofs+1] = g
				bmp[ofs+2] = b
			end
			ofs = ofs + 3
		end
	end

	--draw the stored pixels as tiny filled rectangles
	local setpixel = self.surface:set_image_pixel_function()
	local ofs = 0
	for j = 0, ch-1 do
		for i = 0, cw-1 do
			local r = bmp[ofs+0]
			local g = bmp[ofs+1]
			local b = bmp[ofs+2]
			for jj = 0, zoom_level-1 do
				for ii = 0, zoom_level-1 do
					local x1 = x + i * zoom_level + ii
					local y1 = y + j * zoom_level + jj
					if x1 >= 0 and x1 < sw and y1 >= 0 and y1 < sh then
						setpixel(x1, y1, r, g, b)
					end
				end
			end
			ofs = ofs + 3
		end
	end
	self:rect(x, y, w, h, nil, 'selected_bg', 1)
end

if not ... then require'cplayer.widgets_demo' end

