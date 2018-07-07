local player = require'cplayer'
local grid_band = require'grid_band'

player.continuous_rendering = false

local band = {
	row_h = 100,
	name = 'A', w = 480,
	{name = 'A1', w = 100, pw = .15},
	{name = 'A2', w = 20},
	{name = 'A3'},
	{name = 'A22', w = 20},
	{name = 'A4'},
	{name = 'A5', w = 120},
}

local band = {
	--row_h = 100,
	w = 1000,
	name = 'main',
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
}

grid_band.set_all(band)

local function eq(a, b, e) return math.abs(a-b) < e end

function player:render_band(band)
	for band in grid_band.bands(band) do
		local x, y, w, h, i, pband = band._x, band._y, band._w, band._h, band.index, band.parent
		if not (self.active and self.ui.action == 'move' and grid_band.isparent(self.active, band)) then
			local h = self.active == band and band._total_h or h
			local color = self.active == band and self.ui.action == 'move' and '#ff9999' or 'normal_bg'
			self:rect(x + 1, y + 1, w - 1, h - 1, color)
		end
		local t = {
			band.name,
			(band.w or (band.wp and band.wp * 100 .. '%') or '') .. ''
		}
		for i,s in ipairs(t) do
			self:textbox(x, y + 13 * (i-1), w, h, s, nil, nil, 'center', 'center')
		end
	end
end

function player:draw_arrow(x, y, angle)
	local cr = self.cr
	local l = 12
	cr:new_path()
	cr:move_to(x, y)
	cr:rotate(math.rad(angle))
	cr:rel_line_to(l/2, math.sqrt(3) / 2 * l)
	cr:rel_line_to(-l * .3, 0)
	cr:rel_line_to(0, l / 2)
	cr:rel_line_to(-l * .4, 0)
	cr:rel_line_to(0, -l / 2)
	cr:rel_line_to(-l * .3, 0)
	cr:close_path()
	cr:rotate(math.rad(-angle))
	self:fillstroke('#ffffff', '#000000', 1)
end

function player:on_render()

	self.cr:translate(50, 50)

	local mx, my = self.cr:device_to_user(self.mousex, self.mousey)

	for band in grid_band.bands(band) do

		local hit, top, left, bottom, right = grid_band.hit_test_margins(band, mx, my, 5)

		if hit then
			if bottom then
				self.cursor = 'size_v'
				if not self.active and self.lbutton then
					self.active = band
					self.ui.action = 'resize_vert'
				end
			elseif right then
				self.cursor = 'size_h'
				if not self.active and self.lbutton then
					self.active = band
					self.ui.action = 'resize_horiz'
				end
			end
		elseif grid_band.hit_test_body(band, mx, my) then
			self.cursor = 'move'
			if not self.active and self.lbutton then
				self.active = band
				self.ui.action = 'move'
			end
		end
	end

	if self.active then
		if self.lbutton then
			if self.ui.action == 'move' then

				self.ui.dest = nil

				for band in grid_band.bands(band) do

					if band.index and not grid_band.isparent(self.active, band) then

						local hit, top, left, bottom, right = grid_band.hit_test_margins(band, mx, my, 5)

						if hit and bottom then

							self:draw_arrow(band._x, band._y + band._h, 90)
							self:draw_arrow(band._x + band._w, band._y + band._h, -90)
							self.ui.dest = band
							self.ui.index = 1
							break

						else

							local hit, side = grid_band.hit_test_body(band, mx, my)

							if hit then
								local right = side == 'right'
								local w = (right and band._w or 0)
								self:draw_arrow(band._x + w, band._y, 180)
								self:draw_arrow(band._x + w, band._y + band._total_h, 0)
								self.ui.dest = band.parent
								self.ui.index = band.index + (right and 1 or 0)
								self:textbox(
									100, 100, 1000, 100,
									(self.ui.dest.name or '') .. ' ' .. self.ui.index, nil, 'normal_fg', 'right', 'center')
								break
							end

						end

					end

				end

			elseif self.ui.action == 'resize_vert' then

				self.active.rows = math.max(math.floor((my - self.active._y) / self.active._row_h + 0.5), 1)
				grid_band.set_all(band)

			elseif self.ui.action == 'resize_horiz' then

				self.active.w = mx - self.active._x
				grid_band.set_all(band, 0)
				self:text(1000, 100, self.active.name or '', nil, 'normal_fg', 'right')

			end

		else

			if self.ui.action == 'move' and self.ui.dest then
				grid_band.move(self.active, self.ui.dest, self.ui.index)
				grid_band.set_all(band, 0)
				self.ui.dest = nil
			end

			self.active = nil

		end
	end

	self:render_band(band)

end

player:play()

