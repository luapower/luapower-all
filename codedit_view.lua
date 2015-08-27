--[[
--codedit view object: measuring, layouting, rendering and hit testing codedit objects.
--implementation for monospace fonts and fixed line height.

...................................
:client :m1 :m2 :                 :  view rect (*):     x, y, w, h (contains the clipped margins and the scrollbox)
:rect   :   :   :                 :  scrollbox rect:    x + margins_w, y, w - margins_w, h
:       :___:___:______________   :  clip rect:         clip_x, clip_y, clip_w, clip_h (from drawing the scrollbox)
:       |(*)|   |clip       | |   :  client rect:       clip_x + scroll_x, clip_y + scroll_y, client_size()
:       |   |   |rect       | |   :  margin1 rect:      x, client_y, m1:get_width(), client_h
:       |   |   |           |#|   :  margin1 clip rect: m1_x, clip_y, m1_w, clip_h
:       |   |   |           |#|   :
:       |   |   |           |#|   :
:       |   |   |           |#|   :
:       |   |   |           | |   :
:       |___|___|___________|_|   :
:       :   :   |_____####__|     :
:       :   :   :                 :
:       :   :   :                 :
...................................

]]
local glue = require'glue'
local str = require'codedit_str'
local tabs = require'codedit_tabs'
local hl = require'codedit_hl'

local view = {
	--tab expansion
	tabsize = 3,
	--font metrics
	line_h = 16,
	char_w = 8,
	char_baseline = 13,
	--cursor metrics
	cursor_xoffset = -1,     --cursor x offset from a char's left corner
	cursor_xoffset_col1 = 0, --cursor x offset for the first column
	cursor_thickness = 2,
	--scrolling
	cursor_margins = {top = 16, left = 0, right = 0, bottom = 16},
	--rendering
	highlight_cursor_lines = true,
	lang = nil, --lexer to use for syntax highlighting. nil means no highlighting.
	--reflowing
	line_width = 72,
}

--lifetime

function view:new(buffer)
	self = glue.inherit({
		buffer = buffer,
	}, self)
	--objects to render
	self.selections = {} --{selections = true, ...}
	self.cursors = {} --{cursor = true, ...}
	self.margins = {} --{margin1, ...}
	--state
	self.scroll_x = 0 --client rect position relative to the clip rect
	self.scroll_y = 0
	self.last_valid_line = 0 --for incremental lexing
	return self
end

--adding objects to render

function view:add_selection(sel) self.selections[sel] = true end
function view:add_cursor(cur) self.cursors[cur] = true end
function view:add_margin(margin, pos)
	table.insert(self.margins, pos or #self.margins + 1, margin)
end

--state management

function view:invalidate(line)
	if line then
		self.last_valid_line = math.min(self.last_valid_line, line - 1)
	end
end

local function update_state(dst, src)
	dst.scroll_x = src.scroll_x
	dst.scroll_y = src.scroll_y
end

function view:save_state(state)
	update_state(state, self)
end

function view:load_state(state)
	update_state(self, state)
	self:invalidate()
end

--utils

local function clamp(x, a, b)
	return math.min(math.max(x, a), b)
end

local function point_in_rect(x, y, x1, y1, w1, h1)
	return x >= x1 and x <= x1 + w1 and y >= y1 and y <= y1 + h1
end

--measurements in text space, which is is a matrix of char glyphs

--visual char position in text space
function view:char_coords(line, vcol)
	local x = self.char_w * (vcol - 1)
	local y = self.line_h * (line - 1)
	return x, y
end

--visual char at text space coordinates
function view:char_at(x, y)
	local line = math.floor(y / self.line_h) + 1
	local vcol = math.floor((x + self.char_w / 2) / self.char_w) + 1
	return line, vcol
end

--rectangle surrounding a block of text
function view:char_rect(line1, vcol1, line2, vcol2)
	local x1, y1 = self:char_coords(line1, vcol1)
	local x2, y2 = self:char_coords(line2 + 1, vcol2)
	return x1, y1, x2 - x1, y2 - y1
end

--selection shape in text space

function view:selection_line_rect(sel, line)
	local col1, col2 = sel:cols(line)
	local vcol1 = self.buffer:visual_col(line, col1)
	local vcol2 = self.buffer:visual_col(line, col2)
	local x, y, w, h = self:char_rect(line, vcol1, line, vcol2)
	if not sel.block and line < (sel:isforward() and sel.line2 or sel.line1) then
		w = w + 0.5 * self.char_w --show eol as half space
	end
	return x, y, w, h, vcol1, vcol2
end

--cursor shape in text space

function view:cursor_rect_insert_mode(cursor)
	local vcol = self.buffer:visual_col(cursor.line, cursor.col)
	local x, y = self:char_coords(cursor.line, vcol)
	local w = cursor.thickness or self.cursor_thickness
	local h = self.line_h
	x = x + (vcol == 1 and self.cursor_xoffset_col1 or self.cursor_xoffset)
	return x, y, w, h
end

function view:cursor_rect_over_mode(cursor)
	local vcol = self.buffer:visual_col(cursor.line, cursor.col)
	local x, y = self:char_coords(cursor.line, vcol)
	local w = self.buffer:istab(cursor.line, cursor.col) and self.buffer:tab_width(vcol) or 1
	w = w * self.char_w
	local h = cursor.thickness or self.cursor_thickness
	y = y + self.char_baseline + 1 --1 pixel under the baseline
	return x, y, w, h
end

function view:cursor_rect(cursor)
	if cursor.insert_mode then
		return self:cursor_rect_insert_mode(cursor)
	else
		return self:cursor_rect_over_mode(cursor)
	end
end

--measurements in screen space for layouting, scrolling, clipping and hit testing

--size of the text space (also called client rectangle in the context of layouting)
--as limited by the available text and any out-of-text cursors.
function view:client_size()
	local maxvcol = self.buffer:max_visual_col() + 1
	local maxline = self.buffer:last_line()
	--unrestricted cursors can enlarge the client area
	for cur in pairs(self.cursors) do
		maxline = math.max(maxline, cur.line)
		if not cur.restrict_eol then
			maxvcol = math.max(maxvcol, self.buffer:visual_col(cur.line, cur.col))
		end
	end
	return self:char_coords(maxline + 1, maxvcol + 1)
end

--width of all margins combined
function view:margins_width()
	local w = 0
	for _,m in ipairs(self.margins) do
		w = w + m:get_width()
	end
	return w
end

--x coord of a margin in screen space
function view:margin_x(target_margin)
	local x = self.x
	for _,margin in ipairs(self.margins) do
		if margin == target_margin then
			return x
		end
		x = x + margin:get_width()
	end
end

--clipping rectangles

--clip rect of the client area in screen space, as obtained from drawing the scrollbox.
function view:clip_rect()
	return self.clip_x, self.clip_y, self.clip_w, self.clip_h
end

--clip rect of a margin area in screen space
function view:margin_clip_rect(margin)
	local clip_x = self:margin_x(margin)
	local clip_w = margin:get_width()
	return clip_x, self.clip_y, clip_w, self.clip_h
end

--clip rect of a line in screen space
function view:line_clip_rect(line)
	local _, y = self:char_coords(line, 1)
	local _, y = self:client_to_screen(0, y)
	return self.clip_x, y, self.clip_w, self.line_h
end

--clipping in visual char space

--which lines are partially or entirely visibile
function view:visible_lines()
	local line1 = math.floor(-self.scroll_y / self.line_h) + 1
	local line2 = math.ceil((-self.scroll_y + self.clip_h) / self.line_h)
	line1 = clamp(line1, 1, self.buffer:last_line())
	line2 = clamp(line2, 1, self.buffer:last_line())
	return line1, line2
end

--which visual columns are partially or entirely visibile
function view:visible_cols()
	local vcol1 = math.floor(-self.scroll_x / self.char_w) + 1
	local vcol2 = math.ceil((-self.scroll_x + self.clip_w) / self.char_w)
	return vcol1, vcol2
end

function view:line_is_visible(line)
	local line1, line2 = self:visible_lines()
	return line >= line1 and line <= line2
end

--point translation from screen space to client (text) space and back

function view:screen_to_client(x, y)
	x = x - self.clip_x - self.scroll_x
	y = y - self.clip_y - self.scroll_y
	return x, y
end

function view:client_to_screen(x, y)
	x = x + self.clip_x + self.scroll_x
	y = y + self.clip_y + self.scroll_y
	return x, y
end

function view:screen_to_margin_client(margin, x, y)
	x = x - self:margin_x(margin)
	y = y - self.clip_y - self.scroll_y
	return x, y
end

function view:margin_client_to_screen(margin, x, y)
	x = x + self:margin_x(margin)
	y = y + self.clip_y + self.scroll_y
	return x, y
end

--hit testing

function view:selection_hit_test(sel, x, y)
	if not sel.visible or sel:isempty() or not point_in_rect(x, y, self:clip_rect()) then
		return false
	end
	x, y = self:screen_to_client(x, y)
	local line1, line2 = sel:line_range()
	for line = line1, line2 do
		if point_in_rect(x, y, self:selection_line_rect(sel, line)) then
			return true
		end
	end
	return false
end

function view:margin_hit_test(margin, x, y)
	if not point_in_rect(x, y, self:margin_clip_rect(margin)) then
		return false
	end
	x, y = self:screen_to_margin_client(margin, x, y)
	return true, self:char_at(x, y)
end

function view:client_hit_test(x, y)
	return point_in_rect(x, y, self:clip_rect())
end

--scrolling (adjusting the position of the client rectangle relative to the clipping rectangle)

--how many lines are in the clipping rect
function view:pagesize()
	return math.floor(self.clip_h / self.line_h)
end

function view:scroll_by(x, y)
	self.scroll_x = self.scroll_x + x
	self.scroll_y = self.scroll_y + y
end

function view:scroll_up()
	self:scroll_by(0, self.line_h)
end

function view:scroll_down()
	self:scroll_by(0, -self.line_h)
end

--scroll to make a specific rectangle visible
function view:make_rect_visible(x, y, w, h)
	self.scroll_x = -clamp(-self.scroll_x, x + w - self.clip_w, x)
	self.scroll_y = -clamp(-self.scroll_y, y + h - self.clip_h, y)
end

--scroll to make the char under cursor visible
function view:cursor_make_visible(cur)
	local line, vcol = cur.line, self.buffer:visual_col(cur.line, cur.col)
	local x, y, w, h = self:char_rect(line, vcol, line, vcol + 1)
	--enlarge the char rectangle with the cursor margins
	x = x - self.cursor_margins.left
	y = y - self.cursor_margins.top
	w = w + self.cursor_margins.right  + self.cursor_margins.left
	h = h + self.cursor_margins.bottom + self.cursor_margins.top
	self:make_rect_visible(x, y, w, h)
end

--rendering stubs: all rendering is based on these functions

function view:draw_char(x, y, s, i, color) error'stub' end
function view:draw_rect(x, y, w, h, color) error'stub' end
function view:clip(x, y, w, h) error'stub' end

--rendering

function view:draw_text(cx, cy, s, color, i, j)
	i = i or 1
	j = j or str.len(s)
	cy = cy + self.char_baseline
	for i = i, j do
		self:draw_char(cx, cy, s, i, color)
		cx = cx + self.char_w
	end
end

function view:draw_buffer(cx, cy, line1, vcol1, line2, vcol2, color)

	--clamp the text rectangle to the visible rectangle
	local minline, maxline = self:visible_lines()
	local minvcol, maxvcol = self:visible_cols()
	line1 = clamp(line1, minline, maxline+1)
	line2 = clamp(line2, minline-1, maxline)
	vcol1 = clamp(vcol1, minvcol, maxvcol+1)
	vcol2 = clamp(vcol2, minvcol-1, maxvcol)
	if vcol1 > vcol2 then
		return
	end

	for line = line1, line2 do
		local s = self.buffer:getline(line)
		local vcol = 1
		for i in str.byte_indices(s) do
			if str.istab(s, i) then
				vcol = vcol + self.buffer:tab_width(vcol)
			else
				if vcol > vcol2 then
					break
				elseif vcol >= vcol1 then
					local x, y = self:char_coords(line, vcol)
					self:draw_char(cx + x, cy + y + self.char_baseline, s, i, color)
				end
				vcol = vcol + 1
			end
		end
	end
end

function view:draw_buffer_text(x, y, color, line1, i1, line2, i2)
	for line = line1, line2 do
		local s = self.buffer:getline(line)
		local vcol = 1
		for i in str.byte_indices(s) do
			if str.istab(s, i) then
				vcol = vcol + self.buffer:tab_width(vcol)
			else
				if vcol > vcol2 then
					break
				elseif vcol >= vcol1 then
					local x, y = self:char_coords(line, vcol)
					self:draw_char(cx + x, cy + y + self.char_baseline, s, i, color)
				end
				vcol = vcol + 1
			end
		end
	end
end

--byte index -> visual column: same as tabs.visual_col but based on byte index instead of char index.
local function visual_col_bi(s, targeti, tabsize, previ, prevvcol)
	local vcol = prevvcol and prevvcol + 1 or 1
	for i in str.byte_indices(s, previ) do
		if i >= targeti then
			return vcol
		end
		vcol = vcol + (str.istab(s, i) and tabs.tab_width(vcol, tabsize) or 1)
	end
	return vcol --TODO: fix this differently (this is for when targeti is outside the string)
end

function view:draw_buffer_highlighted(cx, cy)

	local minline, maxline = self:visible_lines()

	self.tokens, self.last_valid_line, self.start_tokens =
		hl.relex(maxline, self.tokens, self.last_valid_line, self.buffer, self.lang, self.start_tokens)

	local last_line, last_p1, last_vcol

	for i, line, p1, p2, style in hl.tokens(self.tokens, 1, 1, self.buffer) do

		if line > maxline then
			break
		end

		if line >= minline then
			if not style:match'whitespace$' then

				if line ~= last_line then
					last_p1, last_vcol = nil
				end

				local s = self.buffer:getline(line)
				local vcol = visual_col_bi(s, p1, self.tabsize, last_p1, last_vcol)
				local x, y = self:char_coords(line, vcol)
				self:draw_text(cx + x, cy + y, s, style, p1, p2)

				last_line, last_p1, last_vcol = line, p1, vcol
			end
		end
	end
end

function view:draw_visible_text(cx, cy)
	if self.lang then
		self:draw_buffer_highlighted(cx, cy)
	else
		local color = self.buffer.text_color or 'text'
		self:draw_buffer(cx, cy, 1, 1, 1/0, 1/0, color)
	end
end

function view:draw_selection(sel, cx, cy)
	if not sel.visible then return end
	if sel:isempty() then return end
	local bg_color = sel.background_color or 'selection_background'
	local text_color = sel.text_color or 'selection_text'
	local line1, line2 = sel:line_range()
	for line = line1, line2 do
		local x, y, w, h, vcol1, vcol2 = self:selection_line_rect(sel, line)
		self:draw_rect(cx + x, cy + y, w, h, bg_color)
		self:draw_buffer(cx, cy, line, vcol1, line, vcol2 - 1, text_color)
	end
end

function view:draw_cursor(cursor, cx, cy)
	if not cursor.visible then return end
	local x, y, w, h = self:cursor_rect(cursor)
	local color = cursor.color or 'cursor'
	self:draw_rect(cx + x, cy + y, w, h, color)
end

function view:draw_margin_line(margin, line, cx, cy, cw, ch, highlighted)
	local x, y = self:char_coords(line, 1)
	margin:draw_line(line, cx + x, cy + y, cw, ch, highlighted)
end

function view:draw_margin(margin)
	local clip_x, clip_y, clip_w, clip_h = self:margin_clip_rect(margin)
	self:clip(clip_x, clip_y, clip_w, clip_h)
	--background
	local color = margin.background_color or 'margin_background'
	self:draw_rect(clip_x, clip_y, clip_w, clip_h, color)
	--contents
	local cx, cy = self:margin_client_to_screen(margin, 0, 0)
	local cw = margin:get_width()
	local ch = self.line_h
	local minline, maxline = self:visible_lines()
	for line = minline, maxline do
		self:draw_margin_line(margin, line, cx, cy, cw, ch)
	end
	--highlighted lines
	if self.highlight_cursor_lines then
		for cursor in pairs(self.cursors) do
			self:draw_margin_line(margin, cursor.line, cx, cy, cw, ch, true)
		end
	end
end

function view:draw_line_highlight(line, color)
	if not self:line_is_visible(line) then return end
	local x, y, w, h = self:line_clip_rect(line)
	color = color or self.buffer.line_highlight_color or 'line_highlight'
	self:draw_rect(x, y, w, h, color)
end

function view:draw_client()
	self:clip(self:clip_rect())
	--background
	local color = self.buffer.background_color or 'background'
	self:draw_rect(self.clip_x, self.clip_y, self.clip_w, self.clip_h, color)
	--highlighting the line under cursor
	for cur in pairs(self.cursors) do
		self:draw_line_highlight(cur.line, cur.line_highlight_color)
	end
	--text, selections, cursors
	local cx, cy = self:client_to_screen(0, 0)
	self:draw_visible_text(cx, cy)
	for sel in pairs(self.selections) do
		self:draw_selection(sel, cx, cy)
	end
	for cur in pairs(self.cursors) do
		self:draw_cursor(cur, cx, cy)
	end
end

--draw a scrollbox widget with (x, y, w, h) outside rect and (cx, cy, cw, ch) client rect.
--return the new cx, cy, adjusted from user input and other scrollbox constraints, followed by the clipping rect.
--the client rect is relative to the clipping rect of the scrollbox (which can be different than it's outside rect).
--this stub implementation is equivalent to a scrollbox that takes no user input, has no margins,
--and has invisible scrollbars.
function view:draw_scrollbox(x, y, w, h, cx, cy, cw, ch)
	return cx, cy, x, y, w, h
end

function view:render()

	local client_w, client_h = self:client_size()
	local margins_w = self:margins_width()

	self.scroll_x, self.scroll_y, self.clip_x, self.clip_y, self.clip_w, self.clip_h =
		self:draw_scrollbox(
			self.x + margins_w,
			self.y,
			self.w - margins_w,
			self.h,
			self.scroll_x, self.scroll_y, client_w, client_h)

	for i,margin in ipairs(self.margins) do
		self:draw_margin(margin)
	end
	self:draw_client()
end


if not ... then require'codedit_demo' end

return view
