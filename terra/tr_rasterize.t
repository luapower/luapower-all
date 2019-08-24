
--Glyph caching & rasterization based on freetype's rasterizer.
--Written by Cosmin Apreutesei. Public Domain.

if not ... then require'terra/tr_test'; return end

setfenv(1, require'terra/tr_types')
require'terra/tr_font'

terra Font:load_glyph(font_size: num, glyph_index: uint)
	if FT_Load_Glyph(self.ft_face, glyph_index, self.ft_load_flags) ~= 0 then
		return nil
	end
	var ft_glyph = self.ft_face.glyph
	var w = ft_glyph.metrics.width
	var h = ft_glyph.metrics.height
	if w == 0 or h == 0 then
		return nil
	end
	return ft_glyph
end

terra Glyph:free(r: &Renderer)
	if self.image.surface == nil then return end
	self.image:free(r)
end

terra Glyph:rasterize(r: &Renderer)

	var font = r.fonts:at(self.font_id)
	var glyph = font:load_glyph(self.font_size, self.glyph_index)

	if glyph == nil then
		self.image.surface = nil
		return
	end

	if glyph.format == FT_GLYPH_FORMAT_OUTLINE then
		FT_Outline_Translate(&glyph.outline, self.subpixel_offset_x_8_6, 0)
	end
	if glyph.format ~= FT_GLYPH_FORMAT_BITMAP then
		FT_Render_Glyph(glyph, font.ft_render_flags)
	end
	assert(glyph.format == FT_GLYPH_FORMAT_BITMAP)

	var bitmap = &glyph.bitmap

	--BGRA bitmaps must already have aligned pitch because we can't change that
	assert(bitmap.pixel_mode ~= FT_PIXEL_MODE_BGRA or ((bitmap.pitch and 3) == 0))

	--bitmaps must be top-down because we can't change that
	assert(bitmap.pitch >= 0) --top-down

	if (bitmap.pitch and 3) ~= 0
		or (bitmap.pixel_mode ~= FT_PIXEL_MODE_GRAY
			and bitmap.pixel_mode ~= FT_PIXEL_MODE_BGRA)
	then
		var tmp_bitmap: FT_Bitmap
		FT_Bitmap_Init(&tmp_bitmap)
		FT_Bitmap_Convert(font.r.ft_lib, bitmap, &tmp_bitmap, 4)
		assert(tmp_bitmap.pixel_mode == FT_PIXEL_MODE_GRAY)
		assert((tmp_bitmap.pitch and 3) == 0)

		font.r:wrap_glyph(self, &tmp_bitmap)

		FT_Bitmap_Done(font.r.ft_lib, &tmp_bitmap)
	else
		font.r:wrap_glyph(self, bitmap)
	end

	self.image.x = glyph.bitmap_left * font.scale + 0.5
	self.image.y = glyph.bitmap_top  * font.scale + 0.5
end

local empty_glyph = constant(Glyph.empty)

terra Renderer:rasterize_glyph(
	font_id: font_id_t, font_size: num,
	glyph_index: uint, ax: num, ay: num
)
	if glyph_index == 0 then --freetype code for "missing glyph"
		return &empty_glyph, ax, ay
	end

	font_size = snap(font_size, self.font_size_resolution)
	var sx = floor(ax)
	var sy = floor(ay)
	var ox = snap(ax - sx, self.subpixel_x_resolution)
	if ox == 1 then inc(sx); ox = 0 end

	var glyph: Glyph
	glyph.font_id = font_id
	glyph.glyph_index = glyph_index
	glyph.font_size = font_size
	glyph.subpixel_offset_x = ox

	var glyph_id, pair = self.glyphs:get(glyph)
	if pair == nil then
		glyph:rasterize(self)
		glyph_id, pair = self.glyphs:put(glyph, {})
	end
	self.glyphs:forget(glyph_id)
	var g = &pair.key

	var x = sx + g.image.x
	var y = sy - g.image.y

	return g, x, y
end

local struct glyph_surfaces {
	r: &Renderer;
	gr: &GlyphRun;
	i: int; j: int;
	ax: num; ay: num;
}
glyph_surfaces.metamethods.__for = function(self, body)
	return quote
		var self = self --workaround for terra issue #368
		var gr = self.gr
		var font = self.r.fonts:at(gr.font_id)
		font:setsize(gr.font_size)
		for i = self.i, self.j do
			var g = gr.glyphs:at(i)
			var glyph, sx, sy = self.r:rasterize_glyph(
				gr.font_id, gr.font_size, g.glyph_index,
				self.ax + g.x + g.image_x,
				self.ay + g.image_y
			)
			if glyph.image.surface ~= nil then
				[ body(`glyph.image.surface, sx, sy) ]
			end
		end
	end
end
terra Renderer:glyph_surfaces(gr: &GlyphRun, i: int, j: int, ax: num, ay: num)
	return glyph_surfaces {r = self, gr = gr, i = i, j = j, ax = ax, ay = ay}
end

terra Renderer:glyph_run_bbox(gr: &GlyphRun, ax: num, ay: num)
	var bx: num, by: num, bw: num, bh: num = 0, 0, 0, 0
	var surfaces = self:glyph_surfaces(gr, 0, gr.glyphs.len, ax, ay)
	for sr, sx, sy in surfaces do
		bx, by, bw, bh = rect.bbox(bx, by, bw, bh, sx, sy, sr:width(), sr:height())
	end
	return bx, by, bw, bh
end

terra Renderer:rasterize_glyph_run(gr: &GlyphRun, ax: num, ay: num)
	var sx = floor(ax)
	var sy = floor(ay)
	var ox = snap(ax - sx, self.word_subpixel_x_resolution)
	if ox == 1 then inc(sx); ox = 0 end
	var si: int = ox / self.word_subpixel_x_resolution

	var gsp = gr.images:at(si, nil)
	if gsp == nil or gsp.surface == nil then
		var bx, by, bw, bh = self:glyph_run_bbox(gr, ax, ay)
		var bx1 = floor(bx)
		var by1 = floor(by)
		var bx2 = ceil(bx + bw)
		var by2 = ceil(by + bh)
		var sr = cairo_image_surface_create(CAIRO_FORMAT_ARGB32, bx2-bx1, by2-by1)
		var srcr = sr:context()
		srcr:translate(-bx1, -by1)
		var surfaces = self:glyph_surfaces(gr, 0, gr.glyphs.len, ax, ay)
		for gsr, gsx, gsy in surfaces do
			self:paint_surface(srcr, gsr, gsx, gsy, false, 0, 0)
		end
		srcr:free()
		gsp = gr.images:set(si,
			GlyphImage{surface = sr, x = bx1-sx, y = by1-sy},
			GlyphImage{surface = nil, x = 0, y = 0})
		inc(gr.images_memsize, 1024 + sr:height() * sr:stride())
	end
	return gsp.surface, sx + gsp.x, sy + gsp.y
end
