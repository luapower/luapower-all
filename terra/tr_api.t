
--C/ffi API.

require'terra/memcheck'
require'terra/tr_paint_cairo'
setfenv(1, require'terra/tr')

--Renderer API

terra tr_renderer_sizeof()
	return [int](sizeof(Renderer))
end
terra tr_renderer_new(load_font: FontLoadFunc, unload_font: FontLoadFunc)
	return new(Renderer, load_font, unload_font)
end
terra Renderer:release()
	release(self)
end

--Layout API

terra tr_layout_sizeof()
	return [int](sizeof(Layout))
end
terra Renderer:layout()
	return new(Layout, self)
end
terra Layout:release()
	release(self)
end

terra Layout:cursor_xs_c(line_i: int, outlen: &int)
	var xs = self:cursor_xs(line_i)
	@outlen = xs.len
	return xs.elements
end

--[[
terra Layout:get_bidi()
	assert(self.state >= STATE_SHAPED)
	return self.bidi
end

terra Layout:get_base_dir()
	assert(self.state >= STATE_SHAPED)
	return self.base_dir
end

terra Layout:get_line_count()
	assert(self.state >= STATE_WRAPPED)
	return self.lines.len
end

terra Layout:get_line(line_i: int)
	assert(self.state >= STATE_WRAPPED)
	return self.lines:at(line_i)
end

terra Layout:get_max_ax()
	assert(self.state >= STATE_WRAPPED)
	return self.max_ax
end

terra Layout:get_h()
	assert(self.state >= STATE_WRAPPED)
	return self.h
end

terra Layout:get_spaced_h()
	assert(self.state >= STATE_WRAPPED)
	return self.spaced_h
end

terra Layout:get_baseline()
	assert(self.state >= STATE_ALIGNED)
	return self.baseline
end

terra Layout:get_min_x()
	assert(self.state >= STATE_WRAPPED)
	return self.min_x
end

terra Layout:get_first_visible_line()
	assert(self.clip_valid)
	return self.first_visible_line
end

terra Layout:get_last_visible_line()
	assert(self.clip_valid)
	return self.last_visible_line
end

--line API

terra Line:get_x() return self.x end
terra Line:get_y() return self.y end
terra Line:get_advance_x() return self.advance_x end
terra Line:get_ascent() return self.ascent end
terra Line:get_descent() return self.descent end
terra Line:get_spaced_ascent() return self.spaced_ascent end
terra Line:get_spaced_descent() return self.spaced_descent end
terra Line:get_spacing() return self.spacing end

--segment API

	line_num: int; --physical line number
	--for line breaking
	linebreak: enum;
	--for bidi reordering
	bidi_level: FriBidiLevel;
	--for cursor positioning
	span: &Span; --span of the first sub-segment
	offset: int; --codepoint offset into the text
	line_index: int;
	--slots filled by layouting
	x: num;
	advance_x: num; --segment's x-axis boundaries
	next_vis: &Seg; --next segment on the same line in visual order
	wrapped: bool; --segment is the last on a wrapped line
	visible: bool; --segment is not entirely clipped
	subsegs: arr(SubSeg);

	first: &Seg; --first segment in text order
	first_vis: &Seg; --first segment in visual order

]]

--cursor API

terra Cursor:rect_c(x: &num, y: &num, w: &num, h: &num)
	@x, @y, @w, @h = self:rect()
end

terra Cursor:get_visible() return self.visible end
terra Cursor:set_visible(v: bool) self.visible = v end

function build()
	local trlib = publish'tr'

	trlib(tr_renderer_sizeof)
	trlib(tr_renderer_new)

	if memtotal then
		trlib(memtotal)
		trlib(memreport)
	end

	trlib(Renderer, {
		init=1,
		free=1,
		release=1,

		get_glyph_run_cache_max_size=1,
		set_glyph_run_cache_max_size=1,
		get_glyph_run_cache_size=1,
		get_glyph_run_cache_count=1,

		get_glyph_cache_max_size=1,
		set_glyph_cache_max_size=1,
		get_glyph_cache_size=1,
		get_glyph_cache_count=1,

		font=1,
		free_font=1,

		layout=1, --must call layout:release() if created this way!

		get_paint_glyph_num=1,
		set_paint_glyph_num=1,

	}, {
		cname = 'tr_renderer_t',
		cprefix = 'tr_renderer_',
		opaque = true,
	})

	trlib(tr_layout_sizeof)

	trlib(Layout, {
		init=1,
		free=1,
		release=1,

		get_text=1,
		get_text_len=1,
		set_text=1,

		get_text_utf8=1,
		set_text_utf8=1,

		get_maxlen=1,
		set_maxlen=1,

		get_dir=1,
		set_dir=1,

		get_align_w=1,
		get_align_h=1,
		get_align_x=1,
		get_align_y=1,

		set_align_w=1,
		set_align_h=1,
		set_align_x=1,
		set_align_y=1,

		get_clip_x=1,
		get_clip_y=1,
		get_clip_w=1,
		get_clip_h=1,

		set_clip_x=1,
		set_clip_y=1,
		set_clip_w=1,
		set_clip_h=1,
		set_clip_extents=1,

		get_x=1,
		get_y=1,
		set_x=1,
		set_y=1,

		get_font_id           =1,
		get_font_size         =1,
		get_features          =1,
		get_script            =1,
		get_lang              =1,
		get_paragraph_dir     =1,
		get_line_spacing      =1,
		get_hardline_spacing  =1,
		get_paragraph_spacing =1,
		get_nowrap            =1,
		get_color             =1,
		get_opacity           =1,
		get_operator          =1,

		set_font_id           =1,
		set_font_size         =1,
		set_features          =1,
		set_script            =1,
		set_lang              =1,
		set_paragraph_dir     =1,
		set_line_spacing      =1,
		set_hardline_spacing  =1,
		set_paragraph_spacing =1,
		set_nowrap            =1,
		set_color             =1,
		set_opacity           =1,
		set_operator          =1,

		get_visible=1,
		get_clipped=1,

		shape=1,
		wrap=1,
		spaceout=1,
		align=1,
		clip=1,
		layout=1,
		paint=1,

		--get_bidi=1,
		--get_base_dir=1,
		--get_line_count=1,
		--get_line=1,
		--get_max_ax=1,
		--get_h=1,
		--get_spaced_h=1,
		--get_baseline=1,
		--get_min_x=1,
		--get_first_visible_line=1,
		--get_last_visible_line=1,

		get_line_count=1,
		get_line=1,

		selection=1,

	}, {
		cname = 'tr_layout_t',
		cprefix = 'tr_layout_',
		opaque = true,
	})

	trlib(Line, {


	}, {
		cname = 'tr_line_t',
		cprefix = 'tr_line_',
		opaque = true,
	})


	trlib(Cursor, {

		get_visible=1,
		set_visible=1,

		get_offset=1,
		get_rtl=1,

		rect_c='rect',

		move_to_offset=1,
		move_to_rel_cursor=1,
		move_to_line=1,
		move_to_pos=1,
		move_to_page=1,
		move_to_rel_page=1,

		paint=1,

		insert=1,
		remove=1,

	}, {
		cname = 'tr_cursor_t',
		cprefix = 'tr_cursor_',
		opaque = true,
	})

	trlib(Selection, {
		release=1,

	}, {
		cname = 'tr_selection_t',
		cprefix = 'tr_selection_',
		opaque = true,
	})

	trlib:getenums(_M, nil, 'TR_')

	trlib:build{
		linkto = {'cairo', 'freetype', 'harfbuzz', 'fribidi', 'unibreak', 'xxhash'},
		--optimize = false,
	}

end

if not ... then
	build()
end

return _M
