local player = require'cplayer'
local circle_3p = require'path2d_circle_3p'

local x1, y1, xp, yp, x2, y2 = 200, 200, 400, 200, 400, 400

function player:on_render(cr)

	x1, y1 = self:dragpoint{id = 'p1', x = x1, y = y1}
	xp, yp = self:dragpoint{id = 'pp', x = xp, y = yp}
	x2, y2 = self:dragpoint{id = 'p2', x = x2, y = y2}

	local function circle(x1, y1, xp, yp, x2, y2)
		local cx, cy, r = circle_3p.to_circle(x1, y1, xp, yp, x2, y2)
		if not cx then return end
		cr:circle(cx, cy, r)
		self:stroke('normal_fg')
	end

	circle(x1, y1, xp, yp, x2, y2)
end

player:play()
