
if not ... then require'terra/tr_test'; return end

setfenv(1, require'terra/tr_types')

--hit-test the lines array for a line number given a relative(!) y-coord.
local terra cmp_ys(line1: &Line, line2: &Line)
	return line1.y - line1.spaced_descent < line2.y -- < < [=] = < <
end

terra Layout:line_at_y(y: num)
	if self.lines.len == 0 then
		return -1 --no lines
	end
	if y < -self.lines(0).spaced_ascent then
		return -1 --above first line
	end
	return self.lines:binsearch(Line{y = y}, cmp_ys)
end

--hit-test the lines array for a line number given an y-coord.
terra Layout:hit_test_lines(y: num)
	var y = y - (self.y + self.baseline)
	return self:line_at_y(y)
end

--hit test the text boundaries.
terra Layout:hit_test(x: num, y: num)
	var line_i = self:hit_test_lines(y)
	var line = self.lines:at(line_i, nil)
	if line == nil then
		return line_i, 0
	end
	var x = x - self.x - line.x
	if x < 0 then
		return line_i, -1
	elseif x > line.advance_x then
		return line_i, 1
	else
		return line_i, 0
	end
end

