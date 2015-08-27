local player = require'cplayer'
local arc = require'path_arc'
local svgarc = require'path_svgarc'
local matrix = require'affine2d'

local world_rotation = 0
local rotation = 0
local scale = 1

function player:on_render(cr)

	world_rotation = self:slider{id = 'world_rotation',
		x = 10, y = 10, w = 300, h = 24, text = 'world rotation',
		i0 = 0, i1 = 360, step = 1, i = world_rotation,
	}

	rotation = self:slider{id = 'rotation',
		x = 10, y = 40, w = 300, h = 24, text = 'arc rotation',
		i0 = 0, i1 = 360, step = 1, i = rotation,
	}

	scale = self:slider{id = 'scale',
		x = 10, y = 70, w = 300, h = 24, text = 'scale',
		i0 = 0.1, i1 = 5, step = 0.01, i = scale,
	}

	cr:identity_matrix()
	cr:translate(400, 500)
	cr:scale(scale, scale)
	cr:translate(-400, -500)

	local cpx, cpy
	local function write(_, x2, y2, x3, y3, x4, y4)
		cpx, cpy = cr:get_current_point()
		cr:circle(cpx, cpy, 2)
		cr:circle(x4, y4, 2)
		cr:move_to(cpx, cpy)
		cr:curve_to(x2, y2, x3, y3, x4, y4)
	end

	local world_center_x, world_center_y = 600, 300
	local mt = matrix():rotate_around(world_center_x, world_center_y, world_rotation)

	local function draw(x1, y1, rx, ry, rotation, large, sweep, x2, y2, r, g, b, a)
		if not svgarc.valid(x1, y1, x2, y2, rx, ry) then return end

		cr:move_to(mt(x1, y1))
		arc.to_bezier3(write, svgarc.to_arc(x1, y1, rx, ry, rotation, large, sweep, x2, y2, mt))
		cr:set_source_rgba(r, g, b, a)
		cr:stroke()
	end

	cr:set_line_width(2)

	local mind, minx, miny, mint
	local function hit(x1, y1, rx, ry, rotation, large, sweep, x2, y2)
		if not svgarc.valid(x1, y1, x2, y2, rx, ry) then return end

		local x, y = cr:device_to_user(self.mousex, self.mousey)
		local d, x, y, t = arc.hit(x, y, svgarc.to_arc(x1, y1, rx, ry, rotation, large, sweep, x2, y2, mt))
		if not mind or d < mind then
			mind, minx, miny, mint = d, x, y, t
		end

		local
			x11, y11, rx1, ry1, rotation1, large1, sweep1, x12, y12,
			x21, y21, rx2, ry2, rotation2, large2, sweep2, x22, y22 =
				svgarc.split(t, x1, y1, rx, ry, rotation, large, sweep, x2, y2)

		draw(x11, y11, rx1, ry1, rotation1, large1, sweep1, x12, y12, 1, 0, 0, 1)
		draw(x21, y21, rx2, ry2, rotation2, large2, sweep2, x22, y22, 0.3, 0.3, 1, 1)
	end

	--the four svg elliptic arcs from http://www.w3.org/TR/SVG/images/paths/arcs02.svg
	local function ellipses(tx, ty, large, sweep)
		local x1, y1, rx, ry, x2, y2 = tx+125, ty+75, 100, 50, tx+125+100, ty+75+50
		local cx, cy, crx, cry = svgarc.to_arc(x1, y1, rx, ry, rotation, large, sweep, x2, y2, mt)

		local cmt = cr:get_matrix()
		cr:rotate_around(world_center_x, world_center_y, math.rad(world_rotation))
		cr:translate(cx, cy)
		cr:rotate(math.rad(rotation))
		cr:translate(-125, -125)
		cr:ellipse(125, 125, crx, cry)
		cr:set_matrix(cmt)
		cr:set_source_rgba(0,1,0,0.3)
		cr:stroke()

		hit(x1, y1, rx, ry, rotation, large, sweep, x2, y2)
	end
	ellipses(200, 100, 0, 0)
	ellipses(600, 100, 0, 1)
	ellipses(600, 400, 1, 0)
	ellipses(200, 400, 1, 1)

	--degenerate arcs
	hit(700, 100, 100, 0, 0, 0, 0, 800, 200) --zero radius
	hit(800, 100, 100, 100, 0, 0, 0, 800, 100) --conincident endpoints

	--closest hit point
	cr:set_line_width(1)
	cr:set_source_rgb(1,1,1)
	cr:circle(minx, miny, 5)
	cr:stroke()

end

player:play()

