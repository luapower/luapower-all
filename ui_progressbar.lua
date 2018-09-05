
--Progress Bar widget.
--Written by Cosmin Apreutesei. Public Domain.

local ui = require'ui'

local progressbar = ui.layer:subclass'progressbar'
ui.progressbar = progressbar

progressbar.border_width = 1
progressbar.border_color = '#333'
progressbar.h = 26

local bar = ui.layer:subclass'progressbar_bar'
progressbar.bar_class = bar

bar.background_color = '#fff'

function progressbar:create_bar()
	return self.bar_class(self.ui, {
		parent = self,
		progressbar = self,
	}, self.bar)
end

function bar:sync()
	local pb = self.progressbar
	self.h = pb.ch
	self.w = pb.cw * pb.progress
end

function progressbar:format_text(progress)
	return string.format('%d%%', progress * 100)
end

function progressbar:after_init()
	self.bar = self:create_bar()
	self.text = self:format_text(self.progress)
end

function progressbar:before_draw()
	self.bar:sync()
end

if not ... then require('ui_demo')(function(ui, win)

	local b1 = ui:progressbar{
		parent = win,
		x = 100, y = 100, w = 200,
		progress = .49,
		text_operator = 'xor',
		text_color = '#ff0',
		bar = {
			background_color = '#ff0',
		},
	}

end) end
