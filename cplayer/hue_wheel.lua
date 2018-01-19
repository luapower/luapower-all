--hue wheel and picker
local player = require'cplayer'
local color = require'color'
local point = require'path2d_point'

function player:hue_wheel(cx, cy, r1, r2, step, hue)

	local mx, my = self:mousepos()

	local hue1 = point.point_angle(mx, my, cx, cy)
	local d = point.distance(mx, my, cx, cy)
	local hot = d >= r1 and d <= r2

	for i = 0, 360, step do
		local r, g, b = color.hsl_to_rgb(i, 1, .5)
		self.cr:rgba(r, g, b, 1)
		self.cr:new_path()
		self.cr:arc(cx, cy, r1, math.rad(i), math.rad(i + step + 1))
		self.cr:arc_negative(cx, cy, r2, math.rad(i + step + 1), math.rad(i))
		self.cr:close_path()
		self.cr:fill()
	end

	if not self.active and hot and self.lpressed then
		self.active = 'wheel'
	elseif self.active == 'wheel' then
		if self.lbutton then
			hue = hue1
		else
			self.active = nil
		end
	end

	if hot or self.active then
		self.cursor = 'hand'
	end

	local x, y = point.point_around(cx, cy, (r1 + r2) / 2, hue)
	self:dot(math.floor(x + 0.5), math.floor(y + 0.5), 5, 'normal_fg')

	return hue
end

if not ... then require'color_demo' end

