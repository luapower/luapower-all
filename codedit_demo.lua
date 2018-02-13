local player = require'cplayer'
local glue = require'glue'
local pp = require'pp'
local str = require'codedit'.str
local boxlayout = require'cplayer.boxlayout'

local editors = {}
local loaded

local root_dir = 'x:/luapower/'

local font_files = {
	root_dir .. '/media/fonts/FSEX300.ttf',
	root_dir .. '/media/fonts/DejaVuSerif.ttf',
}

filename = root_dir .. '/codedt_demo.lua'
--text = '\tx\ty\tz\n\ta\tb'
--text = '    x   y   z\r\n    a   b\n\tc\td'
--text = glue.readfile'c:/temp.c'
--text = glue.readfile'c:/temp2.c'
text = glue.readfile(root_dir .. 'codedit.lua')
--text = 'abcd\nefgh'

player.show_magnifier = false

player.y = 300

function player:on_render(cr)

	if self.window.w ~= 800 then
		--self.window.w = 800
		--return
	end

	local editor_y = 40

	local n = 2
	local nav_w = 120

	self.layout.default_w = nav_w
	self.layout.default_h = 22

	for i = 1, n do
		local w = math.floor(self.w / n)
		local h = self.h - editor_y - 20
		local x = (i - 1) * w + 20
		self.layout:push(x, 0)

		local created = editors[i] and true or false
		local editor = editors[i] or {
			id = 'code_editor_' .. i,
			filename = filename,
			view = {
				x = x, y = editor_y, w = w, h = h,
				eol_markers = false, minimap = false, line_numbers = false,
				_font_file = font_files[1],
				_font_size = 16,
			},
			text = text,
		}

		editor = self:code_editor(editor)

		if not created then
			editors[i] = editor
			editor.view.tabsize = 4
			editor.cursor.restrict_eol = false
			editor.cursor.restrict_eof = false
			editor.cursor.land_bof = false
			editor.cursor.land_eof = false
		end

		editor.view.x = nav_w + 10 + x
		editor.view.y = editor_y
		editor.view.w = w - nav_w - 40
		editor.view.h = h

		local s = editor.selection:isempty()
			and editor.cursor.line .. ' : ' .. editor.cursor.i
			or editor.selection.line1 .. ' : ' ..editor.selection.i1 .. ' - ' ..
				editor.selection.line2 .. ' : ' ..editor.selection.i2
		self:label{y = 10, text = s}

		local s = editor.cursor.line <= #editor.buffer.lines
			and editor.buffer.lines[editor.cursor.line] or ''
		local i1 = editor.cursor.i
		local eol = i1 >= (editor.buffer:eol(editor.cursor.line) or 1)
		local i2 = not eol and str.next_char(s, i1) or #s + 1
		local s = s:sub(i1, i2 - 1)
		local s = pp.format(s):sub(2, -2)
		self:label{x = 100, y = 10, text = s}

		self:label{y = 24, text = editor.cursor.x, w = 0, h = 26}

		self.layout:move(0, 40, 'vert')

		self.layout:push(0, 0, 'h', nav_w / 3)

		editor.cursor.restrict_eol = self:togglebutton{
			id = 'restrict_eol' .. i,
			text = 'restrict_eol', selected = editor.cursor.restrict_eol,
		}

		editor.cursor.restrict_eof = self:togglebutton{
			id = 'restrict_eof' .. i,
			text = 'restrict_eof', selected = editor.cursor.restrict_eof,
		}

		editor.cursor.land_bof = self:togglebutton{
			id = 'land_bof' .. i,
			text = 'land_bof', selected = editor.cursor.land_bof,
		}

		self.layout:pop()

		editor.cursor.land_eof = self:togglebutton{
			id = 'land_eof' .. i,
			text = 'land_eof', selected = editor.cursor.land_eof,
		}

		self:label{text = 'jump_tabstops'}
		editor.cursor.jump_tabstops = self:mbutton{
			id = 'jump_tabstops' .. i,
			values = {'always', 'indent', 'never'}, selected = editor.cursor.jump_tabstops,
		}

		self:label{text = 'delete_tabstops'}
		editor.cursor.delete_tabstops = self:mbutton{
			id = 'delete_tabstops' .. i,
			values = {'always', 'indent', 'never'}, selected = editor.cursor.delete_tabstops,
		}

		self:label{text = 'insert_tabs'}
		editor.cursor.insert_tabs = self:mbutton{
			id = 'insert_tabs' .. i,
			values = {'always', 'indent', 'never'}, selected = editor.cursor.insert_tabs,
		}

		local font_file1 = editor.view:font_file()
		local font_file = self:mbutton{
			id = 'font_file' .. i,
			values = font_files,
			texts = {'Fixedsys', 'DejaVuSerif'},
			selected = editor.view:font_file(),
		}
		if font_file ~= font_file1 then
			editor.view:font_file(font_file)
		end

		editor.view.tabsize = self:slider{
			text = 'tabsize',
			id = 'tabsize' .. i,
			i0 = 1, i1 = 16, i = editor.view.tabsize,
		}

		local font_size1 = editor.view:font_size()
		local font_size = self:slider{
			text = 'fontsize',
			id = 'fontsize' .. i,
			i0 = 6, i1 = 32, i = editor.view:font_size(),
		}
		if font_size ~= font_size1 then
			editor.view:font_size(font_size)
		end

		editor.view.lang = self:mbutton{
			id = 'lexer_' .. i,
			x = x + 200 + nav_w, y = 10, w = 180, values = {'none', 'cpp', 'lua'},
			selected = editor.view.lang or 'none',
		}
		editor.view.lang = editor.view.lang ~= 'none' and editor.view.lang or nil

		editor.eol_markers = self:togglebutton{id = 'eol_markers'..i,
			text = 'eol_markers',
			selected = editor.eol_markers}

		local s = editor.buffer.undo_group
			and (editor.buffer.undo_group.type .. '\n\n') or ''
		for i,g in ipairs(editor.buffer.undo_stack) do
			s = s .. g.type .. '\n'
		end
		self:label{font_face = 'Fixedsys', text = s}

		self.layout:pop()
	end

	--[[
	v.linesize = self:slider{id = 'linesize', x = 10, y = 40, w = 80, h = 24, i0 = 10, i1 = 30, i = v.linesize}
	b.line_terminator = self:mbutton{id = 'term', x = 10, y = 70, w = 80, h = 24,
		values = {'\r\n', '\r', '\n'}, texts = {['\r\n'] = 'CRLF', ['\n'] = 'LF', ['\r'] = 'CR'},
		selected = b.line_terminator}
	]]

end

player:play()

