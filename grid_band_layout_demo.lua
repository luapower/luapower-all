local player = require'cplayer'
local set_layout = require'grid_band_layout'

local bands = {

	{
		w = 1,
		{name = 'Product Information', rows = 2,
			{min_w = 100, name = 'Product ID'},
			{min_w = 100, name = 'Product Name'},
		},
		{name = 'Price Information',
			{name = 'Price',
				{min_w = 100, name = 'Qty / Unit', min_w = 40},
				{min_w = 100, name = 'Unit Price'},
				{min_w = 100, name = 'Discontinued'},
			},
			{name = 'Units',
				{min_w = 100, name = 'Units In Stock'},
				{min_w = 100, name = 'Units On Order'},
			},
		},
		{name = 'Other', rows = 2,
			{min_w = 100, name = 'Reorder Level'},
			{min_w = 100, name = 'EAN13'},
		},
	},

	{
		name = 'A', w = 200,
		{name = 'A1', {w = 130, name = 'A11'}, {w = 200, name = 'A12'}},
		{name = 'A2', {w = 200, name = 'A21'}, {w = 200, name = 'A22'}},
	},

	{
		name = 'A', w = 480,
		{name = 'A1', pw = .15},
		{name = 'A2', w = 20, pw = .5},
		{name = 'A3',         },
		{name = 'A4',         },
		{name = 'A5', pw = .20, min_w = 120},
	},

	{
		name = 'A', w = 240,
		{name = 'A1', min_w = 50},
		{name = 'A2'},
		{name = 'A3'},
		{name = 'A4', min_w = 120},
	},

}

local function walk_band_cells(f, band, x, y)
	x = x or 0.5 --0.5 because 0 is between the pixels in cairo
	y = y or 0.5
	local w = band._w
	local h = (band.rows or 1) * 100
	if band.name then
		f(band, x, y, w, h)
		y = y + h
	end
	for i, cband in ipairs(band) do
		walk_band_cells(f, cband, x, y)
		x = x + cband._w
	end
end

function player:render_band(band)
	walk_band_cells(function(band, x, y, w, h)

		self:rect(x, y, w, h,
			(w == band._min_w or w == band._max_w) and 'hot_bg' or 'normal_bg', 'normal_border', 1)
		self.cr:font_face('MS Sans Serif')
		local t = {
			band.name,
			string.format('%4.2f', band._pw),
			band._min_w .. ' - ' .. band._max_w,
			string.format('%4.2f', band._w)}
		for i,s in ipairs(t) do
			self:textbox(x, y + 13 * (i-1), w, h, s, 'MS Sans Serif,8', 'normal_fg', 'center', 'center')
		end

	end, band)
end

local band = bands[2]

function player:on_render()

	band = self:mbutton{id = 'bands', x = 10, y = 10, w = self.w - 20, h = 26,
								values = bands, selected = band, multiselect = false}

	self.cr:translate(10, 50)

	local mx, my = self.cr:device_to_user(self.mousex, self.mousey)

	band.w = mx

	set_layout(band)

	self:render_band(band)

end

player:play()

