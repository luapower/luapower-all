
--extensible UI toolkit with layouts, styles and animations.
--Written by Cosmin Apreutesei. Public Domain.

local oo = require'oo'
local glue = require'glue'
local box2d = require'box2d'
local easing = require'easing'
local color = require'color'
local draw = require'ui_draw'
local time = require'time'

local push = table.insert
local pop = table.remove
local indexof = glue.indexof
local update = glue.update
local attr = glue.attr
local lerp = glue.lerp

--object system --------------------------------------------------------------

local object = oo.object()

function object:override_subclass(inherited, ...)
	--speed up class field lookup by converting subclassing to static
	--inheritance. note: this breaks runtime patching of non-final classes.
	return inherited(self, ...):detach()
end

function object:before_init()
	--speed up virtual property lookup without detaching instances completely,
	--which would copy over too many fields.
	self.getproperty = self.getproperty
	self.setproperty = self.setproperty
end

--module ---------------------------------------------------------------------

local ui = oo.ui(object)
ui.object = object

function ui:after_init()
	local class_stylesheet = self._stylesheet
	self._stylesheet = self:stylesheet()
	self._stylesheet:add_stylesheet(class_stylesheet)
	self._elements = {}
	self._element_index = self:element_index()
end

--selectors ------------------------------------------------------------------

ui.selector = oo.selector(ui.object)

local function parse_tags(s, t)
	t = t or {}
	for tag in s:gmatch'[^%s]+' do
		push(t, tag)
	end
	return t
end

function ui.selector:after_init(ui, sel, filter)
	if sel:find'>' then --parents filter
		self.parent_tags = {} --{{tag,...}, ...}
		sel = sel:gsub('%s*([^>%s]+)%s*>', function(s) -- tag > ...
			local tags = parse_tags(s)
			push(self.parent_tags, tags)
			return ''
		end)
	end
	self.tags = parse_tags(sel) --tags filter
	assert(#self.tags > 0)
	self.filter = filter --custom filter
end

--check that all needed_tags are found in tags table as keys
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
	if self.filter and not self.filter(elem) then
		return false
	end
	return true
end

--stylesheets ----------------------------------------------------------------

ui.stylesheet = oo.stylesheet(ui.object)

function ui.stylesheet:after_init(ui)
	self.ui = ui
	self.tags = {} --{tag -> {sel1, ...}}
end

function ui.stylesheet:add_style(sel, attrs)
	for i, tag in ipairs(sel.tags) do
		push(attr(self.tags, tag), sel)
	end
	sel.attrs = attrs
end

function ui.stylesheet:add_stylesheet(stylesheet)
	for tag, selectors in pairs(stylesheet.tags) do
		if self.tags[tag] then
			for i,sel in ipairs(selectors) do
				push(self.tags, sel)
			end
		else
			self.tags[tag] = selectors
		end
	end
end

function ui.stylesheet:find_selectors(elem)
	--find all selectors affecting all tags of elem. later tags take precedence
	--over earlier tags, and later selectors affecting a tag take precedence
	--over earlier ones affecting that tag (so no specificity order like css).
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
		elem:transition(sel.attrs)
	end
end

function ui:style(sel, attrs)
	if type(sel) == 'string' and sel:find(',', 1, true) then
		for sel in sel:gmatch'[^,]+' do
			ui:style(sel, attrs)
		end
	else
		local sel = self:selector(sel)
		self._stylesheet:add_style(sel, attrs)
	end
end

ui._stylesheet = ui:stylesheet()

--animations -----------------------------------------------------------------

ui.animation = oo.animation(ui.object)

ui.animation._type = {} --{attr -> type}
ui.animation.type = {}  --{patt|f(attr) -> type}
ui.animation.interpolate = {} --func(d, x1, x2, xout) -> xout

function ui.animation:after_init(ui, elem, attr, to, duration, ease)
	--timing model
	local start = time.clock()
	local ease, way = (ease or 'linear'):match'^([^%s_]+)[%s_]?(.*)'
	if way == '' then way = 'in' end
	local duration = duration or 0
	--animation model
	local atype = self:_attr_type(attr)
	local interpolate = self.interpolate[atype]
	local from = elem[attr]
	local from = interpolate(1, from, from) --copy `from` for by-ref semantics

	function self:update(clock)
		local t = (clock - start) / duration
		local d = easing.ease(ease, way, t)
		if d <= 1 then
			elem[attr] = interpolate(d, from, to, elem[attr])
			return true
		end
	end
end

--find an attribute type based on its name
function ui.animation:_attr_type(attr)
	local atype = self._type[attr]
	if not atype then
		for patt, atype1 in pairs(self.type) do
			if (type(patt) == 'string' and attr:find(patt))
				or (type(patt) ~= 'string' and patt(attr))
			then
				atype = atype1
				break
			end
		end
		atype = atype or 'number'
		self._type[attr] = atype --cache it
	end
	return atype
end

--interpolators

function ui.animation.interpolate.number(d, x1, x2)
	return lerp(d, 0, 1, tonumber(x1), tonumber(x2))
end

local function rgba(s)
	if type(s) == 'string' then
		return color.string_to_rgba(s)
	else
		return unpack(s)
	end
end

function ui.animation.interpolate.color(d, c1, c2, c)
	local r1, g1, b1, a1 = rgba(c1)
	local r2, g2, b2, a2 = rgba(c2)
	local r = lerp(d, 0, 1, r1, r2)
	local g = lerp(d, 0, 1, g1, g2)
	local b = lerp(d, 0, 1, b1, b2)
	local a = lerp(d, 0, 1, a1, a2)
	if type(c) == 'table' then
		c[1], c[2], c[3], c[4] = r, g, b, a
		return c
	else
		return {r, g, b, a}
	end
end

--attr. type matching

ui.animation.type['_color$'] = 'color'

--element lists --------------------------------------------------------------

ui.element_index = oo.element_index(ui.object)

function ui.element_index:after_init(ui)
	self.ui = ui
end

function ui.element_index:add_element(elem)
	--TODO
end

function ui.element_index:remove_element(elem)
	--TODO
end

function ui.element_index:find_elements(sel)
	--TODO
	return self.ui:_find_elements(sel, self._elements)
end

ui.element_list = oo.element_list(ui.object)

function ui:_find_elements(sel, elems)
	local res = self.element_list()
	for i,elem in ipairs(elems) do
		if sel:selects(elem) then
			push(res, elem)
		end
	end
	return res
end

function ui.element_list:each(f)
	for i,elem in ipairs(self) do
		local v = f(elem)
		if v ~= nil then return v end
	end
end

function ui.element_list:find(sel)
	return self:_find_elements(sel, self)
end

function ui:find(sel)
	if type(sel) == 'string' then
		sel = self:selector(sel)
	end
	return self._element_index:find_elements(sel)
end

function ui:each(sel, f)
	return self:find(sel):each(f)
end

--elements -------------------------------------------------------------------

ui.element = oo.element(ui.object)

function ui.element:after_init(ui, t)
	self.ui = ui
	self.id = t.id
	self.window = t.window
	self.parent = t.parent
	self.visible = t.visible == nil or t.visible
	self:_init_tags(t)
end

--tags & styles

function ui.element:_init_tags(t)
	self.tags = {'*'}
	push(self.tags, self.classname)
	push(self.tags, self.id)
	parse_tags(t.tags or '', self.tags)
	for i,tag in ipairs(self.tags) do
		self.tags[tag] = true
	end
	self:update_styles()
end

function ui.element:_settag(tag, set, i)
	if not tag then return end
	if set then --insert/add/move
		i = i or #self.tags + 1
		assert(i <= #self.tags + 1)
		if self.tags[tag] then --remove existing
			local i0 = indexof(tag, self.tags)
			pop(self.tags, i0)
			if i > i0 then
				i = i - 1
			end
		end
		table.insert(self.tags, i, tag)
		self.tags[tag] = true
	elseif self.tags[tag] then --remove
		i = i or indexof(tag, self.tags)
		assert(self.tags[i] == tag)
		pop(self.tags, i)
		self.tags[tag] = nil
	end
end

function ui.element:settags(s, i)
	for op, tag in s:gmatch'([-+~]?)([^%s]+)' do
		if op == '' or op == '+' then
			self:_settag(tag, true, i)
		elseif op == '-' then
			self:_settag(tag, false, i)
		elseif op == '~' then
			self:_settag(tag, not self.tags[tag], i)
		end
	end
	self:update_styles()
end

function ui.element:update_styles()
	self.ui._stylesheet:update_element(self)
end

--animations

function ui.element:transition(attrs)
	local duration = attrs.transition_duration
	if not duration or duration <= 0 then
		update(self, attrs)
	else
		local ease = attrs.transition_ease
		for attr, val in pairs(attrs) do
			if not attr:find'^transition_' then
				self:animate(attr, val, duration, ease)
			end
		end
	end
end

function ui.element:animate(attr, ...)
	self._animations = self._animations or {}
	self._animations[attr] = self:animation(self, attr, ...)
end

function ui.element:draw()
	local a = self._animations
	if not a or not next(a) then return end
	local clock = self:frame_clock()
	local invalidate
	for attr, animation in pairs(a) do
		if animation:update(clock) then
			invalidate = true
		else
			a[attr] = nil
		end
	end
	if invalidate then
		self:invalidate()
	end
end

function ui.element:frame_clock()
	return self.window:frame_clock()
end

function ui.element:animation(...)
	return self.ui:animation(...)
end

function ui.element:invalidate()
	if not self.visible then return end
	self.window:invalidate()
end

--windows --------------------------------------------------------------------

ui.window = oo.window(ui.element)

ui:style('window', {
	background_color = '#000',
})

function ui.window:after_init(ui, t)
	self.dr = draw:new()
	local win = self.window
	self.x, self.y = 0, 0
	self.w, self.h = win:client_size()
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
		self._frame_clock = time.clock()

		local cr = win:bitmap():cairo()
		self.dr.cr = cr
		self:draw()
	end)
	win:on('client_resized.ui', function(win, cw, ch)
		self.w = cw
		self.h = ch
	end)

	self._layers = {}
end

function ui.window:free()
	win:off'.ui'
	self.window = nil
end

function ui.window:rect()
	return self.x, self.y, self.w, self.h
end

--layer management

function ui.window:sort_layers()
	table.sort(self._layers, function(a, b)
		return a.z_order < b.z_order
	end)
end

function ui.window:add_layer(layer)
	push(self._layers, layer)
	self:sort_layers()
end

function ui.window:remove_layer(layer)
	local i = indexof(layer, self._layers)
	if i then pop(self._layers, i) end
end

function ui.window:hit_test_layer(x, y)
	for i = #self._layers, 1, -1 do
		local layer = self._layers[i]
		if layer:hit_test(x, y) then
			return layer, x - layer.x, y - layer.y
		end
	end
end

--mouse events routing to layers and to the active widget

function ui.window:set_hot_layer(hot_layer) --virtual property!
	if self.hot_layer and self.hot_layer ~= hot_layer then
		self.hot_layer:fire('mouseleave')
	end
end

function ui.window:mousemove(x, y)
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

function ui.window:mouseenter(x, y)
	self:mousemove(x, y)
end

function ui.window:mouseleave()
	self.hot_layer = false
end

function ui.window:mousedown(button, x, y)
	local layer, wx, wy = self:hit_test_layer(x, y)
	self.hot_layer = layer
	if layer then
		layer:fire('mousedown', button, wx, wy)
	end
end

function ui.window:mouseup(button, x, y)
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

--rendering layers

function ui.window:after_draw()
	if not self.visible then return end
	self.dr:paint(self.background_color) --clear the background
	for i = 1, #self._layers do
		local layer = self._layers[i]
		layer:draw()
	end
end

--animations management

function ui.window:frame_clock()
	return self._frame_clock
end

--[[
function ui.window:animate(elem, attr, val, duration, ease)
	local a = self._animations
	local t = glue.attr(a, elem)
	local ease, way = ease:match'^([^%s_])[%s_]?(.*)'
	if way == '' then way = 'in' end
	t[attr] = {ease = ease, way = way, duration = duration,
		start = time.clock(),
		from = elem[attr], to = val,
	}
end

function ui.window:_check_frame()
	local a = self._animations
	local clock = time.clock()
	for elem, t in pairs(a) do
		for attr, t in pairs(t) do
			local d = (clock - t.start) / t.duration
			local d = easing.ease(t.ease, t.way, d)
			interpolate(d, t.from, t.to, elem[attr])
			elem[attr] = val
		end
	end
	self:invalidate()
end

function ui.window:animate()
	--
end
]]

--layers ---------------------------------------------------------------------

ui.layer = oo.layer(ui.element)

function ui.layer:after_init(ui, t)
	if self.parent then return end
	self._z_order = t.z_order or 0
	self.window:add_layer(self)
end

function ui.layer:get_z_order()
	return self._z_order
end

function ui.layer:set_z_order(z_order)
	if self.parent then return end
	self._z_order = z_order
	self.window:sort_layers()
end

function ui.layer:hit_test(x, y) end

--box-like widgets -----------------------------------------------------------

ui.box = oo.box(ui.layer)

function ui.box:after_init(ui, t)
	self.x = t.x
	self.y = t.y
	self.w = t.w
	self.h = t.h
end

function ui.box:rect()
	return self.x, self.y, self.w, self.h
end

function ui.box:hit_test(x, y)
	return box2d.hit(x, y, self:rect())
end

function ui.box:after_draw()
	if not self.visible then return end
	local dr = self.window.dr
	if self.background_color then
		dr:rect(self.x, self.y, self.w, self.h, self.background_color)
	end
	if self.border_color then
		dr:border(self.x, self.y, self.w, self.h, self.border_color)
	end
end

--buttons --------------------------------------------------------------------

ui.button = oo.button(ui.box)

ui:style('button', {
	background_color = '#ffffff4c',
	border_color = '#888',
})

ui:style('button hot', {
	background_color = '#ffffff99',
	border_color = '#ccc',
	transition_duration = 0.5,
})

ui:style('button active', {
	background_color = '#fff',
	border_color = '#fff',
})

function ui.window:button(t)
	t.window = self
	return self.ui:button(t)
end

function ui.button:after_init(ui, t)
	self.text = t.text
end

function ui.button:mouseenter(x, y)
	self.hot = true
	self:settags('hot', indexof('active', self.tags))
	self:invalidate()
end

function ui.button:mouseleave(x, y)
	self.hot = false
	self:settags'-hot'
	self:invalidate()
end

function ui.button:mousedown(button, x, y)
	if button == 'left' then
		self.active = true
		self.window.active_widget = self
		self:settags'active'
		self:invalidate()
	end
end

function ui.button:mouseup(button, x, y)
	if button == 'left' then
		self.active = false
		self.window.active_widget = false
		self:settags'-active'
		self:invalidate()
	end
end

function ui.button:after_draw()
	if not self.visible then return end
	local dr = self.window.dr
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

function ui.scrollbar:after_init(ui, t)
	local vertical = self.vertical
	self.size = assert(t.size, 'size missing')
	self.step = t.step or 1
	self.i = client_offset_clamp(t.i or 0, self.size,
		vertical and self.h or self.w, self.step)
	self.min_width = t.min_width or min_width
	self.autohide = t.autohide
end

function ui.scrollbar:after_draw()
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

function ui.scrollbox:after_init(ui, t)
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
local ui = ui()

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

local win = ui:window{window = win}

local p1 = ui:element{name = 'p1', tags = 'p1'}
local p2 = ui:element{name = 'p2', tags = 'p2', parent = p1}
local b1 = win:button{parent = p2, name = 'b1', tags = 'b1', ctl = ctl, x = 10, y = 10, w = 100, h = 26}
local b2 = win:button{parent = p2, name = 'b2', tags = 'b2', ctl = ctl, x = 20, y = 20, w = 100, h = 26}
local sel = ui:selector('p1 > p2 > b1')
assert(sel:selects(b1) == true)
print('b1.custom_all', b1.custom_all)
print('b2.custom_all', b2.custom_all)
print('b1.custom_field', b1.custom_field)
print('b1.custom_and', b1.custom_and)
print('b2.custom_and', b2.custom_and)
--print('b2.custom_and', b2.custom_and)

local b1 = win:button{name = 'b1', tags = 'b1', ctl = ctl, x = 10, y = 10, w = 100, h = 26}
local b2 = win:button{name = 'b2', tags = 'b2', ctl = ctl, x = 20, y = 20, w = 100, h = 26}
b1.z_order = 2

app:run()

end

return ui
