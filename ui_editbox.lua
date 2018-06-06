
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
editor.line_numbers = false

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
editbox.cursor_color = '#fff'
editbox.tabstop_color = '#111'
editbox.margin_background_color = '#000'
editbox.line_number_text_color = '#66ffff'
editbox.line_number_background_color = '#111'
editbox.line_number_highlighted_text_color = '#66ffff'
editbox.line_number_highlighted_background_color = '#222222'
editbox.line_number_separator_color = '#333'
editbox.line_highlight_color = '#222'
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

editbox.clip_content = true --TODO: remove this
editbox.border_color = '#888'
editbox.border_width = 1

ui:style('editbox', {
	transition_border_color = true,
	transition_duration = .5,
	transition_ease = 'expo out',
})

ui:style('editbox hot', {
	border_color = '#999',
	transition_border_color = true,
	transition_duration = .5,
	transition_ease = 'expo out',
})

ui:style('editbox focused', {
	selection_background_color = '#666',
	selection_text_color = '#fff',
	border_color = '#fff',
	shadow_blur = 3,
	shadow_color = '#666',
})

local caret = ui.layer
editbox.caret_class = caret

function editbox:color(color)
	return self[color..'_color'] or self.text_color
end

function editbox:_sync()
	self:setfont()
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
	self.vscrollbar:scroll_by(delta * self.editor.view.line_h)
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
function view:draw_cursor() end --using the cursor layer

function view:draw_rect(x, y, w, h, color)
	local cr = self.editbox.window.cr
	cr:rgba(self.editbox.ui:color(self.editbox:color(color)))
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
	cr:rgba(self.editbox.ui:color(self.editbox:color(color)))
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

function editor:draw()
	self.view:draw()
	self.view:draw_eol_markers()
	self.view:draw_minimap()
end

function editor:invalidate()
	self.editbox:invalidate()
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

	self.caret.x, self.caret.y, self.caret.w, self.caret.h =
		self.editor.view:cursor_rect(self.editor.cursor)

	self.caret.background_color =
		self:color(self.editor.cursor.color or 'cursor')

	self.caret.visible = self.editor.cursor.visible

	if self.editor.cursor.changed.blinking then
		self.editor.cursor.changed.blinking = false
		local bt = self.ui:caret_blink_time()
		if bt then
			self.caret:transition('opacity', 0, 0, nil, bt, 'replace')
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
	self:settags(multiline and 'multiline' or '-multiline')
	self:invalidate()
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

	self.editor.editbox = self
	self.editor.view.editbox = self

	self.caret = self.caret_class(self.ui, {
		id = self:_subtag'caret',
		parent = self,
	}, self.caret)

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

	self.editor.cursor.visible = false
	self.editor.cursor.changed.blinking = false

	--[[
	local toggle_blink
	local function schedule_toggle_blink()
		self.ui:runafter(self.ui.app():caret_blink_time(), toggle_blink)
	end
	function toggle_blink()
		if not self.ui then return end --editbox freed
		if not self.editor.cursor.changed.blinking then
			self:settags'blinking'
			self.editor.cursor.changed.blinking = true
		end
		schedule_toggle_blink()
	end
	toggle_blink()
	schedule_toggle_blink()
	]]
end

function editbox:after_gotfocus()
	self.editor:focus()
end

function editbox:after_lostfocus()
	self.editor:unfocus()
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
			parent = win,
			text = (('Hello World! '):rep(10)..'\n'):rep(30),
			multiline = false,
		}
	end

	function win:client_rect_changed(cx, cy, cw, ch)
		edit.h = ch - 20
	end

end) end
