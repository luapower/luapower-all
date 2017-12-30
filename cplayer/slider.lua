local player = require'cplayer'
local cairo = require'cairo'

local function clamp(i, i0, i1)
	return math.min(math.max(i, i0), i1)
end

local function lerp(x, x0, x1, y0, y1)
	return y0 + (x-x0) * ((y1-y0) / (x1 - x0))
end

local function snap(i, step)
	return math.floor(i / step) * step
end

function player:slider(t)
	local id = assert(t.id, 'id missing')
	local x, y, w, h = self:getbox(t)
	local text = t.text or id

	local i0, i1, step = t.i0 or 0, t.i1 or 100, t.step or 1
	local i = t.i or i0

	local hot = self:hotbox(x, y, w, h)

	if hot and (not self.active or self.active == id) then
		self.cursor = 'resize_horizontal'
	end

	if not self.active and self.lbutton and hot then
		self.active = id
	elseif self.active == id then
		if self.lbutton then
			local w1 = clamp(self.mousex - x, 0, w)
			i = lerp(w1, 0, w, i0, i1)
		else
			self.active = nil
		end
	end
	i = snap(i, step)
	i = clamp(i, i0, i1)

	local w1 = lerp(i, i0, i1, 0, w)
	text =
		t.pos_text and t.pos_text(i)
		or (text and (text .. ': ') or '') .. tostring(i)

	--drawing
	self:rect(x + 0.5, y + 0.5, w - 1, h - 1, 'faint_bg', 'normal_border')
	self:rect(x, y, w1, h, 'selected_bg')

	self.cr:save()
	self.cr:operator'difference'
	self:textbox(x, y, w, h, text, t.font, '#ffffff', 'center', 'center')
	self.cr:restore()

	return i
end

if not ... then require'cplayer.widgets_demo' end
