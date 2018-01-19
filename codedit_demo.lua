local codedit = require'codedit'
local cursor = require'codedit_cursor'
local player = require'cplayer'
local glue = require'glue'
local str = require'codedit_str'
local pp = require'pp'

local editors = {}
local loaded

filename = 'x:/work/luapower/codedt_demo.lua'
--text = glue.readfile'c:/temp.c'
--text = glue.readfile'c:/temp2.c'

player.show_magnifier = false

player.y = 300

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

		local created = editors[i] and true or false
		local editor = editors[i] or {
			id = 'code_editor_' .. i,
			filename = filename,
			view = {
				x = x, y = editor_y, w = w, h = h,
				eol_markers = false, minimap = false, line_numbers = false,
				--font_file = 'media/fonts/FSEX300.ttf',
				font_file = 'media/fonts/DejaVuSerif.ttf',
			},
			--text = '\tx\ty\tz\n\ta\tb',
			text = '   x  y  z\r\n   a   b\n\tc\td',
		}

		local nav_w = 120

		editor = self:code_editor(editor)
		editor.view.x = nav_w + 10 + x
		editor.view.y = editor_y
		editor.view.w = w
		editor.view.h = h

		if not created then
			editor.cursor.restrict_eol = false
			editor.cursor.restrict_eof = false
			editor.cursor.land_bof = false
			editor.cursor.land_eof = false
		end

		local s = editor.selection:isempty()
			and editor.cursor.line .. ' : ' .. editor.cursor.i
			or editor.selection.line1 .. ' : ' ..editor.selection.i1 .. ' - ' ..
				editor.selection.line2 .. ' : ' ..editor.selection.i2
		self:label{x = x, y = 10, text = s}

		local s = editor.cursor.line <= #editor.buffer.lines
			and editor.buffer.lines[editor.cursor.line] or ''
		local i1 = editor.cursor.i
		local eol = i1 >= (editor.buffer:eol(editor.cursor.line) or 1)
		local i2 = not eol and str.next_char(s, i1) or #s + 1
		local s = s:sub(i1, i2 - 1)
		local s = pp.format(s):sub(2, -2)
		self:label{x = x + 100, y = 10, text = s}

		cursor.restrict_eol = self:togglebutton{
			id = 'restrict_eol' .. i, x = x, y = 40, w = nav_w, h = 26,
			text = 'restrict_eol', selected = cursor.restrict_eol,
		}

		editor.cursor.restrict_eof = self:togglebutton{
			id = 'restrict_eof' .. i, x = x, y = 70, w = nav_w, h = 26,
			text = 'restrict_eof', selected = editor.cursor.restrict_eof,
		}

		editor.cursor.land_bof = self:togglebutton{
			id = 'land_bof' .. i, x = x, y = 100, w = nav_w, h = 26,
			text = 'land_bof', selected = editor.cursor.land_bof,
		}

		editor.cursor.land_eof = self:togglebutton{
			id = 'land_eof' .. i, x = x, y = 130, w = nav_w, h = 26,
			text = 'land_eof', selected = editor.cursor.land_eof,
		}

		self:label{x = x, y = 165, text = 'jump_tabstops'}
		editor.cursor.jump_tabstops = self:mbutton{
			id = 'jump_tabstops' .. i, x = x, y = 180, w = nav_w, h = 26,
			values = {'always', 'indent', 'never'}, selected = editor.cursor.jump_tabstops,
		}

		self:label{x = x, y = 215, text = 'delete_tabstops'}
		editor.cursor.delete_tabstops = self:mbutton{
			id = 'delete_tabstops' .. i, x = x, y = 230, w = nav_w, h = 26,
			values = {'always', 'indent', 'never'}, selected = editor.cursor.delete_tabstops,
		}

		self:label{x = x, y = 265, text = 'insert_tabs'}
		editor.cursor.insert_tabs = self:mbutton{
			id = 'insert_tabs' .. i, x = x, y = 280, w = nav_w, h = 26,
			values = {'always', 'indent', 'never'}, selected = editor.cursor.insert_tabs,
		}

		editor.view.font_file = self:mbutton{
			id = 'font' .. i, x = x, y = 320, w = nav_w, h = 26,
			values = {
				'media/fonts/FSEX300.ttf',
				'media/fonts/DejaVuSerif.ttf',
			},
			texts = {'Fixedsys', 'DejaVuSerif'},
			selected = editor.view.font_file,
		}

		local tabsize1 = editor.view.tabsize
		editor.view.tabsize = self:slider{
			text = 'tabsize',
			id = 'tabsize' .. i, x = x, y = 400, w = nav_w, h = 26,
			i0 = 1, i1 = 16, i = editor.view.tabsize,
		}
		if tabsize1 ~= editor.view.tabsize then
			editor.view:font_changed()
		end

		editor.view.lang = self:mbutton{
			id = 'lexer_' .. i,
			x = x + 200 + nav_w, y = 10, w = 180, h = 26, values = {'none', 'cpp', 'lua'},
			selected = editor.view.lang or 'none',
		}
		editor.view.lang = editor.view.lang ~= 'none' and editor.view.lang or nil

		editors[i] = editor

		local s = editor.buffer.undo_group and (editor.buffer.undo_group.type .. '\n\n') or ''
		for i,g in ipairs(editor.buffer.undo_stack) do
			s = s .. g.type .. '\n'
		end
		self:label{x = self.w - 500, y = 40, font_face = 'Fixedsys', text = s}
	end

	--[[
	v.linesize = self:slider{id = 'linesize', x = 10, y = 40, w = 80, h = 24, i0 = 10, i1 = 30, i = v.linesize}
	b.line_terminator = self:mbutton{id = 'term', x = 10, y = 70, w = 80, h = 24,
		values = {'\r\n', '\r', '\n'}, texts = {['\r\n'] = 'CRLF', ['\n'] = 'LF', ['\r'] = 'CR'},
		selected = b.line_terminator}
	v.eol_markers = self:togglebutton{id = 'eol markers', x = 10, y = 100, w = 80, h = 24, selected = v.eol_markers}
	]]

end

player:play()

