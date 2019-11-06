
--Painting text underlines.

if not ... then require'terra/tr_test'; return end

setfenv(1, require'terra/tr_types')
require'terra/tr_cursor'
require'terra/tr_clip'

terra Layout:draw_underline(cr: &context, line: &Line,
	seg1: &Seg, sub1: &SubSeg,
	seg2: &Seg, sub2: &SubSeg,
	underline: enum,
	for_shadow: bool
)
	var ax, ay = self:line_pos(line)
	var x1 = seg1.x + iif(sub1 ~= nil, sub1.x1, 0)
	var x2 = seg2.x + iif(sub2 ~= nil, sub2.x2, seg2.advance_x)
	var span1 = iif(sub1 ~= nil, sub1.span, seg1.span)
	var face = seg1.span.face
	var x = ax + x1
	var w = ax + x2 - x1
	var y = ay - face.underline_position
	var h = face.underline_thickness
	if underline == UNDERLINE_SOLID then
		self.r:draw_rect(cr, x, y, w, h,
			span1.underline_color,
			span1.underline_opacity)
	elseif underline == UNDERLINE_ZIGZAG then
		self.r:draw_zigzag(cr, x, y, w, h * 2,
			span1.underline_color,
			span1.underline_opacity)
	end
end

terra Layout:draw_underlines(cr: &context, for_shadow: bool)
	for _,line in self:visible_lines() do
		var seg1: &Seg
		var seg2: &Seg
		var sub1: &SubSeg
		var sub2: &SubSeg
		var u0 = enum(UNDERLINE_NONE)
		for seg in line do
			if seg.visible then
				if seg.subsegs.len > 0 then
					for _,sub in seg.subsegs do
						var u = sub.span.underline
						if u ~= UNDERLINE_NONE then
							if u0 ~= u then
								seg1, sub1 = seg, sub
							end
							seg2, sub2 = seg, sub
						elseif u0 ~= UNDERLINE_NONE then
							self:draw_underline(cr, line, seg1, sub1, seg2, sub2, u0, for_shadow)
						end
						u0 = u
					end
				else
					var u = seg.span.underline
					if u ~= UNDERLINE_NONE then
						if u0 ~= u then
							seg1, sub1 = seg, nil
						end
						seg2, sub2 = seg, nil
					elseif u0 ~= UNDERLINE_NONE then
						self:draw_underline(cr, line, seg1, sub1, seg2, sub2, u0, for_shadow)
					end
					u0 = u
				end
			end
		end
		if u0 ~= UNDERLINE_NONE then
			self:draw_underline(cr, line, seg1, sub1, seg2, sub2, u0, for_shadow)
		end
	end
end

