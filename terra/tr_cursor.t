
if not ... then require'terra/tr_test'; return end

setfenv(1, require'terra/tr_types')

terra Layout:line_pos(line_i: int)
	var line = self.lines:at(line_i)
	var x = self.x + line.x
	var y = self.y + self.baseline + line.y
	return x, y
end

terra Layout:cursor_x(seg: &Seg, i: int) --relative to line_pos().
	var run = self:glyph_run(seg)
	var i = clamp(i, 0, run.text.len)
	return seg.x + run.cursor_xs(i)
end

local terra cmp_offsets(seg1: &Seg, seg2: &Seg)
	return seg1.offset <= seg2.offset -- < < = = [<] <
end
terra Layout:cursor_at_offset(offset: int)
	var seg_i = self.segs:binsearch(Seg{offset = offset}, cmp_offsets) - 1
	var seg = self.segs:at(seg_i)
	var i = offset - seg.offset
	assert(i >= 0)
	var run = self:glyph_run(seg)
	i = min(i, run.text.len) --fix if inside inter-segment gap.
	i = run.cursor_offsets(i) --normalize to the first cursor.
	return seg, i
end

terra Layout:offset_at_cursor(seg: &Seg, i: int)
	var run = self:glyph_run(seg)
	assert(i >= 0)
	assert(i <= run.text.len)
	return seg.offset + run.cursor_offsets(i)
end

