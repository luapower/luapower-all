local glue = require'glue'

local operator_palette = {
	type = 'group', y = 380, x = 10,
}
for i,operator in ipairs{
	'clear', 'source', 'over', 'in', 'out', 'atop', 'dest', 'dest_over', 'dest_in', 'dest_out',
	'dest_atop', 'xor', 'add', 'saturate', 'multiply', 'screen', 'overlay', 'darken',
	'lighten', 'color_dodge', 'color_burn', 'hard_light', 'soft_light', 'difference',
	'exclusion', 'hsl_hue', 'hsl_saturation', 'hsl_color', 'hsl_luminosity',
} do
	operator_palette[#operator_palette+1] = {
		type = 'group', scale = .5,
		x = .5 + ((i-1) % 12) * 100,
		y = math.floor((i-1) / 12) * 80,
		{type = 'shape', path = {'rect', 0, 0, 130, 130}, fill = {type = 'color', 1,1,1,1}},
		{type = 'shape', path = {'rect', 0, 0, 100, 100}, fill = {type = 'color', 1,0,0,.7}},
		{type = 'shape', path = {'rect', 0, 0, 100, 100}, fill = {type = 'color', 0,0,1,.7},
			x = 30, y = 30, operator = operator},
		{type = 'shape', path = {nocache = true, 'move', 0, 0, 'text', {size = 16*2}, operator}, fill = {type = 'color', 1,1,1,1}},
	}
end

local measuring_box = {type = 'shape', path = {'move',0,0}, stroke = {type = 'color', 1,1,1,1}, line_dashes = {5}}
local measuring_subject = {type = 'group', x = 900, y = 550, scale = 0.5,
	{type = 'group', x = 200, angle = 15, scale = 1, skew_x = 0,
		{type = 'shape', path = {'rect', 0, 0, 100, 100}, fill = {type = 'color', 1,1,1,1}},
		{type = 'shape', y = 210, path = {'rect', 0, 0, 100, 100}, line_width = 50, stroke = {type = 'color', 1,1,1,1}},
		{type = 'image', angle = -30, y = 360, x = 100, file = {path = 'media/jpeg/testorig.jpg'}},
	},
}

local transformations = {type = 'group',
	{type = 'shape', path = {'move', 0, 0, 'line', 100, 0}, stroke = {type = 'color', 1,1,1,1},
		x = 10, y = 60, cx = 50, cy = 0, angle = 45, skew_x = 0},
	{type = 'shape', path = {'move', 0, 0, 'line', 100, 0}, stroke = {type = 'color', 1,1,1,1},
		x = 10, y = 60, cx = 50, cy = 0, angle = -45, scale = .5, sx = 1, sy = 8, skew_y = 0},
	{type = 'shape', path = {'rect', 0, 0, 100, 100}, stroke = {type = 'color', 1,1,1,1},
		matrix = {math.tan(math.rad(3)),1,1,-math.tan(math.rad(3)),120,10}},

	--transform series
	{type = 'shape', path = {'move', 0, 0, 'line', 100, 0}, stroke = {type = 'color', 1,1,1,1},
		transforms = {
			{'translate', 110, 0},
			{'translate', 10, 60},
			{'translate', 50, 0},
			{'rotate', 45},
			{'translate', -50, 0},
			{'skew', 0, 0},
	}},
	{type = 'shape', path = {'move', 0, 0, 'line', 100, 0}, stroke = {type = 'color', 1,1,1,1},
		transforms = {
			{'translate', 110, 0},
			{'translate', 10, 60},
			{'translate', 50, 0},
			{'rotate', -45},
			{'scale', .5},
			{'scale', 1, 8},
			{'translate', -50, 0},
			{'skew', 0, 0},
	}},
}

line_styles = {type = 'group',
	{type = 'group', x = 240, y = 40,
		{type = 'shape', line_join = 'miter', x = 0, line_cap = 'butt',
			path = {'move', 0, 0, 'line', 40, 50, 'line', 70, 0}, stroke = {type = 'color', 1,1,1,.5}, line_width = 20},
		{type = 'shape', line_join = 'round', x = 120, line_cap = 'round',
			path = {'move', 0, 0, 'line', 40, 50, 'line', 70, 0}, stroke = {type = 'color', 1,1,1,.5}, line_width = 20},
		{type = 'shape', line_join = 'bevel', x = 240, line_cap = 'square',
			path = {'move', 0, 0, 'line', 40, 50, 'line', 70, 0}, stroke = {type = 'color', 1,1,1,.5}, line_width = 20},

		{type = 'shape', x = 0,
			path = {'move', 0, 0, 'line', 40, 50, 'line', 70, 0}, stroke = {type = 'color', 1,1,1,1}, line_width = 1},
		{type = 'shape', x = 120,
			path = {'move', 0, 0, 'line', 40, 50, 'line', 70, 0}, stroke = {type = 'color', 1,1,1,1}, line_width = 1},
		{type = 'shape', x = 240,
			path = {'move', 0, 0, 'line', 40, 50, 'line', 70, 0}, stroke = {type = 'color', 1,1,1,1}, line_width = 1},

		{type = 'group', x = 360,
			{type = 'shape', line_join = 'miter', x = 0, line_cap = 'butt',
				path = {'move', 0, 0, 'line', 40, 50, 'line', 70, 0}, stroke = {type = 'color', 1,1,1,.5}, line_width = 20,
				line_dashes = {10}},
			{type = 'shape', line_join = 'round', x = 120, line_cap = 'round',
				path = {'move', 0, 0, 'line', 40, 50, 'line', 70, 0}, stroke = {type = 'color', 1,1,1,.5}, line_width = 20,
				line_dashes = {15}},
			{type = 'shape', line_join = 'bevel', x = 240, line_cap = 'square',
				path = {'move', 0, 0, 'line', 40, 50, 'line', 70, 0}, stroke = {type = 'color', 1,1,1,.5}, line_width = 20,
				line_dashes = {10,30}},

			{type = 'shape', x = 0,
				path = {'move', 0, 0, 'line', 40, 50, 'line', 70, 0}, stroke = {type = 'color', 1,1,1,1}, line_width = 1},
			{type = 'shape', x = 120,
				path = {'move', 0, 0, 'line', 40, 50, 'line', 70, 0}, stroke = {type = 'color', 1,1,1,1}, line_width = 1},
			{type = 'shape', x = 240,
				path = {'move', 0, 0, 'line', 40, 50, 'line', 70, 0}, stroke = {type = 'color', 1,1,1,1}, line_width = 1},
		},
	},
}

local fill_rule = {type = 'group',
	{type = 'group', x = 960, y = 10,
		{type = 'shape', x = 0, fill_rule = 'evenodd',
			path = {'move', 0, 0, 'circle', 50, 50, 50, 'circle', 50, 50, 20},
			stroke = {type = 'color', 1,1,1,1}, fill = {type = 'color', 1,1,1,.5},},
		{type = 'shape', x = 110, fill_rule = 'nonzero',
			path = {'move', 0, 0, 'circle', 50, 50, 50, 'circle', 50, 50, 20},
			stroke = {type = 'color', 1,1,1,1}, fill = {type = 'color', 1,1,1,.5},},
	},
}

local gradients = {type = 'group',
	{type = 'group', y = 620,
		{type = 'shape', path = {'rect', 0, 0, 100, 20},
			fill = {type = 'gradient', relative = true, x1 = 0, y1 = 0, x2 = 1, y2 = 0, 0, {1,1,1,0}, 1, {1,1,1,1}}},
		{type = 'shape', y = 30, path = {'rect', 0, 0, 100, 20},
			fill = {type = 'gradient', relative = true, x1 = 0, y1 = 0, x2 = 1, y2 = 0,
				0, {0,0,0,1}, .2, {1,1,0,1}, .8, {1,0,1,1}, 1, {1,1,1,1}}},

		{type = 'shape', x = 110, path = {'rect', 0, 0, 100, 100}, fill = {type = 'gradient', relative = true, extend = 'none',
			x1 = .5, y1 = .5, x2 = .5, y2 = .5, r1 = 0, r2 = .5, 0, {1,1,1,0}, 1, {1,1,1,1}}},
		{type = 'shape', x = 220, path = {'rect', 0, 0, 100, 100}, fill = {type = 'gradient', relative = true, extend = 'none',
			x1 = 0, y1 = .5, x2 = .5, y2 = .5, r1 = 0, r2 = .5, 0, {1,1,1,0}, 1, {1,1,1,1}}},
		{type = 'shape', x = 330, path = {'rect', 0, 0, 100, 100}, fill = {type = 'gradient', relative = true, extend = 'none',
			x1 = 0, y1 = 0, x2 = 1, y2 = 1, r1 = .1, r2 = .5, 0, {1,1,1,0}, 1, {1,1,1,1}}},
		{type = 'shape', x = 440, path = {'rect', 0, 0, 100, 100}, fill = {type = 'gradient', relative = true, extend = 'repeat',
			x1 = 0, y1 = 0, x2 = .1, y2 = .1, r1 = 0, r2 = .2, 0, {1,1,1,0}, 1, {1,1,1,1}}},
		{type = 'shape', x = 550, path = {'rect', 0, 0, 100, 100}, fill = {type = 'gradient', relative = true, extend = 'repeat',
			x1 = 0, y1 = 0, x2 = .2, y2 = .2, 0, {1,1,1,0}, 1, {1,1,1,1}}},

		{type = 'shape', x = 660, path = {'rect', 0, 0, 100, 100}, fill = {type = 'gradient', relative = true, extend = 'reflect',
			x1 = 0, y1 = 0, x2 = .1, y2 = .1, r1 = 0, r2 = .2, 0, {1,1,1,0}, 1, {1,1,1,1}}},
		{type = 'shape', x = 770, path = {'rect', 0, 0, 100, 100}, fill = {type = 'gradient', relative = true, extend = 'reflect',
			x1 = 0, y1 = 0, x2 = .2, y2 = .2, 0, {1,1,1,0}, 1, {1,1,1,1}}},
	},
}

local shapes = {type = 'group',
	{type = 'shape', y = 110,
		path = {
			'move', 10, 10,
			'rel_line', 0, 100,
			'rel_hline', 100,
			'rel_vline', -100,
			'close',
			'rel_move', 110, 0,
			'rel_curve', 100, 0, 0, 100, 100, 100,
			'rel_move', 10, -100,
			'rel_curve', 100, 200, 100, -100, 0, 100,
			'rel_move', 110, -50,
			'rel_curve', 30, -60, 100-30, -60, 100, 0,
			'rel_symm_curve', 100-30, 60, 100, 0,
			'rel_quad_curve', 50, 50, 100, 0,
			'rel_symm_quad_curve', 100, 0,
			'rel_svgarc', 50, 20, -15, 1, 0, 20, 0,
			'rel_svgarc', 50, 20, -15, 1, 1, 20, 0,
			'rel_arc', 0, 0, 50, 0, -330,
			'rel_arc', 0, 0, 50, 0, 330,
			'break',
			'move', 780, 60,

			'move', 10, 120,
			'line', 10, 220,
			'hline', 110,
			'vline', 120,
			'close',
			'move', 120, 120,
			'curve', 120+100, 120+0, 120+0, 120+100, 120+100, 120+100,
			'move', 230, 120,
			'curve', 230+100, 120+200, 230+100, 120+-100, 230+0, 120+100,
			'move', 340, 220-50,
			'curve', 340+30, 220+-60-50, 340+100-30, 220+-60-50, 340+100, 220+0-50,
			'symm_curve', 340+100+100-30, 220+60-50, 340+100+100, 220+0-50,
			'quad_curve', 340+100+100+50, 220+0-50+50, 340+100+100+100, 220+0-50,
			'symm_quad_curve', 340+100+100+100+100, 220+0-50,
			'svgarc', 50, 20, -15, 1, 0, 340+100+100+100+100+20, 220+0-50,
			'svgarc', 50, 20, -15, 1, 1, 340+100+100+100+100+20+20, 220+0-50,
			'arc', 340+100+100+100+100+40, 220+0-50, 50, 0, -330,
			'arc', 340+100+100+100+100+40+50, 220+0-50+25, 50, 0, 330,

			'ellipse', 960, 60, 100, 50,
			'circle', 960, 60, 50,
			'rect', 960+110, 10, 100, 100,
			'round_rect', 960+220, 10, 100, 100, 20,
			'move', 900, 220,
			'text', {size = 110, family = 'georgia', slant = 'italic'}, 'g@AWmi',
		},
		stroke = {type = 'color', 1,1,1,1},
	},
}

local leon = {type = 'svg', x = 1500, file = {path = 'media/svg/leon.svg'}}
local tiger = {type = 'svg', x = 1400, y = 600, scale = 1.5, file = {path = 'media/svg/tiger.svg'}}
local futurama = {type = 'svg', x = 1400, y = 600, scale = 1.5, file = {path = 'media/svg/futurama/Homer_and_Bender___Drinking_by_sircle.svg'}}
local ellipse = {type = 'svg', x = 1400, y = 600, scale = 1.5, file = {path = 'media/svg/arcs02.svg'}}

local scene = {
	type = 'group', y = .5, x = .5, scale = .5,
	{type = 'color', 0, 0, 0, 1}, --background
	transformations,
	line_styles,
	fill_rule,
	gradients,
	shapes,
	operator_palette,
	measuring_subject,
	measuring_box,
	--ellipse,
	--futurama,
	tiger,
	leon,
}

local function box2rect(x1,y1,x2,y2)
	return x1,y1,x2-x1,y2-y1
end

local highlight_stroke = {type = 'color', 1,0,0,1}

local player = require'sg_cplayer'

function player:on_render()
	measuring_box.path = {'rect', box2rect(self:measure(measuring_subject))}
	local t = {}
	local x, y = self.scene_graph.mouse_x, self.scene_graph.mouse_y
	if x then
		t = self:hit_test(x, y, scene)
		--print'-----'
		for e in pairs(t) do
			if e.type == 'shape' then
				--e.line_width = 5
				e.stroke, e.old_stroke = highlight_stroke, e.stroke
				--pp(e.path)
			end
			--print(e.type)
		end
	end
	self:render(scene)
	for e in pairs(t) do if e.type == 'shape' then e.stroke, e.old_stroke = e.old_stroke end end
end

player:play()

