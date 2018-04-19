
--ui edit box widget.
--Written by Cosmin Apreutesei. Public Domain.

local ui = require'ui'
local glue = require'glue'
local codedit = require'codedit'

local editbox = ui.layer:subclass'editbox'
ui.editbox = editbox

editbox.focusable = true
editbox.scrollable = true
editbox.max_click_chain = 3 --receive doubleclick and tripleclick events
editbox.cursor_client = 'text'

local view = codedit.object(codedit.view, {
	colors = {
		background = '#080808',
		selection_background = '#999999',
		selection_text = '#333333',
		cursor = '#ffffff',
		text = '#ffffff',
		tabstop = '#111',
		margin_background = '#000000',
		line_number_text = '#66ffff',
		line_number_background = '#111111',
		line_number_highlighted_text = '#66ffff',
		line_number_highlighted_background = '#222222',
		line_number_separator = '#333333',
		line_highlight = '#222222',
		blame_text = '#444444',
		--lexer styles
		default = '#CCCCCC',
		whitespace = '#000000',
		comment = '#56CC66',
		string = '#FF3333',
		number = '#FF6666',
		keyword = '#FFFF00',
		identifier = '#FFFFFF',
		operator = '#FFFFFF',
		error = '#FF0000',
		preprocessor = '#56CC66',
		constant = '#FF3333',
		variable = '#FFFFFF',
		['function'] = '#FF6699',
		class        = '#FFFF00',
		type         = '#56CC66',
		label        = '#FFFF66',
		regex        = '#FF3333',
	},
	--extras
	eol_markers = false,
	minimap = false,
	smooth_vscroll = false,
	smooth_hscroll = false,
})

editbox.view = view

local editor = codedit.object(codedit.editor, {
	view = view,
})

editbox.editor = editor

function editbox:_sync()
	self:setfont()
	self:_sync_view()
	self:_sync_scrollbars()
end

function editbox:before_draw_content()
	self:_sync()
	self.editor:draw()
end

function view:scroll_changed(scroll_x, scroll_y)
	self.editbox.vscrollbar:transition('offset', -scroll_y)
	self.editbox.hscrollbar:transition('offset', -scroll_x)
end

function editbox:override_hit_test_content(inherited, x, y, reason)
	local widget, area = inherited(self, x, y, reason)
	if not widget then
		area = self.editor:hit_test(x, y)
		if area then
			widget = self
		end
	end
	return widget, area
end

function editor:capture_mouse(capture)
	self.editbox.active = capture
end

function editbox:mousedown(mx, my)
	self.editor:mousedown(mx, my)
	self:invalidate()
end

function editbox:mouseup(mx, my)
	self.editor:mouseup(mx, my)
	self:invalidate()
end

function editbox:mousemove(mx, my)
	self:_sync()
	self.editor:mousemove(mx, my)
	self:invalidate()
end

function editbox:click(mx, my)
	self.editor:click(mx, my)
	self:invalidate()
end

function editbox:doubleclick(mx, my)
	self.editor:doubleclick(mx, my)
	self:invalidate()
end

function editbox:tripleclick(mx, my)
	self.editor:tripleclick(mx, my)
	self:invalidate()
end

function editbox:mousewheel(delta, mx, my, area, pdelta)
	self:_sync()
	self.vscrollbar:scroll_by(delta * self.editor.view.line_h)
	self:invalidate()
end

function view:clip(x, y, w, h)
	local cr = self.editbox.window.cr
	cr:save()
	cr:new_path()
	cr:rectangle(x, y, w, h)
	cr:clip()
end

function view:end_clip()
	local cr = self.editbox.window.cr
	cr:restore()
end

function view:draw_rect(x, y, w, h, color)
	local cr = self.editbox.window.cr
	cr:rgba(self.editbox.ui:color(self.colors[color]))
	cr:new_path()
	cr:rectangle(x, y, w, h)
	cr:fill()
end

function view:char_advance_x(s, i)
	local cr = self.editbox.window.cr
	local ext = cr:text_extents(s:sub(i, i))
	return ext.x_advance
end

function view:draw_char(x, y, s, i, color)
	local cr = self.editbox.window.cr
	cr:rgba(self.editbox.ui:color(self.colors[color] or self.colors.text))
	cr:move_to(x, y)
	cr:show_text(s:sub(i, i))
end

--draw a reverse pilcrow at eol
function view:draw_eol_marker(line)
	local x, y = self:char_coords(line,
		self.buffer:visual_col(line, self.buffer:eol(line) + 1))
	local x = x + 2.5
	local y = y + self.char_baseline - self.line_h + 3.5
	local cr = self.player.cr
	cr:new_path()
	cr:move_to(x, y)
	cr:rel_line_to(0, self.line_h - 0.5)
	cr:move_to(x + 3, y)
	cr:rel_line_to(0, self.line_h - 0.5)
	cr:move_to(x - 2.5, y)
	cr:line_to(x + 3.5, y)
	self.player:stroke('#ffffff66')
	cr:arc(x + 2.5, y + 3.5, 4, - math.pi / 2 + 0.2, - 3 * math.pi / 2 - 0.2)
	cr:close_path()
	self.player:fill('#ffffff66')
	cr:fill()
end

function view:draw_eol_markers()
	if self.eol_markers then
		local line1, line2 = self:visible_lines()
		for line = line1, line2 do
			self:draw_eol_marker(line)
		end
	end
end

function view:draw_minimap()
	local cr = self.player.cr
	local mmap = glue.inherit({editor = self}, self)
	local self = mmap
	local scale = 1/6
	self.vscroll = 'never'
	self.hscroll = 'never'
	self.x = 0
	self.y = 0
	self.w = (100 - self.vscroll_w - 4) / scale
	self.h = self.h * 1/scale
	cr:save()
		cr:translate(self.editor.x + self.editor.w - 100, self.editor.y)
		cr:scale(scale, scale)
		codedit.draw(self)
		cr:restore()
	cr:restore()
end

function view:font_file(font_file)
	if not font_file then
		return self._font_file
	end
	self:clear_glpyh_cache()
	if self.ft_face then
		self.ft_face:free()
	end
	self._font_file = font_file
	self.ft_face = ft_lib:face(font_file)
	self:font_size(self._font_size)
end

function view:font_size(font_size)
	if not font_size then
		return self._font_size
	end
	self:clear_glpyh_cache()
	self._font_size = font_size
	self.ft_face:set_pixel_sizes(self._font_size)
	self.line_h = self.ft_face.size.metrics.height / 64
	self.ascender = self.ft_face.size.metrics.ascender / 64
end

function editor:draw()
	self.view:draw()
	self.view:draw_eol_markers()
	if self.view.minimap then
		self.view:draw_minimap()
	end
end

function editor:set_clipboard(s)
	nw:app():setclipboard(s, 'text')
end

function editor:get_clipboard()
	return nw:app():getclipboard'text' or ''
end

function editbox.editor:key(key)
	return self.editbox.ui:key(key)
end

function editbox:keypress(key)
	self.editor:keypress(key)
	self:invalidate()
end

function editbox:keychar(s)
	self.editor:keychar(s)
	self:invalidate()
end

function editbox:view_rect()
	local vs = self.vscrollbar
	local hs = self.hscrollbar
	return
		0, 0,
		self.w - (vs.autohide and 0 or vs.h),
		self.h - (hs.autohide and 0 or hs.h)
end

function editbox:_sync_view()
	local view = self.editor.view
	self:setfont()
	view.line_h = self.window:text_line_h()
	view.ascender = self.window._font_ascent
	view.x, view.y, view.w, view.h = self:view_rect()
	view.scroll_x = -self.hscrollbar.offset
	view.scroll_y = -self.vscrollbar.offset
end

function editbox:_sync_scrollbars()
	local vs = self.vscrollbar
	local hs = self.hscrollbar
	local view = self.editor.view
	local cw, ch = view:client_size()
	local mw = view:margins_width()
	local vx, vy, vw, vh = self:view_rect()
	vs.x = vx + vw + (vs.autohide and -vs.h or 0)
	vs.w = vh
	vs.view_size = vh
	vs.content_size = ch
	hs.y = vy + vh + (hs.autohide and -hs.h or 0)
	hs.x = vx + mw
	hs.w = vw - mw - vs.h
	hs.view_size = vw - mw
	hs.content_size = cw + view.cursor_xoffset + view.cursor_thickness
end

editbox.vscrollbar_class = ui.scrollbar
editbox.hscrollbar_class = ui.scrollbar

function editbox:after_init(ui, t)

	local editor = self.super.editor(t.editor)
	--self.cursor.changed.blinking = true
	self.editor = editor
	editor.editbox = self
	editor.view.editbox = self

	self.vscrollbar = self.vscrollbar_class(self.ui, self.vscrollbar):merge{
		id = self:_subtag'vscrollbar',
		parent = self,
		vertical = true,
	}

	self.hscrollbar = self.ui:scrollbar{
		id = self:_subtag'hscrollbar',
		parent = self,
		vertical = false,
		autohide = true,
	}

	--[[
	--make the cursor blink
	if ed.cursor.changed.blinking then
		ed.cursor.start_clock = self.clock
		ed.cursor.changed.blinking = false
	end
	ed.cursor.on = (self.clock - ed.cursor.start_clock) % 1 < 0.5
	]]
	self.editor.cursor.on = true
end

--demo -----------------------------------------------------------------------

if not ... then require('ui_demo')(function(ui, win)

	local edit = ui:editbox{
		id = 'ed',
		x = 10, y = 10,
		w = 500, h = 300,
		parent = win,
		editor = {text = (('Hello World! '):rep(10)..'\n'):rep(30) }
	}

	edit:focus()

	function win:client_rect_changed(cx, cy, cw, ch)
		edit.w = cw - 20
		edit.h = ch - 20
	end

end) end
