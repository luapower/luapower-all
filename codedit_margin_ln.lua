--codedit line numbers margin
local margin = require'codedit_margin'
local glue = require'glue'

local ln_margin = glue.update({}, margin)

local function digits(n) --number of base-10 digits of a number
	return math.floor(math.log10(n) + 1)
end

function ln_margin:get_width()
	return (digits(#self.buffer.lines) + 2) * self.view.char_w
end

function ln_margin:draw_line(line, cx, cy, cw, ch, highlighted)
	if highlighted then
		local color = self.highlighted_background_color or 'line_number_highlighted_background'
		self.view:draw_rect(cx, cy, cw, ch, color)
	end

	local color = self.line_number_separator_color or 'line_number_separator'
	self.view:draw_rect(cx + cw - 1, cy, 1, ch, color)

	local s = tostring(line)
	cx = cx + cw - (#s + 1) * self.view.char_w
	local color = highlighted and
							(self.highlighted_text_color or 'line_number_highlighted_text') or
							(self.text_color or 'line_number_text')
	self.view:draw_text(cx, cy, s, color)
end

if not ... then require'codedit_demo' end

return ln_margin
