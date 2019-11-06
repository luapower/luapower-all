--[[

	Glyph caching & rasterization based on the FreeType rasterizer.
	Written by Cosmin Apreutesei. Public Domain.

]]

if not ... then require'terra/tr_test'; return end

setfenv(1, require'terra/tr_types')
require'terra/tr_font'

terra FontFace:load_glyph(glyph_index: uint)
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

terra Glyph:rasterize(r: &Renderer, face: &FontFace)

	var glyph = face:load_glyph(self.glyph_index)

	if glyph == nil then
		self.image.surface = nil
		return
	end

	if glyph.format == FT_GLYPH_FORMAT_OUTLINE then
		FT_Outline_Translate(&glyph.outline, self.subpixel_offset_x_8_6, 0)
	end
	if glyph.format ~= FT_GLYPH_FORMAT_BITMAP then
		FT_Render_Glyph(glyph, face.ft_render_flags)
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
		FT_Bitmap_Convert(r.ft_lib, bitmap, &tmp_bitmap, 4)
		assert(tmp_bitmap.pixel_mode == FT_PIXEL_MODE_GRAY)
		assert((tmp_bitmap.pitch and 3) == 0)

		r:create_glyph_surface(self, &tmp_bitmap, face.scale, face.size)

		FT_Bitmap_Done(r.ft_lib, &tmp_bitmap)
	else
		r:create_glyph_surface(self, bitmap, face.scale, face.size)
	end

	self.image.x = glyph.bitmap_left * face.scale + 0.5
	self.image.y = glyph.bitmap_top  * face.scale + 0.5
end

local empty_glyph = constant(Glyph.empty)

terra Renderer:rasterize_glyph(
	font_id: int, font_face_index: int, font_size: num, glyph_index: uint,
	face: &FontFace, ax: num, ay: num
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
	glyph.font_face_index = font_face_index
	glyph.font_size = font_size
	glyph.subpixel_offset_x = ox

	var glyph_id, pair = self.glyphs:get(glyph)
	if pair == nil then
		glyph:rasterize(self, face)
		glyph_id, pair = self.glyphs:put(glyph, {})
	end
	self.glyphs:forget(glyph_id)
	var g = &pair.key

	var x = sx + g.image.x
	var y = sy - g.image.y

	return g, x, y
end

do
	local struct glyph_surfaces_iter {
		r: &Renderer;
		run: &GlyphRun;
		i: int;
		j: int;
		face: &FontFace;
		ax: num; ay: num;
	}

	glyph_surfaces_iter.metamethods.__for = function(self, body)
		return quote
			var self = self --workaround for terra issue #368
			var run = self.run
			for i = self.i, self.j do
				var g = run.glyphs:at(i)
				var glyph, sx, sy = self.r:rasterize_glyph(
					run.font_id, run.font_face_index, run.font_size, g.glyph_index,
					self.face,
					self.ax + g.x + g.image_x,
					self.ay       + g.image_y
				)
				if glyph.image.surface ~= nil then
					[ body(`glyph.image.surface, sx, sy) ]
				end
			end
		end
	end

	terra Renderer:glyph_surfaces(run: &GlyphRun, i: int, j: int, face: &FontFace, ax: num, ay: num)
		return glyph_surfaces_iter {r = self, run = run, i = i, j = j, face = face, ax = ax, ay = ay}
	end
end

terra Renderer:glyph_run_bbox(run: &GlyphRun, face: &FontFace, ax: num, ay: num)
	var bx: num, by: num, bw: num, bh: num = 0, 0, 0, 0
	var surfaces = self:glyph_surfaces(run, 0, run.glyphs.len, face, ax, ay)
	for sr, sx, sy in surfaces do
		bx, by, bw, bh = rect.bbox(bx, by, bw, bh, sx, sy, sr:width(), sr:height())
	end
	return bx, by, bw, bh
end

terra Renderer:rasterize_glyph_run(run: &GlyphRun, face: &FontFace, ax: num, ay: num)
	var sx = floor(ax)
	var sy = floor(ay)
	var ox = snap(ax - sx, self.word_subpixel_x_resolution)
	if ox == 1 then inc(sx); ox = 0 end
	var si: int = ox / self.word_subpixel_x_resolution

	var gsp = run.images:at(si, nil)
	if gsp == nil or gsp.surface == nil then
		var bx, by, bw, bh = self:glyph_run_bbox(run, face, ax, ay)
		var bx1 = floor(bx)
		var by1 = floor(by)
		var bx2 = ceil(bx + bw)
		var by2 = ceil(by + bh)
		var sr = create_surface(bx2-bx1, by2-by1, CAIRO_FORMAT_A8)
		var cr = sr:context()
		cr:translate(-bx1, -by1)
		var surfaces = self:glyph_surfaces(run, 0, run.glyphs.len, face, ax, ay)
		for gsr, gsx, gsy in surfaces do
			self:paint_surface(cr, gsr, gsx, gsy)
		end
		cr:free()
		gsp = run.images:set(si,
			GlyphImage{surface = sr, x = bx1-sx, y = by1-sy},
			GlyphImage{surface = nil, x = 0, y = 0})
		inc(run.images_memsize, 1024 + sr:height() * sr:stride())
	end
	return gsp.surface, sx + gsp.x, sy + gsp.y
end
