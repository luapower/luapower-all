--go @ bin/mingw64/luajit -jp=a -e io.stdout:setvbuf'no';io.stderr:setvbuf'no';require'strict';pp=require'pp' "ui_grid.lua"

--ui grid widget.
--Written by Cosmin Apreutesei. Public Domain.

local ui = require'ui'
local glue = require'glue'
local box2d = require'box2d'

local push = table.insert
local pop = table.remove
local clamp = glue.clamp
local indexof = glue.indexof
local binsearch = glue.binsearch
local attr = glue.attr

local function popval(t, v)
	local i = indexof(v, t)
	return i and pop(t, i)
end

local grid = ui.layer:subclass'grid'
ui.grid = grid

grid.focusable = true
grid.border_color = '#080808'
grid.border_width = 1

--column panes ---------------------------------------------------------------

local pane = {} --pane mixin: goes into scroll_pane and freeze_pane

function pane:after_init()
	self.header_layer = self.grid:create_header_layer(self)
	self.rows_layer = self.grid:create_rows_layer(self)
end

function pane:cols_w()
	local w = 0
	for _,col in ipairs(self.grid.cols) do
		if col.pane == self and col.visible then
			w = w + col.w
		end
	end
	return w
end

function pane:after_sync()
	--sync columns parent and height based on their pane property.
	local col_h = self.grid.col_h
	for _,col in ipairs(self.grid.cols) do
		if col.pane == self then
			col.parent = self.header_layer
			col_h = math.max(col_h, col.h or 0)
			col.h = col_h
		end
	end
	--sync column positions.
	self:sync_cols_x()

	self.header_layer:sync()
	self.rows_layer:sync()
end

function pane:col_at_x(x, clamp_left, clamp_right)
	clamp_left = clamp_left == nil or clamp_left
	clamp_right = clamp_right == nil or clamp_right
	local first_col, last_col
	for _,col in ipairs(self.grid.cols) do
		if col.visible and col.pane == self then
			if x >= col.x and x <= col.x2 then
				return col
			end
			first_col = first_col or col
			last_col = col
		end
	end
	if clamp_left and x < first_col.x then
		return first_col
	end
	if clamp_right and x > last_col.x2 then
		return last_col
	end
end

function pane:max_w()
	return 1/0
end

--freeze pane ----------------------------------------------------------------

local freeze_pane = ui.layer:subclass'grid_freeze_pane'
grid.freeze_pane_class = freeze_pane
freeze_pane:inherit(pane)

function grid:create_freeze_pane(t)
	local pane = self.freeze_pane_class(self.ui, {
		parent = self,
		grid = self,
		frozen = true,
	}, t)
	pane.content = pane
	return pane
end

function freeze_pane:col_index_range()
	return 1, self.grid.freeze_col
end

--the freeze pane must be small enough so that the splitter is always visible.
function freeze_pane:max_w()
	return self.grid.cw - self.grid.splitter.w
end

function freeze_pane:after_sync()
	self.h = self.grid.ch
	self.cw = self:cols_w()
end

--scroll pane ----------------------------------------------------------------

local scroll_pane = ui.scrollbox:subclass'grid_scroll_pane'
grid.scroll_pane_class = scroll_pane
scroll_pane:inherit(pane)

scroll_pane.vscrollable = false
scroll_pane.scrollbar_margin_right = 12

function grid:create_scroll_pane(freeze_pane)
	return self.scroll_pane_class(self.ui, {
		parent = self,
		grid = self,
		frozen = false,
		freeze_pane = freeze_pane,
	}, self.scroll_pane)
end

function scroll_pane:col_index_range()
	return self.grid.freeze_col and self.grid.freeze_col + 1 or 1, 1/0
end

function scroll_pane:after_sync()
	self.h = self.grid.ch
	self.content.h = self.h
	local fp = self.freeze_pane
	local s = self.grid.splitter
	local sw = s.visible and s.w or 0
	self:transition('x', fp.w + sw)
	self:transition('w', self.grid.cw - fp.w - sw)
	if self.grid.resizing_col then
		--prevent shrinking to avoid scrolling while resizing
		self.content.w = math.max(self.content.w, self:cols_w())
	else
		--prevent going smaller than container to prevent clipping while moving
		self.content.w = math.max(self:cols_w(), self.content_container.cw)
	end
end

--freeze pane splitter -------------------------------------------------------

local splitter = ui.layer:subclass'grid_splitter'
grid.splitter_class = splitter

splitter.w = 6
splitter.background_color = '#888'
splitter.cursor = 'size_h'

ui:style('grid_splitter', {
	transition_x = true,
	transition_duration = .1,
})

ui:style('grid resize_col > grid_splitter', {
	transition_x = false,
})

local drag_splitter = ui.layer:subclass'grid_drag_splitter'
splitter.drag_splitter_class = drag_splitter

drag_splitter.background_color = '#fff2'

function grid:create_splitter()
	return self.splitter_class(self.ui, {
		parent = self,
		grid = self,
	}, self.splitter)
end

function splitter:sync()
	self:transition('x', self.grid.scroll_pane.x - self.w)
	self.h = self.grid.ch
end

function splitter:mousedown()
	self.active = true
end

function splitter:mouseup()
	self.active = false
end

function splitter:start_drag(button, mx, my, area)
	if button ~= 'left' then return end

	self.grid.scroll_pane.hscrollbar:transition('offset', 0)

	local ds = self.grid.drag_splitter
		or self.drag_splitter_class(self.ui, {
				parent = self.parent,
				grid = self.grid,
			}, self.grid.drag_splitter)

	self.grid.drag_splitter = ds

	ds.x = self.x
	ds.y = self.y
	ds.w = self.w
	ds.h = self.h
	ds.visible = true

	self.grid:settag('move_splitter', true)

	return ds
end

function drag_splitter:drag(dx, dy)
	local sp = self.grid.scroll_pane
	sp.hscrollbar.offset = 0

	local col = self.grid:rel_visible_col(-1)
	local last_col_x2 = col and col.parent:to_other(self.grid, col.x2, 0)
	local max_w = math.min(last_col_x2 or 0, self.grid.cw) - self.w
	self:transition('x', clamp(0, self.x + dx + self.w / 2, max_w), 0)

	local ci = self.grid:nearest_col_index_at_x(self.x)
	self.grid.freeze_col = ci
	self:invalidate()
end

function splitter:end_drag(ds)
	ds.visible = false
	self.grid:settag('move_splitter', false)
end

--freeze col -----------------------------------------------------------------

--returns the largest freeze_col which satisifes freeze_pane:max_w()
function grid:max_freeze_col()
	local max_w = self.freeze_pane:max_w()
	local last_i
	for i,col in ipairs(self.cols) do
		if col.visible then
			max_w = max_w - col.w
			if max_w < 0 then
				return i > 1 and i - 1 or nil
			end
		end
	end
	local last_i
	for i = #self.cols, 1, -1 do
		local col = self.cols[i]
		if col.visible then
			if last_i then
				return i
			else
				last_i = i
			end
		end
	end
end

function grid:get_freeze_col()
	return self._freeze_col
end

function grid:set_freeze_col(ci)
	self._freeze_col = ci or nil
end

function grid:sync_freeze_col()
	if self.freeze_col then
		local max_ci = self:max_freeze_col()
		if not max_ci or max_ci < self.freeze_col then
			self.freeze_col = max_ci
		end
	end
	local fi = self.freeze_col
	for i,col in ipairs(self.cols) do
		local frozen = fi and i <= fi
		col.pane = frozen and self.freeze_pane or self.scroll_pane
	end
	self.splitter.visible = fi and true or false
	self.freeze_pane.visible = fi and true or false
end

--header layer ---------------------------------------------------------------

local header = ui.layer:subclass'grid_header'
grid.header_layer_class = header

header.clip_content = true --for column moving
grid.header_visible = true

function grid:create_header_layer(pane)
	return self.header_layer_class(self.ui, {
		parent = pane.content or pane,
		pane = pane,
		grid = self,
	}, self.header_layer)
end

function header:after_sync()
	self.visible = self.grid.header_visible
	self.w = self.pane.content.w
	self.h = self.grid.col_h
end

--rows layer -----------------------------------------------------------------

local rows = ui.layer:subclass'grid_rows'
grid.rows_layer_class = rows

rows.vscrollable = true
rows.background_hittable = true
rows.clip_content = true --for rows

function grid:create_rows_layer(pane)
	return self.rows_layer_class(self.ui, {
		parent = pane.content or pane,
		pane = pane,
		grid = self,
	}, self.rows_layer)
end

function rows:after_sync()
	self.y = self.pane.header_layer.visible and self.grid.col_h or 0
	self.w = self.pane.content.w
	local ct = self.pane.content_container
	self.h = (ct and ct.h or self.pane.h) - self.y
end

function rows:before_draw_content(cr)
	self.grid:draw_rows(cr, self)
end

function rows:mousewheel(delta, mx, my, area, pdelta)
	local rows = math.floor(-delta)
	local i = rows < 0
		and self.grid:row_at_screen_y(0)
		or self.grid:row_at_screen_bottom_y(-1)
	self.grid:scroll_to_view_row(i + rows)
end

function rows:hit_test_cell(x, y, clamp_left, clamp_right)
	local i = self.grid:row_at_screen_y(y)
	if i then
		local col = self.pane:col_at_x(x, clamp_left, clamp_right)
		if col then
			return i, col
		end
	end
end

function rows:override_hit_test_content(inherited, x, y, reason)
	if reason == 'activate' then
		local i, col = self:hit_test_cell(x, y, false, false)
		if i then
			self.grid.hot_row_index = i
			self.grid.hot_col = col
			self:invalidate()
			return self, 'cell'
		end
		self.grid.hot_row_index = false
		self.grid.hot_col = false
		self:invalidate()
	end
	return inherited(self, x, y, reason)
end

function grid:cell_hot()
	return self.ui.hot_area == 'cell'
		and (self.freeze_pane.rows_layer.hot
			or self.scroll_pane.rows_layer.hot)
end

--column headers -------------------------------------------------------------

local col = ui.layer:subclass'grid_col'
grid.col_class = col

col.text_align = 'left'
col._w = 200
col.min_cw = 8
col.max_w = 1000
col.padding_left = 4
col.padding_right = 4
col.clip_content = true
col.background_color = '#111' --for moving
col.border_width = 1
col.border_color = '#333'
col.background_hittable = true
col.cursor_resize = 'size_h'

grid.col_h = 24

function grid:create_col(col, col_index)
	col = self.col_class(self.ui, self.col, col)
	col.grid = self
	col.value_index = col.value_index or col_index
	return col
end

function grid:remove_col(col)
	if col.grid ~= self then return end
	popval(self.cols, col)
	col.grid = nil
end

function col:get_index()
	return indexof(self, self.grid.cols)
end

function col:set_index(i)
	local i0 = self.index
	local i = clamp(i, 1, #self.grid.cols)
	if i == i0 then return end
	pop(self.grid.cols, i0)
	push(self.grid.cols, i, self)
end

function col:get_w()
	return self._w
end

function col:set_w(w)
	local padding = self.w - self.cw
	self._w = clamp(w, padding + self.min_cw, self.max_w)
end

function col:get_frozen()
	local fi = self.grid.freeze_col
	return fi and self.index <= fi
end

function col:get_clipped()
	if not self.visible then
		return true
	end
	local x, y, w, h = self.x, self.y, self.w, self.h
	local w, h = select(3, box2d.clip(x, y, w, h, self.parent:content_rect()))
	return w == 0 or h == 0
end

function col:override_hit_test(inherited, x, y, reason)
	local widget, area = inherited(self, x, y, reason)
	if widget == self then
		if x >= self.x2 - self.padding_right then
			return self, 'resize'
		elseif x <= self.x + self.padding_left then
			local col = self.grid:rel_visible_col(-1, self)
			if col then
				return col, 'resize'
			end
		end
	end
	return widget, area
end

function grid:nearest_col_index_at_x(x)
	local last_ci
	for i,col in ipairs(self.cols) do
		if col.visible then
			local x = self:to_other(col.parent, x, 0)
			if x <= col.cx then
				return last_ci
			elseif x <= col.x2 then
				return i
			end
			last_ci = i
		end
	end
	return last_ci
end

function grid:rel_visible_col(positions, col, clamp)
	if positions == 0 then
		return col or self:rel_visible_col(1)
	end
	local j1, j2, step
	local last_col = col
	if positions > 0 then
		j1, j2, step = col and col.index + 1 or 1, #self.cols, 1
	else
		j1, j2, step = col and col.index - 1 or #self.cols, 1, -1
		positions = -positions
	end
	for j = j1, j2, step do
		local col = self.cols[j]
		if col.visible then
			positions = positions - 1
			last_col = col
			if positions == 0 then
				return col
			elseif positions < 0 then
				break
			end
		end
	end
	return clamp and last_col or nil
end

--column drag & drop ---------------------------------------------------------

col.drag_threshold = 10

function col:mousedown(mx, my, area)
	if area == 'resize' or area == 'background' then
		self.active = true
	end
end

function col:mouseup(mx, my, area)
	self.active = false
end

function col:start_drag(button, mx, my, area)
	if area == 'resize' then
		return self:start_drag_resize(button, mx, my)
	else
		return self:start_drag_move(button, mx, my)
	end
end

function col:drag(dx, dy)
	if self.grid.resizing_col then
		self:drag_resize(dx, dy)
	else
		self:drag_move(dx, dy)
	end
end

function col:end_drag()
	if self.grid.resizing_col then
		self:end_drag_resize()
	else
		self:end_drag_move()
	end
end

--column resizing ------------------------------------------------------------

function col:start_drag_resize(button, mx, my)
	if button ~= 'left' then return end
	self.resizing = true
	self:settag('resizing', true)
	self.grid.resizing_col = self
	self.grid:settag('resize_col', true)
	self.drag_w = self.w
	self.drag_max_w = self.pane:max_w() - self.pane.content.w + self.w
	return self
end

function col:drag_resize(dx, dy)
	local w = self.drag_w + dx
	self.w = math.min(w, self.drag_max_w)
	self:invalidate()
end

function col:end_drag_resize()
	self.drag_w = false
	self.resizing = false
	self:settag('resizing', false)
	self.grid.resizing_col = false
	self.grid:settag('resize_col', false)
end

--column moving --------------------------------------------------------------

function col:start_drag_move(button, mx, my, area)
	if button ~= 'left' then return end
	self.window.cursor = 'move'
	self.moving = true
	self:settag('moving', true)
	self.grid.moving_col = self
	self.grid:settag('move_col', true)
	self:to_front()
	return self
end

function col:drag_move(dx, dy)
	self:transition('x', self.x + dx, 0)
	self:invalidate()
end

function col:end_drag_move()
	self.index = self.move_index
	self.move_index = false
	self.moving = false
	self:settag('moving', false)
	self.grid.moving_col = false
	self.grid:settag('move_col', false)
	self.window.cursor = nil
end

--sync columns x position and move_index for the moving column.
function freeze_pane:sync_cols_x()
	local moving_col = self.grid.moving_col
	moving_col = moving_col and moving_col.pane == self and moving_col
	if moving_col then
		moving_col.move_index = false
	end
	local x = 0
	local i = 1
	local min_col_index, max_col_index = self:col_index_range()
	for _,col in ipairs(self.grid.cols) do
		if col.pane == self then
			if not col.moving and col.visible then
				if moving_col
					and not moving_col.move_index
					and i >= min_col_index
					and i <= max_col_index
					and moving_col.x < x + col.w / 2
				then
					moving_col.move_index = i
					x = x + moving_col.w --make room for the moving col
				end
				col:transition('x', x)
				x = x + col.w
			end
		end
		if not col.moving then
			i = i + 1
		end
	end
	if moving_col and not moving_col.move_index then --too far to the right
		x = x + moving_col.w
		moving_col.move_index = max_col_index
	end
end
scroll_pane.sync_cols_x = freeze_pane.sync_cols_x

ui:style('grid_col', {
	transition_x = true,
	transition_duration = .2,
})

ui:style('grid move_col > grid_col', {
	transition_x = true,
	transition_duration = .5,
})

ui:style([[
	grid resize_col > grid_col,
	grid move_splitter > grid_col,
]], {
	transition_x = false,
})

ui:style('grid_col moving, grid_cell moving', {
	opacity = .7,
})

--cells ----------------------------------------------------------------------

local cell = ui.layer:subclass'grid_cell'
grid.cell_class = cell

cell.clip_content = true
cell.text_multiline = false
cell.border_width_bottom = 1
cell.border_color = '#080808'

ui:style('grid_cell moving', {
	background_color = '#000',
})

ui:style('grid_cell even', {
	background_color = '#040404',
})

ui:style('grid_cell hot', {
	background_color = '#111',
})

ui:style('grid_cell selected', {
	background_color = '#111',
	border_color = '#333',
})

ui:style('grid_cell grid_focused selected', {
	background_color = '#113',
	border_color = '#335',
})

ui:style('grid_cell focused selected', {
	background_color = '#181818',
	border_color = '#333',
})

ui:style('grid_cell grid_focused focused selected', {
	background_color = '#181844',
	border_color = '#669',
})

ui:style('grid_cell focused', {
	border_width_top = 1,
	border_width_bottom = 1,
})

ui:style('grid_cell focused', {
	border_width_top = 1,
	border_width_bottom = 1,
})

ui:style('grid_cell focused first_col', {
	border_width_left = 1,
})

ui:style('grid_cell focused last_col', {
	border_width_right = 1,
})

ui:style('grid_cell cell_select focused', {
	border_width = 1,
})

function cell:sync_grid(grid)
	self.grid = grid
	self:settag('cell_select', self.grid.cell_select)
	self:settag('grid_focused', self.grid.focused)
end

function cell:sync_col(col)
	self.parent = col.pane.rows_layer
	self.x = col.x
	self.w = col.w
	self:setfont(
		col.font_family,
		col.font_weight,
		col.font_slant,
		col.text_size,
		col.text_color,
		col.line_spacing)
	self.text_align = col.text_align
	self.text_valign = col.text_valign
	self.padding_left = col.padding_left
	self.padding_right = col.padding_right
	self.padding_top = col.padding_top
	self.padding_bottom = col.padding_bottom
	local index = col.index
	self:settag('moving', col.moving)
	self:settag('resizing', col.resizing)
	self:settag('first_col', index == 1)
	self:settag('last_col', index == self.grid:rel_visible_col(-1).index)
end

function cell:sync_row(i, y, h)
	self.y = y - self.grid.vscrollbar.offset
	self.h = h
	self:settag('even', i % 2 == 0)
	if self.grid.moving_row_index == i then
		self:settag('moving', true)
	end
end

function cell:sync_value(i, col, val)
	self.text = val
	self:settag('selected', self.grid:cell_selected(i, col))
	self:settag('focused', self.grid:cell_focused(i, col))
end

function cell:invalidate() end --we call draw() manually

function grid:create_cell()
	local cell = self.cell_class(self.ui, self.cell)
	cell:inherit() --speed up cell drawing
	return cell
end

function grid:cell_at(i, col)
	if not self.default_cell then
		self.default_cell = self:create_cell(self.cell)
	end
	return self.default_cell
end

function grid:cell_value(i, col)
	local row = self.rows[i]
	if type(row) == 'table' then
		return row[col.value_index]
	else
		return tostring(row)
	end
end

function grid:draw_cell(cr, i, col, hot)
	local y, h = self:row_yh(i)
	local cell = self:cell_at(i, col)
	cell:sync_grid(self)
	cell:sync_col(col)
	cell:sync_row(i, y, h)
	cell:sync_value(i, col, self:cell_value(i, col))
	cell:settag('hot', hot)
	cell:draw()
end

--rows -----------------------------------------------------------------------

grid.row_h = 24
grid.var_row_h = false

function grid:get_row_count()
	return #self.rows
end

function grid:rows_h()
	local y, h = self:row_yh(self.row_count)
	return y + h
end

function grid:row_var_h(i)
	return self.rows[i].h or self.row_h
end

function grid:_build_row_y_table()
	local t = {}
	self._row_y = t
	local y = 0
	for i = 1, self.row_count do
		t[i] = y
		y = y + self:row_var_h(i)
	end
	t[#t+1] = y --for computing row_h of the last row
end

function grid:row_yh(i)
	i = clamp(i, 1, self.row_count)
	if self.var_row_h then
		local y = self._row_y[i]
		return y, self._row_y[i+1] - y
	else
		return self.row_h * (i - 1), self.row_h
	end
end

function grid:row_at_y(y, clamp_top, clamp_bottom)
	clamp_top = clamp_top == nil or clamp_top
	clamp_bottom = clamp_bottom == nil or clamp_bottom
	if self.var_row_h then
		local t = self._row_y
		if #t == 0 then return nil end
		if y < t[1] then
			return clamp_top and 1 or nil
		elseif y > t[#t] then
			return clamp_bottom and self.row_count or nil
		end
		local i = binsearch(y, t)
		return y < t[i] and i-1 or i
	else
		local i = math.floor(y / self.row_h) + 1
		if i < 1 then
			return clamp_top and 1 or nil
		end
		if i >= self.row_count then
			return clamp_bottom and self.row_count or nil
		end
		return i
	end
end

function grid:abs_row_y(y)
	return y + self.vscrollbar.offset
end

function grid:rel_row_y(y)
	return y - self.vscrollbar.offset
end

function grid:row_screen_yh(i)
	local y, h = self:row_yh(i)
	return self:rel_row_y(y), h
end

function grid:row_at_screen_y(y, ...)
	return self:row_at_y(self:abs_row_y(y), ...)
end

function grid:row_at_screen_bottom_y(y, ...)
	local screen_h = self.vscrollbar.view_length
	return self:row_at_screen_y(y + screen_h, ...)
end

function grid:visible_rows_range()
	local h = self.scroll_pane.rows_layer.ch
	local i1 = self:row_at_screen_y(0)
	local i2 = self:row_at_screen_y(h - 1)
	return i1, i2
end

function grid:draw_row_col(cr, i, col, y, h, hot)
	local cell = self:cell_at(i, col)
	if cell ~= self._cell then
		self._cell = cell
		cell:sync_grid(self)
		cell:sync_col(col)
	end
	cell:sync_row(i, y, h)
	cell:sync_value(i, col, self:cell_value(i, col))
	cell:settag('hot', hot)
	cell:draw(cr)
end

function grid:draw_rows_col(cr, i1, i2, col, hot_i, hot_col)

	local moving_i = self.moving_row_index
	local moving_y, moving_h
	if moving_i then
		moving_y, moving_h = self:row_screen_yh(moving_i)
		moving_y = self:abs_row_y(self.moving_row_y + self.moving_row_dy)
	end

	for i = i1, i2 do
		if i ~= moving_i then
			local hot = i == hot_i and (not self.cell_select or col == hot_col)
			local y, h = self:row_yh(i)
			if moving_y then
				if i > moving_i then
					--remove the space originally taken by the moving row
					y = y - moving_h
				end
				if moving_y < y + h / 2 then
					--make space for the moving row at its target position
					y = y + moving_h
				end
			end
			self:draw_row_col(cr, i, col, y, h, hot)
		end
	end

	if moving_i then
		self:draw_row_col(cr, moving_i, col, moving_y, moving_h)
	end
end

function grid:draw_rows(cr, rows_layer)
	local i1, i2 = self:visible_rows_range()
	if not i1 then return end
	local hot_i, hot_col
	if self:cell_hot() then
		hot_i, hot_col = self.hot_row_index, self.hot_col
	end
	self._cell = false
	for _,col in ipairs(rows_layer.pane.header_layer.layers) do
		if col.isgrid_col and not col.clipped then
			local cell = self:cell_at(i1, col)
			if cell == self._cell then
				cell:sync_col(col)
			end
			self:draw_rows_col(cr, i1, i2, col, hot_i, hot_col)
		end
	end
end

--row moving -----------------------------------------------------------------

grid.row_move = true
grid.row_move_ctrl = true
rows.drag_threshold = 4 --TODO: fix conflict between row-move and drag-select

function rows:mousedown(mx, my, area)
	if area == 'cell' then
		self.active = true
	end
end

function rows:mouseup(mx, my, area)
	self.active = false
end

function grid:allow_move_row(i, col) --stub
	return self.row_move and (not self.row_move_ctrl or self.ui:key'ctrl')
end

function grid:move_row(i1, i2) end --stub

function rows:start_drag(button, mx, my)
	local i, col = self.grid.focused_row_index, self.grid.focused_col
	if self.grid:allow_move_row(i, col) then
		self.grid.moving_row_index = i
		local y, h = self.grid:row_screen_yh(i)
		self.grid.moving_row_y = y
		self.grid.moving_row_dy = 0
		self.grid:settag('move_row', true)
		return self
	end
end

function rows:drag(dx, dy)
	self.grid.moving_row_dy = dy
end

function rows:end_drag()
	--TODO: move multiple rows
	self.grid.moving_row_index = false
	self.grid:settag('move_row', false)
end

--row drag-select ------------------------------------------------------------

grid.drag_select = true --select by dragging with the mouse

function rows:after_mousemove(mx, my)
	if not self.active or self.dragging then return end
	local pane = self.pane
	local i, col = self:hit_test_cell(mx, my, pane.clamp_left, pane.clamp_right)
	if not i then
		local pane = self.pane.other_pane
		local rows = pane.rows_layer
		local mx, my = self:to_other(rows, mx, my)
		i, col = rows:hit_test_cell(mx, my, pane.clamp_left, pane.clamp_right)
	end
	if i then
		self.grid.hot_row_index = i
		self.grid.hot_col = col
		self.grid:move(self.grid.multi_select
			and '@hot reset extend scroll'
			or '@hot reset select focus scroll')
	end
end

--row & cell focus, selection, scrolling -------------------------------------

grid.cell_select = false --select individual cells or entire rows
grid.multi_select = false --allow selecting multiple cells/rows

function grid:cell_selected(i, col)
	if not self.multi_select then
		return self.selected_row_index == i
			and (not self.cell_select or self.selected_col == col)
	else
		local t = self.selected_cells[col]
		return t and t[i] or false
	end
end

function grid:select_cells(i1, col1, i2, col2, selected)
	selected = selected and true or false
	i2 = i2 or i1
	i1 = clamp(i1, 1, self.row_count)
	i2 = clamp(i2, 1, self.row_count)
	if i2 < i1 then
		i1, i2 = i2, i1
	end
	local j1 = self.cell_select and col1 and col1.index or 1
	local j2 = self.cell_select and col2 and col2.index or #self.cols
	if j2 < j1 then
		j1, j2 = j2, j1
	end
	if not self.multi_select then
		self.selected_row_index = selected and i1
		self.selected_col = selected and col1
		self:fire(selected and 'row_was_selected' or 'row_was_deselected', i1)
	else
		for j = j1, j2 do
			local col = self.cols[j]
			local t = attr(self.selected_cells, col)
			for i = i1, i2 do
				local was_selected = t[i]
				t[i] = selected
				if selected and not was_selected then
					self:fire('cell_was_selected', i, col)
				elseif not selected and was_selected then
					self:fire('cell_was_deselected', i, col)
				end
			end
		end
	end
end

function grid:row_focused(i)
	return self.focused_row_index == i
end

function grid:cell_focused(i, col)
	return self.focused_row_index == i and
		(not self.cell_select or self.focused_col == col)
end

function grid:after_focus()
	if not self.focused_row_index then
		self.focused_row_index = 1
		self.focused_col = self:rel_visible_col(1)
		self:move('@focus reset select focus')
	end
end

function grid:override_canfocus(inherited)
	return inherited(self) and self.row_count > 0 and #self.cols > 0
end

function grid:focus_cell(i, col)
	if self:canfocus() then
		self.focused_row_index = clamp(i, 1, self.row_count)
		self.focused_col = col
		self:focus()
		return true
	else
		return false
	end
end

function grid:scroll_to_view_row(i)
	local y, h = self:row_yh(i)
	self.vscrollbar:scroll_to_view(y, h)
end

function grid:scroll_to_view_col(col)
	if col.pane == self.scroll_pane then
		col.pane.hscrollbar:scroll_to_view(col.x, col.w)
	end
end

function grid:scroll_to_view_cell(i, col)
	self:scroll_to_view_row(i)
	self:scroll_to_view_col(col)
end

function grid:select_none()
	self.selected_cells = {}
	self.selected_row_index = false
	self.selected_col = false
end

function grid:select_all()
	self:select_cells(1, nil, 1/0, nil, true)
end

function grid:move(actions, di, dj)
	di = di or 0
	dj = dj or 0
	local i, col, reset_extend
	for action in actions:gmatch'[^%s]+' do
		if action == '@extend' then
			if self.extend_row_index then
				i = self.extend_row_index + di
				col = self:rel_visible_col(dj, self.extend_col, true)
			end
		elseif action == '@focus' then
			i = self.focused_row_index + di
			col = self:rel_visible_col(dj, self.focused_col, true)
		elseif action == '@hot' then
			i = self.hot_row_index + di
			col = self:rel_visible_col(dj, self.hot_col, true)
		elseif action == 'reset' then
			self:select_none()
		elseif action == 'select_all' then
			self:select_all()
			reset_extend = true
		elseif action == 'focus' then
			self:focus_cell(i, col)
			reset_extend = true
		elseif action == 'invert' then
			local selected = not self:cell_selected(i, col)
			self:select_cells(i, col, i, col, selected)
			reset_extend = true
		elseif action == 'extend' then
			self:select_cells(
				self.focused_row_index or i,
				self.focused_col or col,
				i, col, true)
			self.extend_row_index = clamp(i, 1, self.row_count)
			self.extend_col = col
		elseif action == 'select' or action == 'unselect' then
			self:select_cells(i, col, i, col, action == 'select')
			reset_extend = true
		elseif action == 'scroll' then
			self:scroll_to_view_cell(i, col)
		end
	end
	if reset_extend then
		self.extend_row_index = false
		self.extend_col = false
	end
	self:invalidate()
end

function rows:after_click()
	local shift = self.ui:key'shift'
	local ctrl = self.ui:key'ctrl'
	if self.grid.multi_select then
		self.grid:move(
			shift and ctrl and '@hot extend scroll'
			or shift and '@hot reset extend scroll'
			or ctrl and '@hot focus invert scroll'
			or '@hot reset select focus scroll')
	end
end

--find the number of rows relative to the focused row that should move the
--focused row on page-up/down requests. the scrolling logic is two-phase:
--first, move the focused row to the top/bottom on the current screen, then
--scroll _at most_ one full screen such that no gaps between screens occur
--i.e. no information is lost between screens.
function grid:screen_page_offset(dir, focused)
	focused = focused or self.focused_row_index
	local screen_h = self.vscrollbar.view_length
	if dir > 0 then
		local bottom = self:row_at_screen_y(screen_h - 1)
		if bottom > focused then
			return bottom - focused
		else
			local bottom = self:row_at_screen_bottom_y(screen_h, true, false)
			bottom = (bottom or self.row_count + 1) - 1
			return bottom - focused
		end
	else
		local top = self:row_at_screen_y(0)
		if top < focused then
			return top - focused
		else
			local top = self:row_at_screen_y(-screen_h, false, true)
			top = (top or 0) + 1
			return top - focused
		end
	end
end

function grid:fixed_page_yh(page)
	local page_h = self.vscrollbar.view_length
	return (page - 1) * page_h, page_h
end

function grid:fixed_page_at_y(y)
	local page_h = self.vscrollbar.view_length
	return math.floor(y / page_h) + 1
end

function grid:fixed_page_at_screen_y(y)
	return self:fixed_page_at_y(self:abs_row_y(y))
end

--find the number of rows relative to the focused row that should move the
--focused row on ctrl+page-up/down requests. the logic here is to split the
--rows into fixed-pixel-height pages and scroll to the row at the top of the
--previous or next page.
function grid:fixed_page_offset(dir, focused)
	focused = focused or self.focused_row_index
	--local screen_y = self.vscrollbar.offset
	local row_y, row_h = self:row_yh(focused)
	local page
	if dir > 0 then
		page = self:fixed_page_at_y(row_y + row_h) + 1
	else
		page = self:fixed_page_at_y(row_y)
		if row_y == screen_y then
			page = page - 1
		end
	end
	local page_y = self:fixed_page_yh(page)
	local row = self:row_at_y(page_y)
	return row - focused
end

function grid:keypress(key)
	local shift = self.ui:key'shift'
	local ctrl = self.ui:key'ctrl'

	local rows =
		ctrl and key == 'down' and 1/0
		or ctrl and key == 'up' and -1/0
		or key == 'down' and 1
		or key == 'up' and -1
		or ctrl and key == 'pagedown' and self:fixed_page_offset(1)
		or ctrl and key == 'pageup' and self:fixed_page_offset(-1)
		or key == 'pagedown' and self:screen_page_offset(1)
		or key == 'pageup' and self:screen_page_offset(-1)
		or (ctrl or not self.cell_select) and key == 'home' and -1/0
		or (ctrl or not self.cell_select) and key == 'end' and 1/0
		or not self.cell_select and key == 'right' and 1
		or not self.cell_select and key == 'left' and -1

	local cols =
		self.cell_select and key == 'right' and 1
		or self.cell_select and key == 'left' and -1
		or not ctrl and key == 'home' and -1/0
		or not ctrl and key == 'end' and 1/0

	if rows or cols then

		self:move(
			self.multi_select and shift
				and '@focus @extend reset extend scroll'
				or '@focus reset select focus scroll',
			rows or 0, cols or 0)

	elseif ctrl and key == 'A' then
		if self.multi_select then
			self:move('select_all')
		end
	end
end

--vertical scrollbar ---------------------------------------------------------

local vscrollbar = ui.scrollbar:subclass'grid_vscrollbar'
grid.vscrollbar_class = vscrollbar

grid.vscrollbar_margin_top = 6
grid.vscrollbar_margin_bottom = 6
grid.vscrollbar_margin_right = 6

function grid:create_vscrollbar()
	return self.vscrollbar_class(self.ui, {
		parent = self,
		grid = self,
		vertical = true,
	}, self.vscrollbar)
end

function vscrollbar:after_sync()
	local m1 = grid.vscrollbar_margin_top
	local m2 = grid.vscrollbar_margin_bottom
	local m3 = grid.vscrollbar_margin_right
	local sp = self.grid.scroll_pane
	self.y = (sp.header_layer.visible and self.grid.col_h or 0) + m1
	self.x = self.grid.cw - self.h - m3
	self.w = self.grid.ch - self.y - m1 - m2
	self.view_length = sp.rows_layer.ch
	self.content_length = self.grid:rows_h()
end

--grid -----------------------------------------------------------------------

grid:init_ignore{freeze_col=1}

function grid:after_sync()
	self:sync_freeze_col()
	self.freeze_pane:sync()
	self.scroll_pane:sync()
	self.splitter:sync()
	self.vscrollbar:sync()
end

function grid:before_draw()
	self:sync()
end

function grid:after_init(ui, t)

	self._freeze_col = t.freeze_col
	self.cols = {}
	if t.cols then
		for i,col in ipairs(t.cols) do
			push(self.cols, self:create_col(col, i))
		end
	end
	self.freeze_pane = self:create_freeze_pane(self.freeze_pane)
	self.scroll_pane = self:create_scroll_pane(self.freeze_pane)

	--set up panes for drag-selecting over the other pane
	self.freeze_pane.other_pane = self.scroll_pane
	self.freeze_pane.clamp_left = true
	self.freeze_pane.clamp_right = false
	self.scroll_pane.other_pane = self.freeze_pane
	self.scroll_pane.clamp_left = false
	self.scroll_pane.clamp_right = true

	self.splitter = self:create_splitter()
	self.vscrollbar = self:create_vscrollbar()
	if self.var_row_h then
		self:_build_row_y_table()
	end
	self:select_none()
end

--demo -----------------------------------------------------------------------

ui.window.topmost = true

if not ... then require('ui_demo')(function(ui, win)

	local grid = ui.grid:subclass'subgrid'

	local g = grid(ui, {
		id = 'g',
		x = 20,
		y = 20,
		w = 860,
		h = 460,
		row_count = 1e6,
		parent = win,
		--clip_content = true,
		cols = {
			{text = 'col1', w = 150},
			{text = 'icol', w = 100, visible = false},
			{text = 'col2', w = 300},
			{text = 'col3', w = 300},
			{text = 'col4', w = 150},
			--{text = 'col5', w = 150},
			--{text = 'col6', w = 150},
			--{text = 'col7', w = 150},
			--{text = 'col8', w = 500},
		},
		col = {
			--border_width = 1,
			--border_color = '#f00',
		},
		freeze_col = 3,
		freeze_scroll_col = 6,
		scroll_pane = {
			--background_color = '#f00',
			content = {
				--background_color = '#00f',
			},
			hscrollbar = {
				--autohide = false,
			},
		},
		freeze_pane = {
			--background_color = '#111',
		},
		spliiter = {
			--background_color = '#0f0',
		},
		var_row_h = true,
		row_var_h = function(self, i)
			local n = math.random()
			return n < .1 and 200 or 34
		end,
		--multi_select = false,
		--row_move_ctrl = false,
		--row_move = false,
		cell_select = false,
	})

	function g:cell_value(i, col)
		return col.text..' '..i..' 123456789 ................ abcdefghijklmnopqrstuvwxyz'
	end

	win.native_window:on('shown', function(self)
		--self:maximize()
	end)

	win.native_window:on('repaint', function(self)
		--self:invalidate()
	end)

end) end
