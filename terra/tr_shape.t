--[[

	Shaping a piece of text into an array of glyphs called a glyph run.

	A glyph run contains enough info for both rasterization and positioning
	of each glyph. It also contains cursor position info for each codepoint
	(not glyph!). See below for the logic on computing these.

]]

if not ... then require'terra/tr_test'; return end

setfenv(1, require'terra/tr_types')
require'terra/tr_font'
require'terra/tr_rle'

terra GlyphRun.methods.compute_cursors :: {&GlyphRun, &Renderer, &FontFace} -> {}

terra GlyphRun:shape(r: &Renderer, face: &FontFace)
	self.text = self.text:copy()
	self.features = self.features:copy()

	var hb_dir = iif(self.rtl, HB_DIRECTION_RTL, HB_DIRECTION_LTR)
	var hb_buf = hb_buffer_create()

	--see https://harfbuzz.github.io/clusters.html
	hb_buffer_set_cluster_level(hb_buf,
		HB_BUFFER_CLUSTER_LEVEL_MONOTONE_GRAPHEMES) --old Harfbuzz behavior
		--HB_BUFFER_CLUSTER_LEVEL_MONOTONE_CHARACTERS)

	hb_buffer_set_direction(hb_buf, hb_dir)
	hb_buffer_set_script(hb_buf, self.script)
	hb_buffer_set_language(hb_buf, self.lang)
	hb_buffer_add_codepoints(hb_buf, self.text.elements, self.text.len, 0, self.text.len)
	hb_shape(face.hb_font, hb_buf, self.features.elements, self.features.len)

	var len: uint32
	var info = hb_buffer_get_glyph_infos(hb_buf, &len)
	var pos  = hb_buffer_get_glyph_positions(hb_buf, &len)

	--1. scale advances and offsets based on `face.scale` (for bitmap fonts).
	--2. make the advance of each glyph relative to the start of the run
	--   so that x() is O(1) for any index.
	--3. compute the run's total advance.
	self.glyphs:init()
	self.glyphs.len = len
	var ax: num = 0.0
	for i,g in self.glyphs do
		g.glyph_index = info[i].codepoint
		g.cluster = info[i].cluster
		g.x = ax
		g.image_x_16_6 =  pos[i].x_offset * face.scale
		g.image_y_16_6 = -pos[i].y_offset * face.scale
		ax = (ax + pos[i].x_advance / 64.0) * face.scale
	end
	self.metrics.advance_x = ax --for positioning in horizontal flow
	self.metrics.ascent = face.ascent
	self.metrics.descent = face.descent

	hb_buffer_destroy(hb_buf)

	self.images:init()
	self.images_memsize = 0

	self:compute_cursors(r, face)
end

terra Renderer:shape(run: GlyphRun, face: &FontFace)
	--get the shaped run from cache or shape it and cache it.
	var run_id, pair = self.glyph_runs:get(run)
	if pair == nil then
		run:shape(self, face)
		run_id, pair = self.glyph_runs:put(run, {})
		assert(pair ~= nil)
	end
	return run_id, &pair.key
end

--computing cursor positions -------------------------------------------------

do --iterate clusters in RLE-compressed form.

	local c1 = symbol(uint32)
	local c0 = symbol(uint32)

	local clusters_iter = rle_iterator{
		state_t = &GlyphRun,
		for_variables = {c0},
		declare_variables = function()        return quote var [c1], [c0] end end,
		save_values       = function()        return quote c0 = c1 end end,
		load_values       = function(self, i) return quote c1 = self.glyphs:at(i).cluster end end,
		values_different  = function()        return `c0 ~= c1 end,
	}

	GlyphRun.methods.cluster_runs = macro(function(self)
		return `clusters_iter{&self, 0, self.glyphs.len}
	end)

end

local terra count_graphemes(grapheme_breaks: arrview(char), start: int, len: int)
	var n = 0
	for i = start, start + len do
		if grapheme_breaks(i) == 0 then
			n = n + 1
		end
	end
	return n
end

local terra next_grapheme(grapheme_breaks: arrview(char), i: int, len: int)
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
	return iif(i == self.glyphs.len, self.metrics.advance_x, self.glyphs:at(i).x)
end

terra GlyphRun:add_cursors(
	r: &Renderer,
	face: &FontFace,
	glyph_offset: int,
	glyph_len: int,
	cluster: int,
	cluster_len: int,
	cluster_x: num
)
	self.cursors.offsets:set(cluster, cluster)
	self.cursors.xs:set(cluster, cluster_x)
	if cluster_len <= 1 then return end

	var str = self.text.elements
	var str_len = self.text.len

	--the cluster is made of multiple codepoints. check how many
	--graphemes it contains since we need to add additional cursor
	--positions at each grapheme boundary.
	r.grapheme_breaks.len = str_len
	var lang: &char = nil --not used in current libunibreak impl.
	set_graphemebreaks_utf32(str, str_len, lang, r.grapheme_breaks.elements)
	var grapheme_count = count_graphemes(r.grapheme_breaks.view, cluster, cluster_len)
	if grapheme_count <= 1 then return end

	--the cluster is made of multiple graphemes, which can be the
	--result of forming ligatures, which the font can provide carets
	--for. missing ligature carets, we divide the combined x-advance
	--of the glyphs evenly between graphemes.
	for i = glyph_offset, glyph_offset + glyph_len do
		var glyph_index = self.glyphs:at(i).glyph_index
		var cluster_x = self:x(i)
		var carets, caret_count =
			get_ligature_carets(
				r,
				face.hb_font,
				iif(self.rtl, HB_DIRECTION_RTL, HB_DIRECTION_LTR),
				glyph_index)
		if caret_count > 0 then
			-- there shouldn't be more carets than grapheme_count-1.
			caret_count = min(caret_count, grapheme_count - 1)
			--add the ligature carets from the font.
			for i = 0, caret_count do
				--create a synthetic cluster at each grapheme boundary.
				cluster = next_grapheme(r.grapheme_breaks.view, cluster, str_len)
				var lig_x = carets[i] / 64.0
				self.cursors.offsets:set(cluster, cluster)
				self.cursors.xs:set(cluster, cluster_x + lig_x)
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
			for i = 1, grapheme_count do
				--create a synthetic cluster at each grapheme boundary.
				cluster = next_grapheme(r.grapheme_breaks.view, cluster, str_len)
				var lig_x = i * w
				self.cursors.offsets:set(cluster, cluster)
				self.cursors.xs:set(cluster, cluster_x + lig_x)
			end
			grapheme_count = 0
		end
		if grapheme_count == 0 then
			break --all graphemes have carets
		end
	end
end

terra GlyphRun:compute_cursors(r: &Renderer, f: &FontFace)

	--NOTE: cursors are kept in logical order.
	self.cursors:init()
	self.cursors.offsets.len = self.text.len + 1
	self.cursors.xs:init()
	self.cursors.xs.len = self.text.len + 1
	self.cursors.offsets:fill(-1) --set all to invalid offset, fixed later
	r.grapheme_breaks.len = 0

	if self.rtl then
		--add last logical (first visual), after-the-text cursor
		self.cursors.offsets:set(self.text.len, self.text.len)
		self.cursors.xs:set(self.text.len, 0)
		var i: int = -1 --index in glyph_info
		var n: int --glyph count
		var c: int --cluster
		var cn: int --cluster len
		var cx: num --cluster x
		c = self.text.len
		for i1, n1, c1 in self:cluster_runs() do
			cx = self:x(i1)
			if i ~= -1 then
				self:add_cursors(r, f, i, n, c, cn, cx)
			end
			var cn1 = c - c1
			i, n, c, cn = i1, n1, c1, cn1
		end
		if i ~= -1 then
			cx = self.metrics.advance_x
			self:add_cursors(r, f, i, n, c, cn, cx)
		end
	else
		var i: int = -1 --index in glyph_info
		var n: int --glyph count
		var c: int = -1 --cluster
		var cx: num --cluster x
		for i1, n1, c1 in self:cluster_runs() do
			if c ~= -1 then
				var cn = c1 - c
				self:add_cursors(r, f, i, n, c, cn, cx)
			end
			var cx1 = self:x(i1)
			i, n, c, cx = i1, n1, c1, cx1
		end
		if i ~= -1 then
			var cn = self.text.len - c
			self:add_cursors(r, f, i, n, c, cn, cx)
		end
		--add last logical (last visual), after-the-text cursor
		self.cursors.offsets:set(self.text.len, self.text.len)
		self.cursors.xs:set(self.text.len, self.metrics.advance_x)
	end

	--add cursor offsets for all codepoints which are missing one.
	if r.grapheme_breaks.len > 0 then --there are clusters with multiple codepoints.
		var c: int --cluster
		var x: num --cluster x
		for i = 0, self.text.len + 1 do
			if self.cursors.offsets(i) == -1 then
				self.cursors.offsets:set(i, c)
				self.cursors.xs:set(i, x)
			else
				c = self.cursors.offsets(i)
				x = self.cursors.xs(i)
			end
		end
	end

	--compute `wrap_advance_x` by removing the advance of the trailing space.
	var wx = self.metrics.advance_x
	if self.trailing_space then
		var i = iif(self.rtl, 0, self.glyphs.len-1)
		assert(self.glyphs:at(i).cluster == self.text.len-1)
		wx = wx - (self:x(i+1) - self:x(i))
	end
	self.metrics.wrap_advance_x = wx
end
