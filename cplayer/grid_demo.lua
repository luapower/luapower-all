local player = require'cplayer'
local glue = require'glue'

local grid = {
	x = 10, y = 10, w = 500, h = 300,
	fields = {'id', 'name', 'description'},

}

function player:on_render()

	grid = self:grid(grid)

	--[[
	grid_state =
	self:grid{id = 'grid', x = 10, y = 10, w = 400, h = 200,
		fields = {'id', 'name', 'description'},
		field_meta = {
			id = {align = 'right'},
		},
		rows = {
			{1, 'goon', 'woody quality'},
			{2, 'tit', 'tinny quality'},
			{3, 'tit', 'tinny quality'},
			{4, 'tit', 'tinny quality'},
			{5, 'tit', 'tinny quality'},
			{6, 'tit', 'tinny quality'},
			{7, 'tit', 'tinny quality'},
			{8, 'tit', 'tinny quality'},
			{9, 'tit', 'tinny quality'},
			{10,'end', 'endy quality'},
		},
		state = grid_state or {
			selected_row = 5,
			col_widths = {
				id = 50,
				description = 300,
			},
		},
	}
	]]

end

player:play()
