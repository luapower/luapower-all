local player = require'cplayer'
local bezier3 = require'path_bezier3'

local b1 = {600, 150, 1000, 10, 550, 10, 1000, 150}
local b2 = {800, 200, 20, 600, 1000, 100, 1200, 350}
local b3 = {50, 400, 4000050, 450, 150, 450, 4000050, 400}
local b4 = {4000050, 550, 150, 500, 4000050, 500, 50, 550}

local scale = 1
local width = 0
local angle_tolerance = 0
local cusp_limit = 0

function player:on_render(cr)

	scale = self:slider{id = 'scale',
		x = 10, y = 10, w = 400, h = 24, text = 'scale',
		i1 = 100, i0 = 0.01, step = 0.01, i = scale,
	}

	width = self:slider{id = 'width',
		x = 10, y = 40, w = 400, h = 24, text = 'width',
		i1 = 200, i0 = 0, step = 1, i = width,
	}

	angle_tolerance = self:slider{id = 'angle_tolerance',
		x = 10, y = 70, w = 400, h = 24, text = 'angle tolerance',
		i1 = 90, i0 = 0, step = 0.1, i = angle_tolerance,
	}

	cusp_limit = self:slider{id = 'cusp_limit',
		x = 10, y = 100, w = 400, h = 24, text = 'cusp limit',
		i1 = 90, i0 = 0, step = 1, i = cusp_limit,
	}

	local function interpolate(x1, y1, x2, y2, x3, y3, x4, y4, ...)
		--stroke segments
		local n = 0
		cr:move_to(x1, y1)
		bezier3.interpolate(function(s, x, y) cr:line_to(x, y); n = n + 1 end,
			x1, y1, x2, y2, x3, y3, x4, y4, scale, angle_tolerance, cusp_limit)
		self:stroke(...)

		--segment endpoints
		self:dot(x1, y1, 2)
		bezier3.interpolate(function(s, x, y) self:dot(x, y, 2) end,
			x1, y1, x2, y2, x3, y3, x4, y4, scale, angle_tolerance, cusp_limit)

		--offsetting
		cr:move_to(x1, y1)
		bezier3.interpolate(function(s, x, y) cr:line_to(x, y) end,
			x1, y1, x2, y2, x3, y3, x4, y4, scale, angle_tolerance, cusp_limit)
		self:stroke((...)..'80', width)

		return n
	end

	local function draw(id, b)
		--draw draggable control points
		self:dragpoints{id = id, points = b}

		--draw faint lines to control points
		self:line(b[1], b[2], b[3], b[4], 'faint_bg')
		self:line(b[5], b[6], b[7], b[8], 'faint_bg')

		--draw with cairo first to see if there's any difference
		local x1, y1, x2, y2, x3, y3, x4, y4 = unpack(b)
		self:curve(x1, y1, x2, y2, x3, y3, x4, y4, 'error_bg')

		--bounding box
		local x, y, w, h = bezier3.bounding_box(unpack(b))
		self:rect(x, y, w, h, 'faint_bg')

		--hit -> draw hit point
		local d,x,y,t = bezier3.hit(self.mousex, self.mousey, unpack(b))
		self:dot(x, y, 4, '#00ff00')

		--split -> draw pieces with different colors
		local
			ax1, ay1, ax2, ay2, ax3, ay3, ax4, ay4,
			bx1, by1, bx2, by2, bx3, by3, bx4, by4 = bezier3.split(t, unpack(b))
		local n1 = interpolate(ax1, ay1, ax2, ay2, ax3, ay3, ax4, ay4, '#ffff00')
		local n2 = interpolate(bx1, by1, bx2, by2, bx3, by3, bx4, by4, '#ff00ff')

		--t and length
		self:label{x = x, y = y+10, text =
			string.format('t: %4.2f, len: %4.2f, segs: %d', t, bezier3.length(t, unpack(b)), n1 + n2)}
	end

	--draw curves
	draw('b1', b1)
	draw('b2', b2)
	draw('b3', b3)
	draw('b4', b4)
end

player:play()
