
--Fit line-wrapped text inside a box.

if not ... then require'terra.tr_test'; return end

setfenv(1, require'terra.tr_types')
require'terra.tr_font'
require'terra.tr_wrap'

terra Line:_update_vertical_metrics(
	line_spacing: num,
	baseline: num,
	run_ascent: num,
	run_descent: num,
	ascent_factor: num,
	descent_factor: num
)
	self.ascent = max(self.ascent, baseline + run_ascent)
	self.descent = min(self.descent, baseline + run_descent)
	var run_h = run_ascent - run_descent
	var half_line_gap = run_h * (line_spacing - 1) / 2
	self.spaced_ascent
		= max(self.spaced_ascent,
			(baseline + run_ascent + half_line_gap) * ascent_factor)
	self.spaced_descent
		= min(self.spaced_descent,
			(baseline + run_descent - half_line_gap) * descent_factor)
end

terra Layout:spaceout()

	self.h = 0
	self.spaced_h = 0
	self.baseline = 0

	var prev_line: &Line = nil
	var prev_line_spacing = 1.0

	for line_i, line in self.lines do

		line.ascent  = 0
		line.descent = 0
		line.spaced_ascent  = 0
		line.spaced_descent = 0

		var line_spacing =
			iif(line.linebreak == BREAK_PARA,
				self.paragraph_spacing,
				iif(line.linebreak == BREAK_LINE,
					self.hardline_spacing,
					self.line_spacing))

		--compute line ascent and descent scaling based on paragraph spacing.
		var ascent_factor = prev_line_spacing
		var descent_factor = line_spacing

		var seg = line.first_vis
		if seg == nil then --special case for empty text: use font's metrics.
			assert(line_i == 0)
			var span = self.spans:at(0, nil)
			var face = iif(span ~= nil, span.face, nil)
			if face ~= nil then
				line:_update_vertical_metrics(
					self.line_spacing,
					span.baseline * face.ascent,
					face.ascent,
					face.descent,
					ascent_factor,
					descent_factor
				)
			end
		else
			repeat
				var m = self:seg_metrics(seg)
				line:_update_vertical_metrics(
					self.line_spacing,
					seg.span.baseline * m.ascent,
					m.ascent,
					m.descent,
					ascent_factor,
					descent_factor
				)
				seg = seg.next_vis
			until seg == nil
		end

		--compute line's y position relative to first line's baseline.
		if prev_line ~= nil then
			var baseline_h = line.spaced_ascent - prev_line.spaced_descent
			line.y = prev_line.y + baseline_h
		else
			line.y = 0
		end

		prev_line = line
		prev_line_spacing = line_spacing
	end

	var first_line = self.lines:at(0)
	var last_line = self.lines:at(self.lines.len-1)

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

end

local struct line_nowrap_segments_iter { layout: &Layout; line: &Line; }

line_nowrap_segments_iter.metamethods.__for = function(self, body)
	if self:islvalue() then self = &self end
	return quote
		var iter = self --workaround for terra issue #368
		var line = iter.line
		var self = iter.layout
		var seg_i = self.segs:index(line.first_vis)
		var line_i = self.lines:index(line)
		repeat
			var segs_wx, segs_ax, next_seg_i = self:nowrap_segments(seg_i)
			var next_seg = self.segs:at(next_seg_i, nil)
			var last = next_seg == nil or next_seg.line_index ~= line_i
			[ body(seg_i, next_seg_i, segs_wx, segs_ax, last) ]
			seg_i = next_seg_i
		until last
	end
end

terra Layout:line_nowrap_segments(line: &Line)
	return line_nowrap_segments_iter {layout = self, line = line}
end

terra Layout:justify(line: &Line)
	var w: num = 0 --width of total justifiable whitespace
	var n = 0 --total number of gaps
	for _, __, segs_wx, segs_ax, last in self:line_nowrap_segments(line) do
		if not last then
			inc(w, segs_ax - segs_wx)
			inc(n)
		else
			inc(w, self.align_w - line.advance_x)
		end
	end
	var sp = w / n
	var ax: num = 0
	for seg_i, next_seg_i, segs_wx, _, last in self:line_nowrap_segments(line) do
		var ax1 = ax
		for i = seg_i, next_seg_i do
			var seg = self.segs:at(i)
			seg.x = ax1
			ax1 = ax1 + seg.advance_x
		end
		ax = ax + segs_wx + sp
	end
end

--set segments `x` to be relative to the line's origin.
terra Layout:unjustify(line: &Line)
	var ax: num = 0
	for seg in line do
		seg.x = ax
		ax = ax + seg.advance_x
	end
end

terra Layout:align()

	self.min_x = inf
	for line_i, line in self.lines do

		var align_x = self.align_x
		if align_x == ALIGN_START or align_x == ALIGN_END then
			var dir = iif(line.first ~= nil, line.first.paragraph_dir, ALIGN_LEFT)
			var left  = iif(align_x == ALIGN_START, ALIGN_LEFT, ALIGN_RIGHT)
			var right = iif(align_x == ALIGN_START, ALIGN_RIGHT, ALIGN_LEFT)
			    if dir == DIR_AUTO then align_x = left
			elseif dir == DIR_LTR  then align_x = left
			elseif dir == DIR_RTL  then align_x = right
			elseif dir == DIR_WLTR then align_x = left
			elseif dir == DIR_WRTL then align_x = right
			end
		end

		--compute line's aligned x position relative to the textbox origin.
		if align_x == ALIGN_JUSTIFY then
			line.x = 0
			if line.linebreak < BREAK_LINE and line_i < self.lines.len-1 then
				self:justify(line)
			else
				self:unjustify(line)
			end
		else
			if align_x == ALIGN_RIGHT then
				line.x = self.align_w - line.advance_x
			elseif align_x == ALIGN_CENTER then
				line.x = (self.align_w - line.advance_x) / 2.0
			else
				line.x = 0
			end
			self:unjustify(line)
		end
		self.min_x = min(self.min_x, line.x)
	end

	--compute first line's baseline based on vertical alignment.
	if self.align_y == ALIGN_TOP then
		var first_line = self.lines:at(0)
		self.baseline = first_line.spaced_ascent
	elseif self.align_y == ALIGN_BOTTOM then
		var last_line = self.lines:at(self.lines.len-1)
		self.baseline = self.align_h - (last_line.y - last_line.spaced_descent)
	elseif self.align_y == ALIGN_CENTER then
		var first_line = self.lines:at(0)
		self.baseline = first_line.spaced_ascent + (self.align_h - self.spaced_h) / 2
	end
end

terra Layout:bbox()
	var bx = self.x + self.min_x
	var bw = self.max_ax
	var by = self.y + self.baseline
		- iif(self.lines.len > 0, self.lines:at(0).spaced_ascent, 0)
	var bh = self.spaced_h
	return bx, by, bw, bh
end

terra Layout:line_pos(line: &Line)
	self.lines:index(line)
	var x = self.x + line.x
	var y = self.y + self.baseline + line.y
	return x, y
end

--hit-test lines vertically given a relative(!) y-coord.
local terra cmp_ys(line1: &Line, line2: &Line)
	return line1.y - line1.spaced_descent < line2.y -- < < [=] = < <
end
terra Layout:line_at_y(y: num)
	return self.lines:clamp(self.lines:binsearch(Line{y = y}, cmp_ys))
end

--hit-test the text vertical boundaries for a line index given an y-coord.
terra Layout:hit_test_lines(y: num)
	var y = y - (self.y + self.baseline)
	return self:line_at_y(y)
end

