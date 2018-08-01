
--glyph drawing to cairo contexts.
--Written by Cosmin Apreutesei. Public Domain.

if not ... then require'tr_demo'; return end

local ffi = require'ffi'
local glue = require'glue'
local box2d = require'box2d'
local ft = require'freetype'
local cairo = require'cairo'
local rs_ft = require'tr_raster_ft'
local zone = require'jit.zone' --glue.noop

local update = glue.update
local round = glue.round
local fit = box2d.fit

local cairo_rs = update({}, rs_ft)
setmetatable(cairo_rs, cairo_rs)

cairo_rs.rasterize_glyph_ft = rs_ft.rasterize_glyph

function cairo_rs:rasterize_glyph(font, font_size, glyph_index, x_offset, y_offset)

	local glyph = self:rasterize_glyph_ft(font, font_size, glyph_index, x_offset, y_offset)

	if glyph.bitmap then

		local w = glyph.bitmap.width
		local h = glyph.bitmap.rows

		glyph.surface = cairo.image_surface{
			data = glyph.bitmap.buffer,
			format = glyph.bitmap_format,
			w = w, h = h,
			stride = glyph.bitmap.pitch,
		}

		--scale raster glyphs which freetype cannot scale by itself.
		if font.scale ~= 1 then
			local bw = font.wanted_size
			if w ~= bw and h ~= bw then
				local w1, h1 = fit(w, h, bw, bw)
				local sr0 = glyph.surface
				local sr1 = cairo.image_surface(
					glyph.bitmap_format,
					math.ceil(w1),
					math.ceil(h1))
				local cr = sr1:context()
				cr:translate(x_offset, y_offset)
				cr:scale(w1 / w, h1 / h)
				cr:source(sr0)
				cr:paint()
				cr:rgb(0, 0, 0) --release source
				cr:free()
				sr0:free()
				glyph.surface = sr1
			end
		end

		glyph.paint = glyph.bitmap_format == 'g8'
			and self.paint_g8_glyph
			or self.paint_bgra8_glyph

		local free_bitmap = glyph.free
		function glyph:free()
			free_bitmap(self)
			self.surface:free()
		end

	end

	return glyph
end

function cairo_rs:paint_glyph(cr, glyph, x, y)
	local paint = glyph.paint
	if not paint then return end
	paint(self, cr, glyph, x, y)
end

function cairo_rs:paint_g8_glyph(cr, glyph, x, y)
	cr:mask(glyph.surface, x, y)
end

function cairo_rs:paint_bgra8_glyph(cr, glyph, x, y)
	cr:source(glyph.surface, x, y)
	cr:paint()
	cr:rgb(0, 0, 0) --clear source
end

return cairo_rs
