--codedit margin base object (by itself can be used as a spacer margin).
local glue = require'glue'

local margin = {
	w = 50,
	--view overrides
	text_color = nil,
	background_color = nil,
	highlighted_text_color = nil,
	highlighted_background_color = nil,
}

function margin:new(buffer, view, t, pos)
	self = glue.inherit(t or {
		buffer = buffer,
		view = view,
	}, self)
	self.view:add_margin(self)
	return self
end

function margin:get_width()
	return self.w
end

function margin:draw_line(line, x, y, w) end --stub

function margin:hit_test(x, y)
	return self.view:margin_hit_test(self, x, y)
end

return margin

