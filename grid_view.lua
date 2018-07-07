--grid view class
local glue = require'glue'

local view = {}

function view:new(t, grid)
	self = glue.inherit(t, self)
	self.grid = grid
	return self
end

function view:client_size()

end

function view:margins_width()

end

function view:draw_scrollbox(x, y, w, h, cx, cy, cw, ch)
	return cx, cy, x, y, w, h
end

function view:render()

	local client_w, client_h = self:client_size()
	local margins_w = self:margins_width()

	self.scroll_x, self.scroll_y, self.clip_x, self.clip_y, self.clip_w, self.clip_h =
		self:draw_scrollbox(
			self.x + margins_w,
			self.y,
			self.w - margins_w,
			self.h,
			self.scroll_x, self.scroll_y, client_w, client_h)

	for i,margin in ipairs(self.margins) do
		self:draw_margin(margin)
	end
	self:draw_client()
end

return view
