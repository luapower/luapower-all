
--ui grid widget.
--Written by Cosmin Apreutesei. Public Domain.

local ui = require'ui'
local oo = require'oo'
local glue = require'glue'

local grid = ui.layer:subclass'grid'
ui.grid = grid

local col = ui.element:subclass'grid_col'
ui.grid.col_class = col

col.w = 200

grid.vscrollbar_class = ui.scrollbar
grid.hscrollbar_class = ui.scrollbar

grid.content_clip = true

grid.row_count = 0
grid.default_row_h = 20

function grid:after_init()

	local cols = self.cols
	self.cols = {}
	if cols then
		for i,col in ipairs(cols) do
			self:add_col(col)
		end
	end

	self.vscrollbar = self.vscrollbar_class(self.ui, {
		id = self:_subtag'vscrollbar',
		parent = self,
		vertical = true,
		autohide = true,
	}, self.vscrollbar)

	self.hscrollbar = self.hscrollbar_class(self.ui, {
		id = self:_subtag'hscrollbar',
		parent = self,
		autohide = true,
	}, self.hscrollbar)

end

function col:override_create(inherited, ui, col, ...)
	if oo.isinstance(col, self) then
		return col --pass-through
	end
	return inherited(self, ui, col, ...)
end

function grid:add_col(col)
	col = self.col_class(self.ui, col)
	col.grid = self
	table.insert(self.cols, col)
end

function grid:remove_col(col)
	if col.grid ~= self then return end
	table.remove(self.cols, glue.indexof(col))
	col.grid = nil
end

function grid:rows_w()
	local w = 0
	for i,col in ipairs(self.cols) do
		if col.visible then
			w = w + col.w
		end
	end
	return w
end

function grid:col_x(j)
	local x = 0
	for j = 1, j-1 do
		local col = self.cols[j]
		if col.visible then
			x = x + col.w
		end
	end
	return x
end

function grid:rows_h()
	return self.row_count * self.default_row_h
end

function grid:row_h(i)
	return self.default_row_h
end

function grid:row_y(i)
	return self.default_row_h * (i - 1)
end

function grid:visible_rows()
	local offset = self.vscrollbar.offset
	local i1 = math.floor(offset / self.default_row_h) + 1
	local i2 = math.ceil((offset + self.ch) / self.default_row_h)
	return i1, i2
end

function grid:visible_cols()
	local x1 = self.hscrollbar.offset
	local x2 = x1 + self.cw
	local j1, j2
	local w = 0
	for j, col in ipairs(self.cols) do
		if col.visible then
			w = w + col.w
			if not j1 and w > x1 then
				j1 = j
			end
			if w >= x2 then
				j2 = j
				break
			end
		end
	end
	return j1, j2 or #self.cols
end

function grid:cell_value(i, j)
	return i .. ', ' .. j
end

function grid:_sync_scrollbars()
	local vs = self.vscrollbar
	local hs = self.hscrollbar
	vs.x = self.cw - vs.h
	vs.w = self.ch
	vs.view_size = vs.w
	vs.content_size = self:rows_h()
	--[[
	hs.y = vy + vh + (hs.autohide and -hs.h or 0)
	hs.x = vx + mw
	hs.w = vw - mw - vs.h
	hs.view_size = vw - mw
	hs.content_size = cw + view.cursor_xoffset + view.cursor_thickness
	]]
end

function grid:draw_cell(x, y, w, h, i, j)
	local col = self.cols[j]
	local val = self:cell_value(i, j)
	self:setfont(
		col.font_family,
		col.font_weight,
		col.font_slant,
		col.text_size,
		col.text_color,
		col.line_spacing)
	self.window:textbox(x, y, w, h, val,
		col.text_align or self.text_align,
		col.text_valign or self.text_valign)
end

function grid:draw_row(x, y, h, i, j1, j2)
	for j = j1, j2 do
		local col = self.cols[j]
		local w = col.w
		self:draw_cell(x, y, w, h, i, j)
		x = x + w
	end
end

function grid:before_draw_content()
	self:_sync_scrollbars()
	local i1, i2 = self:visible_rows()
	local j1, j2 = self:visible_cols()
	if not j1 then return end --no visible cols
	local x = self:col_x(j1) - self.hscrollbar.offset
	local y = self:row_y(i1) - self.vscrollbar.offset
	for i = i1, i2 do
		local h = self:row_h(i)
		self:draw_row(x, y, h, i, j1, j2)
		y = y + h
	end
end


if not ... then require('ui_demo')(function(ui, win)

	local g = ui:grid{
		x = 10,
		y = 10,
		w = 500,
		h = 300,
		row_count = 1e6,
		parent = win,
		background_color = '#111',
		cols = {{name = 'col1'}, {name = 'col2'}},
	}

end) end
