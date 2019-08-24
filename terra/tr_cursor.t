
--Cursor navigation and hit testing.

if not ... then require'terra/tr_test'; return end

setfenv(1, require'terra/tr_types')
require'terra/tr_font'
require'terra/tr_hit_test'
require'terra/tr_paint'

terra Layout:line_pos(line: &Line)
	assert(self.state >= STATE_ALIGNED)
	self.lines:index(line)
	var x = self.x + line.x
	var y = self.y + self.baseline + line.y
	return x, y
end

terra Layout:seg_line(seg: &Seg)
	assert(self.state >= STATE_ALIGNED)
	if seg ~= nil then
		self.segs:index(seg)
		return self.lines:at(seg.line_index)
	else
		return self.lines:at(0)
	end
end

terra Pos:get_x() --relative to line_pos().
	assert(self.layout.state >= STATE_SHAPED)
	self.layout.segs:index(self.seg)
	if self.seg ~= nil then
		var run = self.layout:glyph_run(self.seg)
		return self.seg.x + run.cursor_xs(self.i)
	else
		return 0
	end
end

terra Pos:get_line()
	return self.layout:seg_line(self.seg)
end

terra Pos:line_pos()
	return self.layout:line_pos(self.line)
end

terra Pos:get_rtl()
	return iif(self.seg ~= nil, self.layout:glyph_run(self.seg).rtl, false)
end

terra Pos:cursor_rect(w: num, forward: bool) --relative to line_pos.
	assert(self.layout.state >= STATE_ALIGNED)
	var line = self.line
	var x = self.x
	var y = -line.ascent
	var w = iif(forward ~= false, 1, -1) * iif(isnan(w), 1, w)
	var h = line.ascent - line.descent
	if w < 0 then
		x, w = x + w, -w
	end
	return x, y, max(1, round(w * h / 50.0)), h
end

terra Layout:cursor_offset(seg: &Seg, i: int)
	assert(self.state >= STATE_SHAPED)
	var run = self:glyph_run(seg)
	return seg.offset + run.cursor_offsets(i)
end

terra Layout:pos(seg: &Seg, i: int)
	return Pos{self, seg, i, self:cursor_offset(seg, i)}
end

local terra cmp_offsets(seg1: &Seg, seg2: &Seg)
	return seg1.offset <= seg2.offset -- < < = = [<] <
end
terra Layout:cursor_at_offset(offset: int)
	assert(self.state >= STATE_SHAPED)
	var seg_i = iif(offset > 0,
		self.segs:binsearch(Seg{offset = offset}, cmp_offsets) - 1, 0)
	var seg = self.segs:at(seg_i, nil)
	if seg ~= nil then
		var i = offset - seg.offset
		assert(i >= 0)
		var run = self:glyph_run(seg)
		i = run.cursor_offsets:clamp(i) --fix if inside inter-segment gap.
		i = run.cursor_offsets(i) --normalize to the first cursor.
		return Pos{self, seg, i, offset}
	else
		return Pos{self, nil, 0, offset}
	end
end

terra Pos:reset()
	@self = self.layout:cursor_at_offset(0)
end

terra Pos:reposition()
	@self = self.layout:cursor_at_offset(self.offset)
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
			var run = self:glyph_run(seg)
			var i, j, step = 0, run.text.len, 1
			if run.rtl then
				i, j, step = j-1, i-1, -step
			end
			for i = i, j, step do
				var x = seg.x + run.cursor_xs(i)
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

--custom function that responds to the question:
-- "is this cursor position different than other cursor position?"
diff_t  = {&opaque, Pos, Pos, enum} -> {bool}

--custom function that responds to the question:
--	"is this cursor position a valid cursor position?"
valid_t = {&opaque, Pos, enum} -> {bool}

--hit-test a line for a cursor position given a line number and an x-coord.
terra Layout:hit_test_cursors(line_i: int, x: num,
	diff: diff_t, valid: valid_t, obj: &opaque, mode: enum
)
	var line_i = self.lines:clamp(line_i)
	var line = self.lines:at(line_i)
	--find the cursor position closest to x.
	var x = x - self.x - line.x
	var min_d: num = 1/0
	var cp = Pos{self, nil, 0} --closest cursor
	var p = Pos{self, line.first, 0}
	var p0 = Pos{self, nil, 0}
	while p.seg ~= nil do
		var xs = self:glyph_run(p.seg).cursor_xs
		var x = x - p.seg.x
		var d = abs(xs(p.i) - x)
		if p0.seg == nil
			or (d < min_d
				and (valid == nil or valid(obj, p, mode))
				and (diff == nil or diff(obj, p, p0, mode)))
		then
			min_d = d
			cp = p
		end
		p0 = p
		p.i = p.i + 1
		if p.i >= xs.len then
			p = Pos{self, self.segs:next(p.seg), 0}
		end
	end
	cp.offset = self:cursor_offset(cp.seg, cp.i)
	return cp
end

local DEFAULT, NEXT, PREV, CURR = 0, 1, 2, 3
CURSOR_DIR_NEXT = NEXT
CURSOR_DIR_PREV = PREV
CURSOR_DIR_CURR = CURR

--next/prev valid cursor position.
terra Layout:rel_physical_cursor(p: Pos, dir: enum,
	valid: valid_t, obj: &opaque, mode: enum
)
	if dir == DEFAULT then dir = NEXT end
	repeat
		if dir == NEXT then
			if p.i >= self:glyph_run(p.seg).cursor_xs.len-1 then
				p.seg = self.segs:next(p.seg, nil)
				if p.seg == nil then return self:pos(p.seg, 0) end
				p.i = 0
			else
				inc(p.i)
			end
		elseif dir == PREV then
			if p.i <= 0 then
				p.seg = self.segs:prev(p.seg, nil)
				if p.seg == nil then return self:pos(p.seg, 0) end
				p.i = self:glyph_run(p.seg).cursor_xs.len-1
			else
				dec(p.i)
			end
		else
			assert(false)
		end
	until valid == nil or valid(obj, p, mode)
	return p
end

local FIRST, LAST = 1, 2
CURSOR_WHICH_FIRST = FIRST
CURSOR_WHICH_LAST  = LAST

--next/prev cursor position filtered by a is-different-than-other-position
--question and a is-valid-position question.
--`dir` controls which distinct cursor to return. `which` controls which
--non-distinct cursor to return once a distinct cursor was found.
terra Layout:rel_cursor(
	p: Pos,
	dir: enum, which: enum,
	diff: diff_t, valid: valid_t, obj: &opaque, mode: enum
): Pos
	if dir == DEFAULT then dir = CURR end
	if which == DEFAULT then which = FIRST end
	assert(which == FIRST or which == LAST)
	if dir == NEXT or dir == PREV then --find prev/next distinct position
		::again::
		var p1 = self:rel_physical_cursor(p, dir, valid, obj, mode)
		if p1.seg == nil then --bos/eos
			return p1
		elseif diff ~= nil and not diff(obj, p1, p, mode) then
			p = p1
			goto again
		elseif which == iif(dir == NEXT, FIRST, LAST) then --already there
			return p1
		end
		var last = iif(dir == NEXT, LAST, FIRST)
		return self:rel_cursor(p1, CURR, last, diff, valid, obj, mode)
	elseif dir == CURR then --find first/last non-distinct position
		if diff == nil then
			return p
		end
		var dir = iif(which == FIRST, PREV, NEXT)
		var p1 = self:rel_physical_cursor(p, dir, valid, obj, mode)
		if p1.seg == nil then --bos/eos
			return p
		elseif diff(obj, p1, p, mode) then --distinct position
			return p
		end
		return self:rel_cursor(p1, CURR, which, diff, valid, obj, mode)
	else
		assert(false)
	end
end

--cursor object --------------------------------------------------------------

terra Cursor:init(layout: &Layout)
	fill(self)
	self.layout = layout
	self.p = layout:cursor_at_offset(0)
	self.park_home = true
	self.park_end = true
	self.insert_mode = true
	self.visible = true
	self.color = DEFAULT_TEXT_COLOR
	self.opacity = 1
	self.w = 1
end

terra Cursor:free()
	dealloc(self)
end

terra Layout:cursor()
	var cur = new(Cursor, self)
	self.cursors:add(cur) --takes ownership
	return cur
end

terra Cursor:release()
	var i = self.layout.cursors:find(self)
	self.layout.cursors:remove(i) --calls Cursor:free()
end

terra Cursor:rel_physical_cursor(dir: enum,
	valid: valid_t, obj: &opaque, mode: enum
)
	return self.layout:rel_physical_cursor(self.p, dir, valid, obj, mode)
end

terra Cursor:assign(c: &Cursor)
	assert(c.layout == self.layout)
	self.p = c.p
	self.x = c.x
end

terra Cursor:set(p: Pos, x: num)
	self.p = p
	if not isnan(x) then
		self.x = x
	end
end

local POS, CHAR, WORD, LINE = 1, 2, 3, 4
CURSOR_MODE_POS  = POS
CURSOR_MODE_CHAR = CHAR
CURSOR_MODE_WORD = WORD
CURSOR_MODE_LINE = LINE

terra Cursor.methods.find_at_rel_cursor :: {&Cursor, enum, enum, enum, bool} -> Pos

terra Cursor:rect()
	if not self.insert_mode then
		--wide caret (spanning two adjacent cursor positions).
		var p1 = self:find_at_rel_cursor(NEXT, DEFAULT, DEFAULT, false)
		if p1.seg ~= nil and self.p.seg ~= nil
			and p1.seg.line_index == self.p.seg.line_index
		then
			var x, y, _, h = self.p:cursor_rect(nan, false)
			var x1 = p1:cursor_rect(nan, false)._0
			var w = x1 - x
			if w < 0 then
				x, w = x + w, -w
			end
			var x0, y0 = self.p:line_pos()
			return x0 + x, y0 + y, w, h
		end
	end
	--normal caret, `w`-wide to the left or right of a cursor position.
	var forward = not self.p.rtl and self.layout.align_x ~= ALIGN_RIGHT
	var x, y, w, h = self.p:cursor_rect(self.w, forward)
	var x0, y0 = self.p:line_pos()
	return x0 + x, y0 + y, w, h
end

terra Cursor:visibility_rect()
	var x, y, w, h = self:rect()
	--enlarge the caret rect to contain the line spacing.
	var line = self.p.line
	y = y + line.ascent - line.spaced_ascent
	h = line.spaced_ascent - line.spaced_descent
	return x, y, w, h
end

local terra valid(obj: &opaque, p: Pos, mode: enum)
	var self = [&Cursor](obj)
	return not (
		not self.wrapped_space
		and p.seg.wrapped
		and p.i == self.layout:glyph_run(p.seg).cursor_xs.len-1
		and self.layout:glyph_run(p.seg).trailing_space
	)
end

local terra diff(obj: &opaque, p: Pos, p0: Pos, mode: enum)
	var self = [&Cursor](obj)
	if p0.seg == nil then
		return true
	end
	if mode == DEFAULT then mode = POS end
	if mode == POS and self.unique_offsets then
		mode = CHAR
	end
	if mode == POS then
		return
			p.seg.line_index ~= p0.seg.line_index
			or self.p.x ~= p0.x
			or self.p.offset ~= p0.offset
	elseif mode == CHAR then
		return p.offset ~= p0.offset
	elseif mode == WORD then
		return p.seg ~= p0.seg
	elseif mode == LINE then
		return p.seg.line_num ~= p0.seg.line_num
	else
		assert(false)
	end
end

terra Cursor.methods.find_at_offset :: {&Cursor, int, enum} -> Pos

terra Cursor:find_at_cursor(p: Pos, dir: enum, mode: enum, which: enum, clamp: bool)
	var p = self.layout:rel_cursor(p, dir, which, diff, valid, self, mode)
	if p.seg == nil and clamp then
		var last = dir == NEXT or (dir == CURR and which == LAST)
		return self:find_at_offset(iif(last, 1/0, 0), DEFAULT)
	end
	return p
end

terra Cursor:find_at_offset(offset: int, which: enum)
	var p = self.layout:cursor_at_offset(offset)
	if which ~= DEFAULT then
		return self:find_at_cursor(p, CURR, CHAR, which, false)
	else
		return p
	end
end
terra Cursor:move_to_offset(offset: int, which: enum)
	self:set(self:find_at_offset(offset, which), nan)
end

terra Cursor:reset()
	self.p:reset()
end

terra Cursor:reposition()
	self.p:reposition()
end

terra Cursor:find_at_rel_cursor(dir: enum, mode: enum, which: enum, clamp: bool)
	return self:find_at_cursor(self.p, dir, mode, which, clamp)
end
terra Cursor:move_to_rel_cursor(dir: enum, mode: enum, which: enum, clamp: bool)
	self:set(self:find_at_rel_cursor(dir, mode, which, clamp), nan)
end

terra Cursor:find_at_line(line_i: int, x: num)
	if isnan(x) then x = self.x end
	if line_i < 1 and self.park_home then
		return self:find_at_offset(0, DEFAULT)
	elseif line_i > self.layout.lines.len and self.park_end then
		return self:find_at_offset(1/0, DEFAULT)
	end
	return self.layout:hit_test_cursors(line_i, x, diff, valid, self, DEFAULT)
end
terra Cursor:move_to_line(line_i: int, x: num)
	self:set(self:find_at_line(line_i, x), x)
end

terra Cursor:find_at_rel_line(delta_lines: int, x: num)
	var line_i = iif(self.p.seg ~= nil,
		self.p.seg.line_index + (delta_lines or 0), 0)
	return self:find_at_line(line_i, x)
end
terra Cursor:move_to_rel_line(delta_lines: int, x: num)
	self:set(self:find_at_rel_line(delta_lines, x), x)
end

terra Cursor:find_at_pos(x: num, y: num)
	var line_i = self.layout:hit_test_lines(y)
	return self:find_at_line(line_i, x)
end
terra Cursor:move_to_pos(x: num, y: num)
	self:set(self:find_at_pos(x, y), x)
end

terra Cursor:find_at_page(page: int, x: num)
	var _, line1_y = self.layout:line_pos(self.layout.lines:at(0))
	var y = line1_y + (page - 1) * self.layout.h
	return self:find_at_pos(x, y)
end
terra Cursor:move_to_page(page: int, x: num)
	self:set(self:find_at_page(page, x), x)
end

terra Cursor:find_at_rel_page(delta_pages: int, x: num)
	var _, line_y = self.p:line_pos()
	var y = line_y + (delta_pages or 0) * self.layout.h
	return self:find_at_pos(x, y)
end
terra Cursor:move_to_rel_page(delta_pages: int, x: num)
	self:set(self:find_at_rel_page(delta_pages, x), x)
end

terra Cursor:paint(cr: &context)
	if not self.visible then return end
	var x, y, w, h = self:rect()
	x = snap(x, 1)
	y = snap(y, 1)
	h = snap(h, 1)
	var color = iif(self.p.seg ~= nil, self.p.seg.span.color, self.color)
	self.layout:paint_rect(cr, x, y, w, h, color, self.opacity)
end

--[[
function cursor:insert(...) --insert text at cursor.
	local offset = self.seg.offset + self.i
	local offset, changed = self.segments:insert(offset, ...)
	if changed then
		self:move('offset', offset, 'first')
	end
	return changed
end

function cursor:remove(delta) --remove delta cursor positions of text.
	local i1 = self.seg.offset + self.i
	local i2 = self:next_cursor(delta, 'char')
	local offset, changed = self.segments:remove(i1, i2)
	if changed then
		self:move('offset', offset)
	end
	return changed
end
]]
