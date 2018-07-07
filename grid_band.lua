
local set_layout = require'grid_band_layout'

--set hierarchy info

local function set_children(parent, root)
	for i, child in ipairs(parent) do
		child.index = i
		child.parent = parent
		child.root = root
		set_children(child, root)
	end
end

local function set_hierarchy(band)
	band.root = band
	set_children(band, band)
end

local function isparent(band, child)
	return child.parent == band or (child.parent and isparent(band, child.parent))
end

--stateless iteration

local function right_band(band)
	if not band.parent then return end
	if band.index < #band.parent then
		return band.parent[band.index + 1]
	else
		return right_band(band.parent)
	end
end

local function next_band(band0, band)
	if not band then
		return band0
	end
	if #band > 0 then
		return band[1]
	else
		return right_band(band)
	end
end

local function bands(band) --depth-first top-down iterator
	return next_band, band
end

--inherit row height

local function set_row_h(band)
	band._row_h = band.row_h or (band.parent and band.parent._row_h) or 26
	for i, child in ipairs(band) do
		set_row_h(child)
	end
end

-- set number of rows

local function set_rows(band)
	local child_rows = 0
	for i, child in ipairs(band) do
		set_rows(child)
		child_rows = math.max(child_rows, child._total_rows)
	end
	band._rows = band.rows or 1
	band._total_rows = band._rows + child_rows
end

--set coordinates on computed layout

local function band_size(band)
	local w = math.floor(band._w + 0.5)
	local h = band._rows * band._row_h
	local total_h = band._total_rows * band._row_h
	return w, h, total_h
end

local function set_coords_recursive(band, x, y, w, h, total_h)
	band._x = x
	band._y = y
	band._w = w
	band._h = h
	band._total_h = total_h
	local left_w = w
	y = y + h
	for i, child in ipairs(band) do
		w, h, total_h = band_size(child)
		if i == #band then
			w = left_w --drop all rounding chippings on the last child
		end
		set_coords_recursive(child, x, y, w, h, total_h)
		x = x + w
		left_w = left_w - w
	end
end

local function set_coords(band)
	set_coords_recursive(band, 0, 0, band_size(band))
end

--set everything in the right order

local function set_all(band)
	set_hierarchy(band)
	set_row_h(band)
	set_rows(band)
	set_layout(band)
	set_coords(band)
end

--editing

local function move(band, parent, index)
	assert(not parent or band.root == parent.root)
	if parent and band.parent == parent and band.index < index then
		index = index - 1
	end
	assert(not parent or (index >= 1 and index <= #parent + 1))
	if band.parent then
		table.remove(band.parent, band.index)
	end
	if parent then
		table.insert(parent, index, band)
	end
end

--hit testing

local function unpack_band(band)
	return band._x, band._y, band._w, band._h
end

local function hitbox(x0, y0, x, y, w, h)
	return x0 >= x and x0 <= x + w and y0 >= y and y0 <= y + h
end

local function offsetbox(d, x, y, w, h)
	return x - d, y - d, w + 2*d, h + 2*d
end

local function hit_test_body(band, x0, y0) --true, side | nil
	local x, y, w, h = unpack_band(band)
	local half_w = w / 2
	if hitbox(x0, y0, x, y, half_w, h) then
		return true, 'left'
	elseif hitbox(x0, y0, x + half_w, y, half_w, h) then
		return true, 'right'
	end
end

local function hit_test_margins(band, x0, y0, d) --true, top, left, bottom, right | nil
	local x, y, w, h = unpack_band(band)
	if hitbox(x0, y0, offsetbox(d, x, y, 0, 0)) then
		return true, true, true, false, false
	elseif hitbox(x0, y0, offsetbox(d, x + w, y, 0, 0)) then
		return true, true, false, false, true
	elseif hitbox(x0, y0, offsetbox(d, x, y + h, 0, 0)) then
		return true, true, false, true, false
	elseif hitbox(x0, y0, offsetbox(d, x + w, y + h, 0, 0)) then
		return true, false, false, true, true
	elseif hitbox(x0, y0, offsetbox(d, x, y, w, 0)) then
		return true, true, false, false, false
	elseif hitbox(x0, y0, offsetbox(d, x, y + h, w, 0)) then
		return true, false, false, true, false
	elseif hitbox(x0, y0, offsetbox(d, x, y, 0, h)) then
		return true, false, true, false, false
	elseif hitbox(x0, y0, offsetbox(d, x + w, y, 0, h)) then
		return true, false, false, false, true
	end
end

--class

local band = {
	--layout computation
	set_hierarchy = set_hierarchy,
	set_row_h = set_row_h,
	set_rows = set_rows,
	set_layout = set_layout,
	set_coords = set_coords,
	set_all = set_all,
	--navigation
	next = next_band,
	bands = bands,
	isparent = isparent,
	--editing
	move = move,
	--hit testing
	hit_test_body = hit_test_body,
	hit_test_margins = hit_test_margins,
}

function band:new(t)
	self = glue.inherit(t, self)
	return self
end

--rendering stubs
--[[
function band:draw_arrow(x, y, angle) end --draw an arrow pointing at x, y rotated at an angle (in degrees)
function band:draw_rect(x, y, w, h, fill, stroke, line_width) --draw a rectangle
function band:draw_text(text, font_face, font_size, valign, halign, x, y, w, h) --draw text in a box

local function render(band)
	for band in bands(band) do

		local x, y, w, h, i, pband = band._x, band._y, band._w, band._h, band.index, band.parent

		if not (self.active and self.ui.action == 'move' and grid_band.isparent(self.active, band)) then
			self:rect(x + 0.5, y + 0.5, w, self.active == band and band._total_h or h,
				(self.active == band and self.ui.action == 'move' and '#ff9999')
				or 'normal_bg', 'normal_border', 1)
		end

		self.cr:select_font_face('MS Sans Serif', 0, 0)
		local t = {
			band.name,
			(band.w or (band.wp and band.wp * 100 .. '%') or '') .. ''
		}

		for i,s in ipairs(t) do
			self:text(s, 8, 'normal_fg', 'center', 'center', x, y + 13 * (i-1), w, h)
		end
	end
end

local function draw_arrow(cr, x, y, angle)
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
]]

if not ... then require'grid_band_demo' end

return {
	--layout computation
	set_hierarchy = set_hierarchy,
	set_row_h = set_row_h,
	set_rows = set_rows,
	set_layout = set_layout,
	set_coords = set_coords,
	set_all = set_all,
	--navigation
	next_band = next_band,
	bands = bands,
	isparent = isparent,
	--editing
	move = move,
	--hit testing
	hit_test_body = hit_test_body,
	hit_test_margins = hit_test_margins,
}

