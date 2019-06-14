
--Editable flexbox widget.
--Written by Cosmin Apreutesei. Public Domain.

local ui = require'ui'
local glue = require'glue'

local list = ui.layer:subclass'list'
ui.list = list
list.iswidget = true

list.layout = 'flexbox'


if not ... then require('ui_demo')(function(ui, win)

	ui:list{
		parent = win,
		border_width = 1,
		x = 100, y = 100,
		{border_width = 1, min_cw = 100, min_ch = 100},
		{border_width = 1, min_cw = 50, min_ch = 100},
		{border_width = 1, min_cw = 100, min_ch = 100},
	}

end) end
