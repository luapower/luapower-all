local player = require'cplayer'
local boxlayer = require'cplayer.boxlayer'
local layers = require'cplayer.layerlist'

local layers = layers:new()
layers:add(setmetatable({color = '#ff6666', x = 10, y = 10, w = 200, h = 150}, {__index = boxlayer}))
layers:add(setmetatable({color = '#66ff66', x = 50, y = 50, w = 200, h = 150}, {__index = boxlayer}))
layers:add(setmetatable({color = '#6666ff', x = 90, y = 90, w = 200, h = 150}, {__index = boxlayer}))

function player:on_render(cr)
	local mx, my = self:mousepos()

	if self.lpressed then
		local layer = layers:hit(mx, my)
		if layer then
			layers:bring_to_front(layer)
		end
	end

	layers:render(self)
end

player:play()
