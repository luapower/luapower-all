
--Pop-up Window.
--Written by Cosmin Apreutesei. Public Domain.

local ui = require'ui'
local glue = require'glue'

local popup = ui.window:subclass'popup'
ui.popup = popup

popup.w = 200
popup.h = 200
popup.frame = false
popup.activable = false
popup.closeable = false
popup.moveable = false
popup.resizeable = false
popup.maximizable = false
popup.fullscreenable = false
popup.topmost = true

--autohide property: hide when clicking outside of the popup

popup.autohide = true

function popup:mousedown_autohide(win, button, mx, my)
	self:hide()
end

function popup:window_deactivated_autohide(win)
	self:hide()
end

function popup:after_set_parent(parent)
	parent.window:on({'deactivated', self}, function(win)
		if self.ui and self.autohide and self.visible then
			self:window_deactivated_autohide(win)
		end
	end)
	parent.window:on({'mousedown', self}, function(win, button, mx, my)
		if self.ui and self.autohide and self.visible then
			self:mousedown_autohide(button, mx, my)
			--TODO: find out why this needs to be async.
			self.ui:runafter(0, function()
				parent:invalidate()
			end)
		end
	end)
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
