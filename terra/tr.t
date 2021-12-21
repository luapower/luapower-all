--[[

	Unicode text layouting and rendering engine in Terra with a C API.
	Written by Cosmin Apreutesei. Public Domain.

	A pure-Lua prototype of this library is at github.com/luapower/tr.
	Discuss at luapower.com/forum or at github.com/luapower/terra-tr/issues.

	Leverages harfbuzz, freetype, fribidi and libunibreak for text shaping,
	glyph rasterization, bidi reordering and line breaking respectively.

	Scaling and blitting a raster image onto another is out of the scope of
	the library. A module for doing that with `cairo` is included separately.

	NOTE: This is the implementation module. In here, invalid input data is
	undefined behavior and changing layout properties does not keep the
	internal state consistent. Use `tr_api` instead which takes care of that.

	Processing stages from rich text description to pixels on screen:

	* itemization     : split text into an array of segments (or segs).
	* shaping         : shape segments into arrays of glyphs (called glyph runs).
	* line-wrapping   : word-wrap segments and group them into an array of lines.
	* bidi-reordering : re-order mixed-direction segments on each line.
	* line-spacing    : compute each line's `y` based on the heights of its segments.
	* aligning        : align lines horizontally and vertically inside a box.
	* clipping        : mark which lines and segments as visible inside a box.
	* rasterization   : convert glyph outlines into bitmaps that are cached.
	* painting        : draw the visible text plus any selections and carets.

	The API for driving this process is:

	tr_itemize.t   shape()     itemization and shaping.
	tr_wrap.t      wrap()      line-wrapping.
	tr_align.t     spaceout()  line-spacing.
	tr_align.t     align()     justification and aligning.
	tr_clip.t      clip()      clipping.
	tr_paint.t     paint()     painting, with on-demand rasterization.

	The renderer object keeps four LRU caches: one for glyph runs, one for
	glyph images, one for memory fonts and one for memory-mapped fonts.
	Shaping looks-into and adds-to the glyph run cache. Rasterization
	looks-into and adds-to the glyph image cache. Fonts are loaded and cached
	when the span's font_id is set in tr_api. Glyph runs and fonts are
	ref-counted in the cache so while the layout is alive, even if the cache
	size limit is reached, segs won't lose their glyph runs and fonts will
	remain available for reshaping and rasterization.

	Also, there's two levels of rasterization: for glyph images and for entire
	glyph runs. With subpixel resolution, more than one image might end up
	being created for each subpixel offset encountered, which is why
	rasterization is done on-demand by painting.

]]

if not ... then require'terra.tr_test'; return end

setfenv(1, require'terra.tr_types')
require'terra.tr_itemize'
require'terra.tr_wrap'
require'terra.tr_align'
require'terra.tr_clip'
require'terra.tr_paint'

terra Renderer:init(load_font: FontLoadFunc, unload_font: FontUnloadFunc)
	fill(self) --this initializes all arr() types.
	self.font_size_resolution  = 1.0/8  --in pixels
	self.subpixel_x_resolution = 1.0/16 --1/64 pixels is max with freetype
	self.word_subpixel_x_resolution = 1.0/4
	self.mem_fonts:init()
	self.mem_fonts.max_size = 1024 * 1024 * 20 --20 MB net (arbitrary default)
	self.mmapped_fonts:init()
	self.mmapped_fonts.max_count = 1000 -- (arbitrary default)
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
	init_linebreak() --libunibreak API
	self:init_embed_cursors()
end

terra Renderer:free()
	self.embed_cursors   :free()
	self.glyphs          :free()
	self.glyph_runs      :free()
	self.mem_fonts       :free()
	self.mmapped_fonts   :free()
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

terra forget_glyph_run(self: &Renderer, glyph_run_id: int)
	self.glyph_runs:forget(glyph_run_id)
end

terra Span:copy(layout: &Layout) --for splitting spans
	var s = @self
	s.features = self.features:copy()
	s.font = layout.r:font(self.font_id)
	return s
end

terra Layout:free()
	self.lines:free()
	self.segs:call('forget_glyph_run', self.r)
	self.segs:free()
	self.text:free()
	self.spans:free()
	self.embeds:free()
end

return _M
