
--ui button widget.
--Written by Cosmin Apreutesei. Public Domain.

local ui = require'ui'

ui.button = ui.layer:subclass'button'

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

function ui.button:mousedown(button, x, y)
	if button == 'left' then
		self.active = true
	end
end

function ui.button:mouseup(button, x, y)
	if button == 'left' then
		self.active = false
	end
end

function ui.button:before_draw_content()
	if self.text then
		self.window:textbox(0, 0, self.w, self.h, self.text,
			self.font_family, self.font_weight, self.font_slant, self.text_size,
			self.line_spacing, self.text_color, 'center', 'center')
	end
end

--demo -----------------------------------------------------------------------

if not ... then require('ui_demo')(function(ui, win)

	--TOOD:

end) end
