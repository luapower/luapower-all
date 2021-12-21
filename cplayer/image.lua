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
		bitmap.paint(img, src)
	end
	local surface = cairo.image_surface(img)

	local mt = self.cr:matrix()
	self.cr:translate(x, y)
	if t.scale then
		self.cr:scale(t.scale, t.scale)
	end
	self.cr:source(surface)
	self.cr:paint()
	self.cr:rgb(0,0,0)
	self.cr:matrix(mt)

	surface:free()
end

if not ... then require'cplayer.widgets_demo' end

