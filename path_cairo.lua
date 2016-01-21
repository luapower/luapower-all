--2d path drawing using cairo.

local path = require'path'

local b2_to_b3 = require'path_bezier2'.to_bezier3

local function draw_function(cr)
	local cpx, cpy
	local function write(s, ...)
		if s == 'move' then
			cr:move_to(...)
			cpx, cpy = ...
		elseif s == 'close' then
			cr:close_path()
		elseif s == 'line' then
			cr:line_to(...)
			cpx, cpy = ...
		elseif s == 'curve' then
			cr:curve_to(...)
			cpx, cpy = select(5, ...)
		elseif s == 'quad_curve' then
			cr:curve_to(select(3, b2_to_b3(cpx, cpy, ...)))
			cpx, cpy = select(3, ...)
		elseif s == 'text' then
			local x1, y1, font, text = ...
			cr:select_font_face(font.family or 'Arial', 0, 0)
			cr:font_size(font.size or 12)
			cr:move_to(x1, y1)
			cr:text_path(tostring(text))
			cpx, cpy = nil
		end
	end
	local function draw(path_, mt)
		cr:new_sub_path()
		path.decompose(write, path_, mt)
	end

	return draw
end

if not ... then require'path_cairo_demo' end

return draw_function

