local player = require'cplayer'

local screen = player:screen()

--screen.snapping = false

local t1 = player:toolbox{id = 'toolbox example', x = 10, y = 10, w = 200, h = 200, screen = screen, bg_color = '#003366'}
local t2 = player:toolbox{id = 'another toolbox', x = 10, y = 250, w = 200, h = 200, screen = screen, bg_color = '#003366'}
local t3 = player:toolbox{id = 'toolbox 3', x = 250, y = 200, w = 100, h = 50, screen = screen, bg_color = '#003366'}

local maxt = 2
local t = {}
for i = 1, maxt do
	t[#t+1] = player:toolbox{id = 'toolbox example #'..i,
		x = 10 + i * 100, y = 10 + i * 10, w = 250, h = 200, screen = screen,
		bg_color = '#0033'..string.format('%2x', i)}
end

--player.continuous_rendering = false

function player:on_render(cr)
	screen.x = 0
	screen.y = 0
	screen.w = self.w
	screen.h = self.h
	screen.app = self
	t1.app = self
	t2.app = self
	t3.app = self
	for i = 1, maxt do
		t[i].app = self
	end
	screen:render()
end

player:play()

