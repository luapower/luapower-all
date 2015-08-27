--codedit blame info margin
local margin = require'codedit_margin'
local glue = require'glue'
local str = require'codedit_str'

--TODO: synchronize the blame list with buffer:insert_line() / buffer:remove_line() / buffer:setline() operations
--TODO: request blame info again after each file save

local blame_margin = glue.update({
	blame_command = 'hg blame -u "%s"',
}, margin)

function blame_margin:get_blame_info(filename)
	self.blame_info = {}
	self.w = 0

	local cmd = string.format(self.blame_command, filename)
	local f = io.popen(cmd)
	local s = f:read('*a')
	for _,line in str.lines(s) do
		local user = line:match('([^%:]+)%:') or ''
		self.w = math.max(self.w, str.len(user))
		table.insert(self.blame_info, user)
	end
	f:close()
	self.w = self.w * self.view.char_w
end

function blame_margin:draw_line(line, cx, cy, cw, ch, highlighted)
	if self.view.buffer.changed.blame_info then
		self.blame_info = nil
	end
	if not self.blame_info and self.view.buffer.filename then
		self:get_blame_info(self.view.buffer.filename)
		self.view.buffer.changed.blame_info = false
	end
	if not self.blame_info then return end
	local color = self.text_color or 'blame_text'
	local s = self.blame_info[line] or ''
	self.view:draw_text(cx, cy, s, color)
end

if not ... then require'codedit_demo' end

return blame_margin
