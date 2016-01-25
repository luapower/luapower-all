local player = require'cplayer'
local arc = require'path2d_arc'
local affine = require'affine2d'
local glue = require'glue'

local cx, cy, rx, ry, start_angle, sweep_angle, rotation = 500, 400, 300, 200, 0, 300, 30
local zoom = 1
local tangent_t = 1
local max_segment_sweep

function player:on_render(cr)

	cx, cy = self:dragpoint{id = 'center', x = cx, y = cy}
	zoom = self:slider{id = 'zoom', x = 10, y = 10, w = 490, h = 24, i0 = 1, i1 = 1000, i = zoom}
	rx = self:slider{id = 'rx', x = 10, y = 40, w = 190, h = 24, i0 = -500, i1 = 500, i = rx}
	ry = self:slider{id = 'ry', x = 10, y = 70, w = 190, h = 24, i0 = -500, i1 = 500, i = ry}
	start_angle = self:slider{id = 'start_angle', x = 10, y = 100, w = 190, h = 24, i0 = -720, i1 = 720, step = 0.01, i = start_angle}
	sweep_angle = self:slider{id = 'sweep_angle', x = 10, y = 130, w = 190, h = 24, i0 = -720, i1 = 720, step = 0.01, i = sweep_angle}
	rotation = self:slider{id = 'rotation', x = 10, y = 160, w = 190, h = 24, i0 = -360, i1 = 360, step = 0.01, i = rotation}
	tangent_t = self:slider{id = 'tangent_t', x = 10, y = 190, w = 190, h = 24, i0 = 0, i1 = 1, step = 0.01, i = tangent_t}
	max_segment_sweep = self:slider{id = 'max_segment_sweep', x = 10, y = 220, w = 190, h = 24, i0 = 0, i1 = 360, step = 0.01, i = max_segment_sweep or 0}
	max_segment_sweep = max_segment_sweep ~= 0 and max_segment_sweep or nil
	if self:button{id = 'make circular', x = 10, y = 250, w = 190, h = 24} then
		rx = (rx + ry) / 2
		ry = rx
		rotation = 0
	end

	local function draw(cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2, mt, color)
		local x1, y1 = arc.endpoints(cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2, mt)
		cr:move_to(x1, y1)
		local function write(s, ...)
			cr:curve_to(...)
			x1, y1 = select(5, ...)
			cr:circle(x1, y1, 4)
			cr:move_to(x1, y1)
		end
		arc.to_bezier3(write, cx, cy, rx, ry, start_angle, sweep_angle, rotation, x2, y2, mt, max_segment_sweep)
		self:stroke(color, 6)
	end

	local scale = zoom^2

	local mt = affine():translate(400, 170.922):scale(scale):translate(-400, -170.922)

	--bounding box
	local x, y, w, h = arc.bounding_box(cx, cy, rx, ry, start_angle, sweep_angle, rotation, nil, nil, mt)
	self:rect(x, y, w, h, 'faint_bg')

	--draw
	draw(cx, cy, rx, ry, start_angle, sweep_angle, rotation, nil, nil, mt, 'normal_fg')

	--draw tangent vector
	local x1, y1, x2, y2 = arc.tangent_vector(tangent_t, cx, cy, rx, ry, start_angle, sweep_angle, rotation, nil, nil, mt)
	self:line(x1, y1, x2, y2, '#22466A', 2)
	self:dot(x2, y2, 4, '#22466A')

	--hit -> point & time
	local d,x,y,t = arc.hit(self.mousex, self.mousey, cx, cy, rx, ry, start_angle, sweep_angle, rotation,
										nil, nil, mt, max_segment_sweep)

	--split -> draw #1, draw #2
	local
		cx1, cy1, r1x, r1y, start_angle1, sweep_angle1, rotation1,
		cx2, cy2, r2x, r2y, start_angle2, sweep_angle2, rotation2 =
			arc.split(t, cx, cy, rx, ry, start_angle, sweep_angle, rotation)

	draw(cx1, cy1, r1x, r1y, start_angle1, sweep_angle1, rotation1, nil, nil, mt, '#ffff00')
	draw(cx2, cy2, r2x, r2y, start_angle2, sweep_angle2, rotation2, nil, nil, mt, '#ff00ff')

	--exact hit/split point
	self:circle(x, y, 2, '#00ff00')

	--arc length
	local len1 = arc.length(1, cx1, cy1, r1x, r1y, start_angle1, sweep_angle1, rotation1, nil, nil, mt, max_segment_sweep)
	local tlen = arc.length(1, cx, cy, rx, ry, start_angle, sweep_angle, rotation, nil, nil, mt, max_segment_sweep)
	local clen = arc.length(t, cx, cy, rx, ry, start_angle, sweep_angle, rotation, nil, nil, mt, max_segment_sweep)
	local len2 = arc.length(1, cx2, cy2, r2x, r2y, start_angle2, sweep_angle2, rotation2, nil, nil, mt, max_segment_sweep)

	--split time
	self:label{x = x, y = y+30, text =
		string.format('t: %4.2f (scale: %d), tlen: %4.2f, len1: %4.2f\nlen1+len2-tlen: %4.4f, len1-clen: %4.4f',
								t, scale, tlen, len1, len1+len2-tlen, len1-clen), font_size = 16}
end

player:play()

