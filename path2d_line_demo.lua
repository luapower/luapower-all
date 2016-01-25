local player = require'cplayer'
local line = require'path2d_line'

local l1 = {100, 100, 400, 600}
local l2 = {100, 400, 600, 100}

function player:on_render(cr)

	local function draw(id, l)
		--draggable control points
		self:dragpoints{id = id, points = l}

		--bounding box
		local x, y, w, h = line.bounding_box(unpack(l))
		self:rect(x, y, w, h, 'faint_bg')

		--hit -> draw hit point
		local d,x,y,t = line.hit(self.mousex, self.mousey, unpack(l))
		self:dot(x, y, 4, '#00ff00')

		--split -> draw pieces with different colors
		local
			ax1, ay1, ax2, ay2,
			bx1, by1, bx2, by2 = line.split(t, unpack(l))
		self:line(ax1, ay1, ax2, ay2, '#ffff00')
		self:line(bx1, by1, bx2, by2, '#ff00ff')

		--length
		self:label{x = x, y = y+10, text = string.format('t: %4.2f, len: %4.2f', t, line.length(t, unpack(l)))}
	end

	--line intersect
	local x1, y1, x2, y2 = unpack(l1)
	local t1, t2 = line.line_line_intersection(x1, y1, x2, y2, unpack(l2))
	local ix, iy = line.point(t1, unpack(l1))

	--draw intersection point
	self:dot(ix, iy, 6, t1 >= 0 and t1 <= 1 and t2 >= 0 and t2 <= 1 and '#ff0000' or nil)

	--draw lines
	draw('l1', l1)
	draw('l2', l2)
end

return player:play(...)
