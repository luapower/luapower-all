
--Progress Bar widget.
--Written by Cosmin Apreutesei. Public Domain.

local ui = require'ui'

local progressbar = ui.layer:subclass'progressbar'
ui.progressbar = progressbar
progressbar.iswidget = true

--progressbar.layout = 'textbox'
progressbar.h = 24
progressbar.text_operator = 'xor'
progressbar.border_width = 1
progressbar.border_color = '#333'

function progressbar:format_text(progress)
	return string.format('%d%%', progress * 100)
end

function progressbar:after_sync()
	self.text = self:format_text(self.progress)
end

local bar = ui.layer:subclass'progressbar_bar'
progressbar.bar_class = bar

bar.background_color = '#fff'

function progressbar:create_bar()
	return self.bar_class(self.ui, {
		parent = self,
		iswidget = false,
		progressbar = self,
	}, self.bar)
end

function bar:after_sync()
	local pb = self.progressbar
	self.h = pb.ch
	self.w = pb.cw * pb.progress
end

function progressbar:after_init()
	self.bar = self:create_bar()
end

if not ... then require('ui_demo')(function(ui, win)

	local b1 = ui:progressbar{
		parent = win,
		x = 100, y = 100, w = 200,
		progress = .48,
		text_color = '#f0f',
		bar = {
			background_color = '#ff0',
		},
	}

end) end
