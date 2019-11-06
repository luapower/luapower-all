--[[

	Cursor navigation and hit testing and text selection.

	Cursor navigation follows the logical text order, not the visual order.
	Moving the cursor to a new position can select the text in between or not.

	Cursor navigation and hit-testing is only available on aligned text.
	Cursor state can be set anytime and it survives re-shapes. The `x` field
	must be re-computed after re-align.

	The segments array contain the shaped text segments in logical text order.

	Each glyph run (thus each segment) holds two parallel arrays, `cursors.xs`
	and `cursors.offsets`, containing cursor position information for every
	codepoint in the segment plus one, eg. the text "ab cd" results in segments
	"ab " and "cd" with cursor positions "|a|b| |" and "|c|d|", so 4 and 3
	cursor positions respectively, and with the last position on segment "ab "
	being the same as the first position on segment "cd".

	`cursors.offsets` maps a codepoint offset to the codepoint offset for which
	there is a cursor position that can be landed on, since not every codepoint
	can have a cursor position. So `cursors.offsets` can have duplicate values
	(which are always clumped together; the array is not necessarily monotonic).

	`cursors.xs` maps a codepoint offset to the x-coord of the cursor position
	in front of that codepoint (or after it for the last element).
	Adjacent offset-distinct cursor positions have different x-coords.

	The mapping between text offsets and visually-distinct cursor positions is
	not 1:1 like it is on most (all?) text editors, but 1:2, in two cases:
	1. In mixed RTL/LTR lines, at the offsets where the direction changes.
	2. At the offset right after the last character on a wrapped line.
	You can navigate between these visually-distinct-but-logically-the-same
	positions using CURSOR_MODE_POS, or you can skip them with CURSOR_MODE_CHAR
	which brings back the normal behavior of most editors.

]]

if not ... then require'terra/tr_test'; return end

setfenv(1, require'terra/tr_types')
require'terra/tr_align'
require'terra/tr_paint'

--get offset in logical text for a valid cursor position ---------------------

terra Layout:offset_at_cursor(p: Pos) -- O(1)
	if p.seg ~= nil then
		return p.seg.offset + self:seg_cursors(p.seg).offsets(p.i)
	else
		assert(p.i == 0)
		return 0
	end
end

--cursor navigation & hit-testing --------------------------------------------

--custom function that answers the question:
--	"is this cursor position a valid cursor position?"
valid_t = {&opaque, Pos} -> {bool}

--custom function that answers the question:
-- "is this valid cursor position distinct from the last valid cursor position?"
distinct_t  = {&opaque, Pos, Pos, enum, enum} -> {bool}

--cursor linear navigation ---------------------------------------------------

local NEXT, PREV, CURR = 1, 2, 3

CURSOR_DIR_NEXT = NEXT
CURSOR_DIR_PREV = PREV
CURSOR_DIR_CURR = CURR

CURSOR_DIR_MIN  = NEXT
CURSOR_DIR_MAX  = CURR

--next/prev valid cursor position from any position (valid or invalid).
terra Layout:rel_physical_cursor(
	p: Pos, dir: enum,
	valid: valid_t, obj: &opaque
)
	if p.seg == nil then
		return p
	end
	repeat
		if dir == NEXT then
			if p.i >= self:seg_cursors(p.seg).len-1 then
				p.seg = self.segs:next(p.seg, nil)
				p.i = 0
				if p.seg == nil then
					return p
				end
			else
				inc(p.i)
			end
		elseif dir == PREV then
			if p.i <= 0 then
				p.seg = self.segs:prev(p.seg, nil)
				if p.seg == nil then
					p.i = 0
					return p
				end
				p.i = self:seg_cursors(p.seg).xs.len-1
			else
				dec(p.i)
			end
		else
			assert(false)
		end
	until valid(obj, p)
	return p
end

local FIRST, LAST = 0, 1

CURSOR_WHICH_FIRST = FIRST
CURSOR_WHICH_LAST  = LAST

CURSOR_WHICH_MIN = FIRST
CURSOR_WHICH_MAX = LAST

--next/prev valid _and_ distinct cursor position from a *valid* position.
--`dir` controls which distinct cursor to return. `which` controls which
--non-distinct cursor to return once a distinct cursor was found.
terra Layout:rel_cursor(
	p: Pos, dir: enum, mode: enum, which: enum,
	distinct: distinct_t, valid: valid_t, obj: &opaque
): Pos
	assert(which == FIRST or which == LAST)
	if dir == NEXT or dir == PREV then --find prev/next distinct position
		::again::
		var p1 = self:rel_physical_cursor(p, dir, valid, obj)
		if p1.seg == nil then --bot/eot
			return p1
		elseif not distinct(obj, p1, p, dir, mode) then --still not distinct
			p = p1
			goto again
		elseif which == iif(dir == NEXT, FIRST, LAST) then --already there
			return p1
		end
		var which_curr = iif(dir == NEXT, LAST, FIRST)
		return self:rel_cursor(p1, CURR, mode, which_curr, distinct, valid, obj)
	elseif dir == CURR then --find first/last non-distinct position
		var dir = iif(which == FIRST, PREV, NEXT)
		::again_curr::
		var p1 = self:rel_physical_cursor(p, dir, valid, obj)
		if p1.seg == nil then --bot/eot
			return p
		elseif not distinct(obj, p1, p, dir, mode) then --still not distinct
			p = p1
			goto again_curr
		else
			return p
		end
	else
		assert(false)
	end
end

--find a cursor position for a logical text position -------------------------

--returns -1 if segs.len == 0, otherwise always returns a valid index.
local terra cmp_offsets(seg1: &Seg, seg2: &Seg)
	return seg1.offset <= seg2.offset -- < < = = [>] >
end
terra Layout:seg_at_offset(offset: int)
	return self.segs:binsearch(Seg{offset = offset}, cmp_offsets) - 1
end

--returns a valid position that is neither FIRST nor LAST for sure.
terra Layout:cursor_at_offset(offset: int, valid: valid_t, obj: &opaque) -- O(log n)
	var seg_i = self:seg_at_offset(offset)
	if seg_i >= 0 then
		var seg = self.segs:at(seg_i)
		var i = offset - seg.offset
		assert(i >= 0)
		var offsets = self:seg_cursors(seg).offsets.view
		i = offsets:clamp(i) --fix if inside inter-segment gap.
		i = offsets(i) --fix if in-between navigable offsets.
		var p = Pos{seg, i}
		if not valid(obj, p) then --fix if position is not valid.
			return self:rel_physical_cursor(p, PREV, valid, obj)
		else
			return p
		end
	else
		return Pos{nil, 0}
	end
end

--cursor hit-testing ---------------------------------------------------------

--hit-test a line for a cursor position given a line number and an x-coord.
--NOTE: because of distinct() we need to do a linear scan of all cursor
--positionsin logical order and find the one that is closest to x.
terra Layout:hit_test_cursors(
	line_i: int, x: num, mode: enum,
	distinct: distinct_t, valid: valid_t, obj: &opaque
)
	var line_i = self.lines:clamp(line_i)
	var line = self.lines:at(line_i)
	var x = x - self.x - line.x
	var min_d: num = inf
	var cp = Pos{nil, 0} --closest cursor position
	var p0 = Pos{nil, 0} --previous cursor position
	var p  = Pos{line.first, 0}
	while p.seg ~= nil and p.seg.line_index == line_i do
		var xs = self:seg_cursors(p.seg).xs.view
		var x = x - p.seg.x
		for i = 0, xs.len do
			p.i = i
			if valid(obj, p) then
				if distinct(obj, p, p0, NEXT, mode) then
					var d = abs(xs(i) - x)
					if d < min_d then
						min_d = d
						cp = p
					end
				end
				p0 = p
			end
		end
		p.seg = self.segs:next(p.seg, nil)
	end
	return cp
end

--cursor geometry ------------------------------------------------------------

terra Layout:seg_rtl(seg: &Seg)
	return iif(seg ~= nil, seg.rtl, false)
end

terra Layout:seg_line(seg: &Seg)
	return self.lines:at(iif(seg ~= nil, seg.line_index, 0))
end

--cursor's x-coord relative to line_pos().
terra Layout:cursor_rel_x(p: Pos)
	if p.seg ~= nil then
		return p.seg.x + self:seg_cursors(p.seg).xs(p.i)
	else
		return 0
	end
end

--caret rectangle. its position is relative to line_pos().
terra Layout:cursor_rect(p: Pos, w: num, forward: bool, underline: bool)
	var face = iif(p.seg ~= nil, p.seg.span.face, self.spans:at(0).face)
	var line = self:seg_line(p.seg)
	var x = self:cursor_rel_x(p)
	var thickness = max(face.underline_thickness, 1)
	var w = iif(forward, 1, -1) * w * iif(face ~= nil, thickness, 1)
	var y = iif(underline and face ~= nil, -face.underline_position, -line.spaced_ascent)
	var h = iif(underline and face ~= nil,  thickness, line.spaced_ascent - line.spaced_descent)
	if w < 0 then
		x, w = x + w, -w
	end
	return x, y, w, h
end

--Iterate all visually-unique cursor positions in visual order.
--Useful for mapping editbox password bullet positions to actual positions.
terra Layout:cursor_xs(line_i: int)
	self.r.xsbuf.len = 0
	var line = self.lines:at(line_i, nil)
	if line ~= nil then
		var seg = line.first_vis
		var last_x = nan
		while seg ~= nil do
			var xs = self:seg_cursors(seg).xs.view:ipairs(not seg.rtl)
			for i,x in xs do
				var x = seg.x + @x
				if x ~= last_x then
					self.r.xsbuf:add(x)
				end
				last_x = x
			end
			seg = seg.next_vis
		end
	end
	return self.r.xsbuf
end

------------------------------------------------------------------------------
--cursor object
------------------------------------------------------------------------------

terra Cursor:init(layout: &Layout)
	@self = [Cursor.empty_const]
	self.layout = layout
end

terra Cursor.methods.at_pos :: {&Cursor, Pos} -> {int, enum}

terra Cursor:set_to_pos(p: Pos, x: num, select: bool)
	if isnan(x) then x = self.state.x end
	var offset, which = self:at_pos(p)
	if    self.state.offset ~= offset
		or self.state.which  ~= which
		or self.state.x      ~= x
		or (not select and (
			   self.state.sel_offset ~= offset
			or self.state.sel_which  ~= which
			))
	then
		self.state.offset = offset
		self.state.which  = which
		self.state.x      = x
		if not select then
			self.state.sel_offset = offset
			self.state.sel_which = which
		end
		return true
	else
		return false
	end
end

--cursor linear navigation ---------------------------------------------------

local DEFAULT, POS, CHAR, WORD, LINE = 0, 1, 2, 3, 4

CURSOR_MODE_DEFAULT = DEFAULT --POS or CHAR, based on cursor.unique_offsets
CURSOR_MODE_POS     = POS
CURSOR_MODE_CHAR    = CHAR
CURSOR_MODE_WORD    = WORD
CURSOR_MODE_LINE    = LINE

CURSOR_MODE_MIN = POS
CURSOR_MODE_MAX = LINE

local terra valid(obj: &opaque, p: Pos)
	var self = [&Cursor](obj)
	var cursors = self.layout:seg_cursors(p.seg)
	--any position but the last position in a segment is always valid.
	if p.i ~= cursors.len-1 then
		return true
	end
	--the last position on a hardbreak line is always valid.
	if p.seg.linebreak >= BREAK_LINE then
		return true
	end
	--the last position on a wrapped line in `wrapped_space` mode is valid
	--even when that position is a trailing space.
	if self.wrapped_space and p.seg.wrapped then
		return true
	end
	--the last position of a segment that is a duplicate of the first position
	--of the next segment is invalid, unless bidi direction changes.
	--normally we wouldn't care about that but justify-align makes these two
	--positions visually distinct so we have to invalide one of them.
	var next_seg = self.layout.segs:next(p.seg, nil)
	if next_seg ~= nil then
		if p.seg.rtl == next_seg.rtl then
			return false
		end
	end
	--last position, duplicate but bidi direction changes so keep it.
	return true
end

local terra distinct(obj: &opaque, p: Pos, p0: Pos, dir: enum, mode: enum)
	var self = [&Cursor](obj)
	if p0.seg == nil then
		return true
	end
	if mode == DEFAULT then
		mode = iif(self.unique_offsets, CHAR, POS)
	end
	if mode == POS then
		return p.seg.line_index ~= p0.seg.line_index
			or self.layout:cursor_rel_x(p) ~= self.layout:cursor_rel_x(p0)
			or self.layout:offset_at_cursor(p) ~= self.layout:offset_at_cursor(p0)
	elseif mode == CHAR then
		return
			self.layout:offset_at_cursor(p) ~=
			self.layout:offset_at_cursor(p0)
	elseif mode == WORD then
		return p.seg ~= p0.seg
			and ((dir == NEXT and p0.seg.linebreak > BREAK_NONE)
				or (dir == PREV and p.seg.linebreak > BREAK_NONE))
	elseif mode == LINE then
		return p.seg.line_num ~= p0.seg.line_num
	else
		assert(false)
	end
end

terra Cursor:abs_x(p: Pos)
	var x = self.layout:cursor_rel_x(p)
	var x0, _ = self.layout:line_pos(self.layout:seg_line(p.seg))
	return x0 + x
end

terra Cursor:at_pos(p: Pos)
	var offset = self.layout:offset_at_cursor(p)
	var first_p = self.layout:rel_cursor(p, CURR, DEFAULT, FIRST, distinct, valid, self)
	return offset, enum(iif(first_p.seg == p.seg and first_p.i == p.i, FIRST, LAST))
end

terra Cursor:pos_at(offset: int, which: enum)
	var p = self.layout:cursor_at_offset(offset, valid, self)
	return self.layout:rel_cursor(p, CURR, CHAR, which, distinct, valid, self)
end
terra Cursor:move_to(offset: int, which: enum, select: bool)
	var p = self:pos_at(offset, which)
	return self:set_to_pos(p, self:abs_x(p), select)
end

terra Cursor:get_pos()
	return self:pos_at(self.state.offset, self.state.which)
end

terra Cursor:pos_near_pos(p: Pos, dir: enum, mode: enum, which: enum, clamp: bool)
	var p = self.layout:rel_cursor(p, dir, mode, which, distinct, valid, self)
	if p.seg == nil and clamp then
		var last = dir == NEXT or (dir == CURR and which == LAST)
		var which = iif(last, LAST, FIRST)
		return self:pos_at(iif(last, maxint, 0), which)
	end
	return p
end

terra Cursor:pos_near(dir: enum, mode: enum, which: enum, clamp: bool)
	return self:pos_near_pos(self.pos, dir, mode, which, clamp)
end
terra Cursor:move_near(dir: enum, mode: enum, which: enum, select: bool)
	var p = self:pos_near_pos(self.pos, dir, mode, which, true)
	return self:set_to_pos(p, self:abs_x(p), select)
end

---cursor vertical navigation ------------------------------------------------

terra Cursor:pos_at_line(line_i: int, x: num)
	if isnan(x) then x = self.state.x end
	if line_i < 0 and self.park_home then
		return self:pos_at(0, FIRST)
	elseif line_i >= self.layout.lines.len and self.park_end then
		return self:pos_at(maxint, LAST)
	end
	return self.layout:hit_test_cursors(line_i, x, DEFAULT, distinct, valid, self)
end
terra Cursor:move_to_line(line_i: int, x: num, select: bool)
	return self:set_to_pos(self:pos_at_line(line_i, x), x, select)
end

terra Cursor:pos_near_line(delta_lines: int, x: num)
	var seg = self.pos.seg
	var line_i = iif(seg ~= nil, seg.line_index + (delta_lines or 0), 0)
	return self:pos_at_line(line_i, x)
end
terra Cursor:move_near_line(delta_lines: int, x: num, select: bool)
	return self:set_to_pos(self:pos_near_line(delta_lines, x), x, select)
end

terra Cursor:pos_at_page(page: int, x: num)
	var _, line1_y = self.layout:line_pos(self.layout.lines:at(0))
	var y = line1_y + (page - 1) * self.layout.h
	return self:pos_at_point(x, y)
end
terra Cursor:move_to_page(page: int, x: num, select: bool)
	return self:set_to_pos(self:pos_at_page(page, x), x, select)
end

terra Cursor:pos_near_page(delta_pages: int, x: num)
	var _, line_y = self.layout:line_pos(self.layout:seg_line(self.pos.seg))
	var y = line_y + (delta_pages or 0) * self.layout.h
	return self:pos_at_point(x, y)
end
terra Cursor:move_near_page(delta_pages: int, x: num, select: bool)
	return self:set_to_pos(self:pos_near_page(delta_pages, x), x, select)
end

---cursor hit-testing --------------------------------------------------------

terra Cursor:pos_at_point(x: num, y: num)
	var line_i = self.layout.lines:clamp(self.layout:hit_test_lines(y))
	return self:pos_at_line(line_i, x)
end
terra Cursor:move_to_point(x: num, y: num, select: bool)
	return self:set_to_pos(self:pos_at_point(x, y), x, select)
end

--cursor geometry ------------------------------------------------------------

terra Cursor:rect()
	var p  = self.pos
	if not self.insert_mode then
		--wide caret (spanning two adjacent cursor positions).
		var p1 = self:pos_near(NEXT, DEFAULT, FIRST, false)
		if p1.seg ~= nil and p.seg ~= nil and p1.seg.line_index == p.seg.line_index then
			var x, y, _, h = self.layout:cursor_rect(p, 0, true, true)
			var x1 = self.layout:cursor_rect(p1, 0, true, true)._0
			var w = x1 - x
			if w < 0 then
				x, w = x + w, -w
			end
			var x0, y0 = self.layout:line_pos(self.layout:seg_line(p.seg))
			return x0 + x, y0 + y, w, h
		end
	end
	--normal caret, `w`-wide to the left or right of a cursor position.
	var rtl = self.layout:seg_rtl(p.seg)
	var forward = not rtl and self.layout.align_x ~= ALIGN_RIGHT
	var x, y, w, h = self.layout:cursor_rect(p, self.caret_thickness, forward, false)
	var x0, y0 = self.layout:line_pos(self.layout:seg_line(p.seg))
	return x0 + x, y0 + y, w, h
end

--cursor drawing -------------------------------------------------------------

terra Cursor:draw_caret(cr: &context, for_shadow: bool)
	if not self.caret_visible then return end
	var x, y, w, h = self:rect()
	x = snap(x, 1)
	y = snap(y, 1)
	h = snap(h, 1)
	var color = color{uint = 0xffffffff}
	cr:operator(OPERATOR_DIFF)
	self.layout.r:draw_rect(cr, x, y, w, h, color, self.caret_opacity)
end

--selection drawing ----------------------------------------------------------

--line-relative (x, w) of a selection rectangle on two cursor
--positions in the same segment (in whatever order).
terra Layout:segment_xw(seg: &Seg, i1: int, i2: int)
	var xs = self:seg_cursors(seg).xs.view
	var i1 = xs:clamp(i1)
	var i2 = xs:clamp(i2)
	var cx1 = xs(i1)
	var cx2 = xs(i2)
	if cx1 > cx2 then
		cx1, cx2 = cx2, cx1
	end
	return seg.x + cx1, cx2 - cx1
end

--merge two (x, w) segments together, if possible.
local terra near(x1: num, x2: num)
	return x2 - x1 >= 0 and x2 - x1 < 2 --merge if < 2px gap
end
local terra merge_xw(x1: num, w1: num, x2: num, w2: num)
	if isnan(x1) then --is first
		return x2, w2, false
	elseif near(x1 + w1, x2) then --comes after
		return x1, x2 + w2 - x1, false
	elseif near(x2 + w2, x1) then --comes before
		return x2, x1 + w1 - x2, false
	else --not connected
		return x2, w2, true
	end
end

--selection rectangle of an entire line.
terra Layout:line_rect(line: &Line, spaced: bool)
	var ascent: num, descent: num
	if spaced then
		ascent, descent = line.spaced_ascent, line.spaced_descent
	else
		ascent, descent = line.ascent, line.descent
	end
	var x = self.x + line.x
	var y = self.y + self.baseline + line.y - ascent
	var w = line.advance_x
	var h = ascent - descent
	return x, y, w, h
end

terra Layout:line_visible(line_i: int)
	return line_i >= self.first_visible_line and line_i <= self.last_visible_line
end

terra Cursor:draw_selection_rect(cr: &context, x: num, y: num, w: num, h: num)
	self.layout.r:draw_rect(cr, x, y, w, h, self.selection_color, self.selection_opacity)
end

terra Cursor:get_sel_pos()
	return self:pos_at(self.state.sel_offset, self.state.sel_which)
end

terra Cursor:get_is_selection_empty()
	return self.state.sel_offset == self.state.offset
end

terra Cursor:draw_selection(cr: &context, spaced: bool, for_shadow: bool)
	if not self.selection_visible then return end
	if self.is_selection_empty then return end
	var p1: Pos, p2: Pos
	if self.state.offset < self.state.sel_offset then
		p1, p2 = self.pos, self.sel_pos
	else
		p2, p1 = self.pos, self.sel_pos
	end
	var seg = p1.seg
	while seg ~= nil and self.layout.segs:index(seg) <= self.layout.segs:index(p2.seg) do
		var line_index = seg.line_index
		if self.layout:line_visible(line_index) then
			var line = self.layout:seg_line(seg)
			var line_x, line_y, line_w, line_h = self.layout:line_rect(line, spaced)
			var x = nan
			var w = nan
			while seg ~= nil
				and self.layout.segs:index(seg) <= self.layout.segs:index(p2.seg)
				and seg.line_index == line_index
			do
				var i1 = iif(seg == p1.seg, p1.i, 0)
				var i2 = iif(seg == p2.seg, p2.i, maxint)
				var x1, w1 = self.layout:segment_xw(seg, i1, i2)
				var failed: bool
				x1, w1, failed = merge_xw(x, w, x1, w1)
				if failed then
					self:draw_selection_rect(cr, line_x + x, line_y, w, line_h)
				end
				x, w = x1, w1
				seg = self.layout.segs:next(seg, nil)
			end
			self:draw_selection_rect(cr, line_x + x, line_y, w, line_h)
		else
			var next_line = self.layout.lines:at(line_index + 1, nil)
			seg = iif(next_line ~= nil, next_line.first, nil)
		end
	end
end
