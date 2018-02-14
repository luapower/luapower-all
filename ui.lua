
--UI toolkit in Lua
--Written by Cosmin Apreutesei. Public Domain.

local oo = require'oo'
local glue = require'glue'
local box2d = require'box2d'
local easing = require'easing'
local time = require'time'
local draw = require'ui_draw'
local push = table.insert
local pop = table.remove
local indexof = glue.indexof

local ui = {}

--controller -----------------------------------------------------------------

ui = oo.ui()

function ui:init(win)
	self.window = win
	self.dr = draw:new()
	win:on('mousemove.ui', function(win, x, y)
		self:mousemove(x, y)
	end)
	win:on('mouseleave.ui', function(win)
		self:mouseleave()
	end)
	win:on('mousedown.ui', function(win, button, x, y)
		self:mousedown(button, x, y)
	end)
	win:on('mouseup.ui', function(win, button, x, y)
		self:mouseup(button, x, y)
	end)
	win:on('repaint.ui', function(win)
		local cr = win:bitmap():cairo()
		self.dr.cr = cr
		self:draw()
	end)
	self._layers = {}
	self._elements = {}
	self.stylesheet = self:stylesheet()
end

function ui:free()
	win:off'.ui'
	self.window = nil
end

--layers

function ui:sort_layers()
	table.sort(self._layers, function(a, b)
		return a.z_order < b.z_order
	end)
end

function ui:add_layer(layer)
	push(self._layers, layer)
	self:sort_layers()
end

function ui:remove_layer(layer)
	local i = indexof(layer, self._layers)
	if i then pop(self._layers, i) end
end

function ui:hit_test_layer(x, y)
	for i = #self._layers, 1, -1 do
		local layer = self._layers[i]
		if layer:hit_test(x, y) then
			return layer, x - layer.x, y - layer.y
		end
	end
end

function ui:set_hot_layer(hot_layer)
	if self.hot_layer and self.hot_layer ~= hot_layer then
		self.hot_layer:fire('mouseleave')
	end
end

function ui:_active_widget_fire(...)
	if not self.capture_mouse then return end
	local widget = self.active_widget
	if not widget then return end
	widget:fire(...)
end

function ui:mousemove(x, y)
	local layer, wx, wy = self:hit_test_layer(x, y)
	local enter = self.hot_layer ~= layer
	self.hot_layer = layer
	if layer then
		layer:fire(enter and 'mouseenter' or 'mousemove', wx, wy)
	end
	local widget = self.active_widget
	if widget then
		widget:fire('mousemove', x - widget.x, y - widget.y)
	end
end

function ui:mouseenter(x, y)
	self:mousemove(x, y)
end

function ui:mouseleave()
	self.hot_layer = false
end

function ui:mousedown(button, x, y)
	local layer, wx, wy = self:hit_test_layer(x, y)
	self.hot_layer = layer
	if layer then
		layer:fire('mousedown', button, wx, wy)
	end
end

function ui:mouseup(button, x, y)
	local layer, wx, wy = self:hit_test_layer(x, y)
	self.hot_layer = layer
	if layer then
		layer:fire('mouseup', button, wx, wy)
	end
	local widget = self.active_widget
	if widget then
		widget:fire('mouseup', button, x - widget.x, y - widget.y)
	end
end

function ui:draw()
	self.dr:paint'window_bg' --clear the background
	for i = 1, #self._layers do
		local layer = self._layers[i]
		layer:draw()
	end
end

--selectors ------------------------------------------------------------------

ui.selector = oo.selector()

local function parse_tags(s, t)
	t = t or {}
	for tag in s:gmatch'[^%s]+' do
		push(t, tag)
	end
	return t
end

local function selects_all()
	return true
end

function ui.selector:init(ui, sel, filter)
	if sel:find'>' then --parent filter
		self.parent_tags = {}
		sel = sel:gsub('%s*([^>%s]+)%s*>', function(s)
			local tags = parse_tags(s)
			push(self.parent_tags, tags)
			return ''
		end)
	end
	self.tags = parse_tags(sel)
	assert(#self.tags > 0)
	self.filter = filter
end

local function has_all_tags(needed_tags, tags)
	for i,tag in ipairs(needed_tags) do
		if not tags[tag] then
			return false
		end
	end
	return true
end

function ui.selector:selects(elem)
	if #self.tags > #elem.tags then
		return false --selector too specific
	end
	if not has_all_tags(self.tags, elem.tags) then
		return false
	end
	if self.parent_tags then
		local i = #self.parent_tags
		local tags = self.parent_tags[i]
		local elem = elem.parent
		while tags and elem do
			if has_all_tags(tags, elem.tags) then
				if i == 1 then
					return true
				end
				i = i - 1
				tags = self.parent_tags[i]
			end
			elem = elem.parent
		end
		return false
	end
	return true
end

--stylesheets ----------------------------------------------------------------

ui.stylesheet = oo.stylesheet()

function ui.stylesheet:init(ui)
	self.ui = ui
	self.tags = {} --{tag -> {sel1, ...}}
end

function ui.stylesheet:add_style(sel, attrs)
	for i, tag in ipairs(sel.tags) do
		local t = glue.attr(self.tags, tag)
		push(t, sel)
	end
	sel.attrs = attrs
end

function ui.stylesheet:find_selectors(elem)
	--find all selectors affecting all tags. later tags take precedence over
	--earlier tags, and later selectors affecting a tag take precedence over
	--earlier selectors affecting that tag (so no specificity order like css).
	local t = {}
	local checked = {}
	local tags = elem.tags
	for i=#tags,1,-1 do
		local tag = tags[i]
		local selectors = self.tags[tag]
		if selectors then
			for i=#selectors,1,-1 do
				local sel = selectors[i]
				if not checked[sel] then
					if sel:selects(elem) then
						push(t, sel)
					end
					checked[sel] = true
				end
			end
		end
	end
	return t
end

function ui.stylesheet:update_element(elem)
	local t = self:find_selectors(elem)
	for i=#t,1,-1 do
		local sel = t[i]
		glue.update(elem, sel.attrs)
	end
end

function ui:style(sel, attrs)
	if type(sel) == 'string' and sel:find(',', 1, true) then
		for sel in sel:gmatch'[^,]+' do
			ui:style(sel, attrs)
		end
	else
		local sel = self:selector(sel)
		self.stylesheet:add_style(sel, attrs)
	end
end

--jquery-like selectors ------------------------------------------------------

ui.find_result = oo.find_result()

function ui:_find(sel, elems)
	local res = self.find_result()
	for i,elem in ipairs(elems) do
		if sel:selects(elem) then
			push(res, elem)
		end
	end
	return res
end

function ui.find_result:each(f)
	for i,elem in ipairs(self) do
		local v = f(elem)
		if v ~= nil then return v end
	end
end

function ui.find_result:find(sel)
	return self:_find(sel, self)
end

function ui:find(sel)
	return self:_find(sel, self._elements)
end

function ui:each(sel, f)
	return self:find(sel):each(f)
end

--animation ------------------------------------------------------------------

ui.stopwatch = oo.stopwatch()

function ui.stopwatch:clock()
	return time.clock()
end

function ui.stopwatch:_init(duration, formula, start)
	self.start = start or self:clock()
	self.duration = duration
	self.formula = easing[formula or 'linear'] or formula
end

function ui.stopwatch:init(ui, duration, formula, i1, i2, start)
	self:_init(duration, formula, start)
	self.i1 = i1 or 0
	self.i2 = i2 or 1
end

function ui.stopwatch:finished()
	return self:clock() - self.start > self.duration
end

function ui.stopwatch:_progress()
	local dt = self:clock() - self.start
	return self.formula(dt, 0, 1, self.duration)
end

function ui.stopwatch:progress()
	return self.i1 + (self.i2 - self.i1) * self:_progress()
end

ui.colorfade = oo.colorfade(ui.stopwatch)

function ui.colorfade:init(ui, duration, formula, color1, color2, start)
	self:_init(duration, formula, start)
	local r1, g1, b1, a1 = ui.dr:color(color1)
	local r2, g2, b2, a2 = ui.dr:color(color2)
	self.dr = r2 - r1
	self.dg = g2 - g1
	self.db = b2 - b1
	self.da = a2 - a1
	self.r = r1
	self.g = g1
	self.b = b1
	self.a = a1
end

function ui.colorfade:progress()
	local d = self:_progress()
	local r = self.r + self.dr * d
	local g = self.g + self.dg * d
	local b = self.b + self.db * d
	local a = self.a + self.da * d
	return r, g, b, a
end

--elements--------------------------------------------------------------------

ui.element = oo.element()

function ui.element:init(ui, t)
	self.ui = ui
	self.tags = {'*', self.classname}
	self.parent = t.parent
	parse_tags(t.tags or '', self.tags)
	for i,tag in ipairs(self.tags) do
		self.tags[tag] = true
	end
	self.ui.stylesheet:update_element(self)
	return t
end

--layers

ui.layer = oo.layer()
ui.layer:inherit(ui.element)

function ui.layer:after_init(t)
	self._z_order = t.z_order or 0
	self.ui:add_layer(self)
	return t
end

function ui.layer:get_z_order()
	return self._z_order
end

function ui.layer:set_z_order(z_order)
	self._z_order = z_order
	self.ui:sort_layers()
end

function ui.layer:hit_test(x, y) end
function ui.layer:draw() end

--box-like widgets

ui.box = oo.box()
ui.box:inherit(ui.layer)

function ui.box:after_init(t)
	self.x = t.x
	self.y = t.y
	self.w = t.w
	self.h = t.h
	return t
end

function ui.box:rect()
	return self.x, self.y, self.w, self.h
end

function ui.box:hit_test(x, y)
	return box2d.hit(x, y, self:rect())
end

--buttons --------------------------------------------------------------------

ui.button = oo.button()
ui.button:inherit(ui.box)

function ui.button:after_init(t)
	return t
end

function ui.button:draw()
	local bg_color
	if self.hot then
		if self.active then
			bg_color = 'selected_bg'
		else
			if self.heating then
				if self.heating:finished() then
					self.heating = nil
					bg_color = 'hot_bg'
				else
					bg_color = {self.heating:progress()}
					self.ui.window:invalidate()
				end
			else
				bg_color = 'hot_bg'
			end
		end
	else
		if self.cooling then
			if self.cooling:finished() then
				self.cooling = nil
				bg_color = 'normal_bg'
			else
				bg_color = {self.cooling:progress()}
				self.ui.window:invalidate()
			end
		else
			bg_color = 'normal_bg'
		end
	end

	self.ui.dr:rect(self.x, self.y, self.w, self.h, bg_color)
	self.ui.dr:border(self.x, self.y, self.w, self.h, 'normal_fg')
end

function ui.button:mousemove(x, y)
	self.ui.window:invalidate()
end

function ui.button:mouseenter(x, y)
	self.hot = true
	self.cooling = false
	self.heating = self.ui:colorfade(0.2, nil, 'normal_bg', 'hot_bg')
	self.ui.window:invalidate()
end

function ui.button:mouseleave(x, y)
	self.hot = false
	self.heating = false
	self.cooling = self.ui:colorfade(0.2, nil, 'hot_bg', 'normal_bg')
	self.ui.window:invalidate()
end

function ui.button:mousedown(button, x, y)
	if button == 'left' then
		self.active = true
		self.ui.active_widget = self
	end
	self.ui.window:invalidate()
end

function ui.button:mouseup(button, x, y)
	if button == 'left' then
		self.active = false
		self.ui.active_widget = false
	end
	self.ui.window:invalidate()
end

--scrollbars -----------------------------------------------------------------

local function bar_size(w, size, minw)
	return math.min(math.max(w^2 / size, minw), w)
end

local function bar_offset(x, w, size, i, bw)
	return x + i * (w - bw) / (size - w)
end

local function bar_offset_clamp(bx, x, w, bw)
	return math.min(math.max(bx, x), x + w - bw)
end

local function bar_segment(x, w, size, i, minw)
	local bw = bar_size(w, size, minw)
	local bx = bar_offset(x, w, size, i, bw)
	bx = bar_offset_clamp(bx, x, w, bw)
	return bx, bw
end

local function client_offset_round(i, step)
	return i - i % step
end

local function client_offset(bx, x, w, bw, size, step)
	return client_offset_round((bx - x) / (w - bw) * (size - w), step)
end

local function client_offset_clamp(i, size, w, step)
	return client_offset_round(math.min(math.max(i, 0),
		math.max(size - w, 0)), step)
end

local function bar_box(x, y, w, h, size, i, vertical, min_width)
	local bx, by, bw, bh
	if vertical then
		by, bh = bar_segment(y, h, size, i, min_width)
		bx, bw = x, w
	else
		bx, bw = bar_segment(x, w, size, i, min_width)
		by, bh = y, h
	end
	return bx, by, bw, bh
end

ui.scrollbar = oo.scrollbar(ui.box)

function ui.scrollbar:after_init(t)
	local vertical = self.vertical
	self.size = assert(t.size, 'size missing')
	self.step = t.step or 1
	self.i = client_offset_clamp(t.i or 0, self.size,
		vertical and self.h or self.w, self.step)
	self.min_width = t.min_width or min_width
	self.autohide = t.autohide
end

function ui.scrollbar:draw()
	if self.autohide and self.active ~= id and not self:hotbox(x, y, w, h) then
		return i
	end

	local bx, by, bw, bh = bar_box(x, y, w, h, size, i, vertical, min_width)
	local hot = self:hotbox(bx, by, bw, bh)

	if not self.active and self.lbutton and hot then
		self.active = id
		self.ui.grab = vertical and self.mousey - by or self.mousex - bx
	elseif self.active == id then
		if self.lbutton then
			if vertical then
				by = bar_offset_clamp(self.mousey - self.ui.grab, y, h, bh)
				i = client_offset(by, y, h, bh, size, step)
			else
				bx = bar_offset_clamp(self.mousex - self.ui.grab, x, w, bw)
				i = client_offset(bx, x, w, bw, size, step)
			end
		else
			self.active = nil
		end
	end

	--drawing
	self:rect(x, y, w, h, 'faint_bg')
	if bw < w or bh < h then
		self:rect(bx, by, bw, bh,
			self.active == id and 'selected_bg' or hot and 'hot_bg' or 'normal_bg')
	end

	return i
end

ui.hscrollbar = oo.hscrollbar(oo.scrollbar)
ui.vscrollbar = oo.vscrollbar(oo.scrollbar)
ui.vscrollbar.vertical = true

--scrollbox ------------------------------------------------------------------

ui.scrollbox = oo.scrollbox(ui.box)

function ui.scrollbox:after_init(t)
	local id = assert(t.id, 'id missing')
	local x, y, w, h = self:getbox(t)
	local cx = t.cx or 0
	local cy = t.cy or 0
	local cw = assert(t.cw, 'cw missing')
	local ch = assert(t.ch, 'ch missing')
	local vscroll = t.vscroll or 'always' --auto, always, never
	local hscroll = t.hscroll or 'always'
	local vscroll_w = t.vscroll_w or scroll_width
	local hscroll_h = t.hscroll_h or scroll_width
	local vscroll_step = t.vscroll_step
	local hscroll_step = t.hscroll_step
	local page_size = t.page_size or 120

	local need_vscroll = vscroll == 'always'
		or (vscroll == 'auto' and ch > h -
			((hscroll == 'always' or hscroll == 'auto' and cw > w - vscroll_w) and hscroll_h or 0))
	local need_hscroll = hscroll == 'always' or
		(hscroll == 'auto' and cw > w - (need_vscroll and vscroll_w or 0))

	w = need_vscroll and w - vscroll_w or w
	h = need_hscroll and h - hscroll_h or h

	if self.wheel_delta ~= 0 and not self.active and self:hotbox(x, y, w, h) then
		cy = cy + self.wheel_delta * page_size
	end

	--drawing
	if need_vscroll then
		cy = -self:vscrollbar{id = id .. '_vscrollbar', x = x + w, y = y, w = vscroll_w, h = h,
										size = ch, i = -cy, step = vscroll_step}
	end
	if need_hscroll then
		cx = -self:hscrollbar{id = id .. '_hscrollbar', x = x, y = y + h, w = w, h = hscroll_h,
										size = cw, i = -cx, step = hscroll_step}
	end

	return
		cx, cy,     --client area coordinates, relative to the clipping rectangle
		x, y, w, h  --clipping rectangle, in absolute coordinates
end



if not ... then

local nw = require'nw'
local app = nw:app()
local win = app:window{x = 940, y = 400, w = 800, h = 400}
local ui = ui(win)

ui:style('*', {
	custom_all = 11,
})

ui:style('button', {
	custom_field = 42,
})

ui:style('button b1', {
	custom_and = 13,
})

ui:style('b1', {
	custom_and = 16, --comes later: overwrite (no specificity)
})

ui:style('button', {
	custom_and = 22, --comes later: overwrite (no specificity)
})

ui:style('p1 > p2 > b1', {
	custom_parent = 54, --comes later: overwrite (no specificity)
})

local p1 = ui:element{name = 'p1', tags = 'p1'}
local p2 = ui:element{name = 'p2', tags = 'p2', parent = p1}

local b1 = ui:button{parent = p2, name = 'b1', tags = 'b1', ctl = ctl, x = 10, y = 10, w = 100, h = 26}
local b2 = ui:button{parent = p2, name = 'b2', tags = 'b2', ctl = ctl, x = 20, y = 20, w = 100, h = 26}

b1.z_order = 2

local sel = ui:selector('p1 > p2 > b1')
assert(sel:selects(b1) == true)

print('b1.custom_all', b1.custom_all)
print('b2.custom_all', b2.custom_all)
print('b1.custom_field', b1.custom_field)
print('b1.custom_and', b1.custom_and)
print('b2.custom_and', b2.custom_and)
--print('b2.custom_and', b2.custom_and)

app:run()

end

return ui
