
--Linear Zoom Calendar widget.
--Written by Cosmin Apreutesei. Public Domain.

local ui = require'ui0'
local glue = require'glue'
local lerp = glue.lerp
local clamp = glue.clamp

local cal = ui.layer:subclass'zoomcalendar'
ui.zoomcalendar = cal

cal.background_color = '#111'

function cal:before_draw_content(cr)
	cr:save()
	cr:scale(1)

	cr:restore()
end

--demo -----------------------------------------------------------------------

if not ... then require('ui0_demo')(function(ui, win)

	local cal = ui:zoomcalendar{
		x = 20, y = 20,
		w = 400, h = 100,
		parent = win,
	}

end) end

