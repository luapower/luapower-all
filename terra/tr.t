--[[

	Text shaping & rendering engine in Terra with a C API.
	Written by Cosmin Apreutesei. Public Domain.

	This is a port of github.com/luapower/tr which was written in Lua.

	Leverages harfbuzz, freetype, fribidi and libunibreak for text shaping,
	glyph rasterization, bidi reordering and line breaking respectively.

	Scaling and blitting a raster image onto another is out of the scope of
	the library. A module for doing that with cairo is included separately.

]]

if not ... then require'terra/tr_test'; return end

setfenv(1, require'terra/tr_types')
require'terra/tr_shape'
require'terra/tr_wrap'
require'terra/tr_align'
require'terra/tr_clip'
require'terra/tr_paint'
require'terra/tr_hit_test'
require'terra/tr_layoutedit'
require'terra/tr_spanedit'
require'terra/tr_cursor'
require'terra/tr_selection'

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
	init_ub_lang()
	init_script_lang_map()
	init_linebreak()
end

terra Renderer:get_glyph_run_cache_max_size() return self.glyph_runs.max_size end
terra Renderer:set_glyph_run_cache_max_size(size: int) self.glyph_runs.max_size = size end
terra Renderer:get_glyph_run_cache_size() return self.glyph_runs.size end
terra Renderer:get_glyph_run_cache_count() return self.glyph_runs.count end

terra Renderer:get_glyph_cache_max_size() return self.glyphs.max_size end
terra Renderer:set_glyph_cache_max_size(size: int) self.glyphs.max_size = size end
terra Renderer:get_glyph_cache_size() return self.glyphs.size end
terra Renderer:get_glyph_cache_count() return self.glyphs.count end

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
	self.sbuf            :free()
	self.xsbuf           :free()
	self.paragraph_dirs  :free()
	FT_Done_FreeType(self.ft_lib)
end

terra Layout:free()
	self.selections:free()
	self.cursors:free()
	self.lines:free()
	for _,seg in self.segs do
		self.r.glyph_runs:forget(seg.glyph_run_id)
	end
	self.segs:free()
	self.text:free()
	for _,span in self.spans do
		if span.font_id ~= -1 then
			self.r.fonts:at(span.font_id):unref()
		end
	end
	self.spans:free()
end

terra Layout:get_visible()
	return self.text.len >= 0
		and self.spans:at(0).font_id ~= -1
		and self.spans:at(0).font_size > 0
end

terra Layout:get_min_size_valid()
	return self.text.len == 0 or self.state >= STATE_SPACED
end

terra Layout:shape()
	if self.state >= STATE_SHAPED then return false end
	self:_shape()
	self.state = STATE_SHAPED
	self.cursors:call'reposition'
	self.selections:call'reposition'
	return true
end

terra Layout:wrap()
	if self.state >= STATE_WRAPPED then return false end
	assert(self.state == STATE_WRAPPED - 1)
	self:_wrap()
	self.state = STATE_WRAPPED
	return true
end

terra Layout:spaceout()
	if self.state >= STATE_SPACED then return false end
	assert(self.state == STATE_SPACED - 1)
	self:_spaceout()
	self.state = STATE_SPACED
	return true
end

terra Layout:align()
	if self.state >= STATE_ALIGNED then return false end
	assert(self.state == STATE_ALIGNED - 1)
	self:_align()
	self.state = STATE_ALIGNED
	return true
end

terra Layout:layout()
	self:shape()
	self:wrap()
	self:spaceout()
	self:align()
	self:clip()
end

terra Layout:paint(cr: &context)
	self.selections:call('paint', cr, true)
	self:paint_text(cr)
	self.cursors:call('paint', cr)
end

terra Renderer:font()
	assert(self.fonts.items.len <= 32000)
	var font, font_id = self.fonts:alloc()
	font:init(self)
	return [int](font_id)
end

terra Renderer:free_font(font_id: int)
	assert(self.fonts:at(font_id).refcount == 0)
	self.fonts:release(font_id)
end

terra Renderer:get_paint_glyph_num() return self.paint_glyph_num end
terra Renderer:set_paint_glyph_num(n: int) self.paint_glyph_num = n end

return _M
