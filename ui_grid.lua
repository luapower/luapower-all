--go @ luajit -jp=a -e io.stdout:setvbuf'no';io.stderr:setvbuf'no';require'strict';pp=require'pp' "ui_grid.lua"

--Grid widget.
--Written by Cosmin Apreutesei. Public Domain.

local ui = require'ui'
local glue = require'glue'
local box2d = require'box2d'

local push = table.insert
local pop = table.remove

local round = glue.round
local clamp = glue.clamp
local indexof = glue.indexof
local binsearch = glue.binsearch
local shift = glue.shift

local function popval(t, v)
	local i = indexof(v, t)
	return i and pop(t, i)
end

local grid = ui.layer:subclass'grid'
ui.grid = grid
grid.iswidget = true

grid.border_color = '#333'

--split panes ----------------------------------------------------------------

local split_pane = ui.layer:subclass'grid_split_pane'
grid.freeze_pane_class = split_pane
grid.scroll_pane_class = split_pane

function grid:create_freeze_pane()
	return self:freeze_pane_class({
		tags = 'freeze_pane',
		iswidget = false,
		grid = self,
		frozen = true,
	}, self.split_pane, self.freeze_pane)
end

function grid:create_scroll_pane()
	return self:scroll_pane_class({
		tags = 'scroll_pane',
		iswidget = false,
		grid = self,
		frozen = false,
	}, self.split_pane, self.scroll_pane)
end

function split_pane:after_init()
	self.header_pane = self.grid:create_header_pane(self)
	self.rows_pane = self.grid:create_rows_pane(self)
end

function split_pane:col_index_range()
	local fc = self.grid.freeze_col or 0
	if self.frozen then
		return 1, fc
	else
		return fc + 1, 1/0
	end
end

--the freeze pane must be small enough so that the splitter is always visible.
function split_pane:get_max_w()
	if self.frozen then
		return self.grid.cw - self.grid.splitter.w
	else
		return 1/0
	end
end

function split_pane:sync_to_grid()

	local cols_w = 0
	local col_h = self.grid.col_h
	local col1 = self.grid:rel_visible_col(1).index
	local col2 = self.grid:rel_visible_col(-1).index
	for index, col in ipairs(self.grid.cols) do
		if col.split_pane == self then
			col.parent = self.header_pane.content
			col_h = math.max(col_h, col.h or 0)
			col.h = col_h
			col:settag('first_col', index == col1)
			col:settag('last_col', index == col2)
			if col.visible then
				cols_w = cols_w + col.w
			end
		end
	end
	self._cols_w = cols_w

	self.h = self.grid.ch
	if self.frozen then
		self.visible = self.grid.freeze_col and true or false
		self.cw = cols_w
	else
		local fp = self.freeze_pane
		local s = self.grid.splitter
		local sw = s.visible and s.w or 0
		local x = fp.w + sw
		self:transition('x', x) --moving the splitter animates the pane
		self.w = self.grid.cw - fp.w - sw
	end

	--update width of auto_w columns.
	if not self.frozen and not self.grid.resizing_col then
		local flex_w, fixed_w = 0, 0
		for _,col in ipairs(self.grid.cols) do
			if col.split_pane == self and col.visible then
				if col.auto_w then
					flex_w = flex_w + col.w
				else
					fixed_w = fixed_w + col.w
				end
			end
		end
		local avail_flex_w = self.cw - fixed_w
		local cols_w = 0
		local last_col
		for _,col in ipairs(self.grid.cols) do
			if col.split_pane == self and col.visible then
				if col.auto_w then
					col.w = math.floor(avail_flex_w * (col.w / flex_w))
					last_col = col
				end
				cols_w = cols_w + col.w
			end
		end
		if last_col then --dump accumulated error into the last auto_w column.
			last_col.w = last_col.w + (self.cw - cols_w)
		end
		self._cols_w = math.floor(cols_w)
	end

	--sync column positions.
	self:sync_cols_x()

	self.header_pane:sync_to_grid()
	self.rows_pane:sync_to_grid_header_and_split_pane()
	self.header_pane:sync_to_rows_pane()
end

function split_pane:col_at_x(x, clamp_left, clamp_right)
	clamp_left = clamp_left == nil or clamp_left
	clamp_right = clamp_right == nil or clamp_right
	local first_col, last_col
	for _,col in ipairs(self.grid.cols) do
		if col.visible and col.split_pane == self then
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

--freeze col property --------------------------------------------------------

grid:stored_property'freeze_col'
grid:instance_only'freeze_col'

--returns the largest freeze_col which satisfies freeze_pane.max_w.
function grid:max_freeze_col()
	local max_w = self.freeze_pane.max_w
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

function grid:sync_freeze_col()

	--limit freeze_col to the maximum allowed by geometry.
	if self.freeze_col then
		local max_ci = self:max_freeze_col()
		if not max_ci or max_ci < self.freeze_col then
			self.freeze_col = max_ci
		end
	end

	--assign columns to the right panes based on freeze_col.
	local fi = self.freeze_col
	for i,col in ipairs(self.cols) do
		local frozen = fi and i <= fi
		col.split_pane = frozen and self.freeze_pane or self.scroll_pane
	end
end

--freeze pane <-> scroll pane splitter ---------------------------------------

local splitter = ui.layer:subclass'grid_splitter'
grid.splitter_class = splitter

splitter.w = 6
splitter.background_color = '#666'
splitter.cursor = 'size_h'

ui:style('grid_splitter', {
	transition_x = true,
	transition_duration = .1,
})

ui:style('grid :resize_col > grid_splitter', {
	transition_x = false,
})

function grid:create_splitter()
	return self:splitter_class({
		iswidget = false,
		grid = self,
	}, self.splitter)
end

function splitter:sync_to_grid()
	self.visible = self.grid.freeze_col and true or false
	self:transition('x', self.grid.scroll_pane.x - self.w)
	self.h = self.grid.ch
end

splitter.mousedown_activate = true

local drag_splitter = ui.layer:subclass'grid_drag_splitter'
grid.drag_splitter_class = drag_splitter

drag_splitter.background_color = '#fff2'

function grid:create_drag_splitter()
	return self:drag_splitter_class({
		grid = self,
	}, self.drag_splitter)
end

function splitter:start_drag(button, mx, my, area)
	if button ~= 'left' then return end

	self.grid.scroll_pane.rows_pane.hscrollbar:transition('offset', 0)

	local ds = self.drag_splitter or self.grid:create_drag_splitter()
	self.drag_splitter = ds

	ds.x = self.x
	ds.y = self.y
	ds.w = self.w
	ds.h = self.h
	ds.visible = true

	self.grid:settag(':move_splitter', true)

	return ds
end

function grid:nearest_col(x)
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

function drag_splitter:drag(dx, dy)
	self.grid.scroll_pane.rows_pane.hscrollbar.offset = 0

	local col = self.grid:rel_visible_col(-1)
	local last_col_x2 = col and col.parent:to_other(self.grid, col.x2, 0)
	local max_w = math.min(last_col_x2 or 0, self.grid.cw) - self.w
	self:transition('x', clamp(0, self.x + dx + self.w / 2, max_w), 0)

	self.grid.freeze_col = self.grid:nearest_col(self.x)
	self:invalidate()
end

function splitter:end_drag(ds)
	ds.visible = false
	self.grid:settag(':move_splitter', false)
end

--header pane ---------------------------------------------------------------

local header_pane = ui.scrollbox:subclass'grid_header_pane'
grid.header_pane_class = header_pane

header_pane.clip_content = true --for column moving
grid.header_visible = true

function grid:create_header_pane(split_pane)
	return self.header_pane_class(self.ui, {
		parent = split_pane,
		iswidget = false,
		split_pane = split_pane,
		grid = self,
	}, self.header_pane)
end

function header_pane:sync_to_grid()
	self.visible = self.grid.header_visible
	self.hscrollbar.visible = false
	self.h = self.grid.col_h
	self.content.h = self.ch
end

function header_pane:sync_to_rows_pane()
	local rows_pane = self.split_pane.rows_pane
	self.w = rows_pane.view.w
	self.content.w = rows_pane.content.w
	self.hscrollbar.offset = rows_pane.hscrollbar.offset
end

--rows pane ------------------------------------------------------------------

local rows_pane = ui.scrollbox:subclass'grid_rows_pane'
grid.rows_pane_class = rows_pane

local rows = ui.layer:subclass'grid_rows_layer'
grid.rows_layer_class = rows

function grid:create_rows_pane(split_pane)

	local rows = self.rows_layer_class(self.ui, {
		grid = self,
		iswidget = false,
		split_pane = split_pane,
	})

	local rows_pane = self.rows_pane_class(self.ui, {
		parent = split_pane,
		iswidget = false,
		split_pane = split_pane,
		grid = self,
		content = rows,
		rows_layer = rows,
	}, self.rows_pane)
	rows.rows_pane = rows_pane

	rows_pane.vscrollbar.visible = not split_pane.frozen
	rows_pane.hscrollbar.visible = not split_pane.frozen
	rows_pane.vscrollbar.step = 1 --prevent blurry text

	--synchronize vertical scrolling between split panes.
	local barrier
	rows_pane.vscrollbar:on('offset_changed', function(sb, offset)
		if barrier then return end
		barrier = true
		rows_pane.split_pane.other_pane.rows_pane.vscrollbar.offset = offset
		barrier = false
	end)

	self:create_cell_mouse_events(rows)

	return rows_pane
end

function rows_pane:sync_to_grid_header_and_split_pane()
	--sync to grid
	self.content.ch = self.grid.rows_h

	--sync to header pane
	local header_pane = self.split_pane.header_pane
	self.y = header_pane.visible and header_pane.h or 0

	--sync to split pane
	local split_pane = self.split_pane
	self.w = split_pane.cw
	self.h = split_pane.ch - self.y
	if self.grid.resizing_col then
		--prevent shrinking the rows pane while resizing a column in order to
		--keep scrolling stable and not move the column under the mouse.
		self.content.cw = math.max(self.content.cw, split_pane._cols_w)
	else
		self.content.cw = split_pane._cols_w
	end
	--resolve view w/h which depends on content w/h when autohide_empty.
	self:sync()
	--keep the content layer no smaller than the scrollbox view to prevent
	--clipping the content while moving a column.
	--NOTE: content w/h should not be based on view w/h because view w/h
	--depends on content w/h when autohide_empty, but here is ok.
	self.content.cw = math.max(self.content.cw, self.view.cw)
end

--column headers -------------------------------------------------------------

local col = ui.layer:subclass'grid_col'
grid.col_class = col

col.text_align = 'left center'
col.nowrap = true
col._w = 200
col.auto_w = true --distribute pane's width among all columns
col.min_cw = 8
col.max_w = 1000
col.padding_left = 4
col.padding_right = 4
col.clip_content = true --for text
col.background_color = '#111' --for moving
col.border_width = 1
col.border_color = '#333'
col.cursor_resize = 'size_h'
col.resizeable = true
col.moveable = true

grid.col_resize = true
grid.col_move = true
grid.col_h = 24

local function column(col)
	if type(col) == 'string' then
		return {text = col}
	else
		return col
	end
end

function grid:create_col(col, col_index)

	col = self.col_class(self.ui, column(self.col), column(col))
	col.grid = self
	col.value_index = col.value_index or col_index

	--create a cell object for the column.
	if col.cell then
		col.cell = self:create_cell(col.cell)
	else
		if not self.cell then
			self.cell = self:create_cell(self.cell)
		end
		col.cell = self.cell
	end

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

function col:get_clipped()
	if not self.visible then
		return true
	end
	local x, y, w, h = self.x, self.y, self.w, self.h
	local w, h = select(3, box2d.clip(x, y, w, h, self.parent:client_rect()))
	return w == 0 or h == 0
end

function col:override_hit_test(inherited, x, y, reason)
	local widget, area = inherited(self, x, y, reason)
	if self.grid.col_resize and self.resizeable and widget == self then
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
	self:settag(':resizing', true)
	self.grid.resizing_col = self
	self.grid:settag(':resize_col', true)
	self.drag_w = self.w
	self.drag_max_w = self.split_pane.max_w - self.split_pane.w + self.w
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
	self:settag(':resizing', false)
	self.grid.resizing_col = false
	self.grid:settag(':resize_col', false)
end

--column moving --------------------------------------------------------------

function col:start_drag_move(button, mx, my, area)
	if button ~= 'left' then return end
	if not self.grid.col_move then return end
	if not self.moveable then return end
	self.window.cursor = 'move'
	self.moving = true
	self:settag(':moving', true)
	self.grid.moving_col = self
	self.grid:settag(':move_col', true)
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
	self:settag(':moving', false)
	self.grid.moving_col = false
	self.grid:settag(':move_col', false)
	self.window.cursor = nil
end

--sync columns x position and move_index for the moving column.
function split_pane:sync_cols_x()
	local moving_col = self.grid.moving_col
	moving_col = moving_col and moving_col.split_pane == self and moving_col
	if moving_col then
		moving_col.move_index = false
	end
	local x = 0
	local i = 1
	local min_col_index, max_col_index = self:col_index_range()
	for _,col in ipairs(self.grid.cols) do
		if col.split_pane == self then
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

ui:style('grid_col', {
	transition_x = true,
	transition_duration = .2,
})

ui:style('grid :move_col > grid_col', {
	transition_x = true,
	transition_duration = .5,
})

ui:style([[
	grid :resize_col > grid_col,
	grid :move_splitter > grid_col,
]], {
	transition_x = false,
})

ui:style('grid_col :moving, grid_cell :moving', {
	opacity = .7,
})

ui:style('grid_col !last_col !:moving', {
	border_width_right = 0,
})

--cells ----------------------------------------------------------------------

local cell = ui.layer:subclass'grid_cell'
grid.cell_class = cell

cell.text_align = 'left center'
cell.nowrap = true
cell.padding_left = 4
cell.padding_right = 4
cell.clip_content = true --for text

ui:style('grid_cell even', {
	background_color = '#020202',
})

ui:style('grid_cell :moving', {
	background_color = '#000',
})

ui:style('grid_cell :hot', {
	background_color = '#111',
})

ui:style('grid_cell :selected', {
	background_color = '#111',
})

ui:style('grid_cell :grid_focused :selected', {
	background_color = '#113',
})

ui:style('grid_cell :focused :selected', {
	background_color = '#181818',
})

ui:style('grid_cell :grid_focused :focused :selected', {
	background_color = '#181844',
})

local border_width = ui:value_of'border_width'

ui:style('grid_cell first_col !last_col !multi_select !cell_select :selected', {
	border_width_right = 0,
})

ui:style('grid_cell last_col !first_col !multi_select !cell_select :selected', {
	border_width_left = 0,
})

ui:style('grid_cell !first_col !last_col !multi_select !cell_select :selected', {
	border_width_left = 0,
	border_width_right = 0,
})

function grid.sync_cell_to_grid(grid, self)
	self:settag('grid_cell', true)
	self:settag('standalone', false)
	self:settag('multi_select', grid.multi_select)
	self:settag('cell_select', grid.cell_select)
	self:settag(':grid_focused', grid.focused)
end

function grid.sync_cell_to_col(grid, self, col)
	self.parent = col.split_pane.rows_pane.content
	self.x = col.x
	self.w = col.w
	self:settag(':moving', col.moving)
	self:settag(':resizing', col.resizing)
	local index = col.index
	self:settag('first_col', col.tags.first_col)
	self:settag('last_col', col.tags.last_col)
end

function grid.sync_cell_to_row(grid, self, i, y, h)
	self.y = y
	self.h = h
	self:settag('even', i % 2 == 0)
	if grid.moving_row_index == i then
		self:settag(':moving', true)
	end
end

function grid:display_value(i, col, val)
	if type(val) == 'nil' or type(val) == 'boolean' then
		return string.format('<%s>', tostring(val))
	end
	return tostring(val)
end

function grid.sync_cell_to_value(grid, self, i, col, val)
	self.text = grid:display_value(i, col, val)
	self:settag(':selected', grid:cell_selected(i, col))
	self:settag(':focused', grid:cell_focused(i, col))
end

function cell:invalidate() end --we call draw() manually

function grid:create_cell(cell)
	cell = self.cell_class(self.ui, cell)
	cell:inherit() --speed up cell drawing
	cell.iswidget = false
	return cell
end

local attr = glue.attr
function grid:cell_at(i, col)
	return col.cell
end

--rows -----------------------------------------------------------------------

grid.row_h = 24
grid.var_row_h = false

function grid:get_rows_h()
	local y, h = self:row_yh(self.row_count)
	return y + h
end

function grid:_sync_row_y(i)
	local h = self.row_h
	local t = self._row_y
	local y = i > 1 and t[i-1] + (self:row_var_h(i-1) or h) or 0
	local n = self.row_count
	for i = i, n do
		t[i] = y
		y = y + (self:row_var_h(i) or h)
	end
	t[n+1] = y --for computing row_h of the last row
end

function grid:_init_row_y()
	if not self.var_row_h then return end
	self._row_y = {}
	self:_sync_row_y(1)
end

function grid:row_yh(i)
	local n = self.row_count
	if n == 0 then
		return 0, 0
	end
	i = clamp(i, 1, n)
	if self.var_row_h then
		local y = self._row_y[i]
		return y, self._row_y[i+1] - y
	else
		return self.row_h * (i - 1), self.row_h
	end
end

function grid:_insert_row_y_rows(i, len)
	if not self._row_y then return end
	shift(self._row_y, i, len)
	self:_sync_row_y(i)
end

function grid:_remove_row_y_rows(i, len)
	if not self._row_y then return end
	shift(self._row_y, i, -len)
	self:_sync_row_y(i)
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
	return y + self.scroll_pane.rows_pane.vscrollbar.offset
end

function grid:rel_row_y(y)
	return y - self.scroll_pane.rows_pane.vscrollbar.offset
end

function grid:row_screen_yh(i)
	local y, h = self:row_yh(i)
	return self:rel_row_y(y), h
end

function grid:row_at_screen_y(y, ...)
	return self:row_at_y(self:abs_row_y(y), ...)
end

function grid:row_at_screen_bottom_y(y, ...)
	local screen_h = self.scroll_pane.rows_pane.vscrollbar.view_length
	return self:row_at_screen_y(y + screen_h, ...)
end

function grid:visible_rows_range()
	local h = self.freeze_pane.rows_pane.view.ch
	local i1 = self:row_at_screen_y(0)
	local i2 = self:row_at_screen_y(h - 1)
	return i1, i2
end

--cell drawing & hit-testing -------------------------------------------------

function grid:draw_row_col(cr, i, col, y, h, hot)
	if self.editmode
		and self.focused_row_index == i
		and self.focused_col == col
	then
		return
	end
	local cell = self:cell_at(i, col)
	if cell ~= self._cell then
		self._cell = cell
		self:sync_cell_to_grid(cell)
		self:sync_cell_to_col(cell, col)
	end
	self:sync_cell_to_row(cell, i, y, h)
	self:sync_cell_to_value(cell, i, col, self:cell_value(i, col))
	cell:settag(':hot', hot)
	cell.visible = true
	cell:sync()
	cell:sync_layout()
	cell:draw(cr)
	cell.visible = false
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

			local y, h = self:row_yh(i)
			local hot = i == hot_i and (not self.cell_select or col == hot_col)

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

function grid:draw_rows(cr, rows_pane)
	local i1, i2 = self:visible_rows_range()
	if not i1 then return end
	local hot_i, hot_col
	if self:cell_hot() then
		hot_i, hot_col = self.hot_row_index, self.hot_col
	end
	self._cell = false
	local header = rows_pane.split_pane.header_pane.content
	for _,col in ipairs(header) do
		if col.isgrid_col and not col.clipped then
			local cell = self:cell_at(i1, col)
			if cell == self._cell then
				self:sync_cell_to_col(cell, col)
			end
			self:draw_rows_col(cr, i1, i2, col, hot_i, hot_col)
		end
	end
end

function rows:before_draw_content(cr)
	self.grid:draw_rows(cr, self)
end

function rows:hit_test_cell(x, y, clamp_left, clamp_right)
	local i = self.grid:row_at_y(y)
	if i then
		local col = self.split_pane:col_at_x(x, clamp_left, clamp_right)
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
		and (self.freeze_pane.rows_pane.content.hot
			or self.scroll_pane.rows_pane.content.hot)
end

--cell mouse events ----------------------------------------------------------

--cell_max_click_chain property

function grid:get_cell_max_click_chain(mcc)
	return self.scroll_pane.rows_pane.content.max_click_chain
end

function grid:set_cell_max_click_chain(mcc)
	self.freeze_pane.rows_pane.content.max_click_chain = mcc
	self.scroll_pane.rows_pane.content.max_click_chain = mcc
end

--convert rows coordinates to cell coordinates.
function grid:to_cell(i, col, mx, my)
	local x = col.x
	local y = self:row_yh(i)
	return mx - x, my - y
end

function grid:create_cell_mouse_events(rows)

	function rows:click(mx, my)
		if self.ui.hot_area == 'cell' then
			local i = self.grid.hot_row_index
			local col = self.grid.hot_col
			self.grid:fire('cell_click', i, col,
				self.grid:to_cell(i, col, mx, my))
		end
	end

	function rows:doubleclick(mx, my)
		if self.ui.hot_area == 'cell' then
			local i = self.grid.hot_row_index
			local col = self.grid.hot_col
			self.grid:fire('cell_doubleclick', i, col,
				self.grid:to_cell(i, col, mx, my))
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
		self.grid:settag(':move_row', true)
		return self
	end
end

function rows:drag(dx, dy)
	self.grid.moving_row_dy = dy
end

function rows:end_drag()
	--TODO: move multiple rows
	self.grid.moving_row_index = false
	self.grid:settag(':move_row', false)
end

--row drag-select ------------------------------------------------------------

grid.drag_select = true --select by dragging with the mouse

function rows:after_mousemove(mx, my)
	if self.active and not self.dragging then
		local rows_pane = self.rows_pane
		local split_pane = rows_pane.split_pane
		local i, col = self:hit_test_cell(mx, my,
			split_pane.clamp_left,
			split_pane.clamp_right)
		if not i then
			local other_split_pane = split_pane.other_pane
			local other_rows = other_split_pane.rows_pane.content
			local mx, my = self:to_other(other_rows, mx, my)
			i, col = other_rows:hit_test_cell(mx, my,
				other_split_pane.clamp_left,
				other_split_pane.clamp_right)
		end
		if i then
			self.grid.hot_row_index = i
			self.grid.hot_col = col
			self.grid:move(self.grid.multi_select
				and '@hot reset extend scroll'
				or '@hot reset select focus scroll')
		end
	end
end

--row & cell scrolling -------------------------------------------------------

function grid:scroll_to_view_row(i, duration)
	local y, h = self:row_yh(i)
	self.scroll_pane.rows_pane.vscrollbar:scroll_to_view(y, h, duration)
end

function grid:scroll_to_view_col(col, duration)
	if col and col.split_pane == self.scroll_pane then
		col.split_pane.rows_pane.hscrollbar:scroll_to_view(col.x, col.w, duration)
	end
end

function grid:scroll_to_view_cell(i, col, duration)
	self:scroll_to_view_row(i, duration)
	self:scroll_to_view_col(col, duration)
end

--row & cell focus state -----------------------------------------------------

function grid:row_focused(i)
	return self.focused_row_index == i
end

function grid:cell_focused(i, col)
	return self:row_focused(i)
		and (not self.cell_select or self.focused_col == col)
end

function grid:after_focus()
	if not self.focused_row_index then
		self:move'reset select focus scroll pick'
	else
		--TODO: why not 'reset select focus scroll pick' here too?
		self:move'@focus scroll'
	end
end

function grid:override_canfocus(inherited)
	return inherited(self) and not self.empty
end

function grid:canfocus_row(i)
	return self:row_attr(i, 'focusable', true)
end

function grid:canfocus_cell(i, col)
	return self:canfocus_row(i)
		and (col.cells_focusable == nil or col.cells_focusable)
end

function grid:unfocus_focused_cell()
	local i = self.focused_row_index
	local col = self.focused_col
	if not i then
		return
	end
	self.editmode = false
	if col then
		self:fire('cell_lostfocus', i, col)
	elseif i then
		self:fire('row_lostfocus', i)
	end
	self.focused_row_index = false
	self.focused_col = false
	if i and self:row_attr(i, 'appended') then
		self:remove_rows(i)
	end
	return true
end

function grid:focus_cell(i, col)
	local i = clamp(i, 1, self.row_count)
	if not self:canfocus()
		or (not self.cell_select and not self:canfocus_row(i))
		or (self.cell_select and not self:canfocus_cell(i, col))
	then
		return false
	end
	local old_i = self.focused_row_index
	local old_col = self.focused_col
	local changed = i ~= old_i or col ~= old_col
	if changed then
		self:unfocus_focused_cell()
		self.focused_row_index = i
		self.focused_col = col
	end
	self:focus()
	if changed then
		if col then
			self:fire('cell_gotfocus', i, col)
		elseif i then
			self:fire('row_gotfocus', i)
		end
	end
	return true
end

--row & cell selection state -------------------------------------------------

grid.cell_select = false --select individual cells or entire rows
grid.multi_select = false --allow selecting multiple cells/rows
grid.use_rangelist = true --use rangelist data structure for selections.

local function preallocate(n)
	local t = {}
	for i = 1, n do
		t[i] = false
	end
	return t
end

function grid:_init_selection()
	if not self.multi_select then
		self.selected_row_index = false
		self.selected_col = false
	elseif not self.cell_select then
		if self.use_rangelist then
			local rangelist = require'rangelist'
			self.selected_rows = rangelist()
			self._selrow_cursor = self.selected_rows:cursor()
		else
			self.selected_rows = preallocate(self.row_count)
		end
	else
		self.selected_cells = {}
		for _,col in ipairs(self.cols) do
			self.selected_cells[col] = preallocate(self.row_count)
		end
	end
end

function grid:_insert_sel_rows(i, len)
	if not self.multi_select then
		local si = self.selected_row_index
		if si and i >= si then
			self.selected_row_index = si + len
		end
	elseif not self.cell_select then
		if self.use_rangelist then
			self.selected_rows:insert(i, len)
			self._selrow_cursor:seek(1)
		else
			shift(self.selected_rows, i, len)
		end
	else
		for _,rows in pairs(self.selected_cells) do
			shift(rows, i, len)
		end
	end
end

function grid:_remove_sel_rows(i, len)
	if not self.multi_select then
		local si = self.selected_row_index
		if si and si >= i then
			if si >= i + len then
				self.selected_row_index = si - len
			else
				self.selected_row_index = false
			end
		end
	elseif not self.cell_select then
		if self.use_rangelist then
			self.selected_rows:remove(i, len)
			self._selrow_cursor:seek(1)
		else
			shift(self.selected_rows, i, -len)
		end
	else
		shift(self.selected_cells, i, -len)
	end
end

function grid:cell_selected(i, col)
	if not self.multi_select then
		return self.selected_row_index == i
			and (not self.cell_select or self.selected_col == col)
	elseif not self.cell_select then
		if self.use_rangelist then
			return self._selrow_cursor:hit_test(i)
		else
			return self.selected_rows[i]
		end
	else
		return self.selected_cells[col][i]
	end
end

--NOTE: real events are too expensive here, eg. Ctrl+A wouldn't work on
--large grids, so we use plain methods instead.
grid.cell_was_deselected = nil
grid.cell_was_selected = nil
grid.row_was_selected = nil
grid.row_was_deselected = nil

function grid:select_cells(i1, col1, i2, col2, selected)
	selected = selected and true or false

	i1, i2 = self:valid_row_range(i1, i2)
	local j1 = self.cell_select and col1 and col1.index or 1
	local j2 = self.cell_select and col2 and col2.index or #self.cols
	if j2 < j1 then
		j1, j2 = j2, j1
	end

	if not self.multi_select then

		local i0 = self.selected_row_index
		local col0 = self.selected_col

		local sel_i1 = selected and i0 ~= i1
		local desel_i0 = not selected and i0 == i1
		local desel_i0 = i0 and sel_i1 or desel_i0
		local sel_col1 = sel_i1 or (selected and col0 ~= col1)
		local desel_col0 = desel_i0 or (not selected and col0 == col1)
		local desel_col0 = col0 and sel_col1 or desel_col0

		if desel_i0 then
			if self.row_was_deselected  then
				self:row_was_deselected(i0)
			end
			if desel_col0 and self.cell_select then
				if self.cell_was_deselected then
					self:cell_was_deselected(i0, col0)
				end
			end
		end
		if sel_i1 then
			if self.row_was_selected then
				self:row_was_selected(i1)
			end
			if sel_col1 and self.cell_select then
				if self.cell_was_selected then
					self:cell_was_selected(i1, col1)
				end
			end
		end

		self.selected_row_index = selected and i1
		self.selected_col = selected and self.cell_select and col1

	elseif not self.cell_select then

		if self.use_rangelist then
			local len = i2-i1+1
			self.selected_rows:select(i1, len, selected)
			local event = selected and 'row_was_selected' or 'row_was_deselected'
			local handler = self[event]
			if handler then
				for i = i1, i2 do
					handler(self, i)
				end
			end
		else
			local t = self.selected_rows
			local row_was_selected = self.row_was_selected
			local row_was_deselected = self.row_was_deselected
			for i = i1, i2 do
				local was_selected = t[i]
				t[i] = selected
				if selected and not was_selected then
					if row_was_selected then
						row_was_selected(self, i)
					end
				elseif not selected and was_selected then
					if row_was_deselected then
						row_was_deselected(self, i)
					end
				end
			end
		end

	else

		local cell_was_selected = self.cell_was_selected
		local cell_was_deselected = self.cell_was_deselected
		for j = j1, j2 do
			local col = self.cols[j]
			local t = self.selected_cells[col]
			for i = i1, i2 do
				local was_selected = t[i]
				t[i] = selected
				if selected and not was_selected then
					if cell_was_selected then
						cell_was_selected(self, i, col)
					end
				elseif not selected and was_selected then
					if cell_was_deselected then
						cell_was_deselected(self, i, col)
					end
				end
			end
		end

	end
end

function grid:select_rows(i1, i2, selected)
	return self:select_cells(i1, nil, i2, nil, selected)
end

function grid:select_cell(i, col, selected)
	return self:select_cells(i, col, i, col, selected)
end

function grid:select_none()
	if not self.multi_select then
		local i, col = self.selected_row_index, self.selected_col
		if i then
			self:select_cell(i, col, false)
		end
	else
		self:select_rows(1, 1/0, false)
	end
end

function grid:select_all()
	self:select_rows(1, 1/0, true)
end

--interaction ----------------------------------------------------------------

function grid:move(actions, di, dj)
	di = di or 0
	dj = dj or 0
	local i = di
	local col = self:rel_visible_col(dj)
	local reset_extend
	for action in actions:gmatch'[^%s]+' do
		if action == '@extend' then
			if self.extend_row_index then
				i = self.extend_row_index + di
				col = self:rel_visible_col(dj, self.extend_col, true)
			end
		elseif action == '@focus' then
			if self.focused_row_index then
				i = self.focused_row_index + di
				col = self:rel_visible_col(dj, self.focused_col, true)
			end
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
		elseif action == 'pick' then
			self:pick_row(i, false)
		elseif action == 'pick/close' then
			self:pick_row(i, true)
		elseif action == 'scroll' then
			self:scroll_to_view_cell(i, col)
		elseif action == 'scroll/instant' then
			self:scroll_to_view_cell(i, col, 0)
		elseif action == 'edit' then
			self.editmode = true
		elseif action == '@insert_row' then
			i = self:insert_row(i) or i
		elseif action == '@remove_selected_rows' then
			i = self:remove_selected_rows() or i
		elseif action == '@append_row' then
			i = self:append_row(1/0) or i
		end
	end
	if reset_extend then
		self.extend_row_index = false
		self.extend_col = false
	end
	self:invalidate()
end

--mouse interaction

function rows:after_click()
	if not self.grid.hot_row_index then return end
	local fi, fcol = self.grid.focused_row_index, self.grid.focused_col
	local shift = self.ui:key'shift'
	local ctrl = self.ui:key'ctrl'
	if self.grid.multi_select and (shift or ctrl) then
		self.grid:move(
			shift and ctrl and '@hot extend scroll'
			or shift and '@hot reset extend scroll'
			or ctrl and '@hot focus invert scroll'
		)
	else
		self.grid:move'@hot reset select focus pick/close scroll'
	end
	if fi and fcol
		and self.grid.focused_row_index == fi
		and self.grid.focused_col == fcol
	then
		self.grid.editmode = true
	end
end

--keyboard interaction

--find the number of rows relative to the focused row that should move the
--focused row on page-up/down requests. the scrolling logic is two-phase:
--first, move the focused row to the top/bottom on the current screen, then
--scroll _at most_ one full screen such that no gaps between screens occur
--i.e. no information is lost between screens.
function grid:screen_page_offset(dir, focused)
	focused = focused or self.focused_row_index
	local screen_h = self.scroll_pane.rows_pane.vscrollbar.view_length
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
	local page_h = self.scroll_pane.rows_pane.vscrollbar.view_length
	return (page - 1) * page_h, page_h
end

function grid:fixed_page_at_y(y)
	local page_h = self.scroll_pane.rows_pane.vscrollbar.view_length
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
	local screen_y = self.scroll_pane.rows_pane.vscrollbar.offset
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

grid.focusable = true

function grid:keypress(key)
	local shift = self.ui:key'shift'
	local ctrl = self.ui:key'ctrl'

	local i = self.focused_row_index
	if not ctrl and key == 'down'
		and self.editable and self.add_row_on_down_key
		and (i == self.row_count or self.row_count == 0)
		and (not i or not self:row_attr(i, 'appended'))
	then
		self:move'reset @append_row select focus scroll'
		return
	end

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
				or '@focus reset select pick focus scroll',
			rows or 0, cols or 0)
		return true
	elseif ctrl and key == 'A' then
		if self.multi_select then
			self:move('select_all')
			return true
		end
	elseif not self.editable and self.dropdown and key == 'enter' then
		self:move('@focus pick/close scroll')
		return true
	elseif self.editable then
		if key == 'F2' or key == 'enter' then
			local editmode = not self.editmode
			self.editmode = editmode
			return editmode
		elseif key == 'esc' then
			self.editmode = false
			return self.editmode == false
		elseif key == 'insert' and self.allow_insert_row then
			self:move'@focus reset @insert_row select focus scroll'
		elseif ctrl and key == 'delete' and self.allow_remove_row then
			self:move'@remove_selected_rows select focus scroll'
		elseif not ctrl and key == 'delete' and self.allow_clear_cell then
			self:clear_selected_cells()
		end
	end
end

function grid:keychar(s)
	if not self.editmode then
		if ui.editbox:filter_text(s) ~= '' then
			self.editmode = true
			if self.edit_cell then
				return self.edit_cell:fire('keychar', s)
			end
		end
	end
end

--value lookup ---------------------------------------------------------------

--TODO: build and use an index here!
function grid:lookup(val, col)
	for i = 1, #self.rows do
		if self:cell_value(i, col) == val then
			return i
		end
	end
end

--dropdown picker API --------------------------------------------------------

ui:style('grid dropdown_picker', {
	header_visible = false,
	col_move = false,
	row_move = false,
	border_width_right = 1,
	border_width_left = 1,
	border_width_bottom = 1,
	border_color = '#ccc',
	padding_left = 1,
	padding_right = 1,
	padding_bottom = 1,
})

--dropdown property

function grid:set_dropdown(dropdown)
	self._dropdown = dropdown
	self:_create_dropdown_implicit_column()
	self:settag('dropdown_picker', dropdown and true or false)
end

function grid:get_dropdown()
	return self._dropdown
end

function grid:_create_dropdown_implicit_column()
	if not self.dropdown then return end
	if #self.cols == 0 then
		push(self.cols, self:create_col())
	end
end

--geometry

--called by the dropdown to resize the picker's popup window before it is
--shown (which is why we can't just set the grid size on sync()).
function grid:sync_dropdown()
	--sync styles first because we use self's paddings.
	self:sync_styles()

	local w = self.dropdown.w
	local noscroll_ch = self.rows_h
	local max_ch = w * 1.4
	local ch = math.min(noscroll_ch, max_ch)
	self.w, self.ch = w, ch

	self:sync() --sync so that vscrollbar is synced so that scroll works.
	self:move'@focus scroll/instant'

	return self.w, self.h
end

function grid:sync_picker_col_size(phase)
	if self.dropdown and #self.cols == 1 then
		local vci = self.pick_col_index
		local tci = self.pick_text_col_index or vci
		assert(vci == tci)
		local col = self.cols[tci]
		col.auto_w = false
		if phase == 1 then
			col.w = 0
		else
			col.w = self.scroll_pane.rows_pane.view.cw
		end
	end
end

--picking values

grid.pick_col_index = 1
grid.pick_text_col_index = false --same as pick_col_index

function grid:pick_row(i, close)
	if not self.dropdown then return end
	i = clamp(i, 1, self.row_count)
	local vci = self.pick_col_index
	local tci = self.pick_text_col_index or vci
	local val = self:cell_value(i, assert(self.cols[vci]))
	local text = self:cell_value(i, assert(self.cols[tci]))
	self.dropdown:value_picked(val, text, close)
end

function grid:_pick_row(i, close)
	self:move('reset select focus scroll pick'..(close and '/close' or ''), i)
end

function grid:pick_value(val, close)
	local i = self:lookup(val, self.cols[self.pick_col_index])
	if not i then return end
	self:_pick_row(i, close)
end

--editmode -------------------------------------------------------------------

grid.editable = false
grid.allow_insert_row = true
grid.allow_remove_row = true
grid.allow_clear_cell = true
grid.add_row_on_down_key = true

grid:stored_property'editmode'
grid:track_changes'editmode'

function grid:get_canedit()
	return self.editable and self.focused and self.focused_col and true or false
end

function grid:override_set_editmode(inherited, editmode)
	if editmode and not self.canedit then
		return
	end
	if inherited(self, editmode) then
		local event = editmode and self._enter_editmode or self._exit_editmode
		event(self, self.focused_row_index, self.focused_col)
	end
end

function grid:_enter_editmode(i, col)
	local cell = self:create_cell()
	local i = self.focused_row_index
	local col = self.focused_col
	local y, h = self:row_yh(i)
	self:sync_cell_to_grid(cell)
	self:sync_cell_to_col(cell, col)
	self:sync_cell_to_row(cell, i, y, h)
	self:sync_cell_to_value(cell, i, col, self:cell_value(i, col))
	self.edit_cell = cell
	cell.visible = true
	cell:focus()
end

function grid:_exit_editmode(i, col)
	self:update_cell_value(
		self.focused_row_index,
		self.focused_col,
		self.edit_cell.value
	)
	self.edit_cell:free()
	self.edit_cell = false
	self:focus()
end

function grid:sync_edit_cell()
	local cell = self.edit_cell
	if not cell then return end
	local i = self.focused_row_index
	cell.y = self:row_yh(i)
end

--data model -----------------------------------------------------------------

function grid:init_data_model()
	self.rows = self.rows or {}
end

function grid:get_row_count()
	return #self.rows
end

function grid:get_empty()
	return self.row_count == 0 or #self.cols == 0
end

function grid:row_var_h(i)
	return self.rows[i].h
end

function grid:cell_value(i, col)
	local row = self.rows[i]
	if type(row) == 'table' then
		return row[col.value_index]
	else
		return row
	end
end

function grid:default_cell_value(col)
	local dt = self.default_values
	if dt and dt[col.value_index] ~= nil then
		return dt[col.value_index]
	elseif dt and dt[col.text] ~= nil then
		return dt[col.text]
	elseif col.default_value ~= nil then
		return col.default_value
	else
		return self.default_value
	end
end

function grid:update_cell_value(i, col, val)
	local row = self.rows[i]
	if row == nil then return end --virtual row?
	if type(row) == 'table' then
		row[col.value_index] = val
	elseif row then
		self.rows[i] = val
	end
end

function grid:row_attr(i, attr, default)
	local row = assert(self.rows[i])
	local val = type(row) ~= 'string' and row[attr] or nil
	if val == nil then
		val = default
	end
	return val
end

function grid:row_attr_set(i, attr, val)
	local row = assert(self.rows[i])
	row[attr] = val
end

function grid:create_row()
	local row = {}
	local dt = self.default_values
	for _,col in ipairs(self.cols) do
		row[col.value_index] = self:default_cell_value(col)
	end
	return row
end

function grid:insert_row(i)
	i = clamp(i, 1, self.row_count + 1)
	local row = self:create_row()
	if self:fire('inserting_row', i, row) == false then
		return
	end
	push(self.rows, i, row)
	self:_insert_row_y_rows(i, 1)
	self:_insert_sel_rows(i, 1)
	self:fire('row_inserted', i, row)
	return i
end

function grid:append_row()
	local i = self:insert_row(1/0)
	if not i then return end
	self:row_attr_set(i, 'appended', true)
	return i
end

function grid:valid_row_range(i1, i2, d)
	i2 = i2 or i1
	d = d or 0
	local n = self.row_count
	i1 = clamp(i1, 1, n + d)
	i2 = clamp(i2, 1, n + d)
	if i2 < i1 then
		i1, i2 = i2, i1
	end
	return i1, i2
end

function grid:_remove_row_range(i1, i2)
	local len = i2 - i1 + 1
	self:unfocus_focused_cell()
	self:select_rows(i1, i2, false)
	shift(self.rows, i1, -len)
	self:_remove_row_y_rows(i1, len)
	self:_remove_sel_rows(i1, len)
	local row_removed = self.row_removed
	if row_removed then
		for i = i1, i2 do
			row_removed(self, i)
		end
	end
	return i1
end

--remove rows in batches but run confirmations for each row.
function grid:remove_rows(start_i, end_i, confirm)
	start_i, end_i = self:valid_row_range(start_i, end_i)
	local i1, i2, rem_i
	for i = end_i, start_i, -1 do
		local remove = not confirm or confirm(self, i)
		if remove then
			i1 = i
			i2 = i2 or i
		end
		if i1 and (not remove or i == start_i) then
			rem_i = self:_remove_row_range(i1, i2)
			i1, i2 = nil
		end
	end
	return rem_i
end

function grid:remove_selected_rows()
	local removing_row = self.removing_row
	local confirm = removing_row and function(self, i)
		return removing_row(self, i) ~= false
	end
	if not self.multi_select then
		local i = self.selected_row_index
		if not i then return end
		return self:remove_rows(i, 1, confirm)
	elseif not self.cell_select then
		if self.use_rangelist then
			local rem_i
			for _, i, len in self.selected_rows:ranges() do
				rem_i = self:remove_rows(i, i+len-1, confirm)
			end
			return rem_i
		else
			local selected = self.selected_rows
			return self:remove_rows(1, self.row_count, function(self, i)
				return selected[i] and (not confirm or confirm(self, i))
			end)
		end
	else
		--TODO: remove rows where there are selected cells?
	end
end

function grid:clear_selected_cells()
	local val = self.empty_value
	if not self.multi_select then
		local i = self.selected_row_index
		local col = self.selected_col
		if col then
			self:update_cell_value(i, col, val)
		elseif i then
			for _,col in ipairs(self.cols) do
				self:update_cell_value(i, col, val)
			end
		end
	elseif not self.cell_select then
		if self.use_rangelist then
			for _, i, len in self.selected_rows:ranges() do
				for i = i, i+len-1 do
					for _,col in ipairs(self.cols) do
						self:update_cell_value(i, col, val)
					end
				end
			end
		else
			local t = self.selected_rows
			for i, selected in pairs(t) do
				if selected then
					for _,col in ipairs(self.cols) do
						self:update_cell_value(i, col, val)
					end
				end
			end
		end
	else
		local t = self.selected_cells
		for col, cells in pairs(self.selected_cells) do
			for i, selected in pairs(cells) do
				if selected then
					self:update_cell_value(i, col, val)
				end
			end
		end
	end
end

--grid -----------------------------------------------------------------------

function grid:after_sync()
	self:sync_picker_col_size(1)
	self:sync_freeze_col()
	self.freeze_pane:sync_to_grid()
	self.scroll_pane:sync_to_grid()
	self.splitter:sync_to_grid()
	self:sync_picker_col_size(2)
	self:sync_edit_cell()
end

grid:init_ignore{freeze_col=1, dropdown=1}

function grid:after_init(ui, t)

	self._freeze_col = t.freeze_col

	local cols = t.cols or self.cols or {}
	self.cols = {}
	if cols then
		for i,col in ipairs(cols) do
			push(self.cols, self:create_col(col, i))
		end
	end

	self:init_data_model()

	self.dropdown = t.dropdown

	self.freeze_pane = self:create_freeze_pane()
	self.scroll_pane = self:create_scroll_pane()
	self.scroll_pane.freeze_pane = self.freeze_pane

	--set up panes for drag-selecting over the other pane
	self.freeze_pane.other_pane = self.scroll_pane
	self.freeze_pane.clamp_left = true
	self.freeze_pane.clamp_right = false
	self.scroll_pane.other_pane = self.freeze_pane
	self.scroll_pane.clamp_left = false
	self.scroll_pane.clamp_right = true

	self.splitter = self:create_splitter()
	self:_init_row_y()
	self:_init_selection()
end

--demo -----------------------------------------------------------------------

if not ... then require('ui_demo')(function(ui, win)

	local grid = ui.grid:subclass'subgrid'

	local rows = {}
	for i = 1,1e4 do
		local t = {}
		push(rows, t)
		for j = 1, 5 do
			push(t, 'hello') --'col '..j..' '..i..' 12345')
		end
		local n = math.random()
		t.h = n < .1 and 200 or 24
	end

	local g = grid(ui, {
		tags = 'g',
		x = 20,
		y = 20,
		w = 1160,
		h = 660,
		--row_count = 1e6,
		rows = rows,
		parent = win,
		--clip_content = true,
		cols = {
			{text = 'col1', w = 150},
			{text = 'col2', w = 100, visible = false},
			{text = 'col3', w = 300},
			{text = 'col4', w = 300},
			{text = 'col5', w = 150},
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
		rows_pane = {
			vscrollbar = {
				overlap = true,
			},
		},
		spliiter = {
			--background_color = '#0f0',
		},
		var_row_h = true,
		--[[
		row_var_h = function(self, i)
			local n = math.random()
			return n < .1 and 200 or 34
		end,
		]]
		multi_select = true,
		--row_move_ctrl = false,
		--row_move = true,

		--cell_select = true,
		--cell_class = ui.editbox,
		default_values = {col3 = 'Whaa!'},
		editable = true,
	})

	ui:style('grid_rows_pane > scrollbar', {
		--transition_offset = false,
	})

	function g:Xcell_value(i, col)
		return ''
			.. col.text
			.. ' '..i
			.. ' 123456789'
			--.. ' abcdefghijklmnopqrstuvwxyz'
	end

	win.native_window:on('shown', function(self)
		--self:maximize()
	end)

	win.native_window:on('repaint', function(self)
		--self:invalidate()
	end)

end) end
