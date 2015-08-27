--a dragpoint is a square point that you can drag around, use as a handle.
local player = require'cplayer'

function player:dragpoint(t)
	local id = assert(t.id, 'id missing')
	local x = assert(t.x, 'x missing')
	local y = assert(t.y, 'y missing')
	local radius = t.radius or 5
	local threshold = t.threshold or radius + 2

	local down = self.lbutton
	local hot = self:hotbox(x-threshold, y-threshold, 2*threshold, 2*threshold)

	if not self.active and hot and down then
		self.active = id
	elseif self.active == id then
		if not down then
			self.active = nil
		else
			x, y = self.mousex, self.mousey
		end
	end

	self:dot(x, y, radius, t.fill or self.active == id and 'selected_bg' or hot and 'hot_bg' or 'normal_bg')

	return x, y
end

function player:dragpoints(t)
	local id = assert(t.id, 'id missing')
	local radius = t.radius or 5
	local threshold = t.threshold or radius + 2
	local points = assert(t.points or 'points missing')

	for i=1,#points,2 do
		points[i], points[i+1] = self:dragpoint{
			id = id..'_p'..tostring(i), radius = radius, threshold = threshold,
			x = points[i], y = points[i+1]}
	end

	return points
end

