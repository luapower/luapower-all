
--Shaping a single word into a cached array of glyphs called a glyph run.

if not ... then require'terra.tr_test'; return end

setfenv(1, require'terra.tr_types')
require'terra.tr_font'
require'terra.tr_rle'

terra GlyphImage:free(r: &Renderer)
	if self.surface == nil then return end
	self.surface:free()
	self.surface = nil
end

terra GlyphRun:free(r: &Renderer)
	self.cursor_xs:free()
	self.cursor_offsets:free()
	var font = r.fonts:at(self.font_id)
	self.text:free()
	self.features:free()
	self.glyphs:free()
	self.images:free()
	fill(self)
end

terra GlyphRun.methods.compute_cursors :: {&GlyphRun, &Renderer, &Font} -> {}

terra GlyphRun:shape(r: &Renderer)
	var font = r.fonts:at(self.font_id, nil)
	if font == nil then
		return false
	end
	font:setsize(self.font_size)
	self.text = self.text:copy()
	self.features = self.features:copy()

	var hb_dir = iif(self.rtl, HB_DIRECTION_RTL, HB_DIRECTION_LTR)
	var hb_buf = hb_buffer_create()
	hb_buffer_set_cluster_level(hb_buf,
		--HB_BUFFER_CLUSTER_LEVEL_MONOTONE_CHARACTERS
		HB_BUFFER_CLUSTER_LEVEL_MONOTONE_GRAPHEMES
		--HB_BUFFER_CLUSTER_LEVEL_CHARACTERS
	)
	hb_buffer_set_direction(hb_buf, hb_dir)
	hb_buffer_set_script(hb_buf, self.script)
	hb_buffer_set_language(hb_buf, self.lang)
	hb_buffer_add_codepoints(hb_buf, self.text.elements, self.text.len, 0, self.text.len)
	--print('shaping', font.hb_font, hb_buf, self.features.elements, self.features.len)
	hb_shape(font.hb_font, hb_buf, self.features.elements, self.features.len)
	--print'shaped'
	var len: uint32
	var info = hb_buffer_get_glyph_infos(hb_buf, &len)
	var pos  = hb_buffer_get_glyph_positions(hb_buf, &len)

	--1. scale advances and offsets based on `font.scale` (for bitmap fonts).
	--2. make the advance of each glyph relative to the start of the run
	--   so that x() is O(1) for any index.
	--3. compute the run's total advance.
	self.glyphs:init()
	self.glyphs.len = len
	var ax: num = 0.0
	for i = 0, len do
		var g = self.glyphs:at(i)
		g.glyph_index = info[i].codepoint
		g.cluster = info[i].cluster
		g.x = ax
		g.image_x_16_6 = pos[i].x_offset * font.scale
		g.image_y_16_6 = -pos[i].y_offset * font.scale
		ax = (ax + pos[i].x_advance / 64.0) * font.scale
	end
	self.advance_x = ax --for positioning in horizontal flow

	hb_buffer_destroy(hb_buf)

	self.ascent = font.ascent
	self.descent = font.descent

	self.images:init(r)
	self.images_memsize = 0

	self:compute_cursors(r, font)

	return true
end

--iterate clusters in RLE-compressed form.
local c1 = symbol(uint32)
local c0 = symbol(uint32)
local clusters_iter = rle_iterator{
	state = &GlyphRun,
	for_variables = {c0},
	declare_variables = function()        return quote var [c1], [c0] end end,
	save_values       = function()        return quote c0 = c1 end end,
	load_values       = function(self, i) return quote c1 = self.glyphs:at(i).cluster end end,
	values_different  = function()        return `c0 ~= c1 end,
}
GlyphRun.methods.cluster_runs = macro(function(self)
	return `clusters_iter{&self, 0, self.glyphs.len}
end)

local terra count_graphemes(grapheme_breaks: &arr(int8), start: int, len: int)
	var n = 0
	for i = 0, len do
		if grapheme_breaks(start+i) == 0 then
			n = n + 1
		end
	end
	return n
end

local terra next_grapheme(grapheme_breaks: &arr(int8), i: int, len: int)
	while grapheme_breaks(i) ~= 0 do
		i = i + 1
	end
	i = i + 1
	assert(i < len)
	return i
end

local get_ligature_carets = macro(function(
	r, hb_font, direction, glyph_index
)
	return quote
		var count = hb_ot_layout_get_ligature_carets(hb_font, direction,
			glyph_index, 0, nil, nil)
		r.carets_buffer.len = count
		var count_buf: uint
		hb_ot_layout_get_ligature_carets(hb_font, direction, glyph_index,
			0, &count_buf, r.carets_buffer.elements)
	in
		r.carets_buffer.elements, count_buf
	end
end)

terra GlyphRun:x(i: int)
	assert(i <= self.glyphs.len)
	return iif(i < self.glyphs.len, self.glyphs:at(i).x, self.advance_x)
end

terra GlyphRun:add_cursors(
	r: &Renderer,
	font: &Font,
	glyph_offset: int,
	glyph_len: int,
	cluster: int,
	cluster_len: int,
	cluster_x: num,
	--closure environment
	str: &codepoint,
	str_len: int
)
	self.cursor_offsets:set(cluster, cluster)
	self.cursor_xs:set(cluster, cluster_x)
	if cluster_len <= 1 then return end

	--the cluster is made of multiple codepoints. check how many
	--graphemes it contains since we need to add additional cursor
	--positions at each grapheme boundary.
	r.grapheme_breaks.len = str_len
	var lang: &char = nil --not used in current libunibreak impl.
	set_graphemebreaks_utf32(str, str_len, lang, r.grapheme_breaks.elements)
	var grapheme_count = count_graphemes(&r.grapheme_breaks, cluster, cluster_len)
	if grapheme_count <= 1 then return end

	--the cluster is made of multiple graphemes, which can be the
	--result of forming ligatures, which the font can provide carets
	--for. missing ligature carets, we divide the combined x-advance
	--of the glyphs evenly between graphemes.
	for i = glyph_offset, glyph_offset + glyph_len - 1 do
		var glyph_index = self.glyphs:at(i).glyph_index
		var cluster_x = self:x(i)
		var carets, caret_count =
			get_ligature_carets(
				r,
				font.hb_font,
				iif(self.rtl, HB_DIRECTION_RTL, HB_DIRECTION_LTR),
				glyph_index)
		if caret_count > 0 then
			-- there shouldn't be more carets than grapheme_count-1.
			caret_count = min(caret_count, grapheme_count - 1)
			--add the ligature carets from the font.
			for i = 0, caret_count-1 do
				--create a synthetic cluster at each grapheme boundary.
				cluster = next_grapheme(&r.grapheme_breaks, cluster, str_len)
				var lig_x = carets[i] / 64.0
				self.cursor_offsets:set(cluster, cluster)
				self.cursor_xs:set(cluster, cluster_x + lig_x)
			end
			--infer the number of graphemes in the glyph as being
			--the number of ligature carets in the glyph + 1.
			grapheme_count = grapheme_count - (caret_count + 1)
		else
			--font doesn't provide carets: add synthetic carets by
			--dividing the total x-advance of the remaining glyphs
			--evenly between remaining graphemes.
			var next_i = glyph_offset + glyph_len
			var total_advance_x = self:x(next_i) - self:x(i)
			var w = total_advance_x / grapheme_count
			for i = 1, grapheme_count-1 do
				--create a synthetic cluster at each grapheme boundary.
				cluster = next_grapheme(&r.grapheme_breaks, cluster, str_len)
				var lig_x = i * w
				self.cursor_offsets:set(cluster, cluster)
				self.cursor_xs:set(cluster, cluster_x + lig_x)
			end
			grapheme_count = 0
		end
		if grapheme_count == 0 then
			break --all graphemes have carets
		end
	end
end

terra GlyphRun:compute_cursors(r: &Renderer, f: &Font)

	--NOTE: cursors are kept in logical order.
	self.cursor_offsets:init()
	self.cursor_offsets.len = self.text.len + 1
	self.cursor_xs:init()
	self.cursor_xs.len = self.text.len + 1
	for i,offset in self.cursor_offsets do
		@offset = -1 --invalid offset, fixed later
	end

	if self.rtl then
		--add last logical (first visual), after-the-text cursor
		self.cursor_offsets:set(self.text.len, self.text.len)
		self.cursor_xs:set(self.text.len, 0)
		var i: int = -1 --index in glyph_info
		var n: int --glyph count
		var c: int --cluster
		var cn: int --cluster len
		var cx: num --cluster x
		c = self.text.len
		var cluster_runs = self:cluster_runs()
		for i1, n1, c1 in cluster_runs do
			cx = self:x(i1)
			if i ~= -1 then
				self:add_cursors(r, f, i, n, c, cn, cx, self.text.elements, self.text.len)
			end
			var cn1 = c - c1
			i, n, c, cn = i1, n1, c1, cn1
		end
		if i ~= -1 then
			cx = self.advance_x
			self:add_cursors(r, f, i, n, c, cn, cx, self.text.elements, self.text.len)
		end
	else
		var i: int = -1 --index in glyph_info
		var n: int --glyph count
		var c: int = -1 --cluster
		var cx: num --cluster x
		var cluster_runs = self:cluster_runs()
		for i1, n1, c1 in cluster_runs do
			if c ~= -1 then
				var cn = c1 - c
				self:add_cursors(r, f, i, n, c, cn, cx, self.text.elements, self.text.len)
			end
			var cx1 = self:x(i1)
			i, n, c, cx = i1, n1, c1, cx1
		end
		if i ~= -1 then
			var cn = self.text.len - c
			self:add_cursors(r, f, i, n, c, cn, cx, self.text.elements, self.text.len)
		end
		--add last logical (last visual), after-the-text cursor
		self.cursor_offsets:set(self.text.len, self.text.len)
		self.cursor_xs:set(self.text.len, self.advance_x)
	end

	--add cursor offsets for all codepoints which are missing one.
	if r.grapheme_breaks.len > 0 then --there are clusters with multiple codepoints.
		var c: int --cluster
		var x: num --cluster x
		for i = 0, self.text.len + 1 do
			if self.cursor_offsets(i) == -1 then
				self.cursor_offsets:set(i, c)
				self.cursor_xs:set(i, x)
			else
				c = self.cursor_offsets(i)
				x = self.cursor_xs(i)
			end
		end
	end

	--compute `wrap_advance_x` by removing the advance of the trailing space.
	var wx = self.advance_x
	if self.trailing_space then
		var i = iif(self.rtl, 0, self.glyphs.len-1)
		assert(self.glyphs:at(i).cluster == self.text.len-1)
		wx = wx - (self:x(i+1) - self:x(i))
	end
	self.wrap_advance_x = wx
end

terra Renderer:shape_word(glyph_run: GlyphRun)
	--get the shaped run from cache or shape it and cache it.
	var glyph_run_id, pair = self.glyph_runs:get(glyph_run)
	if pair == nil then
		if glyph_run:shape(self) then
			glyph_run_id, pair = self.glyph_runs:put(glyph_run, {})
			assert(pair ~= nil)
		end
	end
	return glyph_run_id, &pair.key
end
