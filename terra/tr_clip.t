
--Mark segments as clipped.

if not ... then require'terra/tr_test'; return end

setfenv(1, require'terra/tr_types')
require'terra/tr_hit_test'

local overlap_seg = macro(function(ax1, ax2, bx1, bx2) --1D segments overlap test
	return `not (ax2 < bx1 or bx2 < ax1)
end)

local box_overlapping = macro(function(x1, y1, w1, h1, x2, y2, w2, h2)
	return `overlap_seg(x1, x1+w1, x2, x2+w2)
	    and overlap_seg(y1, y1+h1, y2, y2+h2)
end)

--NOTE: doesn't take into account side bearings, so it's not 100% accurate!
terra Layout:clip(x: num, y: num, w: num, h: num)
	var lines = &self.lines
	x = x - self.x
	y = y - self.y - self.baseline
	var first_visible = max(self:line_at_y(y), 0)
	var last_visible = iif(h == inf, self.lines.len-1,
		min(lines.len-1, self:line_at_y(y + h - 1.0/256)))
	var first = false
	for line_i = first_visible, last_visible + 1 do
		var line = lines:at(line_i)
		var bx = line.x
		var bw = line.advance_x
		var by = line.y - line.ascent
		var bh = line.ascent - line.descent
		line.visible = box_overlapping(x, y, w, h, bx, by, bw, bh)
		if line.visible then
			var seg = line.first_vis
			while seg ~= nil do
				var bx = bx + seg.x
				var bw = seg.advance_x
				seg.visible = box_overlapping(x, y, w, h, bx, by, bw, bh)
				seg = seg.next_vis
			end
			if not first then
				first_visible = line_i
				first = true
			end
			last_visible = line_i
		end
	end
	self.first_visible_line = first_visible
	self.last_visible_line = last_visible
	self.clip_valid = true
	return self
end

terra Layout:reset_clip()
	return self:clip(-inf, -inf, inf, inf)
end
