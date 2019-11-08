
--Hit testing entire lines of text.

if not ... then require'terra.tr_test'; return end

setfenv(1, require'terra.tr_types')

--hit-test lines vertically given a relative(!) y-coord.
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

--hit-test the lines array for a line index given an y-coord.
--returns -1 if above the first line or lines.len if below the last one.
terra Layout:hit_test_lines(y: num)
	var y = y - (self.y + self.baseline)
	return self:line_at_y(y)
end

--hit test the text boundaries for a line index and a -1|0|1 flag
--corresponding to left|over|right of the text line that was hit.
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
