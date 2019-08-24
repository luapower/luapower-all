
--Fit line-wrapped text inside a box.

if not ... then require'terra/tr_test'; return end

setfenv(1, require'terra/tr_types')

terra Line:_update_vertical_metrics(
	line_spacing: num,
	run_ascent: num,
	run_descent: num,
	ascent_factor: num,
	descent_factor: num
)
	self.ascent = max(self.ascent, run_ascent)
	self.descent = min(self.descent, run_descent)
	var run_h = run_ascent - run_descent
	var half_line_gap = run_h * (line_spacing - 1) / 2
	self.spaced_ascent
		= max(self.spaced_ascent,
			(run_ascent + half_line_gap) * ascent_factor)
	self.spaced_descent
		= min(self.spaced_descent,
			(run_descent - half_line_gap) * descent_factor)
end

terra Layout:_spaceout()

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
			var span = self.spans:at(0)
			var font = self.r.fonts:at(span.font_id, nil)
			var line = self.lines:at(0)
			if font ~= nil then
				line:_update_vertical_metrics(
					self.line_spacing,
					font.ascent,
					font.descent,
					ascent_factor,
					descent_factor
				)
			end
		else
			repeat
				var run = self:glyph_run(seg)
				line:_update_vertical_metrics(
					self.line_spacing,
					run.ascent,
					run.descent,
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

terra Layout:justify(line: &Line)
	var w: num = 0 --total width of between-segments whitespace
	var n = 0 --total number of between-segments places
	for seg in line do
		if seg.next_vis ~= nil then
			var gr = self:glyph_run(seg)
			inc(w, gr.advance_x - gr.wrap_advance_x)
			inc(n)
		else
			inc(w, self.align_w - line.advance_x)
		end
	end
	var sp = w / n
	var ax: num = 0
	for seg in line do
		var gr = self:glyph_run(seg)
		seg.x = ax
		ax = ax + gr.wrap_advance_x + sp
	end
end

--set segments `x` to be relative to the line's origin.
terra Layout:unjustify(line: &Line)
	var ax: num = 0
	var seg = line.first_vis
	while seg ~= nil do
		seg.x = ax + 0 --TODO: seg.x
		ax = ax + seg.advance_x
		seg = seg.next_vis
	end
end

terra Layout:_align()

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
			if line.linebreak == BREAK_NONE and line_i < self.lines.len-1 then
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

	self.clip_valid = false
end

terra Layout:bbox()
	var bx = self.x + self.min_x
	var bw = self.max_ax
	var by = self.y + self.baseline
		- iif(self.lines.len > 0, self.lines:at(0).spaced_ascent, 0)
	var bh = self.spaced_h
	return bx, by, bw, bh
end
