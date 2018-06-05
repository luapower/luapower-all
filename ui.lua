
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

local round = glue.round
local indexof = glue.indexof
local update = glue.update
local extend = glue.extend
local attr = glue.attr
local lerp = glue.lerp
local clamp = glue.clamp
local assert = glue.assert
local collect = glue.collect
local sortedpairs = glue.sortedpairs
local memoize = glue.memoize

local function single_line(s, val)
	return not val and s or nil
end

local function lines(s, multiline)
	if multiline then
		return glue.lines(s)
	else
		return single_line, s
	end
end

local function popval(t, v)
	local i = indexof(v, t)
	return i and pop(t, i)
end

local nilkey = {}
local function encode_nil(x) return x == nil and nilkey or x end
local function decode_nil(x) if x == nilkey then return nil end; return x; end

--object system --------------------------------------------------------------

local object = oo.object()

function object:before_init()
	--speed up class field lookup by having the final class statically inherit
	--all its fields. with this change, runtime patching of non-final classes
	--after the first instantiation doesn't have an effect anymore (extending
	--those classes still works but it's not that useful).
	if not rawget(self.super, 'isfinalclass') then
		self.super:inherit(self.super.super)
		self.super.isfinalclass = true
	end
	--speed up virtual property lookup without detaching/fattening the instance.
	--with this change, adding or overriding getters and setters through the
	--instance is not allowed anymore, that would patch the class instead!
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

local ui = object:subclass'ui'
ui.object = object

function ui:init(t)
	update(self, t)
end

function ui:_app()
	local nw = require'nw'
	return nw:app()
end

function ui:clock()               return time.clock() end
function ui:native_window(t)      return self:_app():window(t) end
function ui:run()                 return self:_app():run() end
function ui:key(query)            return self:_app():key(query) end
function ui:getclipboard(type)    return self:_app():getclipboard(type) end
function ui:setclipboard(s, type) return self:_app():setclipboard(s, type) end
function ui:caret_blink_time()    return self:_app():caret_blink_time() end
function ui:runevery(t, f)        return self:_app():runevery(t, f) end
function ui:runafter(t, f)        return self:_app():runafter(t, f) end

function ui:error(msg, ...)
	msg = string.format(msg, ...)
	io.stderr:write(msg)
	io.stderr:write'\n'
end

function ui:check(ret, ...)
	if ret then return ret end
	self:error(...)
end

local default_ease = 'expo out'

--selectors ------------------------------------------------------------------

ui.selector = ui.object:subclass'selector'

function ui.selector:override_create(inherited, ui, sel, ...)
	if oo.isinstance(sel, self) then
		return sel --pass-through
	end
	return inherited(self, ui, sel, ...)
end

local function noop() end
local function gmatch_tags(s)
	return s and s:gmatch'[^%s]+' or noop
end

function ui.selector:after_init(ui, sel)
	local filter
	if type(sel) == 'function' then
		sel, filter = '', sel
	elseif sel == nil then
		sel = ''
	end
	if sel:find'>' then --parents filter
		self.parent_tags = {} --{{tag,...}, ...}
		sel = sel:gsub('([^>]+)%s*>', function(s) -- tags... >
			local tags = collect(gmatch_tags(s))
			push(self.parent_tags, tags)
			return ''
		end)
	end
	self.tags = collect(gmatch_tags(sel)) --tags filter
	if filter then
		self:filter(filter)
	end
end

function ui.selector:filter(filter)
	if not self._filter then
		self._filter = filter
	else
		local prev_filter = self._filter
		self._filter = function(elem)
			return prev_filter(elem) and filter(elem)
		end
	end
	return self
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
	if self._filter and not self._filter(elem) then
		return false
	end
	return true
end

--attribute expansion --------------------------------------------------------
--attributes from styles need to be expanded first so that we know which
--initial values to save before applying the attributes.

ui.expand = {} -- {attr -> expand(dest, val)}

function ui:expand_attr(attr, val, dest)
	local expand = self.expand[attr]
	if expand then
		expand(dest, val)
		return true
	end
end

--stylesheets ----------------------------------------------------------------

ui.stylesheet_class = ui.object:subclass'stylesheet'
ui.stylesheet = ui.stylesheet_class()

function ui:after_init()
	--TODO: fix issue with late-loading of class styles in autoloaded widgets.
	--local class_stylesheet = self.stylesheet
	--self.stylesheet = self:stylesheet()
	--self.stylesheet:add_stylesheet(class_stylesheet)
end

function ui.stylesheet:after_init(ui)
	self.ui = ui
	self.tags = {} --{tag -> {sel1, ...}}
	self.parent_tags = {} --{tag -> {sel1, ...}}
	self.selectors = {} --{selector1, ...}
end

function ui.stylesheet:add_style(sel, attrs)
	for attr, val in pairs(attrs) do
		if self.ui:expand_attr(attr, val, attrs) then
			attrs[attr] = nil
		end
	end
	sel.attrs = attrs
	push(self.selectors, sel)
	sel.priority = #self.selectors
	for _,tag in ipairs(sel.tags) do
		push(attr(self.tags, tag), sel)
	end
	if sel.parent_tags then
		for _,tags in ipairs(sel.parent_tags) do
			for _,tag in ipairs(tags) do
				push(attr(self.parent_tags, tag), sel)
			end
		end
	end
end

function ui.stylesheet:add_stylesheet(stylesheet)
	for tag, selectors in pairs(stylesheet.tags) do
		extend(attr(self.tags, tag), selectors)
	end
	for tag, selectors in pairs(stylesheet.parent_tags) do
		extend(attr(self.parent_tags, tag), selectors)
	end
end

--attr. value to use in styles for "initial value of this attr"
function ui.initial(self, attr)
	return self:initial_value(attr)
end

--attr. value to use in styles for "inherit value from parent for this attr"
function ui.inherit(self, attr)
	return self:parent_value(attr)
end

local function cmp_sel(sel1, sel2)
	return sel1.priority < sel2.priority
end

function ui.stylesheet:update_element(elem, update_children)

	--gather all style selectors which select the element.
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
	--sort selectors in style declaration order.
	table.sort(st, cmp_sel)

	--compute attribute values.
	local attrs = {} --{attr -> val}
	for _,sel in ipairs(st) do
		update(attrs, sel.attrs)
	end
	update(attrs, elem.style)

	--add the saved initial values of attributes that were changed by
	--this function before but are missing from the styles this time.
	local init = elem._initial_values
	if init then
		for attr, init_val in pairs(init) do
			if attrs[attr] == nil then
				attrs[attr] = decode_nil(init_val)
			end
		end
	end

	--set transition attrs first so that elem:transition() can use them.
	for attr, val in pairs(attrs) do
		if attr:find'^transition_' then
			elem:_save_initial_value(attr)
			if type(val) == 'function' then --computed value
				val = val(elem, attr)
			end
			elem[attr] = val
		end
	end

	--set all attribute values into elem via transition().
	for attr, val in pairs(attrs) do
		if not attr:find'^transition_' then
			elem:_save_initial_value(attr)
			elem:transition(attr, val)
		end
	end

	--update all children of elem if elem has parent tags in any style.
	--TODO: speed up the pathological case when a container with many children
	--needs to be updated and there's a style which has parent tags that match
	--one of the container's tags (for now, just don't make selectors with too
	--generic parent filters that could match a container and not a widget).
	if not update_children then
		for tag in pairs(elem.tags) do
			if self.parent_tags[tag] then
				update_children = true
				break
			end
		end
	end
	if update_children and elem.layers then
		for _,layer in ipairs(elem.layers) do
			self:update_element(layer, update_children)
		end
	end
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
		self.stylesheet:add_style(sel, attrs)
	end
end

ui.stylesheet = ui:stylesheet()

--attribute types ------------------------------------------------------------

ui._type = {} --{attr -> type}
ui.type = {}  --{patt|f(attr) -> type}

--find an attribute type based on its name
function ui:attr_type(attr)
	for patt, atype in pairs(self.type) do
		if (type(patt) == 'string' and attr:find(patt))
			or (type(patt) ~= 'string' and patt(attr))
		then
			return atype
		end
	end
	return 'number'
end
ui:memoize'attr_type'

ui.type['_color$'] = 'color'
ui.type['_color_'] = 'color'
ui.type['_colors$'] = 'gradient_colors'

--transition animations ------------------------------------------------------

ui.transition = ui.object:subclass'transition'

ui.transition.interpolate = {} --{attr_type -> func(d, x1, x2, xout) -> xout}

function ui.transition:interpolate_function(elem, attr)
	local atype = self.ui:attr_type(attr)
	return self.interpolate[atype]
end

function ui.transition:after_init(ui, elem, attr, to,
	duration, ease, delay, clock)

	self.ui = ui

	--timing model
	local clock = clock or ui:clock()
	local delay = delay or 0
	local start = clock + delay
	local ease, way = (ease or default_ease):match'^([^%s_]+)[%s_]?(.*)'
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
		return t <= 1 --alive status
	end

	function self:end_clock()
		return start + duration
	end

	function self:end_value()
		if self.next_transition then
			return self.next_transition:end_value()
		end
		return to
	end

	function self:chain_to(tran)
		start = tran:end_clock() + delay
		from = tran:end_value()
		tran.next_transition = self
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

ui.element_list = ui.object:subclass'element_list'
ui.element_index = ui.object:subclass'element_index'

function ui:after_init()
	self.elements = self:element_list()
	self._element_index = self:element_index()
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
	sel = self:selector(sel)
	return self._element_index:find_elements(sel)
end

function ui:each(sel, f)
	return self:find(sel):each(f)
end

--elements -------------------------------------------------------------------

ui.element = ui.object:subclass'element'
ui.element.ui = ui

ui.element.visible = true
ui.element.iswindow = false
ui.element.activable = false --can clicked and set as hot
ui.element.targetable = false --can be a potential drop target
ui.element.vscrollable = false --can be hit for vscroll
ui.element.hscrollable = false --can be hit for hscroll
ui.element.scrollable = false --can be hit for vscroll or hscroll
ui.element.focusable = false --can be focused

ui.element.font_family = 'Open Sans'
ui.element.font_weight = 'normal'
ui.element.font_slant = 'normal'
ui.element.text_size = 14
ui.element.text_color = '#fff'
ui.element.line_spacing = 1

ui.element.transition_duration = 0
ui.element.transition_ease = default_ease
ui.element.transition_delay = 0
ui.element.transition_speed = 1
ui.element.transition_blend = 'replace_nodelay'

--tags & styles

function ui.element:init_ignore(t)
	if self._init_ignore == self.super._init_ignore then
		self._init_ignore = update({}, self.super._init_ignore)
	end
	update(self._init_ignore, t)
end

function ui.element:init_priority(t)
	if self._init_priority == self.super._init_priority then
		self._init_priority = update({}, self.super._init_priority)
	end
	update(self._init_priority, t)
end

ui.element:init_priority{}
ui.element:init_ignore{id=1, tags=1, subtag=1}

--override element constructor to take in additional initialization tables
function ui.element:override_create(inherited, ui, t, ...)
	return inherited(self, ui, t and update({}, t, ...))
end

function ui.element:expand_attr(attr, val)
	return self.ui:expand_attr(attr, val, self)
end

local function add_tags(tags, s)
	if not s then return end
	for tag in gmatch_tags(s) do
		tags[tag] = true
	end
end
function ui.element:after_init(ui, t)
	self.ui = ui
	self.ui:_add_element(self)

	local class_tags = self.tags
	self.tags = {['*'] = true}
	add_tags(self.tags, class_tags)

	local super = self.super
	while super do
		if super.classname then
			self.tags[super.classname] = true
			super = super.super
		end
	end

	if t then
		if t.id then
			self._id = t.id
			self.tags[t.id] = true
		end
		add_tags(self.tags, t.tags)
		if t.subtag then
			self:_subtag(t.subtag)
		end
		--set attributes in priority and/or lexicographic order so that eg.
		--`border_width` comes before `border_width_left`.
		local pri = self._init_priority
		local function cmp(a, b)
			local pa, pb = pri[a], pri[b]
			if pa and pb then
				return pa < pb
			elseif pa then
				return true
			elseif pb then
				return false
			else
				return a < b
			end
		end
		local ignore = self._init_ignore
		for k,v in sortedpairs(t, cmp) do
			if not ignore[k] then
				self[k] = v
			end
		end
	end
	self:update_styles()
end

function ui.element:free()
	self.ui:_remove_element(self)
	self.ui = false
end

function ui.element:get_id()
	return self._id
end

function ui.element:set_id(id)
	if self._id == id then return end
	if self._id then
		self.tags[self._id] = nil
	end
	self._id = id
	self.tags[id] = true
	self:update_styles()
end

function ui.element:_subtag(tag)
	tag = self.classname..'_'..tag
	return self.id and self.id..'.'..tag or tag
end

function ui.element:settag(tag, op)
	local had_tag = self.tags[tag]
	if op == '~' then
		self.tags[tag] = not had_tag
		self._styles_valid = false
	elseif op and not had_tag then
		self.tags[tag] = true
		self._styles_valid = false
	elseif not op and had_tag then
		self.tags[tag] = false
		self._styles_valid = false
	end
end

function ui.element:settags(s)
	if type(s) == 'string' then
		for op, tag in s:gmatch'([-+~]?)([^%s]+)' do
			if op == '+' or op == '' then
				op = true
			elseif op == '-' then
				op = false
			end
			self:settag(tag, op)
		end
	else
		for tag, op in pairs(s) do
			self:settag(tag, op)
		end
	end
end

function ui.element:update_styles()
	self.ui.stylesheet:update_element(self)
	self._styles_valid = true
end

function ui.element:_save_initial_value(attr)
	local init = self._initial_values
	if not init then
		init = {}
		self._initial_values = init
	end
	if init[attr] == nil then --wasn't saved before
		init[attr] = encode_nil(self[attr])
	end
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

function ui.element:parent_value(attr)
	local val = self[attr]
	if val == nil and self.parent then
		return self:parent_value(self.parent, attr)
	end
	return val
end

--animated attribute transitions

ui.blend = {}

function ui.blend.replace(ui, tran, elem, attr, val, duration, ease, delay, clock)
	return ui:transition(elem, attr, val, duration, ease, delay, clock)
end

function ui.blend.replace_nodelay(ui, tran, elem, attr, val,
	duration, ease, delay, clock)
	return ui:transition(elem, attr, val, duration, ease, 0, clock)
end

function ui.blend.wait(ui, tran, elem, attr, val, duration, ease, delay, clock)
	local new_tran = ui:transition(elem, attr, val, duration, ease, delay, clock)
	new_tran:chain_to(tran)
	return tran
end

function ui.blend.wait_nodelay(ui, tran, elem, attr, val, duration, ease, delay, clock)
	local new_tran = ui:transition(elem, attr, val, duration, ease, 0, clock)
	new_tran:chain_to(tran)
	return tran
end

function ui.element:end_value(attr)
	local tran = self.transitions and self.transitions[attr]
	if tran then
		return tran:end_value()
	else
		return self[attr]
	end
end

function ui.element:transition(attr, val, duration, ease, delay, blend)

	if type(val) == 'function' then --computed value
		val = val(self, attr)
	end

	--get transition parameters
	if not duration and self['transition_'..attr] then
		duration = self['transition_duration_'..attr] or self.transition_duration
		ease = ease or self['transition_ease_'..attr] or self.transition_ease
		delay = delay or self['transition_delay_'..attr] or self.transition_delay
		local speed = self['transition_speed_'..attr] or self.transition_speed
		blend = blend or self['transition_blend_'..attr] or self.transition_blend
		duration = duration / speed
	else
		duration = duration or 0
		ease = ease or default_ease
		delay = delay or 0
		blend = blend or 'replace_nodelay'
	end
	local blend_func = self.ui.blend[blend]

	local tran = self.transitions and self.transitions[attr]

	if duration <= 0
		and ((blend == 'replace' and delay <= 0) or blend == 'replace_nodelay')
	then
		tran = nil --remove existing transition on attr
		self[attr] = val --set attr directly
	else --set attr with transition
		if tran then
			if tran:end_value() ~= val then
				tran = blend_func(self.ui, tran, self, attr, val,
					duration, ease, delay, self.frame_clock)
			end
		elseif self[attr] ~= val then
			tran = self.ui:transition(self, attr, val,
				duration, ease, delay, self.frame_clock)
		end
	end

	if tran then
		self.transitions = self.transitions or {}
		self.transitions[attr] = tran
	elseif self.transitions then
		self.transitions[attr] = nil
	end

	self:invalidate()
end

function ui.element:draw()
	if not self._styles_valid then
		self:update_styles()
	end
	--update transitioning attributes
	local tr = self.transitions
	if tr and next(tr) then
		local clock = self.frame_clock
		for attr, transition in pairs(tr) do
			if not transition:update(clock) then
				tr[attr] = transition.next_transition
			end
		end
		--TODO: when transition is in delay, set a timer, don't invalidate.
		self:invalidate()
	end
end

--direct manipulation interface

--TODO: function ui.element


--windows --------------------------------------------------------------------

ui.window = ui.element:subclass'window'
ui.window.iswindow = true

ui:style('window_layer', {
	--screen-wiping options that work with transparent windows
	background_color = '#0000',
	background_operator = 'source',
})

function ui:after_init()
	self.windows = {}
end

function ui:free()
	for win in pairs(self.windows) do
		win:free()
	end
end

ui.window:init_priority{native_window=0}

function ui.window:override_init(inherited, ui, t)

	local win = t and t.native_window
	if not win then
		win = ui:native_window(t)
		self.native_window = win
		self.own_native_window = true
	else
		self.native_window = t.native_window
	end
	ui.windows[self] = true

	inherited(self, ui, t)

	self.x, self.y, self.w, self.h = self.native_window:frame_rect()
	self.cx, self.cy, self.cw, self.ch = self.native_window:client_rect()

	self.mouse_x = win:mouse'x' or false
	self.mouse_y = win:mouse'y' or false
	self.mouse_left = win:mouse'left' or false
	self.mouse_right = win:mouse'right' or false
	self.mouse_middle = win:mouse'middle' or false
	self.mouse_x1 = win:mouse'x1' or false --mouse aux button 1
	self.mouse_x2 = win:mouse'x2' or false --mouse aux button 2

	local function setcontext()
		self.frame_clock = ui:clock()
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

	win:on('mousedown.ui', function(win, button, mx, my, click_count)
		local moved = self.mouse_x ~= mx or self.mouse_y ~= my
		setmouse(mx, my)
		if moved then
			self.ui:_window_mousemove(self, mx, my)
		end
		self['mouse_'..button] = true
		self.ui:_window_mousedown(self, button, mx, my, click_count)
	end)

	win:on('click.ui', function(win, button, count, mx, my)
		return self.ui:_window_click(self, button, count, mx, my)
	end)

	win:on('mouseup.ui', function(win, button, mx, my, click_count)
		local moved = self.mouse_x ~= mx or self.mouse_y ~= my
		setmouse(mx, my)
		if moved then
			self.ui:_window_mousemove(self, mx, my)
		end
		self['mouse_'..button] = false
		self.ui:_window_mouseup(self, button, mx, my, click_count)
	end)

	win:on('mousewheel.ui', function(win, delta, mx, my, pdelta)
		local moved = self.mouse_x ~= mx or self.mouse_y ~= my
		setmouse(mx, my)
		if moved then
			self.ui:_window_mousemove(self, mx, my)
		end
		self.ui:_window_mousewheel(self, delta, mx, my, pdelta)
	end)

	win:on('keydown.ui', function(win, key)
		setcontext()
		self:_keydown(key)
	end)

	win:on('keyup.ui', function(win, key)
		setcontext()
		self:_keyup(key)
	end)

	win:on('keypress.ui', function(win, key)
		setcontext()
		self:_keypress(key)
	end)

	win:on('keychar.ui', function(win, s)
		setcontext()
		self:_keychar(s)
	end)

	win:on('repaint.ui', function(win)
		setcontext()
		self._norepaint = true
		if self.mouse_x then
			self.ui:_window_mousemove(self, self.mouse_x, self.mouse_y)
		end
		self._norepaint = false
		self:draw()
	end)

	win:on('client_rect_changed.ui', function(win, cx, cy, cw, ch)
		if not cx then return end --hidden or minimized
		setcontext()
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

	local function passxy(self, x, y) return x, y end

	self.layer = self.layer_class(self.ui, {
		id = self:_subtag'layer',
		x = 0, y = 0, w = self.w, h = self.h,
		clip_content = false, window = self,
		--parent interface
		to_window = passxy,
		from_window = passxy,
	}, self.layer)

end

function ui.window:before_free()
	self.native_window:off'.ui'
	self.layer:free()
	if self.own_native_window then
		self.native_window:close()
	end
	self.native_window = false
	self.ui.windows[self] = nil
end

function ui.window:get_visible()
	return self.native_window:visible()
end

function ui.window:set_visible(visible)
	self.native_window:visible(visible)
end

for method in pairs{show=1, hide=1, cursor=1} do
	ui.window[method] = function(self, ...)
		return self.native_window[method](self.native_window, ...)
	end
end

function ui.window:find(sel)
	local sel = ui:selector(sel):filter(function(elem)
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

function ui:_reset_drag_state()
	self.drag_start_widget = false --widget initiating the drag
	self.drag_button = false --mouse button which started the drag
	self.drag_mx = false --mouse coords in start_widget's content space
	self.drag_my = false
	self.drag_area = false --hit test area in drag_start_widget
	self.drag_widget = false --the widget being dragged
	self.drop_widget = false --the drop target widget
	self.drop_area = false --drop area in drop_widget
end

function ui:after_init()
	self.hot_widget = false
	self.hot_area = false
	self.last_click_hot_widget = false
	self.last_click_hot_area = false
	self.last_click_button = false
	self.active_widget = false
	self:_reset_drag_state()
end

function ui.window:hit_test(x, y, reason)
	return self.layer:hit_test(x, y, reason)
end

function ui.window:get_cursor()
	return (self.native_window:cursor())
end

function ui.window:set_cursor(cursor)
	self.native_window:cursor(cursor or 'arrow')
end

function ui:_set_hot_widget(window, widget, mx, my, area)
	if self.hot_widget == widget then
		if area ~= self.hot_area then
			self.hot_area = area
			if widget then
				window.cursor = widget:getcursor(area)
			end
		end
		return
	end
	if self.hot_widget then
		self.hot_widget:_mouseleave()
	end
	if widget then
		widget:_mouseenter(mx, my, area) --hot widget not changed yet
		window.cursor = widget:getcursor(area)
	else
		window.cursor = nil
	end
	self.hot_widget = widget or false
	self.hot_area = area or false
end

function ui:_accept_drop(drag_widget, drop_widget, mx, my, area)
	return drop_widget:_accept_drag_widget(drag_widget, mx, my, area)
		and drag_widget:accept_drop_widget(drop_widget, area)
end

function ui:_window_mousemove(window, mx, my)
	window:fire('mousemove', mx, my)

	--TODO: hovering with delay

	if self.active_widget then
		self.active_widget:_mousemove(mx, my)
	else
		local hit_widget, hit_area = window:hit_test(mx, my, 'activate')
		self:_set_hot_widget(window, hit_widget, mx, my, hit_area)
		if hit_widget then
			hit_widget:_mousemove(mx, my, hit_area)
		end
	end

	if self.drag_widget then
		local widget, area = window:hit_test(mx, my, 'drop')
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

function ui:_window_mouseenter(window, mx, my)
	window:fire('mouseenter', mx, my)
	self:_window_mousemove(window, mx, my)
end

function ui:_window_mouseleave(window)
	window:fire'mouseleave'
	if not self.active_widget then
		self:_set_hot_widget(window, false)
	end
end

function ui:_widget_mousemove(widget, mx, my, area)
	if not self.drag_widget and widget == self.drag_start_widget then
		--TODO: make this diff. in window space!
		local dx = math.abs(self.drag_mx - mx)
		local dy = math.abs(self.drag_my - my)
		if dx >= widget.drag_threshold or dy >= widget.drag_threshold then
			local dx, dy
			self.drag_widget, dx, dy = widget:_start_drag(
				self.drag_button,
				self.drag_mx,
				self.drag_my,
				self.drag_area)
			if dx then self.drag_mx = dx end
			if dy then self.drag_my = dy end
		end
	end
end

function ui:_window_mousedown(window, button, mx, my, click_count)
	local event = button == 'left' and 'mousedown' or button..'mousedown'
	window:fire(event, mx, my, click_count)

	if click_count > 1 then return end

	if self.active_widget then
		self.active_widget:_mousedown(button, mx, my)
	elseif self.hot_widget then
		self.hot_widget:_mousedown(button, mx, my, self.hot_area)
	end
end

function ui:_window_click(window, button, count, mx, my)
	local event = button == 'left' and 'click' or button..'click'
	window:fire(event, count, mx, my)
	local reset_click_count =
		self.last_click_hot_widget ~= self.hot_widget
		or self.last_click_hot_area ~= self.hot_widget
		or self.last_click_button ~= button
	self.last_click_hot_widget = self.hot_widget
	self.last_click_hot_area = self.hot_widget
	self.last_click_button = button
	count = reset_click_count and 1 or count
	if self.active_widget then
		return self.active_widget:_click(button, count, mx, my)
	elseif self.hot_widget then
		return
			self.hot_widget:_click(button, count, mx, my, self.hot_area)
			or reset_click_count
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

function ui:_window_mouseup(window, button, mx, my, click_count)
	local event = button == 'left' and 'mouseup' or button..'mouseup'
	window:fire(event, mx, my)

	if click_count > 1 then return end

	if self.active_widget then
		self.active_widget:_mouseup(button, mx, my)
	elseif self.hot_widget then
		self.hot_widget:_mouseup(button, mx, my, self.hot_area)
	end

	if self.drag_button == button then
		if self.drag_widget then
			if self.drop_widget then
				self.drop_widget:_drop(self.drag_widget, mx, my, self.drop_area)
				self.drag_widget:_leave_drop_target(self.drop_widget)
			end
			self.drag_widget:_ended_dragging()
			self.drag_start_widget:_end_drag()
			for _,elem in ipairs(self.elements) do
				if elem.targetable then
					elem:_set_drop_target(false)
				end
			end
		end
		self:_reset_drag_state()
	end
end

function ui:_window_mousewheel(window, delta, mx, my, pdelta)
	window:fire('mousewheel', delta, mx, my, pdelta)
	local widget, area = window:hit_test(mx, my, 'vscroll')
	if widget then
		widget:_mousewheel(delta, mx, my, area, pdelta)
	end
end

--keyboard events routing with focus logic

function ui.window:first_focusable_widget()
	return self.layer:focusable_widgets()[1]
end

function ui.window:next_focusable_widget(forward)
	if self.focused_widget then
		return self.focused_widget:next_focusable_widget(forward)
	else
		return self:first_focusable_widget()
	end
end

function ui.window:_keydown(key)
	self:fire('keydown', key)
	if self.focused_widget then
		self.focused_widget:fire('keydown', key)
	end
end

function ui.window:_keyup(key)
	self:fire('keyup', key)
	if self.focused_widget then
		self.focused_widget:fire('keyup', key)
	end
end

function ui.window:_keypress(key)
	self:fire('keypress', key)
	local capture_tab = self.focused_widget and self.focused_widget.capture_tab
	if not capture_tab and key == 'tab' and not self.ui:key'ctrl' then
		local next_widget = self:next_focusable_widget(not self.ui:key'shift')
		if next_widget then
			next_widget:focus()
		end
	elseif self.focused_widget then
		self.focused_widget:fire('keypress', key)
	end
end

function ui.window:_keychar(s)
	self:fire('keychar', s)
	if self.focused_widget then
		self.focused_widget:fire('keychar', s)
	end
end

--rendering

function ui.window:after_draw()
	self.cr:save()
	self.cr:new_path()
	self.layer:draw()
	self.cr:restore()
end

function ui.window:invalidate() --element interface; window intf.
	if self._norepaint then return end
	self.native_window:invalidate()
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

function ui:image_pattern(file)
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
ui:memoize'image_pattern'

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
	self.font_height = ext.height
	self.font_descent = ext.descent
	self.font_ascent = ext.ascent
	self.line_spacing = line_spacing
end

--multi-line self-aligned and box-aligned text

function ui.window:line_extents(s)
	local ext = self.cr:text_extents(s)
	return ext.width, ext.height, ext.y_bearing
end

function ui.window:text_line_h()
	return self.font_height * self.line_spacing
end

function ui.window:text_size(s, multiline)
	local w, h, y1 = 0, 0, self.font_ascent
	local line_h = self.font_height * self.line_spacing
	for s in lines(s, multiline) do
		local w1, h1, yb = self:line_extents(s)
		w, h = select(3, box2d.bounding_box(0, 0, w, h, 0, y1 + yb, w1, h1))
		y1 = y1 + line_h
	end
	return w, h
end

function ui.window:textbox(x0, y0, w, h, s, halign, valign, multiline)
	local cr = self.cr
	local line_h = self.font_height * self.line_spacing

	local x, y

	if halign == 'right' then
		x = w
	elseif not halign or halign == 'center' then
		x = round(w / 2)
	else
		x = 0
	end

	if valign == 'top' then
		y = self.font_ascent
	else
		local lines_h = 0
		for _ in lines(s, multiline) do
			lines_h = lines_h + line_h
		end
		lines_h = lines_h - line_h

		if valign == 'bottom' then
			y = h - self.font_descent
		elseif not valign or valign == 'center' then
			local h1 = h + self.font_ascent - self.font_descent + lines_h
			y = round(h1 / 2)
		else
			assert(false, 'invalid valign "%s"', valign)
		end
		y = y - lines_h
	end

	x = x + x0
	y = y + y0

	cr:new_path()
	for s in lines(s, multiline) do
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
end

--layers ---------------------------------------------------------------------

ui.layer = ui.element:subclass'layer'
ui.window.layer_class = ui.layer

ui.layer.activable = true
ui.layer.targetable = true

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

function ui.expand:padding(s)
	self.padding_left, self.padding_top, self.padding_right,
		self.padding_bottom = args4(s, tonumber)
end

function ui.expand:border_color(s)
	self.border_color_left, self.border_color_right, self.border_color_top,
		self.border_color_bottom = args4(s)
end

function ui.expand:border_width(s)
	self.border_width_left, self.border_width_right, self.border_width_top,
		self.border_width_bottom = args4(s, tonumber)
end

function ui.expand:corner_radius(s)
	self.corner_radius_top_left, self.corner_radius_top_right,
		self.corner_radius_bottom_right, self.corner_radius_bottom_left =
			args4(s, tonumber)
end

function ui.expand:scale(scale)
	self.scale_x = scale
	self.scale_y = scale
end

function ui.expand:background_scale(scale)
	self.background_scale_x = scale
	self.background_scale_y = scale
end

function ui.layer:set_padding(s) self:expand_attr('padding', s) end
function ui.layer:set_border_color(s) self:expand_attr('border_color', s) end
function ui.layer:set_border_width(s) self:expand_attr('border_width', s) end
function ui.layer:set_corner_radius(s) self:expand_attr('corner_radius', s) end
function ui.layer:set_scale(scale) self:expand_attr('scale', scale) end
function ui.layer:set_background_scale(scale)
	self:expand_attr('background_scale', scale)
end

ui.layer.x = 0
ui.layer.y = 0
ui.layer.w = 0
ui.layer.h = 0
ui.layer.rotation = 0
ui.layer.rotation_cx = 0
ui.layer.rotation_cy = 0
ui.layer.scale_x = 1
ui.layer.scale_y = 1
ui.layer.scale_cx = 0
ui.layer.scale_cy = 0

ui.layer.opacity = 1

ui.layer.clip_content = false --'padding'/true, 'background', false

ui.layer.padding = 0

ui.layer.background_type = 'color' --false, 'color', 'gradient', 'radial_gradient', 'image'
ui.layer.background_hittable = false
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
ui.layer.background_color = false --no background
--gradient backgrounds
ui.layer.background_colors = false --{[offset1], color1, ...}
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
ui.layer.background_image = false

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

ui.layer.text_align = 'center'
ui.layer.text_valign = 'center'
ui.layer.text_multiline = true
ui.layer.text = nil

ui.layer.cursor = false

ui.layer.drag_threshold = 0 --moving distance before start dragging
ui.layer.max_click_chain = 1 --2 for getting doubleclick events etc.
ui.layer.hover_delay = 1 --TODO: hover event delay

ui.layer.canfocus = false
ui.layer.tabindex = false

function ui.layer:before_free()
	if self.hot then
		self.ui.hot_widget = false
		self.ui.hot_area = false
	end
	if self.active then
		self.ui.active_widget = false
	end
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
	return self.pos_parent:abs_matrix():transform(self:rel_matrix())
end

local mt
function ui.layer:cr_abs_matrix(cr) --box matrix in cr's current space
	if self.pos_parent ~= self.parent then
		return self:abs_matrix()
	else
		mt = mt or cairo.matrix()
		return cr:matrix(nil, mt):transform(self:rel_matrix())
	end
end

--convert point from own box space to parent content space
function ui.layer:from_box_to_parent(x, y)
	if self.pos_parent ~= self.parent then
		return self.parent:from_window(self:abs_matrix():point(x, y))
	else
		return self:rel_matrix():point(x, y)
	end
end

--convert point from parent content space to own box space
function ui.layer:from_parent_to_box(x, y)
	if self.pos_parent ~= self.parent then
		return self:abs_matrix():invert():point(self.parent:to_window(x, y))
	else
		return self:rel_matrix():invert():point(x, y)
	end
end

--convert point from own content space to parent content space
function ui.layer:to_parent(x, y)
	if self.pos_parent ~= self.parent then
		return self.parent:from_window(
			self:abs_matrix():translate(self:padding_pos()):point(x, y))
	else
		return self:rel_matrix():translate(self:padding_pos()):point(x, y)
	end
end

--convert point from parent content space to own content space
function ui.layer:from_parent(x, y)
	if self.pos_parent ~= self.parent then
		return self:abs_matrix():translate(self:padding_pos()):invert()
			:point(self.parent:to_window(x, y))
	else
		return self:rel_matrix():translate(self:padding_pos()):invert()
			:point(x, y)
	end
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

--convert point from other's content space to own content space
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

function ui.layer:get_mouse()
	return self.window.mouse
end

function ui.layer:get_parent() --child interface
	return self._parent
end

function ui.layer:set_parent(parent)
	if parent and parent.iswindow then
		parent = parent.layer
	end
	if self._parent ~= parent then
		if self._parent then
			self._parent:remove_layer(self)
		end
		if parent then
			parent:add_layer(self)
		end
	end
end

function ui.layer:get_pos_parent() --child interface
	return self._pos_parent or self._parent
end

function ui.layer:set_pos_parent(parent)
	if parent and parent.iswindow then
		parent = parent.layer
	end
	if parent == self.parent then
		parent = nil
	end
	self._pos_parent = parent
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

function ui.layer:each_child(func)
	if not self.layers then return end
	for _,layer in ipairs(self.layers) do
		layer:each_child(func)
		func(layer)
	end
end

function ui.layer:children()
	return coroutine.wrap(function()
		self:each_child(coroutine.yield)
	end)
end

function ui.layer:add_layer(layer) --parent interface
	self.layers = self.layers or {}
	push(self.layers, layer)
	layer._parent = self
	layer.window = self.window
	layer:each_child(function(layer) layer.window = self.window end)
	self:fire('layer_added', layer)
end

function ui.layer:remove_layer(layer) --parent interface
	popval(self.layers, layer)
	self:fire('layer_removed', layer)
	layer._parent = false
	layer.window = false
	layer:each_child(function(layer) layer.window = false end)
end

function ui.layer:_free_layers()
	if not self.layers then return end
	while #self.layers > 0 do
		self.layers[#self.layers]:free()
	end
end

--mouse event handling

function ui.layer:getcursor(area)
	return self['cursor_'..area] or self.cursor
end

function ui.layer:_mousemove(mx, my, area)
	local mx, my = self:from_window(mx, my)
	self:fire('mousemove', mx, my, area)
	self.ui:_widget_mousemove(self, mx, my, area)
end

function ui.layer:_mouseenter(mx, my, area)
	local mx, my = self:from_window(mx, my)
	self:settag('hot', true)
	if area then
		self:settag('hot_'..area, true)
	end
	self:fire('mouseenter', mx, my, area)
end

function ui.layer:_mouseleave()
	self:fire'mouseleave'
	local area = self.ui.hot_area
	self:settag('hot', false)
	if area then
		self:settag('hot_'..area, false)
	end
end

function ui.layer:_mousedown(button, mx, my, area)
	local mx, my = self:from_window(mx, my)
	local event = button == 'left' and 'mousedown' or button..'mousedown'
	self:fire(event, mx, my, area)
	self.ui:_widget_mousedown(self, button, mx, my, area)
end

function ui.layer:_mouseup(button, mx, my, area)
	local mx, my = self:from_window(mx, my)
	local event = button == 'left' and 'mouseup' or button..'mouseup'
	self:fire(event, mx, my, area)
end

function ui.layer:_click(button, count, mx, my, area)
	local mx, my = self:from_window(mx, my)
	local event =
		count == 1 and 'click'
		or count == 2 and 'doubleclick'
		or count == 3 and 'tripleclick'
		or count == 4 and 'quadrupleclick'
	local event = button == 'left' and event or button..event
	self:fire(event, mx, my, area)
	local max_click_chain = self['max_'..button..'_click_chain']
		or self.max_click_chain
	if count >= max_click_chain then
		return true --stop the click chain
	end
end

function ui.layer:_mousewheel(delta, mx, my, area, pdelta)
	self:fire('mousewheel', delta, mx, my, area, pdelta)
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
	self:settag('dropping', true)
	self:fire('enter_drop_target', widget, area)
end

--called on the dragged widget once upon leaving a drop target.
function ui.layer:_leave_drop_target(widget)
	self:fire('leave_drop_target', widget)
	self:settag('dropping', false)
end

--called on the dragged widget when dragging starts.
function ui.layer:_started_dragging()
	self.dragging = true
	self:settag('dragging', true)
	self:fire'started_dragging'
end

--called on the dragged widget when dragging ends.
function ui.layer:_ended_dragging()
	self.dragging = false
	self:settag('dragging', false)
	self:fire'ended_dragging'
end

function ui.layer:_set_drop_target(set)
	self:settag('drop_target', set)
end

--called on drag_start_widget to initiate a drag operation.
function ui.layer:_start_drag(button, mx, my, area)
	local widget, dx, dy = self:start_drag(button, mx, my, area)
	if widget then
		self:settag('drag_source', true)
		for i,elem in ipairs(self.ui.elements) do
			if elem.targetable then
				if self.ui:_accept_drop(widget, elem) then
					elem:_set_drop_target(true)
				end
			end
		end
		widget:_started_dragging()
	end
	return widget, dx, dy
end

--stub: return a widget to drag (self works too).
function ui.layer:start_drag(button, mx, my, area) end

function ui.layer:_end_drag() --called on the drag_start_widget
	self:settag('drag_source', false)
	self:fire('end_drag', self.ui.drag_widget)
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

--focusing and keyboard event handling

function ui.window:remove_focus()
	local fw = self.focused_widget
	if not fw then return end
	fw:fire'lostfocus'
	fw:settag('focused', false)
end

function ui.layer:focus()
	if not self.visible then
		return
	end
	if self.focusable then
		self.window:remove_focus()
		self:fire'gotfocus'
		self:settag('focused', true)
		self.window.focused_widget = self
		return true
	else --focus first focusable child
		local layer = self.layers and self:focusable_widgets()[1]
		if layer and layer:focus() then
			return true
		end
	end
end

function ui.layer:get_focused()
	return self.window and self.window.focused_widget == self
end

function ui.layer:get_focused_widget()
	if self.focused then
		return self
	end
	if self.layers then
		for _,layer in ipairs(self.layers) do
			local focused_widget = layer.focused_widget
			if focused_widget then
				return focused_widget
			end
		end
	end
end

function ui.layer:focusable_widgets()
	local t = {}
	if self.layers then
		for i,layer in ipairs(self.layers) do
			if layer.focusable then
				push(t, layer)
			end
		end
	end
	table.sort(t, function(t1, t2)
		if t1.tabindex == t2.tabindex then
			if t1.x == t2.x then
				return t1.y < t2.y
			else
				return t1.x < t2.x
			end
		else
			return t1.tabindex < t2.tabindex
		end
	end)
	return t
end

function ui.layer:next_focusable_sibling_widget(widget, forward)
	assert(widget.parent == self)
	local t = self:focusable_widgets()
	for i,layer in ipairs(t) do
		if layer == widget then
			return t[i + (forward and 1 or -1)]
		end
	end
end

function ui.layer:next_focusable_widget(forward)
	if not self.parent then
		return self
	else
		return self.parent:next_focusable_sibling_widget(self, forward)
	end
end

--layers geometry, drawing and hit testing

function ui.layer:layers_bounding_box(strict)
	local x, y, w, h = 0, 0, 0, 0
	if self.layers then
		for _,layer in ipairs(self.layers) do
			x, y, w, h = box2d.bounding_box(x, y, w, h,
				layer:bounding_box(strict))
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

function ui.layer:hit_test_layers(x, y, reason) --called in content space
	if not self.layers then return end
	for i = #self.layers, 1, -1 do
		local widget, area = self.layers[i]:hit_test(x, y, reason)
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

function ui.layer:get_border_outer_x() return (select(1, self:border_rect(1))) end
function ui.layer:get_border_outer_y() return (select(2, self:border_rect(1))) end
function ui.layer:get_border_outer_w() return (select(3, self:border_rect(1))) end
function ui.layer:get_border_outer_h() return (select(4, self:border_rect(1))) end

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
	return (
		(self.background_type == 'color' and self.background_color)
		or ((self.background_type == 'gradient'
			or self.background_type == 'radial_gradient')
			and self.background_colors and #self.background_colors > 0)
		or (self.background_type == 'image' and self.background_image)
	) and true or false
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
		local img = self.ui:image_pattern(self.background_image)
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
	return t.shadow_blur == self.shadow_blur
		and t.x == x and t.y == y and t.w == w and t.h == h
		and t.r1x == r1x and t.r1y == r1y and t.r2x == r2x and t.r2y == r2y
		and t.r3x == r3x and t.r3y == r3y and t.r4x == r4x and t.r4y == r4y
		and t.k == k
end

function ui.layer:shadow_store_key(t)
	t.shadow_blur = self.shadow_blur
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
	if not self:shadow_valid_key(t) then

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

--text geometry and drawing

function ui.layer:text_visible()
	return self.text and true or false
end

function ui.layer:draw_text()
	if not self:text_visible() then return end
	self:setfont()
	local cw, ch = self:content_size()
	self.window:textbox(0, 0, cw, ch, self.text,
		self.text_align, self.text_valign, self.text_multiline)
end

function ui.layer:text_bounding_box()
	if not self:text_visible() then return 0, 0, 0, 0 end
	self:setfont()
	local w, h = self.window:text_size(self.text, self.text_multiline)
	local cw, ch = self:content_size()
	return box2d.align(w, h, self.text_align, self.text_valign,
		0, 0, cw, ch)
end

--content-box geometry, drawing and hit testing

function ui.layer:padding_pos() --in box space
	return
		self.padding_left,
		self.padding_top
end

function ui.layer:padding_rect() --in box space
	return
		self.padding_left,
		self.padding_top,
		self.w - self.padding_left - self.padding_right,
		self.h - self.padding_top - self.padding_bottom
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
	self:draw_text()
end

function ui.layer:hit_test_content(x, y, reason) --called in own content space
	return self:hit_test_layers(x, y, reason)
end

function ui.layer:content_bounding_box(strict)
	local x, y, w, h = self:layers_bounding_box(strict)
	return box2d.bounding_box(x, y, w, h, self:text_bounding_box())
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

	local cc = self.clip_content
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

--called in parent's content space; child interface.
function ui.layer:hit_test(x, y, reason)

	if not self.visible or self.opacity == 0 then return end

	local self_allowed =
		   (reason == 'activate' and self.activable)
		or (reason == 'drop' and self.targetable)
		or (reason == 'vscroll' and (self.vscrollable or self.scrollable))
		or (reason == 'hscroll' and (self.hscrollable or self.scrollable))

	local cr = self.window.cr
	local x, y = self:from_parent_to_box(x, y)
	cr:save()
	cr:identity_matrix()

	local cc = self.clip_content

	--hit the content first if it's not clipped
	if not cc then
		local cx, cy = self:to_content(x, y)
		local widget, area = self:hit_test_content(cx, cy, reason)
		if widget then
			cr:restore()
			return widget, area
		end
	end

	--border is drawn last so hit it first
	if self:border_visible() then
		cr:new_path()
		self:border_path(1)
		if cr:in_fill(x, y) then --inside border outer edge
			cr:new_path()
			self:border_path(-1)
			if not cr:in_fill(x, y) then --outside border inner edge
				cr:restore()
				if self_allowed then
					return self, 'border'
				else
					return
				end
			end
		elseif cc then --outside border outer edge when clipped
			cr:restore()
			return
		end
	end

	--hit background's clip area
	local in_bg
	if cc or self.background_hittable or self:background_visible() then
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
		local widget, area = self:hit_test_content(cx, cy, reason)
		if widget then
			cr:restore()
			return widget, area
		end
	end

	--hit the background if any
	if self_allowed and in_bg then
		return self, 'background'
	end
end

function ui.layer:bounding_box(strict) --child interface
	local x, y, w, h = 0, 0, 0, 0
	local cc = self.clip_content
	if strict or not cc then
		x, y, w, h = self:content_bounding_box(strict)
		if cc then
			x, y, w, h = box2d.clip(x, y, w, h, self:background_rect())
			if cc == 'padding' or cc == true then
				x, y, w, h = box2d.clip(x, y, w, h, self:padding_rect())
			end
		end
	end
	if (not strict and cc)
		or self.background_hittable
		or self:background_visible()
	then
		x, y, w, h = box2d.bounding_box(x, y, w, h, self:background_rect())
	end
	if self:border_visible() then
		x, y, w, h = box2d.bounding_box(x, y, w, h, self:border_rect(1))
	end
	return x, y, w, h
end

--element interface

function ui.layer:get_frame_clock()
	return self.window.frame_clock
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
		active_widget:settag('active', false)
		self.ui.active_widget = false
		active_widget:fire'deactivated'
	end
	if active then
		self.ui.active_widget = self
		self:settag('active', true)
		self:fire'activated'
		self:focus()
	end
	self:invalidate()
end

function ui.layer:activate()
	if not self.active then
		self.active = true
		self.active = false
	end
end

--utils in content space to use from draw_content() and hit_test_content()

function ui.layer:rect() return 0, 0, self.w, self.h end --the box itself
function ui.layer:size() return self.w, self.h end

function ui.layer:content_size()
	return select(3, self:padding_rect())
end

function ui.layer:content_rect() --in content space
	return 0, 0, select(3, self:padding_rect())
end
function ui.layer:content_size()
	return select(3, self:padding_rect())
end
function ui.layer:get_cw() return (select(3, self:padding_rect())) end
function ui.layer:get_ch() return (select(4, self:padding_rect())) end

function ui.layer:set_cw(cw) self.w = cw + (self.w - self.cw) end
function ui.layer:set_ch(ch) self.h = ch + (self.h - self.ch) end

function ui.layer:get_x2() return self.x + self.w end
function ui.layer:get_y2() return self.x + self.h end

function ui.layer:set_x2(x2) self.x = x2 - self.w end
function ui.layer:set_y2(y2) self.y = y2 - self.h end

function ui.layer:get_cx() return self.x + self.w / 2 end
function ui.layer:get_cy() return self.x + self.h / 2 end

function ui.layer:set_cx(cx) self.x = cx - self.w / 2 end
function ui.layer:set_cy(cy) self.y = cy - self.h / 2 end

function ui.layer:setfont(family, weight, slant, size, color, line_spacing)
	self.window:setfont(
		family or self.font_family,
		weight or self.font_weight,
		slant or self.font_slant,
		size or self.text_size,
		line_spacing or self.line_spacing)
	self.window.cr:rgba(self.ui:color(color or self.text_color))
end

--widgets autoload -----------------------------------------------------------

local autoload = {
	scrollbar  = 'ui_scrollbox',
	scrollbox  = 'ui_scrollbox',
	button     = 'ui_button',
	slider     = 'ui_slider',
	editbox    = 'ui_editbox',
	tab        = 'ui_tablist',
	tablist    = 'ui_tablist',
	menuitem   = 'ui_menu',
	menu       = 'ui_menu',
	image      = 'ui_image',
}

for widget, submodule in pairs(autoload) do
	ui['get_'..widget] = function()
		require(submodule)
		return ui[widget]
	end
end

return ui
