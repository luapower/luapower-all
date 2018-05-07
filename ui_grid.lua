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
local update = glue.update
local binsearch = glue.binsearch

local grid = ui.layer:subclass'grid'
ui.grid = grid

--scroll pane and freeze pane ------------------------------------------------

local pane = {} --scroll/freeze pane mixin

local rows = ui.layer:subclass'grid_rows_layer'
pane.rows_layer_class = rows

rows.vscrollable = true
rows.background_hittable = true
rows.clip_content = true

function rows:mousewheel(delta, mx, my, area, pdelta)
	self.grid.vscrollbar:scroll_by(delta * self.grid.row_h)
end

function rows:before_draw_content()
	self.grid:draw_rows(self)
end

function rows:override_hit_test_content(inherited, x, y, reason)
	if reason == 'activate' then
		local i = self.grid:row_at_y(y)
		if i then
			local col = i and self.pane:col_by_x(x)
			if col then
				self._area = self._area or {}
				self._area.i = i
				self._area.col = col
				self._area.area = 'cell'
				return self, self._area
			end
		end
	end
	return inherited(self, x, y, reason)
end

function pane:after_init()

	self.rows_layer = self.rows_layer_class(self.ui, {
		parent = self.content or self,
		pane = self,
		grid = self.grid,
	}, self.grid.rows_layer)

end

function pane:sync_rows_layer()
	local r = self.rows_layer
	r.y = self.grid.col_h
	r.w = self.content.w
	r.h = self.content_container.h - r.y
end

function pane:col_by_x(x)
	for i,col in ipairs(self.grid.cols) do
		if col.visible and col.pane == self then
			if x >= col.x and x <= col.x + col.w then
				return col
			end
		end
	end
end

local scroll_pane = ui.scrollbox:subclass'grid_scroll_pane'
grid.scroll_pane_class = scroll_pane
update(scroll_pane, pane)

scroll_pane.vscrollable = false
scroll_pane.scrollbar_margin_right = 12

local freeze_pane = ui.layer:subclass'grid_freeze_pane'
grid.freeze_pane_class = freeze_pane
update(freeze_pane, pane)

function grid:create_content_panes()

	self.scroll_pane = self.scroll_pane_class(self.ui, {
		subtag = 'scroll_pane',
		parent = self,
		grid = self,
	}, self.scroll_pane)

	self.freeze_pane = self.freeze_pane_class(self.ui, {
		subtag = 'freeze_pane',
		parent = self,
		grid = self,
	}, self.freeze_pane)

	self.freeze_pane.content = self.freeze_pane
	self.freeze_pane.content_container = self.freeze_pane

end

function grid:_sync_content_panes()

	local fp = self.freeze_pane
	local sp = self.scroll_pane
	local s = self.splitter

	fp.h = self.ch
	sp.h = fp.h
	sp.content.h = sp.h

	--move cols to their content panes
	local fw = 0
	local sw = 0
	for i,col in ipairs(self.cols) do
		local frozen = self.freeze_col and i <= self.freeze_col
		col.pane = frozen and self.freeze_pane or self.scroll_pane
		col.parent = col.pane.content
		fw = fw + (frozen and col.w or 0)
		sw = sw + (frozen and 0 or col.w)
	end
	fp.cw = fw
	sp.x = fp.w + s.w
	sp.w = self.cw - fw - s.w
	sp.content.w = sw

	self.scroll_pane:sync()
	self.scroll_pane:sync_rows_layer()
	self.freeze_pane:sync_rows_layer()
end

--freeze pane splitter -------------------------------------------------------

local splitter = ui.layer:subclass'grid_splitter'
grid.splitter_class = splitter

splitter.w = 6
splitter.background_color = '#888'
splitter.cursor = 'size_h'

function splitter:mousedown()
	self.active = true
end

function splitter:mouseup()
	self.active = false
end

function splitter:start_drag(button, mx, my, area)
	if button ~= 'left' then return end
	if self.split.auto_w then

		local drag_splitter = self.ui:layer{
			x = self.x,
			y = self.y,
			w = self.w,
			h = self.h,
			parent = self.parent,
			split = self.split,
			grid = self.split.grid,
			background_color = '#fff2',
		}

		drag_splitter.drop_splitter = self.ui:layer{
			x = self.x,
			y = self.y,
			w = self.w,
			h = self.h,
			parent = self.parent,
			split = self.split,
			grid = self.split.grid,
			background_color = '#fff8',
			visible = false,
		}

		function drag_splitter:drag(dx, dy)
			self.x = self.x + dx
			local cx = self:to_other(self.grid, self.w / 2, 0)
			local col, d = self.grid:nearest_col_inbetween(cx)
			local ds = self.drop_splitter
			if col then
				ds.x = col:to_other(self.grid, col.w, 0)
				ds.visible = true
				ds.col = col
			else
				ds.visible = false
			end
			self:invalidate()
		end

		return drag_splitter
	else
		return self
	end
end

function splitter:end_drag(drag_splitter)
	if self.split.auto_w then
		local col = drag_splitter.drop_splitter.col
		if col.split == self.split then

		else

		end
		drag_splitter.drop_splitter:free()
		drag_splitter:free()
	end
end

function splitter:drag(dx, dy)
	self.x = self.x + dx
	self.split.w = math.max(0, self.x - self.split.x)
	self:invalidate()
end

function grid:create_splitter()
	self.splitter = self.splitter_class(self.ui, {
		subtag = 'splitter',
		parent = self,
	}, self.splitter)
end

function grid:_sync_splitter()
	local s = self.splitter
	s.x = self.scroll_pane.x - s.w
	s.h = self.ch
end

--column headers -------------------------------------------------------------

local col = ui.layer:subclass'grid_col'
grid.col_class = col

col.text_align = 'left'
col.w = 200
col.padding_left = 4
col.padding_right = 4

grid.col_h = 20

function col:get_index()
	return indexof(self, self.grid.cols)
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

function grid:add_col(col, value_index)
	col = self.col_class(self.ui, self.col, col)
	col.grid = self
	col.value_index = col.value_index or value_index
	push(self.cols, col)
end

function grid:remove_col(col)
	if col.grid ~= self then return end
	pop(self.cols, indexof(col, self.cols))
	col.grid = nil
end

function grid:create_cols()
	local cols = self.cols
	self.cols = {}
	if cols then
		for i,col in ipairs(cols) do
			self:add_col(col, i)
		end
	end
end

function grid:_sync_cols()
	local x = 0
	local last_col
	for i,col in ipairs(self.cols) do
		col.h = self.col_h
		if col.visible then
			if last_col and last_col.parent ~= col.parent then
				x = 0
			end
			col.x = x
			x = x + col.w
			last_col = col
		end
	end
end

--cells ----------------------------------------------------------------------

local cell = ui.layer:subclass'grid_cell'
grid.cell_class = cell

cell.clip_content = true
cell.text_multiline = false

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
end

function cell:sync_row(i, y, h)
	self.y = y
	self.h = h
	self.background_color = i % 2 == 0 and '#111' or false
end

function cell:sync_value(i, col, val)
	self.text = val
end

function grid:create_cell()
	self.cell = self.cell_class(self.ui, self.cell)
	self.cell:inherit(self.cell.super) --speed up cell drawing
end

function grid:cell_at(i, col)
	return self.cell
end

function grid:cell_value(i, col)
	return self.values[i][col.value_index]
end

--rows -----------------------------------------------------------------------

grid.row_h = 20
grid.var_row_h = false

function grid:get_row_count()
	local rows = self.rows
	return rows and #rows or 0
end

function grid:rows_h()
	local y, h = self:row_yh(self.row_count)
	return y + h
end

function grid:row_var_h(i)
	local rows = self.rows
	local row = rows and rows[i]
	return row and row.h or self.row_h
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
	if self.var_row_h then
		local y = self._row_y[i]
		return y, self._row_y[i+1] - y
	else
		return self.row_h * (i - 1), self.row_h
	end
end

function grid:row_at_y(y)
	if self.var_row_h then
		local t = self._row_y
		if #t > 0 and y < t[1] then return nil end
		local i = binsearch(y, t)
		return i and y < t[i] and i-1 or i
	else
		local i = (y + self.vscrollbar.offset) / self.row_h + 1
		return i >= 1 and i <= self.row_count and i or nil
	end
end

function grid:visible_rows_range()
	local y = self.vscrollbar.offset
	local h = self.scroll_pane.rows_layer.ch
	if self.var_row_h then
		local i1 = self:row_at_y(y)
		local i2 = self:row_at_y(y + h - 1)
		return i1, i2
	else
		local i1 = math.floor(y / self.row_h) + 1
		local i2 = math.ceil((y + h) / self.row_h)
		i1 = i1 >= 1 and i1 <= self.row_count and i1 or nil
		i2 = i2 >= 1 and i2 <= self.row_count and i2 or nil
		return i1, i2
	end
end

function grid:draw_rows(rows_layer)
	local cr = self.window.cr
	local i1, i2 = self:visible_rows_range()
	if not i1 then return end
	local offset = self.vscrollbar.offset
	for _,col in ipairs(self.cols) do
		if col.pane == rows_layer.pane and not col.clipped then
			self.cell:sync_col(col)
			for i = i1, i2 do
				local y, h = self:row_yh(i)
				self.cell:sync_row(i, y - offset, h)
				self.cell:sync_value(i, col, self:cell_value(i, col))
				self.cell:draw()
			end
		end
	end
end

--vertical scrollbar ---------------------------------------------------------

grid.vscrollbar_class = ui.scrollbar

function grid:create_vscrollbar()

	self.vscrollbar = self.vscrollbar_class(self.ui, {
		subtag = 'vscrollbar',
		parent = self,
	}, self.vscrollbar)

end

function grid:_sync_vscrollbar()
	local vs = self.vscrollbar
	local m1 = 6
	local m2 = 6
	vs.y = self.col_h + m1
	vs.x = self.cw - vs.h - m1
	vs.w = self.ch - vs.y - m1 - m2
	vs.view_length = self.scroll_pane.rows_layer.h
	vs.content_length = self:rows_h()
end

--grid -----------------------------------------------------------------------

function grid:sync()
	self:_sync_content_panes()
	self:_sync_cols()
	self:_sync_splitter()
	self:_sync_vscrollbar()
end

function grid:before_draw()
	self:sync()
end

function grid:after_init()
	self:create_content_panes()
	self:create_cols()
	self:create_splitter()
	self:create_vscrollbar()
	self:create_cell()
	if self.var_row_h then
		self:_build_row_y_table()
	end
end


if not ... then require('ui_demo')(function(ui, win)

	local g = ui:grid{
		x = 10,
		y = 10,
		w = 900,
		h = 500,
		row_count = 1e6,
		parent = win,
		border_width = 5,
		padding = 15,
		border_color = '#00f',
		--clip_content = true,
		cols = {
			{text = 'col1', w = 150},
			{text = 'col2', w = 300},
			{text = 'col3', w = 100},
			{text = 'col4', w = 150},
			{text = 'col5', w = 150},
			{text = 'col6', w = 150},
			{text = 'col7', w = 150},
			{text = 'col8', w = 1500},
		},
		col = {
			border_width = 1,
			border_color = '#f00',
		},
		cell = {
			border_width_bottom = 1,
			border_color = '#333',
		},
		freeze_col = 2,
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
			return math.floor(math.random(20, 100))
		end,
	}

	function g:cell_value(i, col)
		return col.text..' '..i..' 123456789 ................ abcdefghijklmnopqrstuvwxyz'
	end

	win.native_window:on('shown', function(self)
		self:maximize()
	end)

	win.native_window:on('repaint', function(self)
		self:invalidate()
	end)

end) end
