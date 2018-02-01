
--Immediate Mode GUI toolkit.
--Written by Cosmin Apreutesei. Public Domain.

--Using this library requires integrating it with two APIs: a windowing
--API to hook in mouse, keyboard and repaint events, and a graphics API
--to draw widgets on. The windowing API must create an imgui object with
--imgui:new() for each window that it creates and must implement all
--self:_backend*() calls on that object for that window. Then it must call
--imgui:_backend_repaint(graphics_api) on the window's repaint event passing
--in the graphics API set up to draw on that window's client area. The
--graphics API needs to implement all self.cr:*() calls which currently map
--to the cairo API.
--Look at imgui_nw_cairo.lua for an example of a complete integration.

if not ... then require'imgui_demo'; return end

local glue = require'glue'
local box2d = require'box2d'
local color = require'color'
local easing = require'easing'

local function str(s)
	if not s then return end
	s = glue.trim(s)
	return s ~= '' and s or nil
end

local imgui = {
	continuous_rendering = true,
	show_magnifier = true,
	tripleclicks = false,
}

--gc-friendly data structures ------------------------------------------------
--these are tables which don't nil their slots on removal.

local function topindex(t, i)
	return (t.n or 0) + (i or 0)
end

local function top(t, i)
	return t[topindex(t, i)]
end

local function push(t, v)
	local n = topindex(t, 1)
	t[n] = v or false
	t.n = n
	t.capacity = math.max(t.capacity or 0, n)
	return n
end

local function pop(t)
	local n = topindex(t)
	if n == 0 then return end
	local v = t[n]
	t[n] = false
	t.n = n - 1
	return v
end

--same thing for multi-value elements

local function pushn(t, n, ...)
	local i = topindex(t, 1)
	for i = 1,n do
		local v = select(i, ...)
		push(t, v)
	end
	return i
end

local function popn(t, n)
	local len = topindex(t)
	n = math.min(n, len)
	for i = 1,n do
		t[len - i + 1] = false
	end
	t.n = len - n
end

local function popall(t)
	popn(t, topindex(t))
end

local function setn(t, ti, n, ...)
	for i = 1,n do
		local v = select(i, ...)
		t[ti + i - 1] = v or false
	end
end

local function insertn(t, ti, n, ...)
	if ti > topindex(t) then
		return pushn(t, n, ...)
	end
	for p = t.n, ti, -1 do --shift n elements from ti to the right
		t[p+n] = t[p]
	end
	t.n = topindex(t, n)
	t.capacity = math.max(t.capacity or 0, t.n)
	setn(t, ti, n, ...)
end

--[[
--record stack (i.e. stack of fixed-length arrays)

local function reclen(t, n)
	t.reclen = n
	t.recnum = 0
	return t
end

local function recnum(t)
	return t.recnum
end

local function reci(t, ri, i)
	return (ri - 1) * t.reclen + i
end

local function rec(t, ri)
	return unpack(t,  reci(t, ri, 1), reci(t, ri + 1, 0))
end

local function setrec(t, ri, ...)
	assert(ri >= 1)
	assert(ri <= t.reclen)
	for i=1,t.reclen do
		local v = select(i, ...)
		t[reci(t, ri, i)] = v or false
	end
end

local function pushrec(t, ...)
	t.recnum = t.recnum + 1
	t.capacity = math.max(t.capacity or 0, t.recnum)
	setrec(t, t.recnum, ...)
end

local function poprec(t)
	for i=1,t.reclen do
		t[reci(t, t.recnum, i)] = false
	end
	t.recnum = t.recnum - 1
end

local function nextrec(t, ri)
	ri = (ri or 0) + 1
	return ri, rec(t, ri)
end

local function recs(t)
	return nextrec, t
end

local function toprec(t, ri)
	return rec(
end
]]

--vararg stack (i.e. stack of variable-length arrays)

local function topvar(t)
	local n = top(t)
	if not n then return end
	return unpack(t, t.n - n, t.n - 1)
end

local function pushvar(t, ...)
	local n = select('#', ...)
	--TODO: push(t, n) and make fwd and reverse iterators
	for i=1,n do
		local v = select(i, ...)
		push(t, v)
	end
	push(t, n)
end

local function pass(t, ...)
	popn(t, pop(t))
	return ...
end
local function popvar(t)
	if not top(t) then return end
	return pass(t, topvar(t))
end

local function set_topvar(t, ...)
	local n0 = top(t)
	if not n0 then return end
	local i0 = t.n - n0
	local n1 = select('#', ...)
	for i = 1, n1 do
		t[i0 + i - 1] = select(i, ...) or false
	end
	t.n = t.n + n1 - n0
end

--imgui controller -----------------------------------------------------------

function imgui:_fps_function()
	local count_per_sec = 1
	local frame_count, last_frame_count, last_time = 0, 0
	return function(self)
		last_time = last_time or self:_backend_clock()
		frame_count = frame_count + 1
		local time = self:_backend_clock()
		if time - last_time > 1 / count_per_sec then
			last_frame_count, frame_count = frame_count, 0
			last_time = time
		end
		return last_frame_count * count_per_sec
	end
end

function imgui:new()

	--NOTE: this is shallow copy, so themes and defaults are shared
	--between all instances.
	local inst = glue.update({}, self)
	inst.new = false --prevent instantiating from the instance

	--statically inherit imgui extensions loaded at runtime
	local self = setmetatable(inst, {__index = function(t, k)
		local v = self[k]
		rawset(t, k, v)
		return v
	end})

	self.init = true --one-shot init trigger, kept until the first frame ends
	self.clock = false --updated on events and on backend-triggered repaints

	self:_init_cr()
	self:_init_theme()
	self:_init_layout()
	self:_init_layers()
	self:_init_animation()
	self:_init_input()

	--widget state
	self.active = false   --has mouse focus
	self.focused = false  --has keyboard focus
	self.ui = {}          --state to be used by the active control

	--event stream
	self.events = {}

	self._fps = self:_fps_function()

	return self
end

function imgui:_render_frame(cr)

	self:_init_frame_cr(cr)
	self:_init_frame_theme()
	self:_init_frame_layout()
	self:_init_frame_input()
	self:_init_frame_animation()
	self:_init_frame_layers()

	self:_backend_render_frame() --user code
	self:_render_layers()

	--magnifier glass: so useful it's enabled by default
	if self.show_magnifier and self:keypressed'ctrl' and self.mousex then
		self.cr:identity_matrix()
		self:magnifier{
			id = 'mag',
			x = self.mousex - 200,
			y = self.mousey - 100,
			w = 400,
			h = 200,
			zoom_level = 4,
		}
	end

	if self.continuous_rendering then
		if self.title then
			self.title = string.format('%s - %d fps', self.title, self:_fps())
		else
			self.title = string.format('%d fps', self:_fps())
		end
	end

	--set/reset the window title
	self:_backend_set_title(self.title)
	self.title = false

	--set/reset the mouse cursor
	self:_backend_set_cursor(self.cursor)
	self.cursor = false

	self:_done_frame_layers()
	self:_done_frame_animation()
	self:_done_frame_input()
	self:_done_frame_layout()
	self:_done_frame_theme()
	self:_done_frame_cr()

	self.init = false
end

function imgui:_consume_event(clock, event, ...)
	self.clock = clock
	self._on[event](self, ...)
end

function imgui:_backend_repaint(cr)
	if not top(self.events) then
		self.clock = self:_backend_clock()
	end
	repeat
		if top(self.events) then
			self:_consume_event(popvar(self.events))
		end
		repeat
			self._frame_valid = true
			self:_render_frame(cr)
		until self._frame_valid
	until not top(self.events)
	self.clock = false
end

function imgui:invalidate()
	self._frame_valid = false
end

--graphics context -----------------------------------------------------------

function imgui:_init_cr() end

function imgui:_init_frame_cr(cr)
	self.cr = cr
	self.cr:save()
end

function imgui:_done_frame_cr()
	self:_backend_load_font(nil)
	self.cr:restore()
	self.cr = false
end

--mouse & keyboard API -------------------------------------------------------

function imgui:_reset_input_state()
	--mouse one-shot state, set when mouse state changed between frames
	self.lpressed = false
	self.rpressed = false
	self.clicked = false       --left mouse button clicked (one-shot)
	self.rightclick = false    --right mouse button clicked (one-shot)
	self.doubleclicked = false --left mouse button double-clicked (one-shot)
	self.tripleclicked = false --left mouse button triple-clicked (one-shot)
	self.wheel_delta = 0       --mouse wheel number of scroll pages (one-shot)
	--keyboard state: to be set on keyboard events
	self.key = false
	self.char = false
	self.shift = false
	self.ctrl = false
	self.alt = false
end

function imgui:_init_input()
	self:_reset_input_state()
end

function imgui:_init_frame_input()
	if self.init then
		imgui.mousex,
		imgui.mousey,
		imgui.lbutton,
		imgui.rbutton =
			self:_backend_mouse_state()
	end
end

function imgui:_done_frame_input()
	self:_reset_input_state()
end

imgui._on = {} --{event->handler}

function imgui._on:mousemove(x, y)
	self.mousex = x
	self.mousey = y
end

function imgui._on:mouseenter(x, y)
	self.mousex = x
	self.mousey = y
end

function imgui._on:mouseleave()
	self.mousex = false
	self.mousey = false
end

function imgui._on:mousedown(button, x, y)
	if button == 'left' then
		if not self.lbutton then
			self.lpressed = true
		end
		self.lbutton = true
	elseif button == 'right' then
		if not self.rbutton then
			self.rpressed = true
		end
		self.rbutton = true
	end
	self.mousex = x
	self.mousey = y
end

function imgui._on:mouseup(button, x, y)
	if button == 'left' then
		self.lbutton = false
		self.clicked = true
	elseif button == 'right' then
		self.rbutton = false
		self.rightclick = true
	end
	self.mousex = x
	self.mousey = y
end

function imgui._on:doubleclick(button, x, y)
	self.doubleclicked = true
end

function imgui._on:tripleclick(button, x, y)
	self.tripleclicked = true
end

function imgui._on:mousewheel(delta, x, y)
	self.wheel_delta = self.wheel_delta + (delta / 120 or 0)
end

function imgui._on:keydown(key)
	self.key = key
	self.shift = self:_backend_key_state'shift'
	self.ctrl  = self:_backend_key_state'ctrl'
	self.alt   = self:_backend_key_state'alt'
end

function imgui._on:keyup(key)
	self.key = nil
	self.shift = self:_backend_key_state'shift'
	self.ctrl  = self:_backend_key_state'ctrl'
	self.alt   = self:_backend_key_state'alt'
end

imgui._on.keypress = imgui._on.keydown

function imgui._on:keychar(char)
	self.char = char
end

function imgui:_backend_event(...)
	local clock = self:_backend_clock()
	pushvar(self.events, clock, ...)
	self:_backend_invalidate()
end

function imgui:mousepos()
	if not self.mousex then return end
	return self.cr:device_to_user(self.mousex, self.mousey)
end

function imgui:hotbox(x, y, w, h)
	if self.hot_layer and self.hot_layer ~= self.current_layer then
		return false
	end
	local mx, my = self:mousepos()
	if not mx then return false end
	return
		box2d.hit(mx, my, x, y, w, h)
		and self.cr:in_clip(mx, my)
end

function imgui:keypressed(keyname)
	return self:_backend_key_state(keyname)
end

--animation API --------------------------------------------------------------

function imgui:_init_animation()
	self.stopwatches = {}
	self.stopwatches.freelist = {}
	self.stopwatches.next_expire_time = 1/0
end

function imgui:_init_frame_animation() end

local function expire_time(time, duration)
	--this formula tells how long before a stopwatch index can get reused.
	--currently it's twice the stopwatch's period and at least 1 second.
	return time + math.max(1, duration * 2)
end

function imgui:_done_frame_animation()
	--free any expired stopwatches and update the next time we need to check.
	if topindex(self.stopwatches) then
		if self.clock >= self.stopwatches.next_expire_time then
			local next_time = 1/0
			for i = 1, #self.stopwatches, 5 do
				local time, duration = unpack(self.stopwatches, i, i + 1)
				if self.clock >= expire_time(time, duration) then
					setn(self.stopwatches, i, 5) --clear slot
					push(self.stopwatches.freelist, i)
				else
					next_time = math.min(next_time, expire_time(time, duration))
				end
			end
			self.stopwatches.next_expire_time = next_time
		end
	end
end

function imgui:stopwatch(duration, formula, i1, i2)
	formula = assert(easing[formula or 'linear'] or formula, 'invalid formula')
	i1 = i1 or 0
	i2 = i2 or 1

	self.stopwatches.next_expire_time =
		math.min(self.stopwatches.next_expire_time,
			expire_time(self.clock, duration))

	if topindex(self.stopwatches.freelist) > 0 then
		local i = pop(self.stopwatches.freelist)
		setn(self.stopwatches, i, 5, self.clock, duration, formula, i1, i2)
		return i
	else
		return pushn(self.stopwatches, 5, self.clock, duration, formula, i1, i2)
	end
end

function imgui:progress(i)
	local time, duration, formula, i1, i2 = unpack(self.stopwatches, i, i + 4)
	if not time or self.clock >= time + duration then return end
	return formula((self.clock - time), i1, i2, duration)
end

--themed graphics API --------------------------------------------------------

imgui.themes = {}
imgui.default = {} --theme defaults, declared inline

imgui.themes.dark = glue.inherit({
	window_bg     = '#000000',
	faint_bg      = '#ffffff33',
	normal_bg     = '#ffffff4c',
	normal_fg     = '#ffffff',
	default_bg    = '#ffffff8c',
	default_fg    = '#ffffff',
	normal_border = '#ffffff66',
	hot_bg        = '#ffffff99',
 	hot_fg        = '#000000',
	selected_bg   = '#ffffff',
	selected_fg   = '#000000',
	disabled_bg   = '#ffffff4c',
	disabled_fg   = '#999999',
	error_bg      = '#ff0000b2',
	error_fg      = '#ffffff',
}, imgui.default)

imgui.themes.light = glue.inherit({
	window_bg     = '#ffffff',
	faint_bg      = '#00000033',
	normal_bg     = '#0000004c',
	normal_fg     = '#000000',
	default_bg    = '#0000008c',
	default_fg    = '#000000',
	normal_border = '#00000066',
	hot_bg        = '#00000099',
	hot_fg        = '#ffffff',
	selected_bg   = '#000000e5',
	selected_fg   = '#ffffff',
	disabled_bg   = '#0000004c',
	disabled_fg   = '#666666',
	error_bg      = '#ff0000b2',
	error_fg      = '#ffffff',
}, imgui.default)

imgui.default_theme = imgui.themes.dark

function imgui:_init_theme() end

function imgui:_init_frame_theme()
	self.theme = self.default_theme

	--clear the background
	self:setcolor'window_bg'
	self.cr:paint()
end

function imgui:_done_frame_theme()
	self.theme = false
end

--themed color setting

local function parse_color(c, g, b, a)
	if type(c) == 'string' then
		return color.string_to_rgba(c)
	elseif type(c) == 'table' then
		local r, g, b, a = unpack(c)
		return r, g, b, a or 1
	else
		return c, g, b, a or 1
	end
end

function imgui:setcolor(color, g, b, a)
	self.cr:rgba(parse_color(self.theme[color] or color, g, b, a))
end

--themed font setting

local function parse_font(font, default_font)
	local name, size, weight, slant =
		font:match'([^,]*),?([^,]*),?([^,]*),?([^,]*)'
	local t = {}
	t.name = assert(str(name) or default_font:match'^(.-),')
	t.size = tonumber(str(size)) or default_font:match',(.*)$'
	t.weight = str(weight) or 'normal'
	t.slant = str(slant) or 'normal'
	return t
end

local fonts = setmetatable({}, {__mode = 'kv'})

local function load_font(font, default_font)
	font = font or default_font
	local t = fonts[font]
	if not t then
		if type(font) == 'string' then
			t = parse_font(font, default_font)
		elseif type(font) == 'number' then
			t = parse_font(default_font, default_font)
			t.size = font
		end
		fonts[font] = t
	end
	return t
end

imgui.default.default_font = 'Open Sans,14'

function imgui:setfont(font)
	font = load_font(self.theme[font] or font, self.theme.default_font)
	self:_backend_load_font(font.name, font.weight, font.slant)
	self.cr:font_size(font.size)
	font.extents = font.extents or self.cr:font_extents()
	return font
end

--themed fill & stroke

function imgui:fill(color)
	self:setcolor(color or 'normal_bg')
	self.cr:fill()
end

function imgui:stroke(color, line_width)
	self:setcolor(color or 'normal_fg')
	self.cr:line_width(line_width or 1)
	self.cr:stroke()
end

function imgui:fillstroke(fill_color, stroke_color, line_width)
	if fill_color and stroke_color then
		self:setcolor(fill_color)
		self.cr:fill_preserve()
		self:stroke(stroke_color, line_width)
	elseif fill_color then
		self:fill(fill_color)
	elseif stroke_color then
		self:stroke(stroke_color, line_width)
	else
		self:fill()
	end
end

--themed basic shapes

function imgui:rect(x, y, w, h, ...)
	self.cr:rectangle(x, y, w, h)
	self:fillstroke(...)
end

function imgui:dot(x, y, r, ...)
	self:rect(x-r, y-r, 2*r, 2*r, ...)
end

function imgui:circle(x, y, r, ...)
	self.cr:circle(x, y, r)
	self:fillstroke(...)
end

function imgui:line(x1, y1, x2, y2, ...)
	self.cr:move_to(x1, y1)
	self.cr:line_to(x2, y2)
	self:stroke(...)
end

function imgui:curve(x1, y1, x2, y2, x3, y3, x4, y4, ...)
	self.cr:move_to(x1, y1)
	self.cr:curve_to(x2, y2, x3, y3, x4, y4)
	self:stroke(...)
end

--themed multi-line self-aligned text

local function round(x)
	return math.floor(x + 0.5)
end

local function text_args(self, s, font, color, line_spacing)
	s = tostring(s)
	font = self:setfont(font)
	self:setcolor(color or 'normal_fg')
	local line_h = font.extents.height * (line_spacing or 1)
	return s, font, line_h
end

function imgui:text_extents(s, font, line_h)
	font = self:setfont(font)
	local w, h = 0, 0
	for s in glue.lines(s) do
		local ext = cr:text_extents(s)
		w = math.max(w, ext.width)
		h = h + ext.y_bearing
	end
	return w, h
end

local function draw_text(cr, x, y, s, align, line_h) --multi-line text
	for s in glue.lines(s) do
		if align == 'right' then
			local extents = cr:text_extents(s)
			cr:move_to(x - extents.width, y)
		elseif align == 'center' then
			local extents = cr:text_extents(s)
			cr:move_to(x - round(extents.width / 2), y)
		else
			cr:move_to(x, y)
		end
		cr:show_text(s)
		y = y + line_h
	end
end

function imgui:text(x, y, s, font, color, align, line_spacing)
	local s, font, line_h = text_args(self, s, font, color, line_spacing)
	draw_text(self.cr, x, y, s, align, line_h)
end

function imgui:textbox(x, y, w, h, s, font, color, halign, valign, line_spacing)
	local s, font, line_h = text_args(self, s, font, color, line_spacing)

	self.cr:save()
	self.cr:rectangle(x, y, w, h)
	self.cr:clip()

	if halign == 'right' then
		x = x + w
	elseif halign == 'center' then
		x = x + round(w / 2)
	end

	if valign == 'top' then
		y = y + font.extents.ascent
	else
		local lines_h = 0
		for _ in glue.lines(s) do
			lines_h = lines_h + line_h
		end
		lines_h = lines_h - line_h

		if valign == 'bottom' then
			y = y + h - font.extents.descent
		elseif valign == 'center' then
			local h1 = h + font.extents.ascent - font.extents.descent + lines_h
			y = y + round(h1 / 2)
		end
		y = y - lines_h
	end

	draw_text(self.cr, x, y, s, halign, line_h)

	self.cr:restore()
end

--layout API -----------------------------------------------------------------

function imgui:_init_frame_layout()
	--init layout state consts
	local cw, ch = self:_backend_client_size()
	self.window_cw = cw
	self.window_ch = ch
	--init layout state vars
	self.flow = false --no default: force app to start specific
	self.halign = 'l'
	self.valign = 't'
	self.cx = 0
	self.cy = 0
	self.cw = self.window_cw
	self.ch = self.window_ch
	self.margin_w = 0
	self.margin_h = 0
end

function imgui:_init_layout()
	self.cr_stack = {}
	self.bbox_stack = {}
end

function imgui:_done_frame_layout()
	assert(not top(self.cr_stack), 'missing end_box()')
	assert(not top(self.bbox_stack), 'missing end_flowbox()')
end

function imgui:_save_cr()
	pushvar(self.cr_stack,
		self.cr,
		self.flow,
		self.halign,
		self.valign,
		self.cx,
		self.cy,
		self.cw,
		self.ch,
		self.margin_w,
		self.margin_h)
	self.cr:save()
end

function imgui:_restore_cr()
	self.cr,
	self.flow,
	self.halign,
	self.valign,
	self.cx,
	self.cy,
	self.cw,
	self.ch,
	self.margin_w,
	self.margin_h
		= popvar(self.cr_stack)
	self.cr:restore()
end

function imgui:setmargin(mw1, mh1)
	local mw, mh, cx, cy, cw, ch =
		self.margin_w, self.margin_h, self.cx, self.cy, self.cw, self.ch
	mw1 = mw1 or 0
	mh1 = mh1 or 0
	cx = cx + mw1 - mw
	cy = cy + mh1 - mh
	cw = cw - 2 * (mw1 - mw)
	ch = ch - 2 * (mh1 - mh)
	self.margin_w, self.margin_h, self.cx, self.cy, self.cw, self.ch =
		mw1, mh1, cx, cy, cw, ch
end

function imgui:setflow(opt, margin_w, margin_h)
	local flow, halign, valign
	if opt then
		flow, halign, valign  = opt:match'^([hv]?)([lrc]?)([tbc]?)'
		flow, halign, valign = str(flow), str(halign), str(valign)
	elseif self.flow == 'h' then --switch flow
		flow = 'v'
	elseif self.flow == 'v' then --switch flow
		flow = 'h'
	end
	if flow then self.flow = flow end
	if halign then self.halign = halign end
	if valign then self.valign = valign end
	if margin_w then self.margin_w = margin_w end
	if margin_h then self.margin_h = margin_h end
end

local function percent(s, from)
	if not (type(s) == 'string' and s:find'%%$') then return end
	local p = tonumber((s:gsub('%%$', '')))
	return p and p / 100 * (from or 1)
end

function imgui:flowbox(w, h)
	local cw = self.cw
	local ch = self.ch
	w = percent(w, cw) or tonumber(w or cw)
	h = percent(h, ch) or tonumber(h or ch)
	if w < 0 then w = cw + w end
	if h < 0 then h = ch + h end
	local x, y
	if self.halign == 'l' then
		x = 0
	elseif self.halign == 'r' then
		x = cw - w
	elseif self.halign == 'c' then
		x = (cw - w) / 2
	end
	if self.valign == 't' then
		y = 0
	elseif self.valign == 'b' then
		y = ch - h
	elseif self.valign == 'c' then
		y = (ch - h) / 2
	end
	return self.cx + x, self.cy + y, w, h
end

function imgui:add_flowbox(x, y, w, h)

	--update the current bounding box
	local bx, by, bw, bh = topvar(self.bbox_stack)
	if bx ~= nil then
		if bx then
			bx, by, bw, bh = box2d.bounding_box(bx, by, bw, bh, x, y, w, h)
		else
			bx, by, bw, bh = x, y, w, h
		end
		set_topvar(self.bbox_stack, bx, by, bw, bh)
	end

	--update client rectangle
	if self.flow == 'v' then
		local bh = h + self.margin_h
		self.ch = math.max(0, self.ch - bh)
		if self.valign ~= 'b' then
			self.cy = self.cy + h + self.margin_h
		end
	elseif self.flow == 'h' then
		local bw = w + self.margin_w
		self.cw = math.max(0, self.cw - bw)
		if self.halign ~= 'r' then
			self.cx = self.cx + w + self.margin_w
		end
	end

end

function imgui:begin_flowbox(flow, margin_w, margin_h)
	self:_save_cr()
	pushvar(self.bbox_stack, false, false, false, false) --bx, by, bw, bh
	self:setflow(flow, margin_w, margin_h)
end

function imgui:end_flowbox()
	local bx, by, bw, bh = pop(self.bbox_stack)
	assert(bx, 'end_flowbox() without begin_flowbox()')
	self:_restore_cr()
	self:add_flowbox(bx, by, bw, bh)
end

function imgui:spacer(w, h)
	local x, y, w, h = self:flowbox(w, h)
	self:add_flowbox(x, y, w, h)
end

function imgui:box(w, h)
	local x, y, w, h = self:flowbox(w, h)

	local cr = self.cr
	cr:rgb(1, .5, .5)
	cr:line_width(1)
	cr:rectangle(x, y, w, h)
	cr:stroke()

	self:add_flowbox(x, y, w, h)
end

function imgui:begin_box_noclip(w, h, flow, margin_w, margin_h)
	self:_save_cr()
	local x, y, w, h = self:flowbox(w, h)
	pushvar(self.cr_stack, x, y, w, h)
	self.cx = x
	self.cy = y
	self.cw = w
	self.ch = h
	self:setflow(flow, margin_w, margin_h)
end

function imgui:begin_box(w, h, flow, margin_w, margin_h)
	self:begin_box_noclip(w, h, flow, margin_w, margin_h)
	self.cr:rectangle(self.cx, self.cy, self.cw, self.ch)
	self.cr:clip()
end

function imgui:end_box()
	local x, y, w, h = popvar(self.cr_stack)
	assert(x, 'end_box() without begin_box()')
	self:_restore_cr()
	self:add_flowbox(x, y, w, h)
end

--layers API -----------------------------------------------------------------

function imgui:_init_layers()
	self.layers = {}
	self.layer_stack = {}
	self.hot_layer = false
	self.current_layer = false
	self.current_z_order = 0
end

function imgui:_init_frame_layers()
	self.current_z_order = 0
end
function imgui:_done_frame_layers() end

function imgui:_render_layers()
	assert(self.current_layer == false, 'missing end_layer()')

	for i = 1, topindex(self.layers), 4 do
		local sr, id, hit_test_func, z = unpack(self.layers, i, i + 3)
		self.cr:identity_matrix()
		self.cr:source(sr)
		self.cr:paint()
		self.cr:rgb(0, 0, 0)
	end

	--hit test layers in reverse z_order to find the new hot one
	local new_hot_layer = false
	local mx = self.mousex
	local my = self.mousey
	if mx then
		for i = topindex(self.layers) - 3, 1, -4 do
			local sr, id, hit_test = unpack(self.layers, i, i + 2)
			if hit_test then --user-provided function
				if hit_test(self, mx, my) then
					new_hot_layer = id
					break
				end
			else --test on sr's bbox
				local x, y, w, h = sr:ink_extents()
				if box2d.hit(mx, my, x, y, w, h) then
					new_hot_layer = id
					break
				end
			end
		end
	end

	--free layer surfaces and clear the stack
	for i = 1, topindex(self.layers), 4 do
		local sr = self.layers[i]
		sr:free()
	end
	popall(self.layers)

	--check if the active layer has changed, in which case we need
	--to invalidate the whole frame, because it's like if mouse moved.
	if new_hot_layer ~= self.hot_layer then
		self.hot_layer = new_hot_layer
		self:invalidate()
	end
end

function imgui:begin_layer(id, z_order, hit_test_func)
	self:_save_cr()
	local sr = self:_backend_layer_surface()
	local cr = sr:context()
	self:_init_frame_cr(cr)
	self:_init_frame_layout()

	z_order = z_order or self.current_z_order * 100 + 1

	--insert record into the layers stack at the right index based on z-order
	local insert_index = topindex(self.layers, 1)
	for i = 1, topindex(self.layers), 4 do
		local z = self.layers[i + 3]
		if z > z_order then
			insert_index = i
			break
		end
	end
	insertn(self.layers, insert_index, 4, sr, id, hit_test_func, z_order)

	push(self.layer_stack, self.current_layer)
	push(self.layer_stack, self.current_z_order)
	self.current_layer = id
	self.current_z_order = z_order
end

function imgui:end_layer()
	assert(self.current_layer, 'end_layer() without begin_layer()')
	self.current_z_order = pop(self.layer_stack)
	self.current_layer   = pop(self.layer_stack)
	self.current_z_order = self.current_z_order + 1
	self:setfont(nil)
	self.cr:free()
	self:_restore_cr()
end

--label widget ---------------------------------------------------------------

function imgui:label(s)
	self:setfont'default_font'
	self:setcolor'normal_fg'
	local ext = self.cr:text_extents(s)
	local w, h, yb = ext.width, ext.height, ext.y_bearing
	local x, y, w, h = self:flowbox(w, h)
	self.cr:move_to(x, y - yb)
	self.cr:show_text(s)
	self:add_flowbox(x, y, w, h)
end

--image widget ---------------------------------------------------------------

function imgui:image(src)

	--link image bits to a surface
	local img = src
	if src.format ~= 'bgra8'
		or src.bottom_up
		or bitmap.stride(src) ~=
			bitmap.aligned_stride(bitmap.min_stride(src.format, src.w))
	then
		img = bitmap.new(src.w, src.h, 'bgra8', false, true)
		bitmap.paint(src, img)
	end
	local surface = cairo.image_surface(img)

	local mt = self.cr:matrix()
	self.cr:translate(x, y)
	if t.scale then
		self.cr:scale(t.scale, t.scale)
	end
	self.cr:source(surface)
	self.cr:paint()
	self.cr:rgb(0,0,0)
	self.cr:matrix(mt)

	surface:free()
end

--external widgets -----------------------------------------------------------

glue.autoload(imgui, {
	--containers
	vscrollbar     = 'imgui_scrollbars',
	hscrollbar     = 'imgui_scrollbars',
	scrollbox      = 'imgui_scrollbars',
	vsplitter      = 'imgui_splitter',
	hsplitter      = 'imgui_splitter',
	toolbox        = 'imgui_toolbox',
	tablist        = 'imgui_tablist',
	--actionables
	button         = 'imgui_buttons',
	mbutton        = 'imgui_buttons',
	togglebutton   = 'imgui_buttons',
	slider         = 'imgui_slider',
	menu           = 'imgui_menu',
	dragpoint      = 'imgui_dragpoint',
	dragpoints     = 'imgui_dragpoint',
	hue_wheel      = 'imgui_hue_wheel',
	sat_lum_square = 'imgui_sat_lum_square',
	--text editing
	editbox        = 'imgui_editbox',
	combobox       = 'imgui_combobox',
	filebox        = 'imgui_filebox',
	screen         = 'imgui_screen',
	--tools
	magnifier      = 'imgui_magnifier',
	checkerboard   = 'imgui_checkerboard',
	--toys
	analog_clock   = 'imgui_analog_clock',
	--complex
	code_editor    = 'imgui_code_editor',
	grid           = 'imgui_grid',
	treeview       = 'imgui_treeview',
})

return imgui
