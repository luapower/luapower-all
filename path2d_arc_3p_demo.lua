local player = require'cplayer'
local arc_3p = require'path2d_arc_3p'
local arc = require'path2d_arc'

local x1, y1, xp, yp, x2, y2 = 200, 200, 400, 200, 400, 400

local split_t = 0.5

function player:on_render(cr)

	split_t = self:slider{id = 'split_t', x = 10, y = 10, w = 190, h = 24,
									i0 = -1, i1 = 2, step = 0.001, i = split_t, text = 'split t'}

	x1, y1 = self:dragpoint{id = 'p1', x = x1, y = y1}
	xp, yp = self:dragpoint{id = 'pp', x = xp, y = yp}
	x2, y2 = self:dragpoint{id = 'p2', x = x2, y = y2}

	--arc_3p -> arc -> bezier -> draw
	local function draw(x1, y1, xp, yp, x2, y2, color, line_width)
		local cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2 = arc_3p.to_arc(x1, y1, xp, yp, x2, y2)
		if not cx then return end
		local function write(s, ...)
			if s == 'move' then
				cr:move_to(...)
			elseif s == 'curve' then
				cr:curve_to(...)
			else
				error(s)
			end
		end
		cr:move_to(x1, y1)
		arc.to_bezier3(write, cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2)
		self:stroke(color, line_width)
	end

	draw(x1, y1, xp, yp, x2, y2, 'normal_fg')

	--split -> draw #1, draw #2

	local ax1, ay1, ax2, ay2, ax3, ay3,
			bx1, by1, bx2, by2, bx3, by3 =
				arc_3p.split(split_t, x1, y1, xp, yp, x2, y2)

	if ax1 then
		cr:translate(500, 0)
		draw(ax1, ay1, ax2, ay2, ax3, ay3, '#ffff00', 4)
		draw(bx1, by1, bx2, by2, bx3, by3, '#ff00ff', 4)
	end

end

player:play()

