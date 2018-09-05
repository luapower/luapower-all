
--Pop-up Window.
--Written by Cosmin Apreutesei. Public Domain.

local ui = require'ui'
local glue = require'glue'

local popup = ui.window:subclass'popup'
ui.popup = popup

popup.frame = false
popup.activable = false
popup.closeable = false
popup.moveable = false
popup.resizeable = false
popup.maximizable = false
popup.fullscreenable = false
popup.topmost = true

popup.autohide = true --hide when clicking outside of the popup

function popup:after_init()
	local function hide()
		if self.ui and self.autohide then
			self:hide()
		end
	end
	self.ui:on({'window_deactivated', self}, hide)
	self.ui:on({'window_mousedown', self}, hide)
end

if not ... then require('ui_demo')(function(ui, win)

	ui:style('window_view :hot', {
		background_color = '#fff',
		transition_background_color = true,
		transition_duration = 1,
	})

	ui:style('popup > window_view :hot', {
		background_color = '#ff0',
		transition_background_color = true,
		transition_duration = 1,
	})

	local popup = ui:popup{
		x = 10, y = 10,
		w = 300,
		h = 600,
		parent = win,
	}
	--function win:mousemove(mx, my)    print('win  ', 'move', mx, my) end
	--function popup:mousemove(mx, my)  print('popup', 'move', mx, my) end
	--function win:mouseleave()         print('win  ', 'leave') end
	--function popup:mouseleave()       print('popup', 'leave') end
	--function win:mouseenter(mx, my)   print('win  ', 'enter', mx, my) end
	--function popup:mouseenter(mx, my) print('popup', 'enter', mx, my) end

end) end
