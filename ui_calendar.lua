
--Calendar widget.
--Written by Cosmin Apreutesei. Public Domain.

local ui = require'ui'
local glue = require'glue'
local push = table.insert

ui = ui()
local calendar = ui.grid:subclass'calendar'
ui.calendar = calendar

calendar.col_resize = false
calendar.col_move = false
calendar.cell_select = true

function calendar:get_time()
	return self._time
end

local function month(time)
	local t = os.date('*t', time)
	local t0 = os.time(glue.merge({day = 1, hour = 0, min = 0, sec = 0}, t))
	local t1 = os.time(glue.merge({day = 1, hour = 0, min = 0, sec = 0, month = t.month + 1}, t)) - 1
	local t0 = os.date('*t', t0)
	local t1 = os.date('*t', t1)
	t0.days = t1.day
	t0.today = t.day
	return t0
end

ui:style('grid_cell :current_month', {
	background_color = '#111',
})

ui:style('grid_cell :today', {
	background_color = '#260',
})

function calendar:sync_cell(cell, i, col, val)
	if not val then
		val = ''
	else
		cell:settag('today', val.today)
		cell:settag('current_month', val.current_month)
		val = val.day
	end
	cell:sync_value(i, col, val)
end

function calendar:set_time(time)
	self._time = time
	self.rows = {}
	local t = month(time)
	local wday = t.wday
	local week = 1
	local row = {}
	push(self.rows, row)
	for wday = 1, wday - 1 do
		push(row, {current_month = false, day = 'x'})
	end
	for day = 1, t.days do
		push(row, {current_month = true, day = day, today = day == t.today})
		wday = wday + 1
		if wday > 7 then
			wday = 1
			week = week + 1
			row = {}
			push(self.rows, row)
		end
	end
	for wday = wday, 7 do
		push(row, {current_month = false, day = 'y'})
	end
end

ui.weekdays_short = ui.weekdays_short
	or {'Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'}

function calendar:before_init()
	self.cols = {}
	for i = 1, 7 do
		push(self.cols, {
			text = ui.weekdays_short[i],
			text_align_x = 'center',
		})
	end
end

function calendar:after_sync()
	local w = math.floor(self.cw / 7)
	for i = 1, 7 do
		self.cols[i].w = w
	end
	self.row_h = math.floor(self.scroll_pane.rows_pane.rows_layer.ch / self.row_count)
end


--demo -----------------------------------------------------------------------

if not ... then require('ui_demo')(function(ui, win)

	local c = ui:calendar{
		x = 10, y = 10,
		w = 7 * 30, h = 6 * 30,
		parent = win,
		time = os.time(),
	}

end) end
