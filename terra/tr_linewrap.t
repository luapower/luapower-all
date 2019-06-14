
--Line-wrapping a list of segments on a width.

if not ... then require'terra/tr_test'; return end

setfenv(1, require'terra/tr_types')
local reorder_segs = require'terra/tr_linewrap_reorder'

--wrap-width and advance-width of all the nowrap segments starting with the
--segment at seg_i and the seg_i after those segments.
--wrap-width == advance-width when it's a hard break or when it's the last
--segment (which implies a hard break), otherwise it's advance-width minus
--the width of the last trailing space.
terra Layout:nowrap_segments(seg_i: int)
	var seg = self.segs:at(seg_i)
	var gr = &self.r.glyph_runs:pair(seg.glyph_run_id).key
	if not seg.span.nowrap then
		var wx = gr.wrap_advance_x
		var ax = gr.advance_x
		wx = iif(seg.linebreak ~= BREAK_NONE or seg_i == self.segs.len-1, ax, wx)
		return wx, ax, seg_i+1
	end
	var ax = 0
	var n = self.segs.len
	for i = seg_i, n do
		var seg = self.segs(i)
		var ax1 = ax + gr.advance_x
		if i == n-1 or seg.linebreak ~= BREAK_NONE then --hard break, w == ax
			return ax1, ax1, i+1
		elseif i < n-1 and not self.segs(i+1).span.nowrap then
			var wx = ax + gr.wrap_advance_x
			return wx, ax1, i+1
		end
		ax = ax1
	end
end

--minimum width that the text can wrap into without overflowing.
terra Layout:min_w()
	var min_w = self._min_w
	if min_w == -inf then
		min_w = 0
		var seg_i, n = 0, self.segs.len
		while seg_i < n do
			var segs_wx, _, next_seg_i = self:nowrap_segments(seg_i)
			min_w = max(min_w, segs_wx)
			seg_i = next_seg_i
		end
		self._min_w = min_w
	end
	return min_w
end

--text width when there's no wrapping.
terra Layout:max_w()
	var max_w = self._max_w
	if max_w == inf then
		max_w = 0
		var line_w = 0
		var n = self.segs.len
		for i = 0, n do
			var seg = self.segs(i)
			var gr = &self.r.glyph_runs:pair(seg.glyph_run_id).key
			var wx = gr.wrap_advance_x
			var ax = gr.advance_x
			var linebreak = seg.linebreak ~= BREAK_NONE or i == n
			wx = iif(linebreak, ax, wx)
			line_w = line_w + wx
			if linebreak then
				max_w = max(max_w, line_w)
				line_w = 0
			end
		end
		self._max_w = max_w
	end
	return max_w
end

terra Layout:wrap(w: num)

	var lines = &self.lines
	lines.len = 0
	self.h = 0
	self.spaced_h = 0
	self.baseline = 0
	self.max_ax = 0
	self.first_visible_line = 0
	self.last_visible_line = -1

	--do line wrapping and compute line advance.
	var seg_i, seg_count = 0, self.segs.len
	var line: &Line = nil
	while seg_i < seg_count do
		var segs_wx, segs_ax, next_seg_i = self:nowrap_segments(seg_i)

		var hardbreak = line == nil
		var softbreak = not hardbreak
			and segs_wx > 0 --don't create a new line for an empty segment
			and line.advance_x + segs_wx > w

		if hardbreak or softbreak then

			var prev_seg = self.segs:at(seg_i-1, nil) --last segment of the previous line

			--adjust last segment due to being wrapped.
			--we can do this because the last segment stays last under bidi reordering.
			if softbreak then
				var prev_run = self:glyph_run(prev_seg)
				line.advance_x = line.advance_x - prev_seg.advance_x
				prev_seg.advance_x = prev_run.wrap_advance_x
				prev_seg.x = iif(prev_run.rtl,
					-(prev_run.advance_x - prev_run.wrap_advance_x), 0)
				prev_seg.wrapped = true
				line.advance_x = line.advance_x + prev_seg.advance_x
			end

			if prev_seg ~= nil then --break the next* chain.
				prev_seg.next = nil
				prev_seg.next_vis = nil
			end

			line = lines:add()
			line.index = lines.len-1
			line.first = self.segs:at(seg_i) --first segment in text order
			line.first_vis = line.first --first segment in visual order
			line.x = 0
			line.y = 0
			line.advance_x = 0
			line.ascent = 0
			line.descent = 0
			line.spaced_ascent = 0
			line.spaced_descent = 0
			line.visible = true --entirely clipped or not
			line.spacing = 1

		end

		line.advance_x = line.advance_x + segs_ax

		for seg_i = seg_i, next_seg_i do
			var seg = self.segs:at(seg_i)
			seg.advance_x = self:glyph_run(seg).advance_x
			seg.x = 0
			seg.wrapped = false
			seg.next = self.segs:at(seg_i+1, nil)
			seg.next_vis = seg.next
		end

		var last_seg = self.segs:at(next_seg_i-1)
		if last_seg.linebreak ~= BREAK_NONE then
			if last_seg.linebreak == BREAK_PARA then
				--we use this particular segment's `paragraph_spacing` property
				--since this is the segment asking for a paragraph break.
				--TODO: is there a more logical way to select this property?
				line.spacing = last_seg.span.paragraph_spacing
			else
				line.spacing = last_seg.span.hardline_spacing
			end
			line = nil
		end

		seg_i = next_seg_i
	end

	--reorder RTL segments on each line separately and concatenate the runs.
	if self.bidi then
		for _,line in lines do
			--UAX#9/L2: reorder segments based on their bidi_level property.
			line.first_vis = reorder_segs(line.first_vis, &self.r.ranges)
		end
	end

	var last_line: &Line = nil
	for _,line in lines do

		self.max_ax = max(self.max_ax, line.advance_x)

		--compute line ascent and descent scaling based on paragraph spacing.
		var ascent_factor = iif(last_line ~= nil, last_line.spacing, 1)
		var descent_factor = line.spacing

		var ax = 0
		var seg = line.first_vis
		while seg ~= nil do
			--compute line's vertical metrics.
			var run = self:glyph_run(seg)
			line.ascent = max(line.ascent, run.ascent)
			line.descent = min(line.descent, run.descent)
			var run_h = run.ascent - run.descent
			var line_spacing = seg.span.line_spacing
			var half_line_gap = run_h * (line_spacing - 1) / 2
			line.spaced_ascent
				= max(line.spaced_ascent,
					(run.ascent + half_line_gap) * ascent_factor)
			line.spaced_descent
				= min(line.spaced_descent,
					(run.descent - half_line_gap) * descent_factor)
			--set segments `x` to be relative to the line's origin.
			seg.x = ax + seg.x
			ax = ax + seg.advance_x
			seg = seg.next_vis
		end

		--compute line's y position relative to first line's baseline.
		if last_line ~= nil then
			var baseline_h = line.spaced_ascent - last_line.spaced_descent
			line.y = last_line.y + baseline_h
		end
		last_line = line
	end

	var first_line = lines:at(0, nil)
	if first_line ~= nil then
		var last_line = lines:at(lines.len-1)
		--compute the bounding-box height excluding paragraph spacing.
		self.h =
			first_line.ascent
			+ last_line.y
			- last_line.descent
		--compute the bounding-box height including paragraph spacing.
		self.spaced_h =
			first_line.spaced_ascent
			+ last_line.y
			- last_line.spaced_descent
		--set the default visible line range.
		self.last_visible_line = lines.len-1
	end

	return self
end

terra Layout:bbox()
	var bx = self.x + self.min_x
	var bw = self.max_ax
	var by = self.y + self.baseline
		- iif(self.lines.len > 0, self.lines:at(0).spaced_ascent, 0)
	var bh = self.spaced_h
	return bx, by, bw, bh
end
