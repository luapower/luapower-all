--saturation/Luminance square and picker
local player = require'cplayer'
local color = require'color'
local cairo = require'cairo'
local box = require'box2d'

function player:sat_lum_square(sx, sy, sw, sh, hue, s, L)
	sw = math.min(self.w, sx + sw) - sx
	sh = math.min(self.h, sy + sh) - sy

	local mx, my = self:mousepos()

	local setpixel = self.surface:set_image_pixel_function()
	assert(self.surface:get_image_format() == cairo.C.CAIRO_FORMAT_RGB24)
	for y = 0, sh-1 do
		for x = 0, sw-1 do
			local r, g, b = color.hsl_to_rgb(hue, x / (sw-1), y / (sh-1))
			setpixel(sx + x, sy + y, r * 255, g * 255, b * 255)
		end
	end

	local shot = box.hit(mx, my, sx, sy, sw, sh)

	if not self.active and shot and self.lpressed then
		self.active = 'square'
	elseif self.active == 'square' then
		if self.lbutton then
			s = (mx - sx) / sw
			L = (my - sy) / sh
			s = math.min(math.max(s, 0), 1)
			L = math.min(math.max(L, 0), 1)
		else
			self.active = nil
		end
	end

	if shot or self.active then
		self.cursor = 'link'
	end

	local x0 = sx + s * sw
	local y0 = sy + L * sh
	x0 = x0 + 0.5
	y0 = y0 + 0.5

	local r, g, b = color(hue, 1-s, 1-L):rgb()
	self:dot(x0, y0, 5, {r, g, b, 1}, {color(hue, s, 1-L):rgba()})

	return s, L
end

if not ... then require'color_demo' end
