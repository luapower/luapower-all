
--Text selection.

if not ... then require'terra/tr_test'; return end

setfenv(1, require'terra/tr_types')
require'terra/tr_paint'
require'terra/tr_cursor'

terra Selection:init(layout: &Layout)
	self.layout = layout
	var p = layout:cursor_at_offset(0)
	self.p1 = p
	self.p2 = p
	self.color = DEFAULT_SELECTION_COLOR
	self.opacity = DEFAULT_SELECTION_OPACITY
end

terra Selection:free()
	dealloc(self)
end

terra Layout:selection()
	var sel = new(Selection, self)
	self.selections:add(sel) --takes ownership
	return sel
end

terra Selection:release()
	var i = self.layout.selections:find(self)
	self.layout.selections:remove(i) --calls Selection:free()
end

terra Selection:reset()
	self.p1:reset()
	self.p2:reset()
end

terra Selection:reposition()
	self.p1:reposition()
	self.p2:reposition()
end

--line-relative (x, w) of a selection rectangle on two cursor
--positions in the same segment (in whatever order).
terra Layout:segment_xw(seg: &Seg, i1: int, i2: int)
	var run = self:glyph_run(seg)
	var i1 = run.cursor_xs:clamp(i1)
	var i2 = run.cursor_xs:clamp(i2)
	var cx1 = run.cursor_xs(i1)
	var cx2 = run.cursor_xs(i2)
	if cx1 > cx2 then
		cx1, cx2 = cx2, cx1
	end
	return seg.x + cx1, cx2 - cx1
end

--merge two (x, w) segments together, if possible.
local terra merge_xw(x1: num, w1: num, x2: num, w2: num)
	if isnan(x1) then --is first
		return x2, w2, false
	elseif x2 == x1 + w1 then --comes after
		return x1, w1 + w2, false
	elseif x1 == x2 + w2 then --comes before
		return x2, w1 + w2, false
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

terra Selection:paint_rect(cr: &context, x: num, y: num, w: num, h: num)
	self.layout:paint_rect(cr, x, y, w, h, self.color, self.opacity)
end

terra Selection:paint(cr: &context, spaced: bool)
	var p1 = self.p1
	var p2 = self.p2
	if p1.offset > p2.offset then
		swap(p1, p2)
	end
	assert(self.layout:seg_index(p1.seg) <= self.layout:seg_index(p2.seg))
	var seg = p1.seg
	while seg ~= nil and self.layout:seg_index(seg) <= self.layout:seg_index(p2.seg) do
		var line_index = seg.line_index
		if self.layout:line_visible(line_index) then
			var line = self.layout:seg_line(seg)
			var line_x, line_y, line_w, line_h = self.layout:line_rect(line, spaced)
			var x = nan
			var w = nan
			while seg ~= nil
				and self.layout:seg_index(seg) <= self.layout:seg_index(p2.seg)
				and seg.line_index == line_index
			do
				var i1 = iif(seg == p1.seg, p1.i, 0)
				var i2 = iif(seg == p2.seg, p2.i, inf)
				var x1, w1 = self.layout:segment_xw(seg, i1, i2)
				var failed: bool
				x1, w1, failed = merge_xw(x, w, x1, w1)
				if failed then
					self:paint_rect(cr, line_x + x, line_y, w, line_h)
				end
				x, w = x1, w1
				seg = self.layout.segs:next(seg, nil)
			end
			self:paint_rect(cr, line_x + x, line_y, w, line_h)
		else
			var next_line = self.layout.lines:at(line_index + 1, nil)
			seg = iif(next_line ~= nil, next_line.first, nil)
		end
	end
end

terra Selection:offsets()
	var o1 = self.p1.offset
	var o2 = self.p2.offset
	return min(o1, o2), max(o1, o2), o1 < o2
end

terra Selection:select(o1: int, o2: int)
	self.p1 = self.layout:cursor_at_offset(o1)
	self.p2 = self.layout:cursor_at_offset(o2)
end

terra Selection:get_empty()
	return self.p1.offset == self.p2.offset
end
