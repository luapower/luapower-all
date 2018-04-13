
--ui button widget.
--Written by Cosmin Apreutesei. Public Domain.

local ui = require'ui'

ui.button = ui.layer:subclass'button'
ui.button.isbutton = true
ui.button.focusable = true

ui.button.background_color = '#444'
ui.button.border_color = '#888'
ui.button.border_width = 1

ui:style('button', {
	transition_background_color = true,
	transition_border_color = true,
	transition_duration = .5,
	transition_ease = 'expo out',
})

ui:style('button hot', {
	background_color = '#ccc',
	border_color = '#ccc',
	text_color = '#000',
})

ui:style('button active', {
	background_color = '#fff',
	border_color = '#fff',
	text_color = '#000',
	transition_duration = 0.2,
})

ui:style('button focused', {
	border_color = '#fff',
	shadow_blur = 3,
	shadow_color = '#666',
})

function ui.button:mousedown()
	self.active = true
end

function ui.button:mouseup()
	self.active = false
end

--demo -----------------------------------------------------------------------

if not ... then require('ui_demo')(function(ui, win)

	local b1 = ui:button{
		parent = win,
		x = 100, y = 100, w = 100, h = 26,
		text = 'OK',
	}

	local b2 = ui:button{
		parent = win,
		x = 100, y = 150, w = 100, h = 26,
		text = 'OK',
	}

end) end
