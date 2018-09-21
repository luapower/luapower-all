
--UI Layout Editor widgets.
--Written by Cosmin Apreutesei.

local ui = require'ui'

--direct manipulation widget editor

local editor = ui.layer:subclass'editor'
ui.editor = editor

function editor:after_init()
	function self.ui.window.after_init(win)
		self:wrap_window(win)
	end
end

function editor:wrap_window(win)
	function win.override_draw(win, inherited, cr)
		inherited(win, cr)
		self:draw(cr)
	end
end

editor.background_color = '#3338'

function editor:after_sync()
	if not self.parent then return end
	local win = self.parent.window
	print'here'
	--stretch to entire window
	self.w = win.cw
	self.h = win.ch
end

function editor:before_draw()

end

return editor
