
--ui edit box widget.
--Written by Cosmin Apreutesei. Public Domain.

local ui = require'ui'
local glue = require'glue'
local codedit = require'codedit'

local editbox = ui.layer:subclass'editbox'
local view = codedit.view:subclass()
local editor = codedit.editor:subclass()
ui.editbox = editbox
editbox.editor_class = editor
editor.view_class = view

editbox.w = 200
editbox.h = 30
editbox.padding = 4
editbox.focusable = true
editbox.max_click_chain = 3 --receive doubleclick and tripleclick events
editbox.cursor_client = 'text'
editbox.clip_content = true --TODO: remove this
editbox.border_color = '#333'
editbox.border_width = 1

editbox.eol_markers = false
editbox.minimap = false
editor.line_numbers = false

--codedit colors
editbox.background_color = '#000'
editbox.selection_background_color = '#333'
editbox.selection_text_color = '#ddd'
editbox.cursor_color = '#fff'
editbox.tabstop_color = '#111'
editbox.margin_background_color = '#000'
editbox.line_number_text_color = '#66ffff'
editbox.line_number_background_color = '#111'
editbox.line_number_highlighted_text_color = '#66ffff'
editbox.line_number_highlighted_background_color = '#222222'
editbox.line_number_separator_color = '#333'
editbox.line_highlight_color = '#000' --same as background (i.e. disabled)
editbox.blame_text_color = '#444'
--codedit colors / syntax highlighting
editbox.default_color = '#ccc'
editbox.whitespace_color = '#000'
editbox.comment_color = '#56cc66'
editbox.string_color = '#ff3333'
editbox.number_color = '#ff6666'
editbox.keyword_color = '#ffff00'
editbox.identifier_color = '#fff'
editbox.operator_color = '#fff'
editbox.error_color = '#ff0000'
editbox.preprocessor_color = '#56cc66'
editbox.constant_color = '#ff3333'
editbox.variable_color = '#fff'
editbox.function_color = '#ff6699'
editbox.class_color = '#ffff00'
editbox.type_color = '#56cc66'
editbox.label_color = '#ffff66'
editbox.regex_color = '#ff3333'

ui:style('editbox', {
	transition_border_color = true,
	transition_duration = .5,
})

ui:style('editbox :hot', {
	border_color = '#999',
	transition_border_color = true,
	transition_duration = .5,
})

ui:style('editbox :focused', {
	selection_background_color = '#666',
	selection_text_color = '#fff',
	border_color = '#fff',
	shadow_blur = 3,
	shadow_color = '#666',
})

ui:style('editbox_caret', {

})

local caret = ui.layer:subclass'editbox_caret'
editbox.caret_class = caret

caret.activable = false

function editbox:color(color)
	return self[color..'_color'] or self.text_color
end

function editbox:_sync()
	self:_sync_view()
	self:_sync_scrollbars()
	self:_sync_caret()
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
end

function editbox:mouseup(mx, my)
	self.editor:mouseup(mx, my)
end

function editbox:mousemove(mx, my)
	self:_sync()
	self.editor:mousemove(mx, my)
end

function editbox:click(mx, my)
	self.editor:click(mx, my)
end

function editbox:doubleclick(mx, my)
	self.editor:doubleclick(mx, my)
end

function editbox:tripleclick(mx, my)
	self.editor:tripleclick(mx, my)
end

function editbox:mousewheel(delta, mx, my, area, pdelta)
	self:_sync()
	self.vscrollbar:scroll(-delta * self.editor.view.line_h)
end

function view:begin_clip(x, y, w, h)
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
function view:draw_cursor(cursor, cx, cy)
	local caret = self.editbox.caret
	caret.x, caret.y, caret.w, caret.h = self:cursor_rect(cursor)
	caret.x = caret.x + cx
	caret.y = caret.y + cy
	caret.background_color = self.editbox:color(cursor.color or 'cursor')
end

function view:draw_rect(x, y, w, h, color)
	local cr = self.editbox.window.cr
	cr:rgba(self.editbox.ui:color(self.editbox:color(color)))
	cr:new_path()
	cr:rectangle(x, y, w, h)
	cr:fill()
end

local ffi = require'ffi'
local ext = ffi.new'cairo_text_extents_t'
local cbuf = ffi.new'uint8_t[2]'
function view:char_advance_x(s, i)
	local xt = self._xt
	if not xt then
		xt = {}
		self._xt = xt
	end
	local c = s:byte(i, i)
	local x = xt[c]
	if not x then
		cbuf[0] = c
		local cr = self.editbox.window.cr
		cr:text_extents(cbuf, ext)
		x = ext.x_advance
		xt[c] = x
	end
	return x
end

function view:draw_char(x, y, s, i, color)
	local cr = self.editbox.window.cr
	cr:rgba(self.editbox.ui:color(self.editbox:color(color)))
	cr:new_path()
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
	local mmap = setmetatable({editor = self}, {__index = self})
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

function editor:draw()
	self.view:draw()
	self.view:draw_eol_markers()
	self.view:draw_minimap()
end

function editor:invalidate()
	self.editbox:invalidate()
end

function editor:setclipboard(s)
	self.editbox.ui:setclipboard(s, 'text')
end

function editor:getclipboard()
	return self.editbox.ui:getclipboard'text' or ''
end

function editor:key(key)
	return self.editbox.ui:key(key)
end

editbox.ctrl_tab_exits = true

function editbox:keypress(key)
	if key == 'tab' then
		if not self.multiline then
			return
		elseif self.ctrl_tab_exits and self.ui:key'ctrl' then
			local next_widget = self:next_focusable_widget(not self.ui:key'shift')
			if next_widget then
				next_widget:focus(true)
			end
			return true
		end
	end
	return self.editor:keypress(key)
end

function editbox:keychar(s)
	self.editor:keychar(s)
end

function editbox:view_rect()
	local vs = self.vscrollbar
	local hs = self.hscrollbar
	return
		0, 0,
		self.cw - (vs.autohide and 0 or vs.h),
		self.ch - (hs.autohide and 0 or hs.h)
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
	view:sync()
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
	vs.view_length = vh
	vs.content_length = ch
	hs.y = vy + vh + (hs.autohide and -hs.h or 0)
	hs.x = vx + mw
	hs.w = vw - mw - vs.h
	hs.view_length = vw - mw
	hs.content_length = cw + view.cursor_xoffset + view.cursor_thickness
end

function editbox:_sync_caret()

	self.caret.visible = self.editor.cursor.visible

	if self.editor.cursor.changed.blinking then
		self.editor.cursor.changed.blinking = false
		local bt = self.ui.caret_blink_time
		if bt then
			self.caret:transition('opacity', 1, 0)
			self.caret:transition('opacity', 0, 0, nil, bt, 1/0, 1, 'replace')
		end
	end
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
	self:settag('multiline', multiline)
	self:invalidate()
end

function editbox:set_multiline(multiline)
	local s = self.editor.buffer:select()
	self:_set_multiline(multiline)
	self.editor:replace(s)
end

editbox:instance_only'multiline'

editbox.multiline = false

function editbox:get_text()
	return self.editor.buffer:select()
end

function editbox:set_text(s)
	self:_sync()
	self.editor:replace(s)
end

editbox:instance_only'text'

editbox:init_ignore{editor=1, multiline=1, text=1}

function editbox:before_init(ui, t)
	self.editor = self.editor_class(t.editor)
	self.editor.editbox = self
	self.editor.view.editbox = self
end

function editbox:after_init(ui, t)

	self:init_proxy_properties()

	self.caret = self.caret_class(self.ui, {
		parent = self,
		editbox = self,
	}, self.caret)

	self.vscrollbar = self.vscrollbar_class(self.ui, {
		tags = 'vscrollbar',
		parent = self,
		vertical = true,
	}, self.vscrollbar)

	self.hscrollbar = self.hscrollbar_class(self.ui, {
		tags = 'hscrollbar',
		parent = self,
		vertical = false,
		autohide = true,
	}, self.hscrollbar)

	self:_set_multiline(t.multiline)

	if t.text then
		self.editor.buffer:load(t.text)
		self.editor.selection:reset_to_cursor(self.editor.cursor)
	end

	self.editor.cursor.visible = false
	self.editor.cursor.changed.blinking = false
end

function editbox:after_gotfocus()
	self.editor:focus()
end

function editbox:after_lostfocus()
	self.editor:unfocus()
end

--demo -----------------------------------------------------------------------

if not ... then require('ui_demo')(function(ui, win)

	local long_text = (('Hello World! '):rep(10)..'\n'):rep(30)

	print(#long_text)

	local edit = ui:editbox{
		tags = 'ed',
		x = 10, y = 10,
		w = 300, h = 300,
		parent = win,
		text = long_text,
		multiline = true,
	}

	for i=1,2 do
		local ed = ui:editbox{
			tags = 'ed'..i,
			x = 320,
			y = 10 + 30 * (i-1),
			w = 200,
			parent = win,
			text = long_text,
			multiline = false,
		}
	end

	function win:client_rect_changed(cx, cy, cw, ch)
		edit.h = ch - 20
	end

end) end
