--draw scaled RGBA8888 and G8 images
local player = require'cplayer'
local cairo = require'cairo'
local bitmap = require'bitmap'

function player:image(t)
	local x = t.x or 0
	local y = t.y or 0
	local src = assert(t.image, 'image missing')

	--link image bits to a surface
	local img = src
	if src.format ~= 'bgra8'
		or src.bottom_up
		or bitmap.stride(src) ~= bitmap.aligned_stride(bitmap.min_stride(src.format, src.w))
	then
		img = bitmap.new(src.w, src.h, 'bgra8', false, true)
		bitmap.paint(src, img)
	end
	local surface = cairo.cairo_image_surface_create_for_data(img.data, cairo.CAIRO_FORMAT_ARGB32,
																					img.w, img.h, img.stride)

	local mt = self.cr:get_matrix()
	self.cr:translate(x, y)
	if t.scale then
		self.cr:scale(t.scale, t.scale)
	end
	self.cr:set_source_surface(surface, 0, 0)
	self.cr:paint()
	self.cr:set_source_rgb(0,0,0)
	self.cr:set_matrix(mt)

	surface:free()
end

if not ... then require'cplayer.widgets_demo' end

