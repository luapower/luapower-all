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

local function popval(t, v)
	local i = indexof(v, t)
	return i and pop(t, i)
end

local grid = ui.layer:subclass'grid'
ui.grid = grid

grid.header_visible = true

--header layer ---------------------------------------------------------------

local header = ui.layer:subclass'grid_header_layer'
header.clip_content = true --for column moving

function header:after_sync()
	self.visible = self.grid.header_visible
	self.w = self.pane.content.w
	self.h = self.grid.col_h
end

--rows layer -----------------------------------------------------------------

local rows = ui.layer:subclass'grid_rows_layer'

rows.vscrollable = true
rows.background_hittable = true
rows.clip_content = true --for rows

function rows:after_sync()
	self.y = self.pane.header_layer.visible and self.grid.col_h or 0
	self.w = self.pane.content.w
	local ct = self.pane.content_container
	self.h = (ct and ct.h or self.pane.h) - self.y
end

function rows:before_draw_content()
	self.grid:draw_rows(self)
end

function rows:mousewheel(delta, mx, my, area, pdelta)
	self.grid.vscrollbar:scroll_by(delta * self.grid.row_h)
end

function rows:override_hit_test_content(inherited, x, y, reason)
	if reason == 'activate' then
		local i = self.grid:row_at_y(y)
		if i then
			local col = i and self.pane:col_at_x(x)
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

--panes ----------------------------------------------------------------------

local pane = {} --scroll/freeze pane mixin

grid.header_layer_class = header
grid.rows_layer_class = rows

function pane:after_init()

	self.header_layer = self.grid.header_layer_class(self.ui, {
		subtag = 'header_layer',
		parent = self.content or self,
		pane = self,
		grid = self.grid,
	}, self.grid.header_layer)

	self.rows_layer = self.grid.rows_layer_class(self.ui, {
		subtags = 'rows_layer',
		parent = self.content or self,
		pane = self,
		grid = self.grid,
	}, self.grid.rows_layer)

end

function pane:before_sync()

	local pw = 0
	local x = 0
	for i,col in ipairs(self.cols) do
		col.pane = self
		col.parent = self.header_layer
		col.h = self.grid.col_h
		if col.visible then
			pw = pw + col.w
			if not col.moving then
				col.x = x
			end
			x = x + col.w
		end
	end

	self.h = self.grid.ch

	if self.frozen then
		self.cw = pw
	else
		self.content.h = self.h
		local fp = self.freeze_pane
		local s = self.grid.splitter
		local sw = s.visible and s.w or 0
		self.x = fp.w + sw
		self.w = self.grid.cw - fp.w - sw
		if self.grid.resizing_col then
			--prevent shrinking to avoid scrolling while resizing
			self.content.w = math.max(self.content.w, pw)
		else
			self.content.w = pw
		end
	end

end

function pane:after_sync()
	self.header_layer:sync()
	self.rows_layer:sync()
end

function pane:col_at_x(x)
	for i,col in ipairs(self.grid.cols) do
		if col.visible and col.pane == self then
			if x >= col.x and x <= col.x2 then
				return col
			end
		end
	end
end

function pane:max_w()
	return 1/0
end

--freeze panes ---------------------------------------------------------------

local freeze_pane = ui.layer:subclass'grid_freeze_pane'
grid.freeze_pane_class = freeze_pane
update(freeze_pane, pane)

function grid:create_freeze_pane(t)
	local pane = self.freeze_pane_class(self.ui, {
		subtag = 'freeze_pane',
		parent = self,
		grid = self,
		frozen = true,
		cols = self:frozen_cols(),
	}, t)
	pane.content = pane
	return pane
end

--the freeze pane must be small enough so that the splitter is always visible.
function freeze_pane:max_w()
	return self.grid.cw - self.grid.splitter.w
end

--scroll panes ---------------------------------------------------------------

local scroll_pane = ui.scrollbox:subclass'grid_scroll_pane'
grid.scroll_pane_class = scroll_pane
update(scroll_pane, pane)

scroll_pane.vscrollable = false
scroll_pane.scrollbar_margin_right = 12

function grid:create_scroll_pane(freeze_pane)
	return self.scroll_pane_class(self.ui, {
		subtag = 'scroll_pane',
		parent = self,
		grid = self,
		frozen = false,
		freeze_pane = freeze_pane,
		cols = self:unfrozen_cols(),
	}, self.scroll_pane)
end

--freeze col -----------------------------------------------------------------

--returns the largest freeze_col which satisifes freeze_pane_max_w().
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
	ci = ci or nil
	if ci == self.freeze_col then return end
	local max_ci = self:max_freeze_col()
	if max_ci then
		ci = ci and clamp(ci, 1, max_ci)
	else
		ci = max_ci
	end
	self._freeze_col = ci
	if self.freeze_pane then
		self.freeze_pane.cols = self:frozen_cols()
		self.scroll_pane.cols = self:unfrozen_cols()
	end
end

function grid:sync_freeze_col()
	if self.freeze_col then
		local max_ci = self:max_freeze_col()
		if not max_ci or max_ci < self.freeze_col then
			self.freeze_col = max_ci
		end
	end
end

--freeze pane splitter -------------------------------------------------------

local splitter = ui.layer:subclass'grid_splitter'
grid.splitter_class = splitter

local drag_splitter = ui.layer:subclass'grid_drag_splitter'
splitter.drag_splitter_class = drag_splitter

drag_splitter.background_color = '#fff2'

splitter.w = 6
splitter.background_color = '#888'
splitter.cursor = 'size_h'

function grid:create_splitter()
	return self.splitter_class(self.ui, {
		subtag = 'splitter',
		parent = self,
		grid = self,
	}, self.splitter)
end

function splitter:sync()
	self.x = self.grid.scroll_pane.x - self.w
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

	return ds
end

function drag_splitter:drag(dx, dy)
	local sp = self.grid.scroll_pane
	sp.hscrollbar.offset = 0

	local col = self.grid:last_visible_col()
	local last_col_x2 = col and col.parent:to_other(self.grid, col.x2, 0)
	local max_w = math.min(last_col_x2 or 0, self.grid.cw) - self.w
	self.x = clamp(0, self.x + dx + self.w / 2, max_w)

	local ci = self.grid:nearest_col_index_at_x(self.x)
	self.grid.freeze_col = ci
	local freezed = self.grid.freeze_col and true or false
	self.grid.splitter.visible = freezed
	self.grid.freeze_pane.visible = freezed
	self:invalidate()
end

function splitter:end_drag(ds)
	ds.visible = false
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
col.background_hittable = true
col.cursor_resize = 'size_h'

grid.col_h = 20

function col:get_index()
	return indexof(self, self.grid.cols)
end

function col:set_index(index)
	--
end

function col:get_w()
	return self._w
end

function col:set_w(w)
	local padding = self.w - self.cw
	self._w = clamp(w, padding + self.min_cw, self.max_w)
end

function col:override_hit_test(inherited, x, y, reason)
	local widget, area = inherited(self, x, y, reason)
	if widget == self then
		if x >= self.x2 - self.padding_right then
			return self, 'resize'
		elseif x <= self.x + self.padding_left then
			local col = self.grid:prev_visible_col(self)
			if col then
				return col, 'resize'
			end
		end
	end
	return widget, area
end

--column drag & drop

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

--column resize --------------------------------------------------------------

function col:start_drag_resize(button, mx, my)
	if button ~= 'left' then return end
	self.grid.resizing_col = true
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
	self.grid.resizing_col = false
end

--column move ----------------------------------------------------------------

function col:start_drag_move(button, mx, my, area)
	if button ~= 'left' then return end
	self.window.cursor = 'move'
	self.moving = true
	self:to_front()
	return self
end

function col:drag_move(dx, dy)
	self.x = self.x + dx
	self:invalidate()
end

function col:end_drag_move()
	self.moving = false
	self.window.cursor = nil
end

--column utils

function col:get_frozen()
	local fi = self.grid.freeze_col
	return fi and self.index <= fi
end

function grid:_cols(frozen)
	local fi = self.freeze_col
	local t = {}
	for i,col in ipairs(self.cols) do
		if frozen == (fi and i <= fi or false) then
			push(t, col)
		end
	end
	return t
end
function grid:frozen_cols() return self:_cols(true) end
function grid:unfrozen_cols() return self:_cols(false) end

function col:get_clipped()
	if not self.visible then
		return true
	end
	local x, y, w, h = self.x, self.y, self.w, self.h
	local w, h = select(3, box2d.clip(x, y, w, h, self.parent:content_rect()))
	return w == 0 or h == 0
end

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

function grid:prev_visible_col(col)
	for i = col.index - 1, 1, -1 do
		local col = self.cols[i]
		if col.visible then
			return col
		end
	end
end

function grid:last_visible_col()
	for i = #self.cols, 1, -1 do
		local col = self.cols[i]
		if col.visible then
			return col
		end
	end
end

--cells ----------------------------------------------------------------------

local cell = ui.layer:subclass'grid_cell'
grid.cell_class = cell

cell.clip_content = true
cell.text_multiline = false
cell.background_color = '#000' --for column moving

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
	self.background_color = i % 2 == 0 and '#111' or '#000'
end

function cell:sync_value(i, col, val)
	self.text = val
end

function grid:create_cell()
	local cell = self.cell_class(self.ui, self.cell)
	cell:inherit(cell.super) --speed up cell drawing
	return cell
end

function grid:cell_at(i, col)
	return self.cell
end

function grid:cell_value(i, col)
	return self.rows[i][col.value_index]
end

--rows -----------------------------------------------------------------------

grid.row_h = 20
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

function grid:draw_rows_col(i1, i2, col)
	local offset = self.vscrollbar.offset
	self.cell:sync_col(col)
	for i = i1, i2 do
		local y, h = self:row_yh(i)
		self.cell:sync_row(i, y - offset, h)
		self.cell:sync_value(i, col, self:cell_value(i, col))
		self.cell:draw()
	end
end

function grid:draw_rows(rows_layer)
	local i1, i2 = self:visible_rows_range()
	if not i1 then return end
	local moving_col
	for _,col in ipairs(self.cols) do
		if col.pane == rows_layer.pane and not col.clipped then
			if col.moving then
				moving_col = col
			else
				self:draw_rows_col(i1, i2, col)
			end
		end
	end
	if moving_col then
		self:draw_rows_col(i1, i2, moving_col)
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
		subtag = 'vscrollbar',
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
	self.view_length = sp.rows_layer.h
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
	self.splitter = self:create_splitter()
	self.vscrollbar = self:create_vscrollbar()
	self.cell = self:create_cell()
	if self.var_row_h then
		self:_build_row_y_table()
	end
end


if not ... then require('ui_demo')(function(ui, win)

	local g = ui:grid{
		id = 'g',
		x = 10,
		y = 10,
		w = 800,
		h = 450,
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
			--{text = 'col5', w = 150},
			--{text = 'col6', w = 150},
			--{text = 'col7', w = 150},
			--{text = 'col8', w = 500},
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
		--self:maximize()
	end)

	win.native_window:on('repaint', function(self)
		--self:invalidate()
	end)

end) end
