--TODO: assumes char size = 1 byte; make it work with arbitrary utf-8 strings
local player = require'cplayer'
local ffi = require'ffi'

local function find_caret_pos(cr, text, target_x)
	local extents = ffi.new'cairo_text_extents_t'
	local last_x = 0
	for i=1,#text do
		local x = cr:text_extents(text:sub(1, i) .. '\0', extents).width
		if target_x >= last_x and target_x <= x then
			return i - (target_x - last_x < x - target_x and 1 or 0)
		end
		last_x = x
	end
	return #text
end

function player:editbox(t)
	local id = assert(t.id, 'id missing')
	local x, y, w, h = self:getbox(t)
	local text = t.text
	local caret_w = t.caret_w or 2
	local font = t.font
	local down = self.lbutton
	local cr = self.cr
	local readonly = t.readonly

	local hot = self:hotbox(x, y, w, h)

	if hot and not self.active or self.active == id then
		self.cursor = 'text'
	end

	local text_x = 0
	local caret_pos
	if (not self.focused and ((hot and down and not self.active) or not self.ui.activate or self.ui.activate == id)) then
		self.focused = id
		self.ui.activation_clock = self.clock
		self.ui.focus_tab = nil
		self.ui.text_x = 0
		caret_pos = find_caret_pos(cr, text, self.mousex - x)
	elseif self.focused == id then
		if down and not hot and not self.active then
			self.focused = nil
		elseif self.key == 'tab' then
			self.focused = nil
			self.ui.activate = self.shift and t.prev_tab or t.next_tab
		else
			text_x = self.ui.text_x
			caret_pos = self.ui.caret_pos
		end
	end

	if hot and down and not self.active and self.focused == id then
		caret_pos = find_caret_pos(cr, text, self.mousex - x - text_x)
	end

	local min_view = 4
	local caret_x
	if caret_pos then
		if self.key == 'left' then
			if self.ctrl then
				local pos = text:sub(1, math.max(0, caret_pos - 1)):find('%s[^%s]*$') or 0
				caret_pos = math.max(0, pos)
			else
				caret_pos = math.max(0, caret_pos - 1)
			end
		elseif self.key == 'right' then
			if self.ctrl then
				local pos = text:find('%s', caret_pos + 1) or #text
				caret_pos = math.min(#text, pos)
			else
				caret_pos = math.min(#text, caret_pos + 1)
			end
		elseif not readonly and self.key == 'backspace' then
			text = text:sub(1, math.max(0, caret_pos - 1)) .. text:sub(caret_pos + 1)
			caret_pos = math.max(0, caret_pos - 1)
		elseif not readonly and self.key == 'delete' then
			text = text:sub(1, caret_pos) .. text:sub(caret_pos + 2)
		elseif not readonly and self.char and string.byte(self.char) >= 32 then
			text = text:sub(1, caret_pos) .. self.char .. text:sub(caret_pos + 1)
			caret_pos = math.min(#text, caret_pos + 1)
		end

		local text_w = cr:text_extents(text).x_advance
		caret_x = cr:text_extents(text:sub(1, caret_pos) .. '\0').x_advance
		text_x = math.min(text_x, -(caret_x + caret_w - w))
		text_x = math.max(text_x, -caret_x)

		self.ui.text_x = text_x
		self.ui.caret_pos = caret_pos
	end

	--drawing
	self:rect(x + 0.5, y + 0.5, w - 1, h - 1, 'normal_bg', 'normal_border')
	self.cr:rectangle(x, y, w, h)
	self.cr:save()
	self.cr:clip()
	self:textbox(x + text_x, y, w, h, text, font, 'normal_fg', 'left', 'center')
	if caret_x and (self.clock - self.ui.activation_clock) % 1000 < 500 then
		self:rect(x + text_x + caret_x, y, caret_w, h, 'normal_fg')
	end
	cr:restore()

	return text
end

if not ... then require'cplayer.widgets_demo' end

