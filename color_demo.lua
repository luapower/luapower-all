local color = require'color'
local player = require'cplayer'
local box = require'box2d'

local hue, sat, lum = 0, 0.7, 0.3

function player:on_render(cr)

	hue = self:hue_wheel(200, 200, 100, 150, 1, hue)
	sat, lum = self:sat_lum_square(400, 75, 256, 256, hue, sat, lum)

	self:text(100, 400,
		'h: ' .. hue .. '\n' ..
		's: ' .. sat .. '\n' ..
		'L: ' .. lum .. '\n' ..
		'rgb: ' .. color(hue, sat, lum):tostring()
	)

	cr:translate(800, 100)
	local c1 = color(hue, sat, lum)
	local c1c = c1:complementary()
	local c2, c3 = c1:triadic()

	self:dot(0, 0, 40, {c1:rgba()})
	self:dot(100, 0, 40, {c2:rgba()})
	self:dot(200, 0, 40, {c3:rgba()})
	self:dot(0, 100, 40, {c1c:rgba()})
end

return player:play(...)
