
--extensible UI toolkit with layouts, styles and animations.
--Written by Cosmin Apreutesei. Public Domain.

if not ... then require'ui_demo'; return end

local oo = require'oo'
local glue = require'glue'
local tuple = require'tuple'
local box2d = require'box2d'
local easing = require'easing'
local color = require'color'
local boxblur = require'boxblur'
local amoeba = require'amoeba'
local time = require'time'
local freetype = require'freetype'
local cairo = require'cairo'
local libjpeg = require'libjpeg'
local fs = require'fs'

local push = table.insert
local pop = table.remove

local indexof = glue.indexof
local update = glue.update
local merge = glue.merge
local attr = glue.attr
local lerp = glue.lerp
local clamp = glue.clamp
local assert = glue.assert
local collect = glue.collect
local sortedpairs = glue.sortedpairs
local memoize = glue.memoize

local function popval(t, v)
	local i = indexof(v, t)
	return i and pop(t, i)
end

local function round(x)
	return math.floor(x + .5)
end

--object system --------------------------------------------------------------

local object = oo.object()

--speed up class field lookup by converting subclassing to static
--inheritance. note that runtime patching of non-final classes doesn't work
--anymore (extending classes still works but it's less useful).
function object:override_subclass(inherited, ...)
	return inherited(self, ...):inherit(self)
end

--speed up virtual property lookup without detaching instances completely
--which would make instances too fat. patching of getters and setters through
--instances is not allowed anymore because this will patch the class instead!
function object:before_init()
	self.__setters = self.__setters
	self.__getters = self.__getters
end

--generic method memoizer
function object:memoize(method_name)
	function self:after_init()
		local method = self[method_name]
		local memfunc = memoize(function(...)
			return method(self, ...)
		end)
		self[method_name] = function(self, ...)
			return memfunc(...)
		end
	end
end

--module object --------------------------------------------------------------

local ui = oo.ui(object)
ui.object = object

function ui:error(msg, ...)
	msg = string.format(msg, ...)
	io.stderr:write(msg)
	io.stderr:write'\n'
end

function ui:check(ret, ...)
	if ret then return ret end
	self:error(...)
end

--selectors ------------------------------------------------------------------

ui.selector = oo.selector(ui.object)

local function noop() end
local function gmatch_tags(s)
	return s and s:gmatch'[^%s]+' or noop
end

function ui.selector:after_init(ui, sel, filter)
	if sel:find'>' then --parents filter
		self.parent_tags = {} --{{tag,...}, ...}
		sel = sel:gsub('([^>]+)%s*>', function(s) -- tags... >
			local tags = collect(gmatch_tags(s))
			push(self.parent_tags, tags)
			return ''
		end)
	end
	self.tags = collect(gmatch_tags(sel)) --tags filter
	assert(next(self.tags))
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

--attribute expansion --------------------------------------------------------

local expand = {} -- {attr -> expand(dest, val)}

local function expand_attr(attr, val, dest)
	local expand = expand[attr]
	if expand then
		expand(dest, val)
		return true
	end
end

--stylesheets ----------------------------------------------------------------

ui.stylesheet = oo.stylesheet(ui.object)

function ui:after_init()
	local class_stylesheet = self._stylesheet
	self._stylesheet = self:stylesheet()
	self._stylesheet:add_stylesheet(class_stylesheet)
end

function ui.stylesheet:after_init(ui)
	self.ui = ui
	self.tags = {} --{tag -> {sel1, ...}}
	self.selectors = {} --{selector1, ...}
end

function ui.stylesheet:add_style(sel, attrs)
	for attr, val in pairs(attrs) do
		if expand_attr(attr, val, attrs) then
			attrs[attr] = nil
		end
	end
	sel.attrs = attrs
	push(self.selectors, sel)
	sel.priority = #self.selectors
	for _,tag in ipairs(sel.tags) do
		local t = attr(self.tags, tag)
		push(t, sel)
	end
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

local function cmp_sel(sel1, sel2)
	return sel1.priority < sel2.priority
end

--gather all attribute values from all selectors affecting all tags of elem.
--later selectors affecting a tag take precedence over earlier ones affecting
--that tag. tags are like css classes while elem.tags is like the html class
--attribute which specifies a list of css classes (i.e. tags) to apply.
function ui.stylesheet:_gather_attrs(elem)
	local st = {} --{sel1, ...}
	local checked = {} --{sel -> true}
	for tag in pairs(elem.tags) do
		local selectors = self.tags[tag]
		if selectors then
			for _,sel in ipairs(selectors) do
				if not checked[sel] then
					if sel:selects(elem) then
						push(st, sel)
					end
					checked[sel] = true
				end
			end
		end
	end
	table.sort(st, cmp_sel)
	local t = {} --{attr -> val}
	for _,sel in ipairs(st) do
		update(t, sel.attrs)
	end
	return t
end

local transition_fields = {delay=1, duration=1, ease=1, speed=1}

local nilkey = {}
local function encode_nil(x) return x == nil and nilkey or x end
local function decode_nil(x) if x == nilkey then return nil end; return x; end

ui.initial = {} --value to use for "initial value" in stylesheets

function ui.stylesheet:update_element(elem)
	local attrs = self:_gather_attrs(elem)

	--gather transition-enabled attrs
	local tr
	for attr, val in pairs(attrs) do
		if val == true then
			local tr_attr = attr:match'^transition_(.*)'
			if tr_attr and not transition_fields[tr_attr] then
				tr = tr or {}
				tr[tr_attr] = true
			end
		end
	end

	--add the saved initial values of attributes that were overwritten by this
	--function in the past but are missing from the computed styles this time.
	local rt = elem._initial_values
	local initial = self.ui.initial
	if rt then
		for attr, init_val in pairs(rt) do
			local val = attrs[attr]
			if val == nil or val == initial then
				attrs[attr] = decode_nil(init_val)
			end
		end
	end

	--save the initial value for an attribute we're about to change for the
	--first time so that later on we can set it back.
	local function save(elem, attr, rt)
		if not rt then
			rt = {}
			elem._initial_values = rt
		end
		if rt[attr] == nil then --new initial value to save
			rt[attr] = encode_nil(elem[attr])
		end
		return rt
	end

	--gather global transition values
	local duration = attrs.transition_duration or 0
	local ease = attrs.transition_ease
	local delay = attrs.transition_delay or 0
	local speed = attrs.transition_speed or 1

	--set all attribute values into elem via transition().
	local changed = false
	for attr, val in pairs(attrs) do
		if val ~= initial then
			if tr and tr[attr] then
				rt = save(elem, attr, rt)
				local duration = attrs['transition_duration_'..attr] or duration
				local ease = attrs['transition_ease_'..attr] or ease
				local delay = attrs['transition_delay_'..attr] or delay
				local speed = attrs['transition_speed_'..attr] or speed
				elem:transition(attr, val, duration / speed, ease, delay)
				changed = true
			elseif not attr:find'^transition_' then
				rt = save(elem, attr, rt)
				elem:transition(attr, val, 0)
				changed = true
			end
		end
	end

	return changed
end

function ui.stylesheet:update_style(style)
	for _,elem in ipairs(self.elements) do
		--TODO:
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

--attribute types ------------------------------------------------------------

ui._type = {} --{attr -> type}
ui.type = {}  --{patt|f(attr) -> type}

--find an attribute type based on its name
function ui:_attr_type(attr)
	for patt, atype in pairs(self.type) do
		if (type(patt) == 'string' and attr:find(patt))
			or (type(patt) ~= 'string' and patt(attr))
		then
			return atype
		end
	end
	return 'number'
end
ui:memoize'_attr_type'

ui.type['_color$'] = 'color'
ui.type['_color_'] = 'color'
ui.type['_colors$'] = 'gradient_colors'

--transition animations ------------------------------------------------------

ui.transition = oo.transition(ui.object)

ui.transition.interpolate = {} --{attr_type -> func(d, x1, x2, xout) -> xout}

function ui.transition:interpolate_function(elem, attr)
	local atype = ui:_attr_type(attr)
	return self.interpolate[atype]
end

function ui.transition:after_init(ui, elem, attr, to, duration, ease, delay)

	--timing model
	local start = time.clock() + (delay or 0)
	local ease, way = (ease or 'linear'):match'^([^%s_]+)[%s_]?(.*)'
	if way == '' then way = 'in' end
	local duration = duration or 0

	--animation model
	local interpolate = self:interpolate_function(elem, attr)
	local from = elem[attr]
	assert(from ~= nil, 'no value for attribute "%s"', attr)
	--set the element value to a copy to avoid overwritting the original value
	--when updating with by-ref semantics.
	elem[attr] = interpolate(1, from, from)

	function self:update(clock)
		local t = (clock - start) / duration
		if t < 0 then --not started
			--nothing
		elseif t >= 1 then --finished, set to actual final value
			elem[attr] = to
		else --running, set to interpolated value
			local d = easing.ease(ease, way, t)
			elem[attr] = interpolate(d, from, to, elem[attr])
		end
		return t <= 1
	end
end

--interpolators

function ui.transition.interpolate.number(d, x1, x2)
	return lerp(d, 0, 1, tonumber(x1), tonumber(x2))
end

local function rgba(s)
	if type(s) == 'string' then
		return color.string_to_rgba(s)
	else
		return unpack(s)
	end
end

function ui.transition.interpolate.color(d, c1, c2, c)
	local r1, g1, b1, a1 = rgba(c1)
	local r2, g2, b2, a2 = rgba(c2)
	local r = lerp(d, 0, 1, r1, r2)
	local g = lerp(d, 0, 1, g1, g2)
	local b = lerp(d, 0, 1, b1, b2)
	local a = lerp(d, 0, 1, a1, a2)
	if type(c) == 'table' then --by-reference semantics
		c[1], c[2], c[3], c[4] = r, g, b, a
		return c
	else --by-value semantics
		return {r, g, b, a}
	end
end

function ui.transition.interpolate.gradient_colors(d, t1, t2, t)
	t = t or {}
	for i,arg1 in ipairs(t1) do
		local arg2 = t2[i]
		local atype = type(arg1) == 'number' and 'number' or 'color'
		t[i] = ui.transition.interpolate[atype](d, arg1, arg2, t[i])
	end
	return t
end

--element lists --------------------------------------------------------------

ui.element_list = oo.element_list(ui.object)
ui.element_index = oo.element_index(ui.object)

function ui:after_init()
	self.elements = self:element_list()
	self._element_index = self:element_index()
end

function ui:before_free()
	while #self.elements > 0 do
		self.elements[#self.elements]:free()
	end
end

function ui:_add_element(elem)
	push(self.elements, elem)
	self._element_index:add_element(elem)
end

function ui:_remove_element(elem)
	popval(self.elements, elem)
	self._element_index:remove_element(elem)
end

function ui:_find_elements(sel, elems)
	local elems = elems or self.elements
	local res = self:element_list()
	for i,elem in ipairs(elems) do
		if sel:selects(elem) then
			push(res, elem)
		end
	end
	return res
end

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
	return self.ui:_find_elements(sel)
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
	if type(sel) == 'string' or type(sel) == 'function' then
		sel = self:selector(sel)
	end
	return self._element_index:find_elements(sel)
end

function ui:each(sel, f)
	return self:find(sel):each(f)
end

--elements -------------------------------------------------------------------

ui.element = oo.element(ui.object)

ui.element.visible = true
ui.element.iswindw = false
ui.element.iswidget = false

ui.element.font_family = 'Open Sans'
ui.element.font_weight = 'normal'
ui.element.font_slant = 'normal'
ui.element.text_size = 14
ui.element.text_color = '#fff'
ui.element.line_spacing = 1

--tags & styles

local function add_tags(tags, t)
	for tag in gmatch_tags(tags) do
		t[tag] = true
	end
end

function ui.element:after_init(ui, t)
	self.ui = ui

	self.ui:_add_element(self)

	local class_tags = self.tags
	local tags = {['*'] = true}
	add_tags(class_tags, tags)
	tags[self.classname] = true
	add_tags(t.tags, tags)
	self.tags = tags
	--update elements in lexicographic order so that eg. `border_width` comes
	--before `border_width_left` even though it's actually undefined behavior.
	self:begin_update()
	for k,v in sortedpairs(t) do
		self[k] = v
	end
	self:end_update()
	self.tags = tags
	if self.id then
		tags[self.id] = true
	end
	self:update_styles()
end

function ui.element:before_free()
	self.ui:_remove_element(self)
	self.ui = false
end

function ui.element:begin_update()
	assert(not self.updating)
	self.updating = true
end

function ui.element:end_update()
	assert(self.updating)
	self.updating = false
end

function ui.element:_addtags(s)
	self.tags = self.tags and self.tags .. ' ' .. s or s
end

function ui.element:_subtag(tag)
	tag = self.classname..'_'..tag
	return self.id and self.id..'.'..tag or tag
end

function ui.element:settags(s)
	for op, tag in s:gmatch'([-+~]?)([^%s]+)' do
		if op == '' or op == '+' then
			self.tags[tag] = true
		elseif op == '-' then
			self.tags[tag] = false
		elseif op == '~' then
			self.tags[tag] = not self.tags[tag]
		end
	end
	if self:update_styles() then
		self:invalidate()
	end
end

function ui.element:update_styles()
	return self.ui._stylesheet:update_element(self)
end

function ui.element:initial_value(attr)
	local t = self._initial_values
	if t then
		local ival = t[attr]
		if ival ~= nil then
			return decode_nil(ival)
		end
	end
	return self[attr]
end

--animated attribute transitions

function ui.element:transition(attr, val, duration, ease, delay)
	if type(val) == 'function' then
		val = val(self, attr)
	end
	if not duration or duration <= 0 then
		if self._transitions then
			self._transitions[attr] = nil --remove existing transition on attr
		end
		self[attr] = val --set attr directly
	else --set attr with transition
		self._transitions = self._transitions or {}
		self._transitions[attr] =
			self.ui:transition(self, attr, val, duration, ease, delay)
	end
end

function ui.element:draw()
	--update transitioning attributes
	local a = self._transitions
	if not a or not next(a) then return end
	local clock = self:frame_clock()
	local invalidate
	for attr, transition in pairs(a) do
		if transition:update(clock) then
			invalidate = true
		else
			a[attr] = nil --finished, remove it
		end
	end
	if invalidate then
		self:invalidate(true)
	end
end

--direct manipulation interface

--TODO: function ui.element


--windows --------------------------------------------------------------------

ui.window = oo.window(ui.element)

ui.window.iswindow = true

ui:style('window_layer', {
	--screen-wiping options that work with transparent windows
	background_color = '#0000',
	background_operator = 'source',
})

function ui.window:after_init(ui, t)

	local win = self.native_window

	self.x, self.y, self.w, self.h = self.native_window:client_rect()

	self.mouse_x = win:mouse'x' or false
	self.mouse_y = win:mouse'y' or false

	local function setcontext()
		self._frame_clock = time.clock()
		self.cr = win:bitmap():cairo()
	end

	local function setmouse(mx, my)
		setcontext()
		self.mouse_x = mx
		self.mouse_y = my
	end

	win:on('mousemove.ui', function(win, mx, my)
		setmouse(mx, my)
		self.ui:_window_mousemove(self, mx, my)
	end)

	win:on('mouseenter.ui', function(win, mx, my)
		setmouse(mx, my)
		self.ui:_window_mouseenter(self, mx, my)
	end)

	win:on('mouseleave.ui', function(win)
		setmouse(false, false)
		self.ui:_window_mouseleave(self)
	end)

	win:on('mousedown.ui', function(win, button, mx, my)
		if self.mouse_x ~= mx or self.mouse_y ~= my then
			self.ui:_window_mousemove(self, mx, my)
		end
		setmouse(mx, my)
		self:fire('mousedown', button, mx, my)
		self.ui:_window_mousedown(self, button, mx, my)
	end)

	win:on('mouseup.ui', function(win, button, mx, my)
		if self.mouse_x ~= mx or self.mouse_y ~= my then
			self.ui:_window_mousemove(self, mx, my)
		end
		setmouse(mx, my)
		self.ui:_window_mouseup(self, button, mx, my)
	end)

	win:on('repaint.ui', function(win)
		setcontext()
		self:draw()
	end)

	win:on('client_rect_changed.ui', function(win, cx, cy, cw, ch)
		if not cx then return end --hidden or minimized
		self.x = cx
		self.y = cy
		self.w = cw
		self.h = ch
		self.layer.w = cw
		self.layer.h = ch
		self:fire('client_rect_changed', cx, cy, cw, ch)
	end)

	win:on('closed.ui', function()
		self:free()
	end)

	self.layer = self.layer_class(self.ui, merge({
		id = self:_subtag'layer', tags = 'window_layer',
		x = 0, y = 0, w = self.w, h = self.h,
		content_clip = false, window = self,
	}, self.layer))

	--prepare the layer for working parent-less
	function self.layer:to_window(x, y)
		return x, y
	end
	function self.layer:from_window(x, y)
		return x, y
	end

end

function ui.window:before_free()
	self.native_window:off'.ui'
	self.layer:free()
	self.native_window = false
end

function ui.window:find(sel)
	local sel = ui:selector(sel, function(elem)
		return elem.window == self
	end)
	return self.ui:find(sel)
end

function ui.window:each(sel, f)
	return self:find(sel):each(f)
end

function ui.window:mouse_pos() --window interface
	return self.mouse_x, self.mouse_y
end

--window mouse events routing with hot, active and drag & drop logic.

function ui.window:hit_test(x, y)
	return self.layer:hit_test(x, y)
end

function ui:_reset_drag_state()
	self.drag_start_widget = false --widget initiating the drag
	self.drag_button = false
	self.drag_mx = false --mouse coords in start_widget's content space
	self.drag_my = false
	self.drag_area = false --hit test area in drag_start_widget
	self.drag_widget = false --the widget being dragged
	self.drop_widget = false --the drop target widget
	self.drop_area = false --drop area in drop_widget
end

function ui:after_init()
	self.hot_widget = false
	self.active_widget = false
	self:_reset_drag_state()
end

function ui:_set_hot_widget(widget, mx, my, area)
	if self.hot_widget == widget then
		return
	end
	if self.hot_widget then
		self.hot_widget:_mouseleave()
	end
	if widget then
		--the hot widget is still the old widget when entering the new widget
		widget:_mouseenter(mx, my, area)
	end
	self.hot_widget = widget
end

function ui:_accept_drop(drag_widget, drop_widget, mx, my, area)
	return drop_widget:_accept_drag_widget(drag_widget, mx, my, area)
		and drag_widget:accept_drop_widget(drop_widget, area)
end

function ui:_window_mousedown(window, button, mx, my)
	local hot_widget, hot_area = window:hit_test(mx, my)
	if self.active_widget then
		local area = self.active_widget == hot_widget and hot_area or nil
		self.active_widget:_mousedown(button, mx, my, area, hot_widget, hot_area)
	end
	if not self.active_widget then
		self:_set_hot_widget(hot_widget, mx, my, hot_area)
		if hot_widget then
			hot_widget:_mousedown(button, mx, my, hot_area, hot_widget, hot_area)
		end
	end
end

function ui:_widget_mousedown(widget, button, mx, my, area)
	if self.drag_start_widget then return end --already dragging on other button
	if self.active_widget ~= widget then return end --widget not activated
	self.drag_start_widget = widget
	self.drag_button = button
	self.drag_mx = mx
	self.drag_my = my
	self.drag_area = area
end

function ui:_window_mousemove(window, mx, my)
	window:fire('mousemove', mx, my)
	local hot_widget, hot_area = window:hit_test(mx, my)
	if self.active_widget then
		local area = self.active_widget == hot_widget and hot_area or nil
		self.active_widget:_mousemove(mx, my, area, hot_widget, hot_area)
	end
	if not self.active_widget then
		self:_set_hot_widget(hot_widget, mx, my, hot_area)
		if hot_widget then
			hot_widget:_mousemove(mx, my, hot_area, hot_widget, hot_area)
		end
	end
	if self.drag_widget then
		local widget, area = window:hit_test(mx, my)
		if widget then
			if not self:_accept_drop(self.drag_widget, widget, mx, my, area) then
				widget = nil
			end
		end
		if self.drop_widget ~= (widget or false) then
			if self.drop_widget then
				self.drag_widget:_leave_drop_target(self.drop_widget)
				self.drop_widget = false
				self.drop_area = false
			end
			if widget then
				self.drag_widget:_enter_drop_target(widget, area)
				self.drop_widget = widget
				self.drop_area = area
			end
		end
	end
	if self.drag_widget then
		self.drag_widget:_drag(mx, my)
	end
end

function ui:_widget_mousemove(widget, mx, my, area)
	if not self.drag_widget and widget == self.drag_start_widget then
		--local dmx, dmy = self:to_window(self.drag_mx, self.drag_my)
		--TODO: make this diff. in window space!
		local dx = math.abs(self.drag_mx - mx)
		local dy = math.abs(self.drag_my - my)
		if dx >= widget.drag_threshold or dy >= widget.drag_threshold then
			self.drag_widget = widget:_start_drag(
				self.drag_button,
				self.drag_mx,
				self.drag_my,
				self.drag_area)
		end
	end
end

function ui:_window_mouseenter(window, mx, my)
	window:fire('mouseenter', mx, my)
	self:_window_mousemove(window, mx, my)
end

function ui:_window_mouseleave(window)
	window:fire'mouseleave'
	if not self.active_widget then
		self:_set_hot_widget(false)
	end
end

function ui:_window_mouseup(window, button, mx, my)
	window:fire('mouseup', button, mx, my)
	local hot_widget, hot_area = window:hit_test(mx, my)
	if self.active_widget then
		local area = self.active_widget == hot_widget and hot_area or nil
		self.active_widget:_mouseup(button, mx, my, area, hot_widget, hot_area)
	else
		self:_set_hot_widget(hot_widget, mx, my, hot_area)
		if hot_widget then
			hot_widget:_mouseup(button, mx, my, hot_area, hot_widget, hot_area)
		end
	end
	if self.drag_button == button then
		if self.drop_widget then
			self.drop_widget:_drop(self.drag_widget, mx, my, self.drop_area)
			self.drag_widget:_leave_drop_target(self.drop_widget)
		end
		if self.drag_widget then
			self.drag_widget:_ended_dragging()
		end
		self.drag_start_widget:_end_drag()
		for _,elem in ipairs(self.elements) do
			if elem.iswidget then
				elem:_set_drop_target(false)
			end
		end
		self:_reset_drag_state()
	end
end

--rendering

function ui.window:after_draw()
	if not self.visible or self.opacity == 0 then return end
	self.cr:save()
	self.cr:new_path()
	self.layer:draw()
	self.cr:restore()
end

function ui.window:invalidate(for_animation) --element interface; window intf.
	self.native_window:invalidate()
end

function ui.window:frame_clock() --element interface; window intf.
	return self._frame_clock
end

--sugar & utils

function ui.window:rect() return 0, 0, self.w, self.h end
function ui.window:size() return self.w, self.h end

--drawing helpers ------------------------------------------------------------

function ui:_color(s)
	local r, g, b, a = color.string_to_rgba(s)
	self:check(r, 'invalid color "%s"', s)
	return r and {r, g, b, a}
end
ui:memoize'_color'

function ui:color(c)
	if type(c) == 'string' then
		c = self:_color(c)
	end
	if not c then
		return 0, 0, 0, 0
	end
	return unpack(c)
end

function ui:_add_color_stops(g, ...)
	local offset = 0
	for i=1,select('#', ...) do
		local arg = select(i, ...)
		if type(arg) == 'number' then
			offset = arg
		else
			g:add_color_stop(offset, self:color(arg))
		end
	end
	return g
end

function ui:linear_gradient(x1, y1, x2, y2, ...)
	local g = cairo.linear_gradient(x1, y1, x2, y2)
	return self:_add_color_stops(g, ...)
end

function ui:radial_gradient(cx1, cy1, r1, cx2, cy2, r2, ...)
	local g = cairo.radial_gradient(cx1, cy1, r1, cx2, cy2, r2)
	return self:_add_color_stops(g, ...)
end

function ui:image(file)
	local ext = file:match'%.([^%.]+)$'
	if ext == 'jpg' or ext == 'jpeg' then
		local f, err = fs.open(file)
		if not f then
			self:error('error loading "%s": %s', file, err)
			return
		end
		local bread = f:buffered_read()
		local function read(buf, sz)
			return self:check(bread(buf, sz))
		end
		local img = self:check(libjpeg.open({read = read}))
		if not img then return end
		local bmp = self:check(img:load{accept = {bgra8 = true}})
		if not bmp then return end
		img:free()
		local sr = cairo.image_surface(bmp) --bmp is Lua-pinned to sr
		local patt = cairo.surface_pattern(sr) --sr is cairo-pinned to patt
		return {patt = patt, sr = sr}
	end
end
ui:memoize'image'

--fonts and text

function ui:after_init()
	self._freetype = freetype:new()
	self._fonts = {} --{file -> {ft_face=, cr_face=, mmap=}}
end

function ui:before_free()
	for _,font in pairs(self._fonts) do
		--can't free() it because cairo's cache is lazy.
		--cairo will free the freetype face object on its own.
		font.cr_face:unref()
	end
	self._fonts = nil
	--safe to free() the freetype object here because cr_face holds a reference
	--to the FT_Library and will call FT_Done_Library() on its destructor.
	self._freetype:free()
end

function ui.window:before_free()
	if self.cr then
		self.cr:font_face(cairo.NULL)
	end
end

--override this for different ways of finding font files
function ui:font_file(family, weight, slant)
	local gfonts = require'gfonts'
	return gfonts.font_file(family, weight, slant, true)
end

--override this for different ways of loading font faces
function ui:_font(family, weight, slant)
	local bundle = require'bundle'
	local file = assert(self:font_file(family, weight, slant),
		'could not find a font for "%s, %s, %s"', family, weight, slant)
	local font = {}
	font.mmap = assert(bundle.mmap(file))
	font.ft_face = self._freetype:memory_face(font.mmap.data, font.mmap.size)
	font.cr_face = assert(cairo.ft_font_face(font.ft_face))
	self._fonts[file] = font
	return font
end
ui:memoize'_font'

--override this for different ways of setting a loaded font
function ui.window:setfont(family, weight, slant, size, line_spacing)
	local font = self.ui:_font(family, weight, slant)
	self.cr:font_face(font.cr_face)
	self.cr:font_size(size)
	local ext = self.cr:font_extents()
	self._font_height = ext.height
	self._font_descent = ext.descent
	self._font_ascent = ext.ascent
	self._line_spacing = line_spacing
end

--multi-line self-aligned and box-aligned text

function ui.window:line_extents(s)
	local ext = self.cr:text_extents(s)
	return ext.width, ext.height, ext.y_bearing
end

function ui.window:textbox(x, y, w, h, s, halign, valign)

	self.cr:save()
	self.cr:rectangle(x, y, w, h)
	self.cr:clip()

	local cr = self.cr

	local line_h = self._font_height * self._line_spacing

	if halign == 'right' then
		x = w
	elseif not halign or halign == 'center' then
		x = round(w / 2)
	else
		x = 0
	end

	if valign == 'top' then
		y = self._font_ascent
	else
		local lines_h = 0
		for _ in glue.lines(s) do
			lines_h = lines_h + line_h
		end
		lines_h = lines_h - line_h

		if valign == 'bottom' then
			y = h - self._font_descent
		elseif not valign or valign == 'center' then
			local h1 = h + self._font_ascent - self._font_descent + lines_h
			y = round(h1 / 2)
		else
			assert(false, 'invalid valign "%s"', valign)
		end
		y = y - lines_h
	end

	for s in glue.lines(s) do
		if halign == 'right' then
			local tw = self:line_extents(s)
			cr:move_to(x - tw, y)
		elseif not halign or halign == 'center' then
			local tw = self:line_extents(s)
			cr:move_to(x - round(tw / 2), y)
		elseif halign == 'left' then
			cr:move_to(x, y)
		else
			assert(false, 'invalid halign "%s"', halign)
		end
		cr:show_text(s)
		y = y + line_h
	end

	self.cr:restore()
end

--layers ---------------------------------------------------------------------

local function args4(s, convert) --parse a string of 4 non-space args
	local a1, a2, a3, a4
	if type(s) == 'string' then
		a1, a2, a3, a4 = s:match'([^%s]+)%s+([^%s]+)([^%s]+)%s+([^%s]+)'
	end
	if not a1 then
		a1, a2, a3, a4 = s, s, s, s
	end
	if convert then
		return convert(a1), convert(a2), convert(a3), convert(a4)
	else
		return a1, a2, a3, a4
	end
end

function expand:padding(s)
	self.padding_left, self.padding_top, self.padding_right,
		self.padding_bottom = args4(s, tonumber)
end

function expand:border_color(s)
	self.border_color_left, self.border_color_right, self.border_color_top,
		self.border_color_bottom = args4(s)
end

function expand:border_width(s)
	self.border_width_left, self.border_width_right, self.border_width_top,
		self.border_width_bottom = args4(s, tonumber)
end

function expand:corner_radius(s)
	self.corner_radius_top_left, self.corner_radius_top_right,
		self.corner_radius_bottom_right, self.corner_radius_bottom_left =
			args4(s, tonumber)
end

function expand:scale(scale)
	self.scale_x = scale
	self.scale_y = scale
end

function expand:background_scale(scale)
	self.background_scale_x = scale
	self.background_scale_y = scale
end

ui.layer = oo.layer(ui.element)
ui.window.layer_class = ui.layer

function ui.layer:set_padding(s) expand_attr('padding', s, self) end
function ui.layer:set_border_color(s) expand_attr('border_color', s, self) end
function ui.layer:set_border_width(s) expand_attr('border_width', s, self) end
function ui.layer:set_corner_radius(s) expand_attr('corner_radius', s, self) end
function ui.layer:set_scale(scale) expand_attr('scale', scale, self) end
function ui.layer:set_background_scale(scale)
	expand_attr('background_scale', scale, self)
end

ui.layer.iswidget = true
ui.layer.x = 0
ui.layer.y = 0
ui.layer.rotation = 0
ui.layer.rotation_cx = 0
ui.layer.rotation_cy = 0
ui.layer.scale_x = 1
ui.layer.scale_y = 1
ui.layer.scale_cx = 0
ui.layer.scale_cy = 0

ui.layer.opacity = 1

ui.layer.content_clip = true --'padding'/true, 'background', false

ui.layer.padding = 0

ui.layer.background_type = 'color'
--all backgrounds
ui.layer.background_x = 0
ui.layer.background_y = 0
ui.layer.background_rotation = 0
ui.layer.background_rotation_cx = 0
ui.layer.background_rotation_cy = 0
ui.layer.background_scale = 1
ui.layer.background_scale_cx = 0
ui.layer.background_scale_cy = 0
--solid color backgrounds
ui.layer.background_color = nil --no background
--gradient backgrounds
ui.layer.background_colors = {} --{[offset1], color1, ...}
--linear gradient backgrounds
ui.layer.background_x1 = 0
ui.layer.background_y1 = 0
ui.layer.background_x2 = 0
ui.layer.background_y2 = 0
--radial gradient backgrounds
ui.layer.background_cx1 = 0
ui.layer.background_cy1 = 0
ui.layer.background_r1 = 0
ui.layer.background_cx2 = 0
ui.layer.background_cy2 = 0
ui.layer.background_r2 = 0
--image backgrounds
ui.layer.background_image = nil

ui.layer.background_operator = 'over'
-- overlapping between background clipping edge and border stroke.
-- -1..1 goes from inside to outside of border edge.
ui.layer.background_clip_border_offset = 1

ui.layer.border_width = 0 --no border
ui.layer.corner_radius = 0 --square
ui.layer.border_color = '#0000'
-- border stroke positioning relative to box edge.
-- -1..1 goes from inside to outside of box edge.
ui.layer.border_offset = -1
--draw rounded corners with a modified bezier for smoother line-to-arc
--transitions. kappa=1 uses circle arcs instead.
ui.layer.corner_radius_kappa = 1.2

ui.layer.shadow_x = 0
ui.layer.shadow_y = 0
ui.layer.shadow_color = '#000'
ui.layer.shadow_blur = 0

ui.layer.drag_threshold = 10 --snapping pixels before starting to drag

function ui.layer:before_free()
	self:_free_layers()
	self.parent = false
end

local mt
function ui.layer:rel_matrix() --box matrix relative to parent's content space
	mt = mt or cairo.matrix()
	return mt:reset()
		:translate(self.x, self.y)
		:rotate_around(self.rotation_cx, self.rotation_cy,
			math.rad(self.rotation))
		:scale_around(self.scale_cx, self.scale_cy, self.scale_x, self.scale_y)
end

function ui.layer:abs_matrix() --box matrix in window space
	return self.parent:abs_matrix():transform(self:rel_matrix())
end

local mt
function ui.layer:cr_abs_matrix(cr) --box matrix in cr's current space
	mt = mt or cairo.matrix()
	return cr:matrix(nil, mt):transform(self:rel_matrix())
end

--convert point from own content space to parent's content space
function ui.layer:to_parent(x, y)
	return self:rel_matrix():translate(self:padding_pos()):point(x, y)
end

--convert point from parent's content space to own content space
function ui.layer:from_parent(x, y)
	return self:rel_matrix():translate(self:padding_pos()):invert():point(x, y)
end

--convert point from parent's content space to own box space
function ui.layer:from_box_to_parent(x, y)
	return self:rel_matrix():point(x, y)
end

--convert point from parent's content space to own box space
function ui.layer:from_parent_to_box(x, y)
	return self:rel_matrix():invert():point(x, y)
end

function ui.layer:to_window(x, y) --parent & child interface
	return self.parent:to_window(self:to_parent(x, y))
end

function ui.layer:from_window(x, y) --parent & child interface
	return self:from_parent(self.parent:from_window(x, y))
end

--convert point from own content space to other's content space
function ui.layer:to_other(widget, x, y)
	return widget:from_window(self:to_window(x, y))
end

--convert point from other's space to own space
function ui.layer:from_other(widget, x, y)
	return self:from_window(widget:to_window(x, y))
end

function ui.layer:mouse_pos()
	if not self.window.mouse_x then
		return false, false
	end
	return self:from_window(self.window:mouse_pos())
end

function ui.layer:get_mouse_x() return (select(1, self:mouse_pos())) end
function ui.layer:get_mouse_y() return (select(2, self:mouse_pos())) end

function ui.layer:get_parent() --child interface
	return self._parent
end

function ui.layer:set_parent(parent)
	if self._parent then
		self._parent:remove_layer(self)
	end
	if parent then
		if parent.iswindow then
			parent = parent.layer
		end
		parent:add_layer(self)
	end
	self:invalidate()
end

function ui.layer:to_back()
	self.layer_index = 1
end

function ui.layer:to_front()
	self.layer_index = 1/0
end

function ui.layer:get_layer_index()
	return indexof(self, self.parent.layers)
end

function ui.layer:move_layer(layer, index)
	local new_index = clamp(index, 1, #self.layers)
	local old_index = indexof(layer, self.layers)
	if old_index == new_index then return end
	table.remove(self.layers, old_index)
	table.insert(self.layers, new_index, layer)
end

function ui.layer:set_layer_index(index)
	self.parent:move_layer(self, index)
end

function ui.layer:add_layer(layer) --parent interface
	self.layers = self.layers or {}
	push(self.layers, layer)
	layer._parent = self
	layer.window = self.window
	self:fire('layer_added', layer)
	self:invalidate()
end

function ui.layer:remove_layer(layer) --parent interface
	popval(self.layers, layer)
	self:fire('layer_removed', layer)
	layer._parent = false
	layer.window = false
	self:invalidate()
end

function ui.layer:_free_layers()
	if not self.layers then return end
	while #self.layers > 0 do
		self.layers[#self.layers]:free()
	end
end

--mouse event handling

function ui.layer:_mousemove(mx, my, area)
	local mx, my = self:from_window(mx, my)
	self:fire('mousemove', mx, my, area)
	self.ui:_widget_mousemove(self, mx, my, area)
end

function ui.layer:_mouseenter(mx, my, area)
	local mx, my = self:from_window(mx, my)
	self:settags'hot'
	self:fire('mouseenter', mx, my, area)
end

function ui.layer:_mouseleave()
	self:fire'mouseleave'
	self:settags'-hot'
end

function ui.layer:_mousedown(button, mx, my, area, hot_widget, hot_area)
	local mx, my = self:from_window(mx, my)
	self:fire('mousedown', button, mx, my, area, hot_widget, hot_area)
	self.ui:_widget_mousedown(self, button, mx, my, area)
end

function ui.layer:_mouseup(button, mx, my, area, hot_widget, hot_area)
	local mx, my = self:from_window(mx, my)
	self:fire('mouseup', button, mx, my, area, hot_widget, hot_area)
end

--called on a potential drop target widget to accept the dragged widget.
function ui.layer:_accept_drag_widget(widget, mx, my, area)
	if mx then
		mx, my = self:from_window(mx, my)
	end
	return self:accept_drag_widget(widget, mx, my, area)
end

--return true to accept a dragged widget. if mx/my/area are nil
--then return true if there's _any_ area which would accept the widget.
function ui.layer:accept_drag_widget(widget, mx, my, area) end

--called on the dragged widget to accept a potential drop target widget.
function ui.layer:accept_drop_widget(widget, area) return true; end

--called on the dragged widget once upon entering a new drop target.
function ui.layer:_enter_drop_target(widget, area)
	self:settags'dropping'
	self:fire('enter_drop_target', widget, area)
end

--called on the dragged widget once upon leaving a drop target.
function ui.layer:_leave_drop_target(widget)
	self:fire('leave_drop_target', widget)
	self:settags'-dropping'
end

--called on the dragged widget when dragging starts.
function ui.layer:_started_dragging()
	self:settags'dragging'
	self:fire'started_dragging'
end

--called on the dragged widget when dragging ends.
function ui.layer:_ended_dragging()
	self:fire'ended_dragging'
	self:settags'-dragging'
end

function ui.layer:_set_drop_target(set)
	self:settags(set and 'drop_target' or '-drop_target')
end

--called on drag_start_widget to initiate a drag operation.
function ui.layer:_start_drag(button, mx, my, area)
	local widget = self:start_drag(button, mx, my, area)
	if widget then
		self:settags'drag_source'
		for i,elem in ipairs(self.ui.elements) do
			if elem.iswidget then
				if self.ui:_accept_drop(widget, elem) then
					elem:_set_drop_target(true)
				end
			end
		end
		widget:_started_dragging()
	end
	return widget
end

--stub: return a widget to drag (self works too).
function ui.layer:start_drag(button, mx, my, area) end

function ui.layer:_end_drag() --called on the drag_start_widget
	self:settags'-drag_source'
end

function ui.layer:_drop(widget, mx, my, area) --called on the drop target
	local mx, my = self:from_window(mx, my)
	self:fire('drop', widget, mx, my, area)
end

function ui.layer:_drag(mx, my) --called on the dragged widget
	local pmx, pmy = self.parent:from_window(mx, my)
	local dmx, dmy = self:to_parent(self.ui.drag_mx, self.ui.drag_my)
	self:fire('drag', pmx - dmx, pmy - dmy)
end

--default behavior: drag the widget from the initial grabbing point.
function ui.layer:drag(dx, dy)
	self.x = self.x + dx
	self.y = self.y + dy
	self:invalidate()
end

--layers geometry, drawing and hit testing

function ui.layer:layers_bounding_box()
	local x, y, w, h = 0, 0, 0, 0
	if self.layers then
		for _,layer in ipairs(self.layers) do
			x, y, w, h = box2d.bounding_box(x, y, w, h, layer:bounding_box())
		end
	end
	return x, y, w, h
end

function ui.layer:draw_layers() --called in content space
	if not self.layers then return end
	for i = 1, #self.layers do
		self.layers[i]:draw()
	end
end

function ui.layer:hit_test_layers(x, y) --called in content space
	if not self.layers then return end
	for i = #self.layers, 1, -1 do
		local widget, area = self.layers[i]:hit_test(x, y)
		if widget then
			return widget, area
		end
	end
end

--border geometry and drawing

--border edge widths relative to box rect at %-offset in border width.
--offset is in -1..1 where -1=inner edge, 0=center, 1=outer edge.
--returned widths are positive when inside and negative when outside box rect.
function ui.layer:_border_edge_widths(offset)
	local o = self.border_offset + offset + 1
	local w1 = lerp(o, -1, 1, self.border_width_left, 0)
	local h1 = lerp(o, -1, 1, self.border_width_top, 0)
	local w2 = lerp(o, -1, 1, self.border_width_right, 0)
	local h2 = lerp(o, -1, 1, self.border_width_bottom, 0)
	--adjust overlapping widths by scaling them down proportionally.
	if w1 + w2 > self.w or h1 + h2 > self.h then
		local scale = math.min(self.w / (w1 + w2), self.h / (h1 + h2))
		w1 = w1 * scale
		h1 = h1 * scale
		w2 = w2 * scale
		h2 = h2 * scale
	end
	return w1, h1, w2, h2
end

function ui.layer:border_pos(offset)
	local w, h = self:_border_edge_widths(offset)
	return w, h
end

--border rect at %-offset in border width.
function ui.layer:border_rect(offset, size_offset)
	local w1, h1, w2, h2 = self:_border_edge_widths(offset)
	local w = self.w - w2 - w1
	local h = self.h - h2 - h1
	return box2d.offset(size_offset or 0, w1, h1, w, h)
end

--corner radius at pixel offset from the stroke's center on one dimension.
local function offset_radius(r, o)
	return r > 0 and math.max(0, r + o) or 0
end

--border rect at %-offset in border width, plus radii of rounded corners.
function ui.layer:border_round_rect(offset, size_offset)
	local k = self.corner_radius_kappa

	local x1, y1, w, h = self:border_rect(0) --at stroke center
	local X1, Y1, W, H = self:border_rect(offset, size_offset) --at offset

	local x2, y2 = x1 + w, y1 + h
	local X2, Y2 = X1 + W, Y1 + H

	local r1 = self.corner_radius_top_left
	local r2 = self.corner_radius_top_right
	local r3 = self.corner_radius_bottom_right
	local r4 = self.corner_radius_bottom_left

	--offset the radii to preserve curvature at offset.
	local r1x = offset_radius(r1, x1-X1)
	local r1y = offset_radius(r1, y1-Y1)
	local r2x = offset_radius(r2, X2-x2)
	local r2y = offset_radius(r2, y1-Y1)
	local r3x = offset_radius(r3, X2-x2)
	local r3y = offset_radius(r3, Y2-y2)
	local r4x = offset_radius(r4, x1-X1)
	local r4y = offset_radius(r4, Y2-y2)

	--remove degenerate arcs.
	if r1x == 0 or r1y == 0 then r1x = 0; r1y = 0 end
	if r2x == 0 or r2y == 0 then r2x = 0; r2y = 0 end
	if r3x == 0 or r3y == 0 then r3x = 0; r3y = 0 end
	if r4x == 0 or r4y == 0 then r4x = 0; r4y = 0 end

	--adjust overlapping radii by scaling them down proportionally.
	local maxx = math.max(r1x + r2x, r3x + r4x)
	local maxy = math.max(r1y + r4y, r2y + r3y)
	if maxx > W or maxy > H then
		local scale = math.min(W / maxx, H / maxy)
		r1x = r1x * scale
		r1y = r1y * scale
		r2x = r2x * scale
		r2y = r2y * scale
		r3x = r3x * scale
		r3y = r3y * scale
		r4x = r4x * scale
		r4y = r4y * scale
	end

	return
		X1, Y1, W, H,
		r1x, r1y, r2x, r2y, r3x, r3y, r4x, r4y,
		k
end

--De Casteljau split of a cubic bezier at time t (from path2d).
local function bezier_split(first, t, x1, y1, x2, y2, x3, y3, x4, y4)
	local mt = 1-t
	local x12 = x1 * mt + x2 * t
	local y12 = y1 * mt + y2 * t
	local x23 = x2 * mt + x3 * t
	local y23 = y2 * mt + y3 * t
	local x34 = x3 * mt + x4 * t
	local y34 = y3 * mt + y4 * t
	local x123 = x12 * mt + x23 * t
	local y123 = y12 * mt + y23 * t
	local x234 = x23 * mt + x34 * t
	local y234 = y23 * mt + y34 * t
	local x1234 = x123 * mt + x234 * t
	local y1234 = y123 * mt + y234 * t
	if first then
		return x1, y1, x12, y12, x123, y123, x1234, y1234 --first curve
	else
		return x1234, y1234, x234, y234, x34, y34, x4, y4 --second curve
	end
end

local kappa = 4 / 3 * (math.sqrt(2) - 1)

--more-aesthetically-pleasing elliptic arc. only for 45deg and 90deg sweeps!
local function bezier_qarc(cr, cx, cy, rx, ry, q1, qlen, k)
	cr:save()
	cr:translate(cx, cy)
	cr:scale(rx / ry, 1)
	cr:rotate(math.floor(math.min(q1, q1 + qlen) - 2) * math.pi / 2)
	local r = ry
	local k = r * kappa * k
	local x1, y1, x2, y2, x3, y3, x4, y4 = 0, -r, k, -r, r, -k, r, 0
	if qlen < 0 then --reverse curve
		x1, y1, x2, y2, x3, y3, x4, y4 = x4, y4, x3, y3, x2, y2, x1, y1
		qlen = math.abs(qlen)
	end
	if qlen ~= 1 then
		assert(qlen == .5)
		local first = q1 == math.floor(q1)
		x1, y1, x2, y2, x3, y3, x4, y4 =
			bezier_split(first, qlen, x1, y1, x2, y2, x3, y3, x4, y4)
	end
	cr:line_to(x1, y1)
	cr:curve_to(x2, y2, x3, y3, x4, y4)
	cr:restore()
end

--draw an eliptic arc: q1 is the quadrant starting top-left going clockwise.
--qlen is in 90deg units and can only be +/- .5 or 1 if k ~= 1.
local function qarc(cr, cx, cy, rx, ry, q1, qlen, k)
	if rx == 0 or ry == 0 then --null arcs need a line to the first endpoint
		assert(rx == 0 and ry == 0)
		cr:line_to(cx, cy)
	elseif k == 1 then --geometrically-correct elliptic arc
		local q2 = q1 + qlen
		local a1 = (q1 - 3) * math.pi / 2
		local a2 = (q2 - 3) * math.pi / 2
		local arc = a1 < a2 and cr.elliptic_arc or cr.elliptic_arc_negative
		arc(cr, cx, cy, rx, ry, 0, a1, a2)
	else
		bezier_qarc(cr, cx, cy, rx, ry, q1, qlen, k)
	end
end

--trace the border contour path at offset.
--offset is in -1..1 where -1=inner edge, 0=center, 1=outer edge.
function ui.layer:border_path(offset, size_offset)
	local cr = self.window.cr
	local x1, y1, w, h, r1x, r1y, r2x, r2y, r3x, r3y, r4x, r4y, k =
		self:border_round_rect(offset, size_offset)
	local x2, y2 = x1 + w, y1 + h
	cr:move_to(x1, y1+r1y)
	qarc(cr, x1+r1x, y1+r1y, r1x, r1y, 1, 1, k) --tl
	qarc(cr, x2-r2x, y1+r2y, r2x, r2y, 2, 1, k) --tr
	qarc(cr, x2-r3x, y2-r3y, r3x, r3y, 3, 1, k) --br
	qarc(cr, x1+r4x, y2-r4y, r4x, r4y, 4, 1, k) --bl
	cr:close_path()
end

function ui.layer:border_visible()
	return
		self.border_width_left ~= 0
		or self.border_width_top ~= 0
		or self.border_width_right ~= 0
		or self.border_width_bottom ~= 0
end

function ui.layer:draw_border()
	if not self:border_visible() then return end
	local cr = self.window.cr

	--seamless drawing when all side colors are the same.
	if self.border_color_left == self.border_color_top
		and self.border_color_left == self.border_color_right
		and self.border_color_left == self.border_color_bottom
	then
		cr:new_path()
		cr:fill_rule'even_odd'
		self:border_path(-1)
		self:border_path(1)
		cr:rgba(self.ui:color(self.border_color_bottom))
		cr:fill()
		return
	end

	--complicated drawing of each side separately.
	--still shows seams on adjacent sides of the same color.
	local x1, y1, w, h, r1x, r1y, r2x, r2y, r3x, r3y, r4x, r4y, k =
		self:border_round_rect(-1)
	local X1, Y1, W, H, R1X, R1Y, R2X, R2Y, R3X, R3Y, R4X, R4Y, K =
		self:border_round_rect(1)

	local x2, y2 = x1 + w, y1 + h
	local X2, Y2 = X1 + W, Y1 + H

	if self.border_color_left then
		cr:new_path()
		cr:move_to(x1, y1+r1y)
		qarc(cr, x1+r1x, y1+r1y, r1x, r1y, 1, .5, k)
		qarc(cr, X1+R1X, Y1+R1Y, R1X, R1Y, 1.5, -.5, K)
		cr:line_to(X1, Y2-R4Y)
		qarc(cr, X1+R4X, Y2-R4Y, R4X, R4Y, 5, -.5, K)
		qarc(cr, x1+r4x, y2-r4y, r4x, r4y, 4.5, .5, k)
		cr:close_path()
		cr:rgba(self.ui:color(self.border_color_left))
		cr:fill()
	end

	if self.border_color_top then
		cr:new_path()
		cr:move_to(x2-r2x, y1)
		qarc(cr, x2-r2x, y1+r2y, r2x, r2y, 2, .5, k)
		qarc(cr, X2-R2X, Y1+R2Y, R2X, R2Y, 2.5, -.5, K)
		cr:line_to(X1+R1X, Y1)
		qarc(cr, X1+R1X, Y1+R1Y, R1X, R1Y, 2, -.5, K)
		qarc(cr, x1+r1x, y1+r1y, r1x, r1y, 1.5, .5, k)
		cr:close_path()
		cr:rgba(self.ui:color(self.border_color_top))
		cr:fill()
	end

	if self.border_color_right then
		cr:new_path()
		cr:move_to(x2, y2-r3y)
		qarc(cr, x2-r3x, y2-r3y, r3x, r3y, 3, .5, k)
		qarc(cr, X2-R3X, Y2-R3Y, R3X, R3Y, 3.5, -.5, K)
		cr:line_to(X2, Y1+R2Y)
		qarc(cr, X2-R2X, Y1+R2Y, R2X, R2Y, 3, -.5, K)
		qarc(cr, x2-r2x, y1+r2y, r2x, r2y, 2.5, .5, k)
		cr:close_path()
		cr:rgba(self.ui:color(self.border_color_right))
		cr:fill()
	end

	if self.border_color_bottom then
		cr:new_path()
		cr:move_to(x1+r4x, y2)
		qarc(cr, x1+r4x, y2-r4y, r4x, r4y, 4, .5, k)
		qarc(cr, X1+R4X, Y2-R4Y, R4X, R4Y, 4.5, -.5, K)
		cr:line_to(X2-R3X, Y2)
		qarc(cr, X2-R3X, Y2-R3Y, R3X, R3Y, 4, -.5, K)
		qarc(cr, x2-r3x, y2-r3y, r3x, r3y, 3.5, .5, k)
		cr:close_path()
		cr:rgba(self.ui:color(self.border_color_bottom))
		cr:fill()
	end
end

--background geometry and drawing

function ui.layer:background_visible()
	return (self.background_type == 'color' and self.background_color)
		or ((self.background_type == 'gradient'
			or self.background_type == 'radial_gradient')
			and self.background_colors and #self.background_colors > 0)
		or (self.background_type == 'image' and self.background_image)
		and true or false
end

function ui.layer:background_rect(size_offset)
	return self:border_rect(self.background_clip_border_offset, size_offset)
end

function ui.layer:background_round_rect(size_offset)
	return self:border_round_rect(self.background_clip_border_offset, size_offset)
end

function ui.layer:background_path(size_offset)
	self:border_path(self.background_clip_border_offset, size_offset)
end

function ui.layer:set_background_scale(scale)
	self.background_scale_x = scale
	self.background_scale_y = scale
end

local mt
function ui.layer:paint_background()
	local cr = self.window.cr
	cr:operator(self.background_operator)
	local bg_type = self.background_type
	if bg_type == 'color' then
		cr:rgba(self.ui:color(self.background_color))
		cr:paint()
		return
	end
	local patt
	if bg_type == 'gradient' or bg_type == 'radial_gradient' then
		if bg_type == 'gradient' then
			patt = self.ui:linear_gradient(
				self.background_x1,
				self.background_y1,
				self.background_x2,
				self.background_y2,
				unpack(self.background_colors))
		elseif bg_type == 'radial_gradient' then
			patt = self.ui:radial_gradient(
				self.background_cx1,
				self.background_cy1,
				self.background_r1,
				self.background_cx2,
				self.background_cy2,
				self.background_r2,
				unpack(self.background_colors))
		end
	elseif bg_type == 'image' then
		local img = self.ui:image(self.background_image)
		if not img then return end
		patt = img.patt
	else
		assert(false, 'invalid background type %s', tostring(bg_type))
	end
	mt = mt or cairo.matrix()
	patt:matrix(
		mt:reset()
			:translate(
				self.background_x,
				self.background_y)
			:rotate_around(
				self.background_rotation_cx,
				self.background_rotation_cy,
				math.rad(self.background_rotation))
			:scale_around(
				self.background_scale_cx,
				self.background_scale_cy,
				self.background_scale_x,
				self.background_scale_y)
			:invert())
	patt:extend(self.background_extend)
	cr:source(patt)
	cr:paint()
	cr:rgb(0, 0, 0) --release source
end

--box-shadow geometry and drawing

ui.layer._shadow_blur_passes = 2

function ui.layer:shadow_visible()
	return self.shadow_blur > 0 or self.shadow_x ~= 0 or self.shadow_y ~= 0
end

function ui.layer:shadow_rect(size)
	if self:border_visible() then
		return self:border_rect(1, size)
	else
		return self:background_rect(size)
	end
end

function ui.layer:shadow_round_rect(size)
	if self:border_visible() then
		return self:border_round_rect(1, size)
	else
		return self:background_round_rect(size)
	end
end

function ui.layer:shadow_path(size)
	if self:border_visible() then
		self:border_path(1, size)
	else
		self:background_path(size)
	end
end

function ui.layer:shadow_valid_key(t)
	local x, y, w, h, r1x, r1y, r2x, r2y, r3x, r3y, r4x, r4y, k =
		self:shadow_round_rect(0)
	return t.x == x and t.y == y and t.w == w and t.h == h
		and t.r1x == r1x and t.r1y == r1y and t.r2x == r2x and t.r2y == r2y
		and t.r3x == r3x and t.r3y == r3y and t.r4x == r4x and t.r4y == r4y
		and t.k == k
end

function ui.layer:shadow_store_key(t)
	t.x, t.y, t.w, t.h, t.r1x, t.r1y,
		t.r2x, t.r2y, t.r3x, t.r3y, t.r4x, t.r4y, t.k =
			self:shadow_round_rect(0)
end

function ui.layer:draw_shadow()
	if not self:shadow_visible() then return end
	local cr = self.window.cr
	local t = self._shadow or {}
	self._shadow = t
	local passes = self._shadow_blur_passes
	local radius = self.shadow_blur
	local spread = radius * passes

	--check if the cached shadow image is still valid
	local shadow_valid
	if t.blur_radius == self.shadow_blur then
		shadow_valid = self:shadow_valid_key(t)
	end

	if not shadow_valid then

		local grow_blur = t.blur and t.blur.max_radius < spread
		local max_radius = spread * (grow_blur and 2 or 1)

		if grow_blur then --free it so we can make a larger one
			t.blurred_surface:free()
			t.blurred_surface = false
			t.bx = false
			t.by = false
			t.blur = false
		end

		--store cache invalidation keys
		t.blur_radius = self.shadow_blur
		self:shadow_store_key(t)

		if not t.blur then

			local bx, by, bw, bh = self:shadow_rect(max_radius)
			t.bx = bx
			t.by = by

			t.blur = boxblur.new(bw, bh, 'g8', max_radius)

			function t.blur.repaint(blur, src)
				local ssr = cairo.image_surface(src)
				local scr = ssr:context()
				scr:operator'source'
				scr:rgba(0, 0, 0, 0)
				scr:paint()
				scr:translate(-bx, -by)
				local cr = self.window.cr
				self.window.cr = scr
				self:shadow_path(0)
				self.window.cr = cr
				scr:rgba(0, 0, 0, 1)
				scr:fill()
				scr:free()
				ssr:free()
			end
		end

		if t.blurred_surface then
			t.blurred_surface:free()
			t.blurred_surface = false
		end

		local dst = t.blur:blur(radius, passes)
		t.blurred_surface = cairo.image_surface(dst)
	end

	local sx = t.bx + self.shadow_x
	local sy = t.by + self.shadow_y
	cr:translate(sx, sy)
	cr:rgba(self.ui:color(self.shadow_color))
	cr:mask(t.blurred_surface)
	cr:translate(-sx, -sy)
end

--content-box geometry, drawing and hit testing

function ui.layer:padding_pos() --in box space
	local x, y = self:border_pos(-1) --inner edge
	return
		x + self.padding_left,
		y + self.padding_top
end

function ui.layer:padding_rect() --in box space
	local x, y, w, h = self:border_rect(-1) --inner edge
	return
		x + self.padding_left,
		y + self.padding_top,
		w - self.padding_left - self.padding_right,
		h - self.padding_top - self.padding_bottom
end

function ui.layer:to_content(x, y) --box space coord in content space
	local px, py = self:padding_pos()
	return x - px, y - py
end

function ui.layer:from_content(x, y) --content space coord in box space
	local px, py = self:padding_pos()
	return px + x, py + y
end

function ui.layer:draw_content() --called in own content space
	self:draw_layers()
end

function ui.layer:hit_test_content(x, y) --called in own content space
	return self:hit_test_layers(x, y)
end

function ui.layer:after_draw() --called in parent's content space; child intf.
	if not self.visible or self.opacity == 0 then return end
	if self.opacity <= 0 then return end
	local cr = self.window.cr

	local opacity = self.opacity
	local compose = opacity < 1
	if compose then
		cr:push_group()
	else
		cr:save()
	end

	cr:matrix(self:cr_abs_matrix(cr))

	local cc = self.content_clip
	local bg = self:background_visible()

	self:draw_shadow()

	local clip = bg or cc
	if clip then
		cr:save()
		cr:new_path()
		self:background_path() --'background' clipping is implicit in 'padding'
		cr:clip()
		if bg then
			self:paint_background()
		end
		if cc == 'padding' or cc == true then
			cr:new_path()
			cr:rectangle(self:padding_rect())
			cr:clip()
		elseif not cc then --clip was only needed to draw the bg
			cr:restore()
			clip = false
		end
	end
	if not cc then
		self:draw_border()
	end
	local cx, cy = self:padding_pos()
	cr:translate(cx, cy)
	self:draw_content()
	cr:translate(-cx, -cy)
	if clip then
		cr:restore()
	end
	if cc then
		self:draw_border()
	end

	if compose then
		cr:pop_group_to_source()
		cr:paint_with_alpha(opacity)
		cr:rgb(0, 0, 0) --release source
	else
		cr:restore()
	end
end

function ui.layer:hit_test(x, y) --called in parent's content space; child int.

	if not self.visible or self.opacity == 0 then return end

	if self.ui.drag_widget == self then return end

	local cr = self.window.cr
	local x, y = self:from_parent_to_box(x, y)
	cr:save()
	cr:identity_matrix()

	local border = self:border_visible()
	local bg = self:background_visible()
	local cc = self.content_clip

	--hit the content first if it's not clipped
	if not cc then
		local cx, cy = self:to_content(x, y)
		local widget, area = self:hit_test_content(cx, cy)
		if widget then
			cr:restore()
			return widget, area
		end
	end

	--border is drawn last so hit it first
	if border then
		cr:new_path()
		self:border_path(1)
		if cr:in_fill(x, y) then --inside border outer edge
			cr:new_path()
			self:border_path(-1)
			if not cr:in_fill(x, y) then --outside border inner edge
				cr:restore()
				return self, 'border'
			end
		elseif cc then --outside border outer edge when clipped
			cr:restore()
			return
		end
	end

	--hit background's clip area
	local in_bg
	if cc or bg then
		cr:new_path()
		self:background_path()
		in_bg = cr:in_fill(x, y)
	end

	--hit content's clip area
	local in_cc
	if cc and in_bg then --'background' clipping is implicit in 'padding'
		if cc == 'padding' or cc == true then
			cr:new_path()
			cr:rectangle(self:padding_rect())
			if cr:in_fill(x, y) then
				in_cc = true
			end
		else
			in_cc = true
		end
	end

	--hit the content
	if in_cc then
		local cx, cy = self:to_content(x, y)
		local widget, area = self:hit_test_content(cx, cy)
		if widget then
			cr:restore()
			return widget, area
		end
	end

	--hit the background if any
	if in_bg then
		return self, 'background'
	end
end

function ui.layer:bounding_box() --child interface
	x, y, w, h = self:layers_bounding_box()
	local cc = self.content_clip
	if cc then
		x, y, w, h = box.clip(x, y, w, h, self:background_rect())
		if cc == 'padding' or cc == true then
			x, y, w, h = box.clip(x, y, w, h, self:padding_rect())
		end
	else
		if self:background_visible() then
			x, y, w, h = box2d.bounding_box(x, y, w, h, self:background_rect())
		end
		if self:border_visible() then
			x, y, w, h = box2d.bounding_box(x, y, w, h, self:border_rect(1))
		end
	end
	return x, y, w, h
end

--element interface

function ui.layer:frame_clock()
	return self.window:frame_clock()
end

function ui.layer:invalidate()
	if self.window then
		self.window:invalidate()
	end
end

--the `hot` property which is managed by the window

function ui.layer:get_hot()
	return self.ui.hot_widget == self
end

--the `active` property and tag which the widget must set manually

function ui.layer:get_active()
	return self.ui.active_widget == self
end

function ui.layer:set_active(active)
	if self.active == active then return end
	local active_widget = self.ui.active_widget
	if active_widget then
		active_widget:settags'-active'
		self.ui.active_widget = false
		active_widget:fire'deactivated'
	end
	if active then
		self.ui.active_widget = self
		self:settags'active'
		self:fire'activated'
	end
	self:invalidate()
end

--utils in content space to use from draw_content() and hit_test_content()

function ui.layer:rect() return 0, 0, self.w, self.h end --the box itself
function ui.layer:size() return self.w, self.h end

function ui.layer:hit(x, y, w, h)
	local mx, my = self:mouse_pos()
	return box2d.hit(mx, my, x, y, w, h)
end

function ui.layer:content_size()
	return select(3, self:padding_rect())
end

function ui.layer:content_rect() --in content space
	return 0, 0, select(3, self:padding_rect())
end

function ui.layer:get_cw() return (select(3, self:padding_rect())) end
function ui.layer:get_ch() return (select(4, self:padding_rect())) end

function ui.layer:setfont(family, weight, slant, size, color, line_spacing)
	self.window:setfont(
		family or self.font_family,
		weight or self.font_weight,
		slant or self.font_slant,
		size or self.text_size,
		line_spacing or self.line_spacing)
	self.window.cr:rgba(self.ui:color(color or self.text_color))
end


return ui
