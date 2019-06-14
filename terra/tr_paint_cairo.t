
--Cairo graphics adapter for terra/tr.
--Paints (and scales) rasterized glyph runs into a cairo surface.

if not ... then require'terra/tr_test'; return end

setfenv(1, require'terra/tr_env')
require'terra/cairo'
color = cairo_argb32_color_t
GraphicsSurface = cairo_surface_t
GraphicsContext = cairo_t
setfenv(1, require'terra/tr_types')

terra Renderer:wrap_glyph(glyph: &Glyph, bmp: &FT_Bitmap)

	var w = bmp.width
	var h = bmp.rows

	var format = iif(bmp.pixel_mode == FT_PIXEL_MODE_GRAY,
		CAIRO_FORMAT_A8, CAIRO_FORMAT_ARGB32)

	var sr0 = cairo_image_surface_create_for_data(
		bmp.buffer, format, w, h, bmp.pitch)

	var font = self.fonts:at(glyph.font_id)
	if font.scale ~= 1 then
		--scale raster glyphs which freetype cannot scale by itself.
		var bw = font.size
		var w1, h1 = rect.fit(w, h, bw, bw)
		var sr = cairo_image_surface_create(CAIRO_FORMAT_ARGB32, ceil(w1), ceil(h1))
		var cr = cairo_create(sr)
		cr:translate(glyph.subpixel_offset_x, 0)
		cr:scale(w1 / w, h1 / h)
		cr:source(sr0, 0, 0)
		cr:paint()
		cr:rgb(0, 0, 0) --release source
		cr:free()
		glyph.image.surface = sr
	else
		var sr = cairo_image_surface_create(CAIRO_FORMAT_ARGB32, w, h)
		var cr = cairo_create(sr)
		if bmp.pixel_mode == FT_PIXEL_MODE_GRAY then
			cr:rgb(1, 1, 1)
			cr:mask(sr0, 0, 0)
		else
			cr:source(sr0, 0, 0)
			cr:paint()
			cr:rgb(0, 0, 0) --release source
		end
		cr:free()
		glyph.image.surface = sr
	end

	sr0:free()
end

--NOTE: clip_left and clip_right are relative to bitmap's left edge.
terra Renderer:paint_surface(
	cr: &GraphicsContext, sr: &GraphicsSurface,
	x: num, y: num, clip: bool, clip_left: num, clip_right: num
)
	if clip then
		cr:save()
		cr:new_path()
		var x1 = x + clip_left
		var x2 = x + sr:width() + clip_right
		cr:rectangle(x1, y, x2 - x1, sr:height())
		cr:clip()
	end
	cr:mask(sr, x, y)
	if clip then
		cr:restore()
	end
end

terra Renderer:setcontext(cr: &GraphicsContext, span: &Span)
	var c: cairo_color_t = span.color --implicit cast
	c.alpha = c.alpha * span.opacity
	cr:rgba(c)
	cr:operator(span.operator)
end
