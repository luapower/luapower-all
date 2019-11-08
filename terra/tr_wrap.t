
--Line-wrapping a list of segments on a width.

if not ... then require'terra.tr_test'; return end

setfenv(1, require'terra.tr_types')
local reorder_segs = require'terra.tr_wrap_reorder'

--wrap-width and advance-width of all the segments that cannot be wrapped
--starting with the segment at seg_i, and the seg_i after those segments.
--wrap-width == advance-width when it's a hard break or when it's the last
--segment (which implies a hard break), otherwise it's advance-width minus
--the width of the last trailing space.
terra Layout:nowrap_segments(seg_i: int)
	var seg = self.segs:at(seg_i)
	var ax = 0
	var n = self.segs.len
	for i = seg_i, n do
		var seg = self.segs:at(i)
		var m = self:seg_metrics(seg)
		var ax1 = ax + m.advance_x
		if i == n-1 or seg.linebreak >= BREAK_LINE then --hard break, w == ax
			return ax1, ax1, i+1
		elseif
			seg.linebreak ~= BREAK_NONE
			and not (seg.span.wrap == WRAP_NONE and self.segs:at(i+1).span.wrap == WRAP_NONE)
		then
			var wx = ax + m.wrap_advance_x
			return wx, ax1, i+1
		end
		ax = ax1
	end
end

--minimum width that the text can wrap into without overflowing.
terra Layout:min_w()
	var min_w: num = 0
	var seg_i, n = 0, self.segs.len
	while seg_i < n do
		var segs_wx, _, next_seg_i = self:nowrap_segments(seg_i)
		min_w = max(min_w, segs_wx)
		seg_i = next_seg_i
	end
	return min_w
end

--text width when there's no wrapping.
terra Layout:max_w()
	var max_w: num = 0
	var line_w = 0
	var n = self.segs.len
	for i = 0, n do
		var seg = self.segs:at(i)
		var m = self:seg_metrics(seg)
		var wx = m.wrap_advance_x
		var ax = m.advance_x
		var linebreak = seg.linebreak >= BREAK_LINE or i == n
		wx = iif(linebreak, ax, wx)
		line_w = line_w + wx
		if linebreak then
			max_w = max(max_w, line_w)
			line_w = 0
		end
	end
	return max_w
end

terra Layout:wrap()

	self.max_ax = 0
	self.lines.len = 0

	--special-case empty text: we still want to set valid wrapping output
	--in order to properly display a cursor.
	if self.segs.len == 0 then
		var line = self.lines:add()
		fill(line)
		return
	end

	--do line wrapping and compute line advance.
	var line: &Line = nil
	var seg_i = 0
	while seg_i < self.segs.len do
		var segs_wx, segs_ax, next_seg_i = self:nowrap_segments(seg_i)

		var hardbreak = line == nil
		var softbreak = not hardbreak
			and segs_wx > 0 --don't create a new line for an empty segment
			and line.advance_x + segs_wx > self.align_w

		if hardbreak or softbreak then

			var prev_seg = self.segs:at(seg_i-1, nil) --last segment of the previous line

			--adjust last segment due to being wrapped.
			--we can do this here because the last segment stays last under bidi reordering.
			if softbreak then
				var prev_m = self:seg_metrics(prev_seg)
				line.advance_x = line.advance_x - prev_seg.advance_x
				prev_seg.advance_x = prev_m.wrap_advance_x
				prev_seg.x = iif(prev_seg.rtl,
					-(prev_m.advance_x - prev_m.wrap_advance_x), 0)
				prev_seg.wrapped = true
				line.advance_x = line.advance_x + prev_seg.advance_x
			end

			if prev_seg ~= nil then --break the next chain.
				prev_seg.next_vis = nil
			end

			line = self.lines:add()
			fill(line)
			line.first = self.segs:at(seg_i) --first segment in text order
			line.first_vis = line.first --first segment in visual order
		end

		line.advance_x = line.advance_x + segs_ax

		for seg_i = seg_i, next_seg_i do
			var seg = self.segs:at(seg_i)
			seg.line_index = self.lines.len-1
			seg.advance_x = self:seg_metrics(seg).advance_x
			seg.x = 0
			seg.wrapped = false
			seg.next_vis = self.segs:at(seg_i+1, nil)
		end

		var last_seg = self.segs:at(next_seg_i-1)
		line.linebreak = last_seg.linebreak
		if line.linebreak >= BREAK_LINE then
			line = nil
		end

		seg_i = next_seg_i
	end

	for _,line in self.lines do

		--UAX#9/L2: reorder segments based on their bidi_level property.
		if self.bidi then
			line.first_vis = reorder_segs(line.first_vis, &self.r.ranges)
		end

		--compute line's max advance_x, used as bounding box boundary.
		self.max_ax = max(self.max_ax, line.advance_x)

	end

end

