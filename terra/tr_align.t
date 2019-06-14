
--Fit line-wrapped text inside a box.

if not ... then require'terra/tr_test'; return end

setfenv(1, require'terra/tr_types')

terra Layout:align(x: num, y: num, w: num, h: num, align_x: enum, align_y: enum)

	var lines = &self.lines
	if lines.len == 0 then return self end
	if w == -1 then w = self.max_ax end   --self-box
	if h == -1 then h = self.spaced_h end --self-box

	self.min_x = inf

	if align_x == ALIGN_AUTO then
		    if self.base_dir == DIR_AUTO then align_x = ALIGN_LEFT
		elseif self.base_dir == DIR_LTR  then align_x = ALIGN_LEFT
		elseif self.base_dir == DIR_RTL  then align_x = ALIGN_RIGHT
		elseif self.base_dir == DIR_WLTR then align_x = ALIGN_LEFT
		elseif self.base_dir == DIR_WRTL then align_x = ALIGN_RIGHT
		end
	end

	for line_i, line in lines do
		--compute line's aligned x position relative to the textbox origin.
		if align_x == ALIGN_RIGHT then
			line.x = w - line.advance_x
		elseif align_x == ALIGN_CENTER then
			line.x = (w - line.advance_x) / 2.0
		end
		self.min_x = min(self.min_x, line.x)
	end

	--compute first line's baseline based on vertical alignment.
	var first_line = lines:at( 0, nil)
	var last_line  = lines:at(lines.len-1, nil)
	if first_line == nil then
		self.baseline = 0
	else
		if align_y == ALIGN_TOP then
			self.baseline = first_line.spaced_ascent
		elseif align_y == ALIGN_BOTTOM then
			self.baseline = h - (last_line.y - last_line.spaced_descent)
		elseif align_y == ALIGN_CENTER then
			self.baseline = first_line.spaced_ascent + (h - self.spaced_h) / 2
		end
	end

	--store textbox's origin, which can be changed anytime after layouting.
	self.x = x
	self.y = y

	--store textbox's height to be used for page up/down cursor navigation.
	self.page_h = h

	--store the actual x-alignment for adjusting the caret x-coord.
	self.align_x = align_x

	self.clip_valid = false

	return self
end
