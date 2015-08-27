local player = require'cplayer'
local glue = require'glue'

function player:label(t)
	local x = assert(t.x, 'x missing')
	local y = assert(t.y, 'y missing')
	local w = t.w or 1000
	local h = t.h or 1000
	local text = assert(t.text, 'text missing')
	local font_size = t.font_size or 12
	local font_face = t.font_face or 'Arial'
	local line_size = font_size * 1.5
	local halign = t.halign or 'left'
	local valign = t.valign or 'top'
	local color = t.color or 'normal_fg'

	local cr = self.cr
	cr:select_font_face(font_face, 0, 0)
	cr:set_font_size(font_size)
	self:setcolor(color)

	local extents = cr:text_extents(text)
	x =
		halign == 'center' and (2 * x + w - extents.width) / 2 or
		halign == 'left'   and x or
		halign == 'right'  and x + w - extents.width or
		error'invalid valign'

	y =
		valign == 'center' and (2 * y + h - extents.y_bearing) / 2 or
		valign == 'top'    and y + extents.height or
		valign == 'bottom' and y + h or
		error'invalid valign'

	for text in glue.gsplit(text, '\n') do
		--TODO: align bottom with multiline text
		cr:move_to(x, y)
		cr:show_text(text)
		y = y + line_size
	end
end

