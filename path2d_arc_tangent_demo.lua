local player = require'cplayer'
local path_cairo = require'path2d_cairo'
local arc = require'path2d_arc'

local angle = 270
local clockwise = true

function player:on_render(cr)

	angle = self:slider{id = 'angle',
		x = 10, y = 10, w = 200, h = 24, text = 'angle',
		i1 = 360, i0 = 0, i = angle}

	clockwise = self:togglebutton{id = 'sign',
		x = 220, y = 10, w = 80, h = 24, text = 'clockwise',
		selected = clockwise}

	local cx, cy, rx, ry, start_angle, sweep_angle, rotation = 500, 200, 200, 100, 0, (angle % 360)*(clockwise and 1 or -1), 30

	local cpx, cpy = arc.endpoints(cx, cy, rx, ry, start_angle, sweep_angle, rotation)
	cr:move_to(cpx, cpy)
	local function write(_, x2, y2, x3, y3, x4, y4)
		cpx, cpy = cr:current_point()
		cr:circle(cpx, cpy, 2)
		cr:circle(x4, y4, 2)
		cr:move_to(cpx, cpy)
		cr:curve_to(x2, y2, x3, y3, x4, y4)
	end
	arc.to_bezier3(write, cx, cy, rx, ry, start_angle, sweep_angle, rotation)

	cr:rgb(1,1,1)
	cr:stroke()

	local px, py, tx, ty = arc.tangent_vector(1, cx, cy, rx, ry, start_angle, sweep_angle, rotation)

	cr:circle(cx, cy, 5)
	cr:circle(px, py, 5)
	cr:circle(tx, ty, 5)
	cr:fill()

	cr:move_to(px, py)
	cr:line_to(tx, ty)
	cr:stroke()
end

player:play()
