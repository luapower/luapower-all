
--ui edit box widget.
--Written by Cosmin Apreutesei. Public Domain.

local ui = require'ui'
local glue = require'glue'
local codedit = require'codedit'

local editbox = ui.layer:subclass'editbox'
ui.editbox = editbox

local view = codedit.view:subclass()
local editor = codedit.editor:subclass()

editbox.editor_class = editor
editor.view_class = view

editbox.focusable = true
editbox.scrollable = true
editbox.max_click_chain = 3 --receive doubleclick and tripleclick events
editbox.cursor_client = 'text'

editbox.eol_markers = false
editbox.minimap = false

--codedit colors
editbox.background_color = '#080808'
editbox.selection_background_color = '#333'
editbox.selection_text_color = '#ddd'
editbox.cursor_color = '#ffffff'
editbox.tabstop_color = '#111'
editbox.margin_background_color = '#000000'
editbox.line_number_text_color = '#66ffff'
editbox.line_number_background_color = '#111111'
editbox.line_number_highlighted_text_color = '#66ffff'
editbox.line_number_highlighted_background_color = '#222222'
editbox.line_number_separator_color = '#333333'
editbox.line_highlight_color = '#222222'
editbox.blame_text_color = '#444444'
--codedit colors / syntax highlighting
editbox.default_color = '#CCCCCC'
editbox.whitespace_color = '#000000'
editbox.comment_color = '#56CC66'
editbox.string_color = '#FF3333'
editbox.number_color = '#FF6666'
editbox.keyword_color = '#FFFF00'
editbox.identifier_color = '#FFFFFF'
editbox.operator_color = '#FFFFFF'
editbox.error_color = '#FF0000'
editbox.preprocessor_color = '#56CC66'
editbox.constant_color = '#FF3333'
editbox.variable_color = '#FFFFFF'
editbox.function_color = '#FF6699'
editbox.class_color = '#FFFF00'
editbox.type_color = '#56CC66'
editbox.label_color = '#FFFF66'
editbox.regex_color = '#FF3333'

ui:style('editbox focused', {
	selection_background_color = '#666',
	selection_text_color = '#fff',
})

function editbox:color(color)
	return self.ui:color(self[color..'_color'] or self.text_color)
end

function editbox:_sync()
	self:setfont()
	self:_sync_view()
	self:_sync_scrollbars()
end

function editbox:draw_text() end --reinterpreting the text property
function editbox:text_bounding_box() return 0, 0, 0, 0 end

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

function view:draw_background() end --using layer's background

function view:draw_rect(x, y, w, h, color)
	local cr = self.editbox.window.cr
	cr:rgba(self.editbox:color(color))
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
	cr:rgba(self.editbox:color(color))
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
	if self.editbox.eol_markers then
		local line1, line2 = self:visible_lines()
		for line = line1, line2 do
			self:draw_eol_marker(line)
		end
	end
end

function view:draw_minimap()
	if not self.editbox.minimap then return end
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
	self.view:draw_minimap()
end

function editor:set_clipboard(s)
	self.editbox.ui:setclipboard(s, 'text')
end

function editor:get_clipboard()
	return self.editbox.ui:getclipboard'text' or ''
end

function editor:key(key)
	return self.editbox.ui:key(key)
end

function editbox:keypress(key)
	--if tab is kept for navigation, use ctrl+tab to indent
	if key == 'tab' and not self.capture_tab and self.ui:key'ctrl' then
		self.editor:indent()
	else
		self.editor:keypress(key)
	end
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
	view.ascender = self.window.font_ascent
	view.x, view.y, view.w, view.h = self:view_rect()
	view.scroll_x = -self.hscrollbar.offset
	view.scroll_y = -self.vscrollbar.offset
	if not self.multiline then
		self.ch = view.line_h
	end
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

function editbox:init_proxy_properties() end

function editbox:proxy_properties(proxy, props)
	for k in ipairs(props) do
		self['get_'..k] = function(self)
			return self[proxy][k]
		end
		self['set_'..k] = function(self, v)
			self[proxy][k] = v
		end
	end
	function self:after_init_proxy_properties()
		for k in ipairs(props) do
			self[proxy] = self[k]
		end
	end
end

function editbox:get_multiline(multiline)
	return self.editor.buffer.multiline
end

function editbox:_set_multiline(multiline)
	self.editor.buffer.multiline = multiline
	self.vscrollbar.visible = multiline
	self.hscrollbar.visible = multiline
	self:settags(multiline and 'multiline' or '-multiline')
end

function editbox:set_multiline(multiline)
	if multiline == self.multiline then return end
	local s = self.editor.buffer:select()
	self:_set_multiline(multiline)
	self.editor:replace(s)
end

function editbox:get_text()
	return self.editor.buffer:select()
end

function editbox:set_text(s)
	self.editor:replace(s)
end

editbox:init_ignore{editor=1, multiline=1, text=1}

function editbox:override_init(inherited, ui, t)

	self.editor = self.editor_class(t.editor)

	inherited(self, ui, t)

	self:init_proxy_properties()

	--self.cursor.changed.blinking = true
	self.editor.editbox = self
	self.editor.view.editbox = self

	self.vscrollbar = self.vscrollbar_class(self.ui, {
		id = self:_subtag'vscrollbar',
		parent = self,
		vertical = true,
	}, self.vscrollbar)

	self.hscrollbar = self.hscrollbar_class(self.ui, {
		id = self:_subtag'hscrollbar',
		parent = self,
		vertical = false,
		autohide = true,
	}, self.hscrollbar)

	self:_set_multiline(t.multiline)

	--[[ TODO:
	if self.text then
		self.editor.buffer:load(self.text)
		self.editor.cursor:move_end()
		self.editor.selection:reset_selection_to_cursor()
	end
	]]

	--[[
	--make the cursor blink
	if ed.cursor.changed.blinking then
		ed.cursor.start_clock = self.clock
		ed.cursor.changed.blinking = false
	end
	ed.cursor.on = (self.clock - ed.cursor.start_clock) % 1 < 0.5
	]]
	self.editor.cursor.on = self.active
end

function editbox:after_focused()
	self.editor.cursor.on = true
	if not self.multiline then
		self.editor:select_all()
	end
end

function editbox:after_lostfocus()
	self.editor.cursor.on = false
	if not self.multiline then
		self.editor:reset_selection_to_cursor()
	end
end

--demo -----------------------------------------------------------------------

if not ... then require('ui_demo')(function(ui, win)

	local edit = ui:editbox{
		id = 'ed',
		x = 10, y = 10,
		w = 300, h = 300,
		parent = win,
		text = (('Hello World! '):rep(10)..'\n'):rep(30),
		multiline = true,
	}

	for i=1,2 do
		local ed = ui:editbox{
			id = 'ed'..i,
			x = 320,
			y = 10 + 30 * (i-1),
			w = 200,
			h = 26,
			parent = win,
			text = (('Hello World! '):rep(10)..'\n'):rep(30),
			multiline = false,
		}
	end

	edit:focus()

	function win:client_rect_changed(cx, cy, cw, ch)
		edit.h = ch - 20
	end

end) end
