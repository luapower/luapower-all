local codedit = require'codedit'
local player = require'cplayer'
local glue = require'glue'

local editors = {}
local loaded

filename = 'x:/work/luapower/codedt_demo.lua'
--text = glue.readfile'c:/temp.c'
--text = glue.readfile'c:/temp2.c'

player.show_magnifier = false

function player:on_render(cr)

	if self.window.w ~= 800 then
		--self.window.w = 800
		--return
	end

	local editor_y = 40
	for i = 1, 1 do
		local w = math.floor(self.w / 1)
		local h = self.h - editor_y - 20
		local x = (i - 1) * w + 20

		local editor = editors[i] or {
								id = 'code_editor_' .. i,
								filename = filename,
								view = {
									x = x, y = editor_y, w = w, h = h,
									eol_markers = false, minimap = false, line_numbers = false,
									font_file = 'media/fonts/FSEX300.ttf'
								}}

		editor = self:code_editor(editor)
		editor.view.x = x
		editor.view.y = editor_y
		editor.view.w = w
		editor.view.h = h
		codedit.cursor.restrict_eof = true
		codedit.cursor.restrict_eol = true
		codedit.cursor.land_bof = false
		codedit.cursor.land_eof = false

		editor.view.lang = self:mbutton{
			id = 'lexer_' .. i,
			x = x, y = 10, w = 180, h = 26, values = {'none', 'cpp', 'lua'}, selected = editor.view.lang or 'none'}
		editor.view.lang = editor.view.lang ~= 'none' and editor.view.lang or nil

		editors[i] = editor

		local s = editor.buffer.undo_group and (editor.buffer.undo_group.type .. '\n\n') or ''
		for i,g in ipairs(editor.buffer.undo_stack) do
			s = s .. g.type .. '\n'
		end
		self:label{x = self.w - 500, y = 40, font_face = 'Fixedsys', text = s}
	end

	--[[
	v.tabsize = self:slider{id = 'tabsize', x = 10, y = 10, w = 80, h = 24, i0 = 1, i1 = 8, i = v.tabsize}
	v.linesize = self:slider{id = 'linesize', x = 10, y = 40, w = 80, h = 24, i0 = 10, i1 = 30, i = v.linesize}
	b.line_terminator = self:mbutton{id = 'term', x = 10, y = 70, w = 80, h = 24,
		values = {'\r\n', '\r', '\n'}, texts = {['\r\n'] = 'CRLF', ['\n'] = 'LF', ['\r'] = 'CR'},
		selected = b.line_terminator}
	v.eol_markers = self:togglebutton{id = 'eol markers', x = 10, y = 100, w = 80, h = 24, selected = v.eol_markers}
	]]

end

player:play()

