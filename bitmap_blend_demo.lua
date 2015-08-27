local player = require'cplayer'
local glue = require'glue'
local bitmap = require'bitmap'
local cairo = require'cairo'

local function bitmap_cairo(w, h)
	local bmp = bitmap.new(w, h, 'bgra8', false, true)
	local surface = cairo.cairo_image_surface_create_for_data(
		bmp.data, cairo.CAIRO_FORMAT_ARGB32, bmp.w, bmp.h, bmp.stride)
	local context = surface:create_context()
	return {surface = surface, context = context, bitmap = bmp}
end

function player:on_render(cr)

	self:checkerboard()

	local function blend(x, y, op)
		local src = bitmap_cairo(100, 100)
		local dst = bitmap_cairo(100, 100)

		--source: a triangle
		local scr = src.context
		scr:move_to(25, 25)
		scr:line_to(75, 50)
		scr:line_to(50, 75)
		scr:set_source_rgba(1, 0.4, 0, 1)
		scr:fill()

		--dest: the "&" character
		local dcr = dst.context
		dcr:move_to(30, 70)
		dcr:set_font_size(60)
		dcr:text_path('&')
		dcr:set_source_rgba(0, 0.4, 1, 1)
		dcr:fill()

		bitmap.blend(src.bitmap, dst.bitmap, op)

		self:image{x = x, y = y, image = dst.bitmap}
		self:label{x = x, y = y, w = 100, h = 100, halign = 'center', text = op}
	end

	for i,mode in ipairs(glue.keys(bitmap.blend_op, true)) do
		local x = 100 + ((i-1) % 6) * 110
		local y = 100 + math.floor((i-1) / 6) * 110
		blend(x, y, mode)
	end
end

player:play()


