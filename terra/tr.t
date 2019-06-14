
--Text shaping & rendering engine for Terra.
--Written by Cosmin Apreutesei. Public Domain.

--This is a port of github.com/luapower/tr which was written in Lua.
--Leverages harfbuzz, freetype, fribidi and libunibreak.
--Scaling and blitting a raster image onto another is out of the scope of
--the library. A module for doing that with cairo is included separately.

if not ... then require'terra/tr_test'; return end

setfenv(1, require'terra/tr_types')

require'terra/tr_shape'
require'terra/tr_linewrap'
require'terra/tr_align'
require'terra/tr_clip'
require'terra/tr_rasterize'
require'terra/tr_paint'
require'terra/tr_hit_test'
require'terra/tr_cursor'

terra Renderer:init(load_font: FontLoadFunc, unload_font: FontLoadFunc)
	fill(self) --this initializes all arr() types.

	self.font_size_resolution  = 1.0/8  --in pixels
	self.subpixel_x_resolution = 1.0/16 --1/64 pixels is max with freetype
	self.word_subpixel_x_resolution = 1.0/4
	self.fonts:init()
	self.load_font = load_font
	self.unload_font = unload_font
	self.glyphs:init(self)
	self.glyphs.max_size = 1024 * 1024 * 20 --20 MB net (arbitrary default)
	self.glyph_runs:init(self)
	self.glyph_runs.max_size = 1024 * 1024 * 10 --10 MB net (arbitrary default)
	self.ranges.min_capacity = 64
	self.cpstack.min_capacity = 64
	assert(FT_Init_FreeType(&self.ft_lib) == 0)
	self:init_ub_lang()
end

terra Renderer:free()
	self.glyphs          :free()
	self.glyph_runs      :free()
	self.fonts           :free()
	self.cpstack         :free()
	self.scripts         :free()
	self.langs           :free()
	self.bidi_types      :free()
	self.bracket_types   :free()
	self.levels          :free()
	self.linebreaks      :free()
	self.grapheme_breaks :free()
	self.carets_buffer   :free()
	self.substack        :free()
	self.ranges          :free()
	FT_Done_FreeType(self.ft_lib)
end

terra Layout:free()
	self.lines:free()
	for _,seg in self.segs do
		self.r.glyph_runs:forget(seg.glyph_run_id)
	end
	self.segs:free()
	self.text:free()
	self.spans:free()
end

terra Renderer:font()
	assert(self.fonts.items.len <= 32000)
	var font, font_id = self.fonts:alloc()
	font:init(self)
	return font_id
end

terra Renderer:free_font(font_id: font_id)
	assert(self.fonts:at(font_id).refcount == 0)
	self.fonts:release(font_id)
end

return _M
