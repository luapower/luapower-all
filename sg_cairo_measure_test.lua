local player = require'cplayer'
local ffi = require'ffi'
local cairo = require'cairo'

local scene = {
	type = 'group', x = 100, y = 100,
	{type = 'color', 0,0,0,1},
	{type = 'group', x = 200, cx = 300, cy = 300, angle = -15, scale = .5, skew_x = 0,
		{type = 'shape', path = {'rect', 0, 0, 100, 100}, fill = {type = 'color', 1,1,1,1}},
		{type = 'shape', y = 210, path = {'rect', 0, 0, 100, 100}, line_width = 50, stroke = {type = 'color', 1,1,1,1}},
		{type = 'image', angle = -30, y = 360, x = 100, file = {path = 'media/jpeg/testorig.jpg'}},
	},
}

local function box2rect(x1,y1,x2,y2)
	return x1,y1,x2-x1,y2-y1
end

local fill_extents_color = {type = 'color', 1, 0, 0, 0.5}
local stroke_extents_color = {type = 'color', 0, 0, 1, 0.5}

function player:on_render()
	self.scene_graph.fill_extents_color = fill_extents_color
	self.scene_graph.stroke_extents_color = stroke_extents_color

	scene[2].angle = scene[2].angle + .2
	player:render(scene)
	player:render{type = 'shape', path = {'rect', box2rect(self.scene_graph:measure(scene))},
						stroke = {type='color',1,1,1,.2}, line_width = 10}
end
player:play()

