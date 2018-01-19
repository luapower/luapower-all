local easing = require'easing'
local player = require'cplayer'
local box = require'box2d'
local color = require'color'

local manual = false
local progress
local duration = 2
local start_time
local selected_func = 'linear'

function player:on_render(cr)

	manual = self:togglebutton{id = 'manual', text = 'manual', x = 10, y = 10, w = 80, h = 26, selected = manual}
	if manual then
		progress = self:slider{id = 'progress', x = 100, y = 10, w = 90, h = 26, i0 = 0, i1 = 1, step = 0.001, i = progress}
	else
		duration = self:slider{id = 'duration', x = 100, y = 10, w = 90, h = 26, i0 = 0.1, i1 = 5, step = 0.01, i = duration}
		if self:button{id = 'restart', x = 200, y = 10, w = 90, h = 26} then
			start_time = nil
		end
	end

	start_time = start_time or self.clock

	local t
	if manual then
		t = progress * duration
	else
		t = self.clock - start_time
		if t > duration then
			start_time = self.clock
			t = 0
		end
	end

	local x = 10
	local y = 45
	local mx, my = self:mousepos()

	for k,f in pairs(easing) do

		local hot = box.hit(mx, my, x, y, 300, 15)
		if hot then
			self.cursor = 'hand'
		end
		if hot and self.clicked then
			selected_func = k
		end
		local selected = selected_func == k

		local bg_color = selected and 'selected_bg' or hot and 'hot_bg' or 'faint_bg'
		local fg_color = selected and 'selected_fg' or hot and 'hot_fg' or 'normal_fg'

		self:rect(x, y, 100, 15, bg_color)
		self:textbox(x, y, 100, 15, k, 12, fg_color, 'left', 'center')

		local i = f(t, 0, 1, duration)
		self:dot(x + 200 + i * 100, math.floor(y + 15 / 2), 5, bg_color)

		if selected then

			--as linear movement
			self:line(400, 100, 400, 400, bg_color)
			self:dot(400, 100 + i * 300, 10)

			--as box offset
			local x, y, w, h = box.offset(i * 50, 500, 100, 100, 100)
			self:rect(x, y, w, h)
			local x, y, w, h = box.offset(-i * 50, 700, 50, 200, 200)
			self:rect(x, y, w, h)

			--as color fade
			self:rect(500, 300, 100, 100, {i, i, i, 1})
			self:rect(610, 300, 100, 100, {1-i, 1-i, 1-i, 1})

			--as hue change
			local r, g, b = color.hsl_to_rgb(i * 360, .5, .5)
			self:rect(500, 410, 100, 100, {r, g, b, 1})
		end

		y = y + 15
	end
end

player:play()


