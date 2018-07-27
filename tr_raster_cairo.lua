
--glyph drawing to cairo contexts.
--Written by Cosmin Apreutesei. Public Domain.

local glue = require'glue'
local ft = require'freetype'
local cairo = require'cairo'
local rs_ft = require'tr_raster_ft'

local object = glue.object

local cairo_rs = object(rs_ft)

cairo_rs.rasterize_glyph_ft = rs_ft.rasterize_glyph

function cairo_rs:rasterize_glyph(...)

	local glyph = self:rasterize_glyph_ft(...)

	glyph.surface = cairo.image_surface{
		data = glyph.bitmap.buffer,
		format = glyph.bitmap.pixel_mode == ft.C.FT_PIXEL_MODE_BGRA
			and 'bgra8' or 'g8',
		w = glyph.bitmap.width,
		h = glyph.bitmap.rows,
		stride = glyph.bitmap.pitch,
	}

	local free_bitmap = glyph.free
	function glyph:free()
		free_bitmap(self)
		self.surface:free()
	end

	return glyph
end

function cairo_rs:paint_glyph(glyph, x, y)
	local cr = self.cr
	if glyph.surface:format() == 'a8' then
		cr:mask(glyph.surface, x, y)
	else
		cr:source(glyph.surface, x, y)
		cr:paint()
		cr:rgb(0, 0, 0) --clear source
	end
end

return cairo_rs
