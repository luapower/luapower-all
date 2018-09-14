
--Extensible UI toolkit in Lua.
--Written by Cosmin Apreutesei. Public Domain.

if not ... then require'ui_demo'; return end

local oo = require'oo'
local glue = require'glue'
local box2d = require'box2d'
local easing = require'easing'
local color = require'color'
local boxblur = require'boxblur'
local amoeba = require'amoeba'
local time = require'time'
local freetype = require'freetype'
local cairo = require'cairo'
local fs = require'fs'
local tr = require'tr'
local font_db = require'tr_font_db'

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
local trim = glue.trim

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
	--after the first instantiation doesn't have an effect anymore (it will
	--require calling inherit() manually on all those final classes).
	if not rawget(self.super, 'isfinalclass') then
		self.super:inherit()
		self.super.isfinalclass = true
	end
	--speed up virtual property lookup without detaching/fattening the instance.
	--with this change, adding or overriding getters and setters through the
	--instance is not allowed anymore, that would patch the class instead!
	--TODO: I don't like this arbitrary limitation, do something about it.
	self.__setters = self.__setters
	self.__getters = self.__getters
end

--method and property decorators ---------------------------------------------

--generic method memoizer
function object:memoize(method_name)
	function self:after_init()
		local method =
			   method_name:find'^get_' and self.__getters[method_name:sub(5)]
			or method_name:find'^set_' and self.__setters[method_name:sub(5)]
			or self[method_name]
		local memfunc = memoize(function(...)
			return method(self, ...)
		end)
		self[method_name] = function(self, ...)
			return memfunc(...)
		end
	end
end

--install event listeners in object which forward events in self.
function object:forward_events(object, event_names)
	for _,event in ipairs(event_names) do
		object:on({event, self}, function(object, ...)
			return self:fire(event, ...)
		end)
	end
	function self:before_free()
		for _,event in ipairs(event_names) do
			object:off{event, self}
		end
	end
end

--create a r/w property which reads/writes to a "private var".
function object:stored_property(prop)
	local priv = '_'..prop
	self[priv] = self[prop] --transfer existing value to private var
	self[prop] = nil
	self['get_'..prop] = function(self)
		return self[priv]
	end
	self['set_'..prop] = function(self, val)
		self[priv] = val or false
	end
end

--change a property so that its setter is only called when the value changes.
function object:nochange_barrier(prop)
	local changed_event = prop..'_changed'
	self['override_set_'..prop] = function(self, inherited, val)
		val = val or false
		local old_val = self[prop] or false
		if val ~= old_val then
			inherited(self, val, old_val)
			return true --useful when overriding the setter further
		end
	end
end

--change a property so that its setter is only called when the value changes
--and also '<prop>_changed' event is fired.
function object:track_changes(prop)
	local changed_event = prop..'_changed'
	self['override_set_'..prop] = function(self, inherited, val)
		val = val or false
		local old_val = self[prop] or false
		if val ~= old_val then
			inherited(self, val, old_val)
			self:fire(changed_event, val, old_val)
			return true --useful when overriding the setter further
		end
	end
end

--inhibit a property's getter and setter when using the property on the class.
--instead, set a private var on the class which serves as default value.
--NOTE: use this only _after_ defining the getter and setter.
function object:instance_only(prop)
	local priv = '_'..prop
	self['override_get_'..prop] = function(self, inherited)
		if self:isinstance() then
			return inherited(self)
		else
			return self[priv] --get the default value
		end
	end
	self['override_set_'..prop] = function(self, inherited, val)
		if self:isinstance() then
			return inherited(self, val)
		else
			self[priv] = val --set the default value
		end
	end
end

--module object --------------------------------------------------------------

local ui = object:subclass'ui'
ui.object = object

function ui:create() --singleton class (no instance is created)
	self:init()
	function self:create() return self end
	return self
end

function ui:after_init()
	local nw = require'nw'
	self.app = nw:app()

	self:forward_events(self.app, {
		'quitting',
		'activated', 'deactivated', 'wakeup',
		'hidden', 'unhidden',
		'displays_changed',
		})
end

function ui:before_free()
	self.app = false
end

function ui:error(msg, ...)
	msg = string.format(msg, ...)
	io.stderr:write(msg)
	io.stderr:write'\n'
end

function ui:check(ret, ...)
	if ret then return ret end
	self:error(...)
end

--native app proxy methods ---------------------------------------------------

function ui:native_window(t)       return self().app:window(t) end

function ui:get_active_window()
	local win = self().app:active_window()
	return win and win.ui_window
end

function ui:clock()                return time.clock() end
function ui:run(func)              return self().app:run(func) end
function ui:poll(timeout)          return self().app:poll(timeout) end
function ui:stop()                 return self().app:stop() end
function ui:quit()                 return self().app:quit() end
function ui:get_autoquit()         return self().app:autoquit() end
function ui:set_autoquit(aq)       return self().app:autoquit(aq or false) end
function ui:get_maxfps()           return self().app:maxfps() end
function ui:set_maxfps(fps)        return self().app:maxfps(fps or false) end
function ui:runevery(t, f)         return self().app:runevery(t, f) end
function ui:runafter(t, f)         return self().app:runafter(t, f) end
function ui:sleep(s)               return self().app:sleep(s) end

function ui:get_app_active()       return self().app:active() end
function ui:activate_app()         return self().app:activate() end
function ui:get_app_visible()      return self().app:visible() end
function ui:set_app_visible(v)     return self().app:visible(v or false) end
function ui:hide_app()             return self().app:hide() end
function ui:unhide_app()           return self().app:unhide() end

function ui:key(query)             return self().app:key(query) end
function ui:get_caret_blink_time() return self().app:caret_blink_time() end

function ui:get_displays()         return self().app:displays() end
function ui:get_main_display()     return self().app:main_display() end
function ui:get_active_display()   return self().app:active_display() end

function ui:getclipboard(type)     return self().app:getclipboard(type) end
function ui:setclipboard(s, type)  return self().app:setclipboard(s, type) end

function ui:opendialog(t)          return self().app:opendialog(t) end
function ui:savedialog(t)          return self().app:savedialog(t) end

function ui:set_app_id(id)         self().app.nw.app_id = id end
function ui:get_app_id(id)         return require'nw'.app_id end
function ui:app_already_running()  return self().app:already_running() end
function ui:wakeup_other_app_instances()
	return self().app:wakeup_other_instances()
end
function ui:check_single_app_instance()
	return self().app:check_single_instance()
end

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

local function has_state_tags(tags)
	for _,tag in ipairs(tags) do
		if tag:find(':', 1, true) then
			return true
		end
	end
end
function ui.selector:has_state_tags()
	if has_state_tags(self.tags) then
		return true
	end
	if self.parent_tags then
		for _,tags in ipairs(self.parent_tags) do
			if has_state_tags(tags) then
				return true
			end
		end
	end
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

local stylesheet = ui.object:subclass'stylesheet'
ui.stylesheet_class = stylesheet

function stylesheet:after_init(ui)
	self.ui = ui
	self.tags = {} --{tag -> {sel1, ...}}
	self.parent_tags = {} --{tag -> {sel1, ...}}
	self.selectors = {} --{selector1, ...}
	self.first_state_sel_index = 1 --index of first selector with :state tags
end

function stylesheet:add_style(sel, attrs)

	if type(sel) == 'string' and sel:find(',', 1, true) then
		for sel in sel:gmatch'[^,]+' do
			self:add_style(sel, attrs)
		end
		return
	end
	local sel = self.ui:selector(sel)

	--expand attributes
	for attr, val in pairs(attrs) do
		if self.ui:expand_attr(attr, val, attrs) then
			attrs[attr] = nil
		end
	end
	sel.attrs = attrs

	local is_state_sel = sel:has_state_tags()
	local index = is_state_sel and #self.selectors+1 or self.first_state_sel_index
	sel.index = index
	push(self.selectors, index, sel)
	for i = index+1, #self.selectors do --update index field on shifted selectors
		self.selectors[i].index = i
	end
	if not is_state_sel then
		self.first_state_sel_index = index+1
	end

	--populate the selector reverse-lookup tables
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

function stylesheet:add_stylesheet(stylesheet)
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
	return sel1.index < sel2.index
end

function stylesheet:update_element(elem, update_children)

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

function stylesheet:update_style(style)
	for _,elem in ipairs(self.elements) do
		--TODO:
	end
end

function ui:style(sel, attrs)
	self.stylesheet:add_style(sel, attrs)
end

ui.stylesheet = ui:stylesheet_class()

--attribute types ------------------------------------------------------------

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

local default_ease = 'expo out'

ui.transition = ui.object:subclass'transition'

ui.transition.interpolate = {}
	--^ {attr_type -> func(self, d, x1, x2, xout) -> xout}

function ui.transition:interpolate_function(elem, attr)
	local atype = self.ui:attr_type(attr)
	return self.interpolate[atype]
end

function ui.transition:after_init(ui, elem, attr, to,
	duration, ease, delay, times, backval, clock)

	self.ui = ui

	--timing model
	local clock = clock or ui:clock()
	local times = times or 1
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
	elem[attr] = interpolate(self, 1, from, from)

	local repeated

	function self:update(clock)
		local t = (clock - start) / duration
		if t < 0 then --not started
			--nothing
		elseif t >= 1 then --finished, set to actual final value
			elem[attr] = to
		else --running, set to interpolated value
			local d = easing.ease(ease, way, t)
			elem[attr] = interpolate(self, d, from, to, elem[attr])
		end
		local alive = t <= 1
		if not alive and times > 1 then --repeat in opposite direction
			if not repeated then
				from = backval
				repeated = true
			end
			times = times - 1
			start = clock + delay
			from, to = to, from
			alive = true
		end
		return alive
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

	--NOTE: chain_to() replaces the next transaction, it does not chain to it.
	function self:chain_to(tran)
		start = tran:end_clock() + delay
		from = tran:end_value()
		tran.next_transition = self
		return tran
	end

end

--interpolators

function ui.transition.interpolate:number(d, x1, x2)
	return lerp(d, 0, 1, tonumber(x1), tonumber(x2))
end

function ui.transition.interpolate:color(d, c1, c2, c)
	local r1, g1, b1, a1 = self.ui:rgba(c1)
	local r2, g2, b2, a2 = self.ui:rgba(c2)
	local r = lerp(d, 0, 1, r1, r2)
	local g = lerp(d, 0, 1, g1, g2)
	local b = lerp(d, 0, 1, b1, b2)
	local a = lerp(d, 0, 1, a1 or 1, a2 or 1)
	if type(c) == 'table' then --by-reference semantics
		c[1], c[2], c[3], c[4] = r, g, b, a
		return c
	else --by-value semantics
		return {r, g, b, a}
	end
end

function ui.transition.interpolate:gradient_colors(d, t1, t2, t)
	t = t or {}
	for i,arg1 in ipairs(t1) do
		local arg2 = t2[i]
		local atype = type(arg1) == 'number' and 'number' or 'color'
		t[i] = ui.transition.interpolate[atype](self, d, arg1, arg2, t[i])
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

local element = ui.object:subclass'element'
ui.element = element
ui.element.ui = ui

function element:expand_attr(attr, val)
	return self.ui:expand_attr(attr, val, self)
end

--init

function element:init_ignore(t) --class method
	if self._init_ignore == self.super._init_ignore then
		self._init_ignore = update({}, self.super._init_ignore)
	end
	update(self._init_ignore, t)
end

function element:init_priority(t) --class method
	if self._init_priority == self.super._init_priority then
		self._init_priority = update({}, self.super._init_priority)
	end
	update(self._init_priority, t)
end

element:init_priority{}
element:init_ignore{}

--override element constructor so that:
-- 1) it can take multiple initialization tables as args.
-- 2) it inherits the class to get default values directly through t.
function element:override_create(inherited, ui, t, ...)
	local t = setmetatable(update({}, t, ...), {__index = self})
	return inherited(self, ui, t)
end

function element:init_fields(t)
	--set attributes in priority and/or lexicographic order so that eg.
	--`border_width` comes before `border_width_left`.
	local pri = self._init_priority
	local function cmp(a, b)
		local pa, pb = pri[a], pri[b]
		if pa or pb then
			return (pa or 0) < (pb or 0)
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

function element:after_init(ui, t)
	self.ui = ui()
	self:init_tags(t)
	self:init_fields(t)
	self.ui:_add_element(self)
end

function element:before_free()
	self.ui:off{nil, self}
	self.ui:_remove_element(self)
	self.ui = false
end

--tags & styles

element.stylesheet = ui.stylesheet

element:init_ignore{tags=1, stylesheet=1}

local function add_tags(tags, s)
	if not s then return end
	for tag in gmatch_tags(s) do
		tags[tag] = true
	end
end
function element:init_tags(t)
	--custom class tags
	local class_tags = self.tags
	self.tags = {['*'] = true}
	add_tags(self.tags, class_tags)

	--classname tags
	local super = self.super
	while true do
		if super.classname then
			self.tags[super.classname] = true
			if super.classname == 'element' then
				break
			end
		end
		super = super.super
	end

	if t then
		if t.stylesheet then
			self.stylesheet = t.stylesheet
		end
		if t.tags then
			add_tags(self.tags, t.tags)
		end
	end
end

function element:settag(tag, op)
	local had_tag = self.tags[tag]
	if op == '~' then
		self.tags[tag] = not had_tag
		self._styles_valid = false
		self:invalidate()
	elseif op and not had_tag then
		self.tags[tag] = true
		self._styles_valid = false
		self:invalidate()
	elseif not op and had_tag then
		self.tags[tag] = false
		self._styles_valid = false
		self:invalidate()
	end
end

function element:settags(s)
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

function element:update_styles()
	if not self._styles_valid then
		self.stylesheet:update_element(self)
		self._styles_valid = true
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

function element:_save_initial_value(attr)
	local init = self._initial_values
	if not init then
		init = {}
		self._initial_values = init
	end
	if init[attr] == nil then --wasn't saved before
		init[attr] = encode_nil(self[attr])
	end
end

function element:initial_value(attr)
	local t = self._initial_values
	if t then
		local ival = t[attr]
		if ival ~= nil then
			return decode_nil(ival)
		end
	end
	return self[attr]
end

function element:parent_value(attr)
	::again::
	local val = self[attr]
	if val == nil then
		local parent = rawget(self, '_parent')
		if parent then
			self = parent
			goto again
		end
	end
	return val
end

--animated attribute transitions

ui.blend = {}

function ui.blend.replace(ui, tran, elem, attr, val, duration, ease, delay, clock)
	return ui:transition(elem, attr, val, duration, ease, delay, nil, nil, clock)
end

function ui.blend.replace_nodelay(ui, tran, elem, attr, val,
	duration, ease, delay, clock)
	return ui:transition(elem, attr, val, duration, ease, 0, nil, nil, clock)
end

function ui.blend.wait(ui, tran, elem, attr, val, duration, ease, delay, clock)
	local new_tran = ui:transition(elem, attr, val, duration, ease, delay, nil, nil, clock)
	return new_tran:chain_to(tran)
end

function ui.blend.wait_nodelay(ui, tran, elem, attr, val, duration, ease, delay, clock)
	local new_tran = ui:transition(elem, attr, val, duration, ease, 0, nil, nil, clock)
	return new_tran:chain_to(tran)
end

function element:end_value(attr)
	local tran = self.transitions and self.transitions[attr]
	if tran then
		return tran:end_value()
	else
		return self[attr]
	end
end

element.transition_duration = 0
element.transition_ease = default_ease
element.transition_delay = 0
element.transition_repeat = 1
element.transition_speed = 1
element.transition_blend = 'replace_nodelay'

function element:transition(attr, val, duration, ease, delay, times, backval, blend)

	if type(val) == 'function' then --computed value
		val = val(self, attr)
	end

	--get transition parameters
	if not duration and self['transition_'..attr] then
		duration = self['transition_duration_'..attr] or self.transition_duration
		ease = ease or self['transition_ease_'..attr] or self.transition_ease
		delay = delay or self['transition_delay_'..attr] or self.transition_delay
		times = times or self['transition_repeat_'..attr] or self.transition_repeat
		local speed = self['transition_speed_'..attr] or self.transition_speed
		blend = blend or self['transition_blend_'..attr] or self.transition_blend
		duration = duration / speed
	else
		duration = duration or 0
		ease = ease or default_ease
		delay = delay or 0
		times = times or 1
		blend = blend or 'replace_nodelay'
	end

	local tran = self.transitions and self.transitions[attr]
	local changed

	if duration <= 0
		and ((blend == 'replace' and delay <= 0) or blend == 'replace_nodelay')
	then
		tran = nil --remove existing transition on attr
		changed = self[attr] ~= val
		self[attr] = val --set attr directly
	else --set attr with transition
		if tran then
			if tran:end_value() ~= val then
				local blend_func = self.ui.blend[blend]
				tran = blend_func(self.ui, tran, self, attr, val,
					duration, ease, delay, self.frame_clock)
				changed = true
			end
		elseif self[attr] ~= val then
			if times > 1 and backval == nil then
				backval = self:initial_value(attr)
			end
			tran = self.ui:transition(self, attr, val,
				duration, ease, delay, times, backval, self.frame_clock)
			changed = true
		end
	end

	if tran then
		self.transitions = self.transitions or {}
		self.transitions[attr] = tran
	elseif self.transitions then
		self.transitions[attr] = nil
	end

	if changed then
		self:invalidate()
	end
end

function element:transitioning(attr)
	return self.transitions and self.transitions[attr] and true or false
end

function element:before_draw(cr)
	self:update_styles()
end

--windows --------------------------------------------------------------------

local window = element:subclass'window'
ui.window = window

function ui:after_init()
	self.windows = {}
end

function ui:before_free()
	for win in pairs(self.windows) do
		win:close()
	end
	self.windows = false
end

local native_fields = {
	x=1, y=1, w=1, h=1,
	cx=1, cy=1, cw=1, ch=1,
	min_cw=1, min_ch=1, max_cw=1, max_ch=1,
	visible=1, minimized=1, maximized=1, enabled=1,
	frame=1, title=1, transparent=1, corner_radius=1,
	sticky=1, topmost=1, minimizable=1, maximizable=1, closeable=1,
	resizeable=1, fullscreenable=1, activable=1, autoquit=1, edgesnapping=1,
}

window:init_ignore{native_window=1, parent=1}
window:init_ignore(native_fields)

function window:create_native_window(t)
	return self.ui:native_window(t)
end

function window:override_init(inherited, ui, t)
	local show_it
	local win = t.native_window
	local parent = t.parent
	if parent and parent.iswindow then
		parent = parent.view
	end
	if not win then
		local nt = {}
		for k in pairs(native_fields) do
			nt[k] = t[k]
		end
		show_it = nt.visible ~= false --defer
		nt.parent = parent and assert(parent.window.native_window)
		nt.visible = false
		if parent then
			local rx = nt.x or 0
			local ry = nt.y or 0
			nt.x, nt.y = parent:to_screen(rx, ry)
		end
		win = self:create_native_window(nt)
		self.native_window = win
		self.own_native_window = true
	else
		self.native_window = t.native_window
	end
	self.ui.windows[self] = true
	win.ui_window = self
	self._parent = parent

	if parent then

		function parent.before_free()
			self._parent = false
		end

		local px0, py0 = parent:to_window(0, 0)
		function parent.before_draw(cr)
			if not self.native_window then return end --freed
			local px1, py1 = parent:to_window(0, 0)
			local dx = px1 - px0
			local dy = py1 - py0
			if dx ~= 0 or dy ~= 0 then
				local x0, y0 = self.native_window:frame_rect()
				self:frame_rect(x0 + dx, y0 + dy)
				px0, py0 = px1, py1
			end
		end

	end

	inherited(self, ui, t)

	self:forward_events(win, {
		'activated', 'deactivated', 'wakeup',
		'shown', 'hidden',
		'minimized', 'unminimized',
		'maximized', 'unmaximized',
		'entered_fullscreen', 'exited_fullscreen',
		'changed',
		'sizing',
		'frame_rect_changed', 'frame_moved', 'frame_resized',
		'client_moved', 'client_resized',
		'magnets',
		'free_cairo', 'free_bitmap',
		'scalingfactor_changed',
		--TODO: dispatch to widgets: 'dropfiles', 'dragging',
	})

	self.mouse_x = win:mouse'x' or false
	self.mouse_y = win:mouse'y' or false
	self.mouse_left = win:mouse'left' or false
	self.mouse_right = win:mouse'right' or false
	self.mouse_middle = win:mouse'middle' or false
	self.mouse_x1 = win:mouse'x1' or false --mouse aux button 1
	self.mouse_x2 = win:mouse'x2' or false --mouse aux button 2

	local function setcontext()
		self.frame_clock = ui:clock()
		self.bitmap = win:bitmap()
		self.cr = self.bitmap:cairo()
	end

	local function setmouse(mx, my)
		setcontext()
		self.mouse_x = mx
		self.mouse_y = my
	end

	if win:frame() == 'none' then

		win:on({'hittest', self}, function(win, mx, my, where)
			setmouse(mx, my)
			self.ui:_window_mousemove(self, mx, my)
			local hw = self.ui.hot_widget
			if hw and hw ~= self.view then
				return false --cancel test
			end
			return self:fire('hittest', mx, my, where)
		end)

	else

		win:on({'mousemove', self}, function(win, mx, my)
			setmouse(mx, my)
			self.ui:_window_mousemove(self, mx, my)
		end)

	end

	win:on({'mouseenter', self}, function(win, mx, my)
		setmouse(mx, my)
		self.ui:_window_mouseenter(self, mx, my)
	end)

	win:on({'mouseleave', self}, function(win)
		setmouse(false, false)
		self.ui:_window_mouseleave(self)
	end)

	win:on({'mousedown', self}, function(win, button, mx, my, click_count)
		local moved = self.mouse_x ~= mx or self.mouse_y ~= my
		setmouse(mx, my)
		if moved then
			self.ui:_window_mousemove(self, mx, my)
		end
		self['mouse_'..button] = true
		self.ui:_window_mousedown(self, button, mx, my, click_count)
	end)

	win:on({'click', self}, function(win, button, count, mx, my)
		return self.ui:_window_click(self, button, count, mx, my)
	end)

	win:on({'mouseup', self}, function(win, button, mx, my, click_count)
		local moved = self.mouse_x ~= mx or self.mouse_y ~= my
		setmouse(mx, my)
		if moved then
			self.ui:_window_mousemove(self, mx, my)
		end
		self['mouse_'..button] = false
		self.ui:_window_mouseup(self, button, mx, my, click_count)
	end)

	win:on({'mousewheel', self}, function(win, delta, mx, my, pdelta)
		local moved = self.mouse_x ~= mx or self.mouse_y ~= my
		setmouse(mx, my)
		if moved then
			self.ui:_window_mousemove(self, mx, my)
		end
		self.ui:_window_mousewheel(self, delta, mx, my, pdelta)
	end)

	win:on({'keydown', self}, function(win, key)
		setcontext()
		self:_keydown(key)
	end)

	win:on({'keyup', self}, function(win, key)
		setcontext()
		self:_keyup(key)
	end)

	win:on({'keypress', self}, function(win, key)
		setcontext()
		self:_keypress(key)
	end)

	win:on({'keychar', self}, function(win, s)
		setcontext()
		self:_keychar(s)
	end)

	win:on({'repaint', self}, function(win)
		setcontext()
		if self.mouse_x then
			self.ui:_window_mousemove(self, self.mouse_x, self.mouse_y)
		end
		self:draw(self.cr)
	end)

	win:on({'client_rect_changed', self}, function(win, cx, cy, cw, ch)
		if not cx then return end --hidden or minimized
		setcontext()
		self.view.w = cw
		self.view.h = ch
		self:fire('client_rect_changed', cx, cy, cw, ch)
		self:invalidate()
	end)

	function win.closing(win)
		local reason = self._close_reason
		self._close_reason = nil
		return self:closing(reason)
	end

	win:on({'closed', self}, function(win)
		self:fire('closed')
		self:free()
	end)

	win:on({'changed', self}, function(win, _, state)
		self:settag(':active', state.active)
		self:settag(':fullscreen', state.fullscreen)
	end)

	--create `window_*` events in ui (needed for ui_popup)
	self:on('event', function(self, event, ...)
		if event == 'mousemove' then return end
		if not self.ui then return end --window was closed
		self.ui:fire('window_'..event, self, ...)
	end)

	self.view = self:create_view()

	if show_it then
		self.visible = true
	end
end

function window:create_view()
	return self.view_class(self.ui, {
		w = self.cw, h = self.ch,
		parent = self,
	}, self.view)
end

function window:before_free()
	self.native_window:off{nil, self}
	self.native_window.ui_window = nil
	self.view:free()
	self.view = false
	if self.own_native_window then
		self.native_window:close()
	end
	self.native_window = false
	self.ui.windows[self] = nil
end

--move frameless window by dragging it

window._move_layer = false

function window:get_move_layer()
	return self._move_layer
end

function window:set_move_layer(layer)
	layer = layer or false
	assert(not layer or layer.window == self)
	if self._move_layer == layer then return end
	if self._move_layer then
		layer.mousedown_activate = false
		layer.start_drag = nil --reset to default
		layer.drag = nil --reset to default
	end
	self._move_layer = layer
	if layer then
		layer.mousedown_activate = true
		layer.focusable = false
		function layer:start_drag()
			return self
		end
		function layer:drag(dx, dy)
			local cx, cy = self.window:client_rect()
			self.window:client_rect(cx + dx, cy + dy)
		end
	end
end

--parent/child interface

function window:get_parent()
	return self._parent
end

function window:set_parent(parent)
	error'NYI'
end

function window:to_parent(x, y)
	if self.parent then
		return self.view:to_other(self.parent.view, x, y)
	else
		return x, y
	end
end

function window:from_parent(x, y)
	if self.parent then
		return self.view:from_other(self.parent.view, x, y)
	else
		return x, y
	end
end

function window:from_window(x, y)
	return x, y
end

function window:to_window(x, y)
	return x, y
end

--geometry

function window:frame_rect(x, y, w, h)
	if self:isinstance() then
		if self.parent then
			if x or y or w or h then
				if x or y then
					if not (x and y) then
						local x0, y0 = self:frame_rect()
						x = x or x0
						y = y or y0
					end
					x, y = self.parent:to_screen(x, y)
				end
				self.native_window:frame_rect(x, y, w, h)
			else
				local x, y, w, h = self.native_window:frame_rect()
				x, y = self.parent:from_screen(x, y)
				return x, y, w, h
			end
		else
			return self.native_window:frame_rect(x, y, w, h)
		end
	elseif x or y or w or h then
		if x then self._x = x end
		if y then self._y = y end
		if w then self._w = w end
		if h then self._h = h end
	else
		return self._x, self._y, self._w, self._h
	end
end

function window:client_to_frame(cx1, cy1)
	local x, y = self.native_window:frame_rect()
	local cx, cy = self.native_window:client_rect()
	return
		cx1 + (cx - x),
		cy1 + (cy - y)
end

function window:frame_to_client(x1, y1)
	local x, y = self.native_window:frame_rect()
	local cx, cy = self.native_window:client_rect()
	return
		x1 - (cx - x),
		y1 - (cy - y)
end

function window:client_rect(cx, cy, cw, ch)
	if self:isinstance() then
		if self.parent then
			if cx or cy or cw or ch then
				if cx or cy then
					if not (cx and cy) then
						local cx0, cy0 = self:client_rect()
						cx = cx or cx0
						cy = cy or cy0
					end
					cx, cy = self.parent:to_screen(cx, cy)
					self:client_rect(cx, cy, cw, ch)
				end
				self.native_window:client_rect(cx, cy, cw, ch)
			else
				local cx, cy, cw, ch = self.native_window:client_rect()
				cx, cy = self.parent:from_screen(cx, cy)
				return cx, cy, cw, ch
			end
		else
			return self.native_window:client_rect(cx, cy, cw, ch)
		end
	elseif cx or cy or cw or ch then
		if cx then self._cx = cx end
		if cy then self._cy = cy end
		if cw then self._cw = cw end
		if ch then self._ch = ch end
	else
		return self._cx, self._cy, self._cw, self._ch
	end
end

function window:get_x() return (select(1, self:frame_rect())) end
function window:get_y() return (select(2, self:frame_rect())) end
function window:get_w() return (select(3, self:frame_rect())) end
function window:get_h() return (select(4, self:frame_rect())) end
function window:set_x(x) self:frame_rect(x, nil, nil, nil) end
function window:set_y(y) self:frame_rect(nil, y, nil, nil) end
function window:set_w(w) self:frame_rect(nil, nil, w, nil) end
function window:set_h(h) self:frame_rect(nil, nil, nil, h) end

function window:get_cx() return (select(1, self:client_rect())) end
function window:get_cy() return (select(2, self:client_rect())) end
function window:get_cw() return (select(3, self:client_rect())) end
function window:get_ch() return (select(4, self:client_rect())) end
function window:set_cx(cx) self:client_rect(cx, nil, nil, nil) end
function window:set_cy(cy) self:client_rect(nil, cy, nil, nil) end
function window:set_cw(cw) self:client_rect(nil, nil, cw, nil) end
function window:set_ch(ch) self:client_rect(nil, nil, nil, ch) end

--layer interface

function window:add_layer(layer, index)
	if layer.iswindow_view then
		layer._parent = self
		layer.window = self
		return
	end
	self.view:add_layer(layer, index)
end

function window:remove_layer(layer)
	layer._parent = false
	layer.window = false
end

local mt = cairo.matrix()
function window:abs_matrix()
	return mt:reset()
end

--native window API forwarding

--r/w and r/o properties which map uniformly to the native API
local props = {
	--r/w properties
	autoquit=1, visible=1, fullscreen=1, enabled=1, edgesnapping=1,
	topmost=1, title=1,
	--r/o properties
	dead=0,
	closeable=0, activable=0, minimizable=0, maximizable=0, resizeable=0,
	fullscreenable=0, frame=0, transparent=0, corner_radius=0, sticky=0,
}
for prop, writable in pairs(props) do
	local priv = '_'..prop
	window['get_'..prop] = function(self)
		if self:isinstance() then
			local nwin = self.native_window
			return nwin[prop](nwin)
		else
			return self[priv]
		end
	end
	window['set_'..prop] = function(self, value)
		if self:isinstance() then
			assert(writable == 1, 'read-only property')
			local nwin = self.native_window
			nwin[prop](nwin, value)
		else
			self[priv] = value
		end
	end
end

--methods
function window:closing(reason) end --stub
function window:close(reason)
	--closing asynchronously so that we don't destroy the window inside an event.
	self.ui:runafter(0, function()
		self._close_reason = reason
		self.native_window:close()
	end)
end
function window:show()        self.native_window:show() end
function window:hide()        self.native_window:hide() end
function window:activate()    self.native_window:activate() end
function window:minimize()    self.native_window:minimize() end
function window:maximize()    self.native_window:maximize() end
function window:restore()     self.native_window:restore() end
function window:shownormal()  self.native_window:shownormal() end
function window:raise(rel)    self.native_window:raise(rel) end
function window:lower(rel)    self.native_window:lower(rel) end
function window:to_screen(x, y)   return self.native_window:to_screen(x, y) end
function window:from_screen(x, y) return self.native_window:to_client(x, y) end

--runtime state
function window:get_active()      return self.native_window:active() end
function window:get_isminimized() return self.native_window:isminimized() end
function window:get_ismaximized() return self.native_window:ismaximized() end
function window:get_display()     return self.native_window:display() end

function window:get_dead()
	return not self.native_window or self.native_window:dead()
end

function window:get_min_cw() return (select(1, self.native_window:minsize())) end
function window:get_min_ch() return (select(2, self.native_window:minsize())) end
function window:get_max_cw() return (select(1, self.native_window:maxsize())) end
function window:get_max_ch() return (select(2, self.native_window:maxsize())) end
function window:set_min_cw(cw) self.native_window:minsize(cw, nil) end
function window:set_min_ch(ch) self.native_window:minsize(nil, ch) end
function window:set_max_cw(cw) self.native_window:maxsize(cw, nil) end
function window:set_max_ch(ch) self.native_window:maxsize(nil, ch) end

window:instance_only'min_cw'
window:instance_only'min_ch'
window:instance_only'max_cw'
window:instance_only'max_ch'

function window:_settooltip(text)
	return self.native_window:tooltip(text)
end

--element query interface

function window:find(sel)
	local sel = ui:selector(sel):filter(function(elem)
		return elem.window == self
	end)
	return self.ui:find(sel)
end

function window:each(sel, f)
	return self:find(sel):each(f)
end

function window:mouse_pos() --window interface
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

function window:hit_test(x, y, reason)
	return self.view:hit_test(x, y, reason)
end

function window:get_cursor()
	return (self.native_window:cursor())
end

function window:set_cursor(cursor)
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
	if widget and widget.enabled then
		widget:_mouseenter(mx, my, area) --hot widget not changed yet
		window.cursor = widget:getcursor(area)
		self.hot_widget = widget
		self.hot_area = area
	else
		self.hot_widget = false
		self.hot_area = false
		window.cursor = nil
	end
end

function ui:accept_drop(drag_widget, drop_widget, mx, my, area)
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
		if hit_widget and hit_widget.enabled then
			hit_widget:_mousemove(mx, my, hit_area)
		end
	end

	if self.drag_widget then
		local widget, area = window:hit_test(mx, my, 'drop')
		if widget then
			if not self:accept_drop(self.drag_widget, widget, mx, my, area) then
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
	if not widget.draggable then return end --widget not draggable
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

	if self.drag_button == button then
		if self.drag_widget then
			if self.drop_widget then
				self.drop_widget:_drop(self.drag_widget, mx, my, self.drop_area)
				self.drag_widget:settag(':dropping', false)
			end
			self.drag_widget:_ended_dragging()
			self.drag_start_widget:_end_drag()
			for _,elem in ipairs(self.elements) do
				if elem.islayer and elem.tags[':drop_target'] then
					elem:_set_drop_target(false)
				end
			end
		end
		self:_reset_drag_state()
	end

	if self.active_widget then
		self.active_widget:_mouseup(button, mx, my)
	elseif self.hot_widget then
		self.hot_widget:_mouseup(button, mx, my, self.hot_area)
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

function window:first_focusable_widget()
	return self.view:first_focusable_widget()
end

function window:next_focusable_widget(forward)
	if self.focused_widget then
		return self.focused_widget:next_focusable_widget(forward)
	else
		return self:first_focusable_widget()
	end
end

function window:_keydown(key)
	local ret
	if self.focused_widget then
		ret = self.focused_widget:fire('keydown', key)
	end
	if ret == nil then
		self:fire('keydown', key)
	end
end

function window:_keyup(key)
	local ret
	if self.focused_widget then
		ret = self.focused_widget:fire('keyup', key)
	end
	if ret == nil then
		self:fire('keyup', key)
	end
end

function window:_keypress(key)
	local ret
	if self.focused_widget then
		ret = self.focused_widget:fire('keypress', key)
	end
	if ret == nil then
		ret = self:fire('keypress', key)
		if ret == nil and key == 'tab' then
			local next_widget = self:next_focusable_widget(not self.ui:key'shift')
			if next_widget then
				next_widget:focus(true)
			end
		end
	end
end

function window:_keychar(s)
	local ret
	if self.focused_widget then
		ret = self.focused_widget:fire('keychar', s)
	end
	if ret == nil then
		self:fire('keychar', ret)
	end
end

--rendering

function window:after_draw(cr)
	self._invalid = false
	self.cr:save()
	self.cr:new_path()
	self.view:draw(cr)
	self.cr:restore()
end

function window:invalidate() --element interface; window intf.
	if self._invalid then return end
	self._invalid = true
	self.native_window:invalidate()
end

--drawing helpers ------------------------------------------------------------

function ui:_rgba(s)
	local r, g, b, a = color.parse(s, 'rgb')
	self:check(r, 'invalid color "%s"', s)
	return r and {r, g, b, a or 1}
end
ui:memoize'_rgba'

function ui:rgba(c)
	if type(c) == 'string' then
		c = self:_rgba(c)
	end
	if not c then
		return 0, 0, 0, 0
	end
	return c[1], c[2], c[3], c[4] or 1
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
		local libjpeg = require'libjpeg'
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

--fonts & text ---------------------------------------------------------------

function ui:add_font_file(...) return self.tr:add_font_file(...) end
function ui:add_mem_font(...) return self.tr:add_mem_font(...) end

function ui:after_init()
	self.tr = tr()
	push(self.tr.rs.font_db.searchers,
		function(font_db, name, weight, slant)
			local gfonts = require'gfonts'
			local file = gfonts.font_file(name, weight, slant, true)
			return file and self:add_font_file(file, name, weight, slant)
		end)
	--mgit clone fonts-awesome
	self:add_font_file('media/fonts/fa-regular-400.ttf', 'Font Awesome')
	self:add_font_file('media/fonts/fa-solid-900.ttf', 'Font Awesome Bold')
	self:add_font_file('media/fonts/fa-brands-400.ttf', 'Font Awesome Brands')
	--mgit clone fonts-material-icons
	self:add_font_file('media/fonts/MaterialIcons-Regular.ttf', 'Material Icons')
	--mgit clone fonts-ionicons
	self:add_font_file('media/fonts/ionicons.ttf', 'Ionicons')
end

function ui:before_free()
	self.tr:free()
	self.tr = false
end

--layers ---------------------------------------------------------------------

local layer = element:subclass'layer'
ui.layer = layer

layer.visible = true
layer._enabled = true
layer.activable = true --can be clicked and set as hot
layer.vscrollable = false --enable mouse wheel when hot and not focused
layer.hscrollable = false --enable mouse horiz. wheel when hot and not focused
layer.scrollable = false --can be hit for vscroll or hscroll
layer.focusable = false --can be focused
layer.draggable = true --can be dragged (still needs to respond to start_drag())
layer.mousedown_activate = false --activate/deactivate on left mouse down/up

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

ui:style('layer :disabled', {
	text_color = '#666',
})

layer.cursor = false  --false or cursor name from nw

layer.drag_threshold = 0 --moving distance before start dragging
layer.max_click_chain = 1 --2 for getting doubleclick events etc.
layer.hover_delay = 1 --TODO: hover event delay

function layer:override_init(inherited, ui, t)
	if ui.islayer or ui.iswindow then --ui is actually the parent
		t.parent = ui
		ui = ui.ui
	end
	if t.parent then
		ui = t.parent.ui
	end
	return inherited(self, ui, t)
end

layer:init_ignore{parent=1, layer_index=1, enabled=1, layers=1, class=1}

function layer:after_init(ui, t)
	--setting parent after _enabled updates the `disabled` tag only once!
	--setting layer_index before parent inserts the layer at its index directly.
	self._enabled = t.enabled
	self.layer_index = t.layer_index
	self.parent = t.parent

	--create and/or attach layers
	if t.layers then
		self.layers = {}
		for i,layer in ipairs(t.layers) do
			if not layer.islayer then
				layer = layer.class(self.ui, self[layer.class], layer)
			end
			assert(layer.islayer)
			layer.parent = self
		end
	end
end

function layer:before_free()
	if self.hot then
		self.ui.hot_widget = false
		self.ui.hot_area = false
	end
	if self.active then
		self.ui.active_widget = false
	end
	self:_free_layers()
	if self.parent then
		self.parent:remove_layer(self, true)
	end
end

--layer relative geometry & matrix

function ui.expand:scale(scale)
	self.scale_x = scale
	self.scale_y = scale
end

function layer:set_scale(scale) self:expand_attr('scale', scale) end

layer.x = 0
layer.y = 0
layer.w = 0
layer.h = 0
layer.rotation = 0
layer.rotation_cx = 0
layer.rotation_cy = 0
layer.scale_x = 1
layer.scale_y = 1
layer.scale_cx = 0
layer.scale_cy = 0

local mt = cairo.matrix()
function layer:rel_matrix() --box matrix relative to parent's content space
	return mt:reset()
		:translate(self.x, self.y)
		:rotate_around(self.rotation_cx, self.rotation_cy,
			math.rad(self.rotation))
		:scale_around(self.scale_cx, self.scale_cy, self.scale_x, self.scale_y)
end

function layer:abs_matrix() --box matrix in window space
	return self.pos_parent:abs_matrix():transform(self:rel_matrix())
end

local mt = cairo.matrix()
function layer:cr_abs_matrix(cr) --box matrix in cr's current space
	if self.pos_parent ~= self.parent then
		return self:abs_matrix()
	else
		return cr:matrix(nil, mt):transform(self:rel_matrix())
	end
end

--convert point from own box space to parent content space
function layer:from_box_to_parent(x, y)
	if self.pos_parent ~= self.parent then
		return self.parent:from_window(self:abs_matrix():point(x, y))
	else
		return self:rel_matrix():point(x, y)
	end
end

--convert point from parent content space to own box space
function layer:from_parent_to_box(x, y)
	if self.pos_parent ~= self.parent then
		return self:abs_matrix():invert():point(self.parent:to_window(x, y))
	else
		return self:rel_matrix():invert():point(x, y)
	end
end

--convert point from own content space to parent content space
function layer:to_parent(x, y)
	if self.pos_parent ~= self.parent then
		return self.parent:from_window(
			self:abs_matrix():translate(self:padding_pos()):point(x, y))
	else
		return self:rel_matrix():translate(self:padding_pos()):point(x, y)
	end
end

--convert point from parent content space to own content space
function layer:from_parent(x, y)
	if self.pos_parent ~= self.parent then
		return self:abs_matrix():translate(self:padding_pos()):invert()
			:point(self.parent:to_window(x, y))
	else
		return self:rel_matrix():translate(self:padding_pos()):invert()
			:point(x, y)
	end
end

function layer:to_window(x, y) --parent & child interface
	return self.parent:to_window(self:to_parent(x, y))
end

function layer:from_window(x, y) --parent & child interface
	return self:from_parent(self.parent:from_window(x, y))
end

function layer:to_screen(x, y)
	local x, y = self:to_window(x, y)
	return self.window:to_screen(x, y)
end

function layer:from_screen(x, y)
	local x, y = self.window:from_screen(x, y)
	return self:from_window(x, y)
end

--convert point from own content space to other's content space
function layer:to_other(widget, x, y)
	if widget.window == self.window then
		return widget:from_window(self:to_window(x, y))
	else
		return widget:from_screen(self:to_screen(x, y))
	end
end

--convert point from other's content space to own content space
function layer:from_other(widget, x, y)
	return widget:to_other(self, x, y)
end

function layer:mouse_pos()
	if not self.window.mouse_x then
		return false, false
	end
	return self:from_window(self.window:mouse_pos())
end

function layer:get_mouse_x() return (select(1, self:mouse_pos())) end
function layer:get_mouse_y() return (select(2, self:mouse_pos())) end

function layer:get_mouse()
	return self.window.mouse
end

function layer:get_parent() --child interface
	return self._parent
end

function layer:set_parent(parent)
	if parent then
		parent:add_layer(self, self._layer_index)
	elseif self._parent then
		self._parent:remove_layer(self)
	end
end

function layer:get_pos_parent() --child interface
	return self._pos_parent or self._parent
end

function layer:set_pos_parent(parent)
	if parent and parent.iswindow then
		parent = parent.view
	end
	if parent == self.parent then
		parent = nil
	end
	self._pos_parent = parent
end

function layer:to_back()
	self.layer_index = 1
end

function layer:to_front()
	self.layer_index = 1/0
end

function layer:get_layer_index()
	if self.parent then
		return indexof(self, self.parent.layers)
	else
		return self._layer_index
	end
end

function layer:move_layer(layer, index)
	local new_index = clamp(index, 1, #self.layers)
	local old_index = indexof(layer, self.layers)
	if old_index == new_index then return end
	table.remove(self.layers, old_index)
	table.insert(self.layers, new_index, layer)
	self:invalidate()
end

function layer:set_layer_index(index)
	if self.parent then
		self.parent:move_layer(self, index)
	else
		self._layer_index = index
	end
end

function layer:each_child(func)
	if not self.layers then return end
	for _,layer in ipairs(self.layers) do
		local ret = layer:each_child(func)
		if ret ~= nil then return ret end
		local ret = func(layer)
		if ret ~= nil then return ret end
	end
end

function layer:children()
	return coroutine.wrap(function()
		self:each_child(coroutine.yield)
	end)
end

function layer:add_layer(layer, index) --parent interface
	if layer._parent == self then return end
	if layer._parent then
		layer._parent:remove_layer(layer)
	end
	self.layers = self.layers or {}
	index = clamp(index or 1/0, 1, #self.layers + 1)
	push(self.layers, index, layer)
	layer._parent = self
	layer.window = self.window
	self:fire('layer_added', layer, index)
	layer:_update_enabled(layer.enabled)
end

function layer:remove_layer(layer, freeing) --parent interface
	assert(layer._parent == self)
	self:off({nil, layer})
	popval(self.layers, layer)
	if not freeing then
		self:fire('layer_removed', layer)
	end
	layer._parent = false
	layer.window = false
	layer:_update_enabled(layer.enabled)
end

function layer:_free_layers()
	if not self.layers then return end
	while #self.layers > 0 do
		self.layers[#self.layers]:free()
	end
end

--mouse event handling

function layer:getcursor(area)
	return self['cursor_'..area] or self.cursor
end

function layer:_mousemove(mx, my, area)
	local mx, my = self:from_window(mx, my)
	self:fire('mousemove', mx, my, area)
	self.ui:_widget_mousemove(self, mx, my, area)
end

function layer:_mouseenter(mx, my, area)
	local mx, my = self:from_window(mx, my)
	self:settag(':hot', true)
	if area then
		self:settag(':hot_'..area, true)
	end
	self:fire('mouseenter', mx, my, area)
	self.window:_settooltip(self.tooltip)
	self:invalidate()
end

function layer:_mouseleave()
	self.window:_settooltip(false)
	self:fire'mouseleave'
	local area = self.ui.hot_area
	self:settag(':hot', false)
	if area then
		self:settag(':hot_'..area, false)
	end
	self:invalidate()
end

function layer:_mousedown(button, mx, my, area)
	local mx, my = self:from_window(mx, my)
	local event = button == 'left' and 'mousedown' or button..'mousedown'
	self:fire(event, mx, my, area)
	if self.mousedown_activate then
		self.active = true
	end
	self.ui:_widget_mousedown(self, button, mx, my, area)
end

function layer:_mouseup(button, mx, my, area)
	local mx, my = self:from_window(mx, my)
	local event = button == 'left' and 'mouseup' or button..'mouseup'
	self:fire(event, mx, my, area)
	if self.ui and self.active and self.mousedown_activate then
		self.active = false
	end
end

function layer:_click(button, count, mx, my, area)
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

function layer:_mousewheel(delta, mx, my, area, pdelta)
	self:fire('mousewheel', delta, mx, my, area, pdelta)
end

--called on a potential drop target widget to accept the dragged widget.
function layer:_accept_drag_widget(widget, mx, my, area)
	if mx then
		mx, my = self:from_window(mx, my)
	end
	return self:accept_drag_widget(widget, mx, my, area)
end

--return true to accept a dragged widget. if mx/my/area are nil
--then return true if there's _any_ area which would accept the widget.
function layer:accept_drag_widget(widget, mx, my, area) end

--called on the dragged widget to accept a potential drop target widget.
function layer:accept_drop_widget(widget, area) return true; end

--called on the dragged widget once upon entering a new drop target.
function layer:_enter_drop_target(widget, area)
	self:settag(':dropping', true)
	self:fire('enter_drop_target', widget, area)
	self:invalidate()
end

--called on the dragged widget once upon leaving a drop target.
function layer:_leave_drop_target(widget)
	self:fire('leave_drop_target', widget)
	self:settag(':dropping', false)
	self:invalidate()
end

--called on the dragged widget when dragging starts.
function layer:_started_dragging()
	self.dragging = true
	self:settag(':dragging', true)
	self:fire'started_dragging'
	self:invalidate()
end

--called on the dragged widget when dragging ends.
function layer:_ended_dragging()
	self.dragging = false
	self:settag(':dragging', false)
	self:fire'ended_dragging'
	self:invalidate()
end

function layer:_set_drop_target(set)
	self:settag(':drop_target', set)
end

--called on drag_start_widget to initiate a drag operation.
function layer:_start_drag(button, mx, my, area)
	local widget, dx, dy = self:start_drag(button, mx, my, area)
	if widget then
		self:settag(':drag_source', true)
		for i,elem in ipairs(self.ui.elements) do
			if elem.islayer and self.ui:accept_drop(widget, elem) then
				elem:_set_drop_target(true)
			end
		end
		widget:_started_dragging()
	end
	return widget, dx, dy
end

--stub: return a widget to drag (self works too).
function layer:start_drag(button, mx, my, area) end

function layer:_end_drag() --called on the drag_start_widget
	self:settag(':drag_source', false)
	self:fire('end_drag', self.ui.drag_widget)
	self:invalidate()
end

function layer:_drop(widget, mx, my, area) --called on the drop target
	local mx, my = self:from_window(mx, my)
	self:fire('drop', widget, mx, my, area)
	self:invalidate()
end

function layer:_drag(mx, my) --called on the dragged widget
	local pmx, pmy, dmx, dmy
	pmx, pmy = self.parent:from_window(mx, my)
	dmx, dmy = self:to_parent(self.ui.drag_mx, self.ui.drag_my)
	self:fire('drag', pmx - dmx, pmy - dmy)
	self:invalidate()
end

--default behavior: drag the widget from the initial grabbing point.
function layer:drag(dx, dy)
	self.x = self.x + dx
	self.y = self.y + dy
	self:invalidate()
end

--window property

function layer:get_window()
	return self._window
end

function layer:set_window(window)
	if self._window then
		self._window:off({nil, self})
	end
	self._window = window
	if self.layers then
		for i,layer in ipairs(self.layers) do
			layer.window = window
		end
	end
end

--enabled property/tag

function layer:get_enabled()
	return self._enabled and (not self.parent or self.parent.enabled)
end

function layer:_update_enabled(enabled)
	self:settag(':disabled', not enabled)
	if self.layers then
		for _,layer in ipairs(self.layers) do
			layer:_update_enabled(enabled)
		end
	end
end

function layer:set_enabled(enabled)
	enabled = enabled and true or false
	if self._enabled == enabled then return end
	self._enabled = enabled
	if self:isinstance() then
		self:_update_enabled(enabled)
	end
end

--tooltip property

layer._tooltip = false --false or text

function layer:get_tooltip()
	return self._tooltip
end

function layer:set_tooltip(text)
	self._tooltip = text
	if self.window and self.hot then --change tooltip text on the fly
		self.window:_settooltip(text)
	end
end

--focusing and keyboard event handling

function layer:canfocus()
	return self.visible and self.focusable and self.enabled
end

function window:unfocus()
	local fw = self.focused_widget
	if not fw then return end
	fw:fire'lostfocus'
	fw:settag(':focused', false)
	self:fire('lostfocus', fw)
	self.ui:fire('lostfocus', fw)
	fw:invalidate()
	self.focused_widget = false
end

function layer:unfocus()
	return self.window:unfocus()
end

function layer:focus(focus_children)
	if self:canfocus() then
		if not self.focused then
			self.window:unfocus()
			self:fire'gotfocus'
			self:settag(':focused', true)
			self.window.focused_widget = self
			self.window:fire('widget_gotfocus', self)
			self.ui:fire('gotfocus', self)
			self:invalidate()
		end
		return true
	elseif focus_children and self.visible and self.enabled then
		--focus the first focusable child
		local layer = self:first_focusable_widget()
		if layer and layer:focus(focus_children) then
			return true
		end
	end
end

function layer:get_focused()
	return self.window and self.window.focused_widget == self
end

function layer:get_focused_widget()
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

layer.tabindex = 0
layer.tabgroup = 0
layer._taborder = 'vh' --simple vertical-first-horizontal-second tab order

function layer:get_taborder()
	return self:parent_value'_taborder'
end

function layer:focusable_widgets(t)
	t = t or {}
	if self.layers then
		for i,layer in ipairs(self.layers) do
			if layer:canfocus() then
				push(t, layer)
			else --add layers' focusable children recursively, depth-first
				layer:focusable_widgets(t)
			end
		end
	end
	table.sort(t, function(t1, t2)
		if t1.tabgroup == t2.tabgroup then
			if t1.tabindex == t2.tabindex then
				local ax1, ay1 = t1.parent:to_window(t1.x, t1.y)
				local bx1, by1 = t2.parent:to_window(t2.x, t2.y)
				if self.taborder == 'hv' then
					ax1, bx1, ay1, by1 = ay1, by1, ax1, bx1
				end
				if ax1 == bx1 then
					return ay1 < by1
				else
					return ax1 < bx1
				end
			else
				return t1.tabindex < t2.tabindex
			end
		else
			return t1.tabgroup < t2.tabgroup
		end
	end)
	return t
end

function layer:first_focusable_widget()
	if not self.layers then return end
	return self:focusable_widgets()[1]
end

function layer:next_focusable_widget(forward)
	if forward and self.nexttab then
		return self.nexttab
	elseif not forward and self.prevtab then
		return self.prevtab
	end
	local t = self.window.view:focusable_widgets()
	for i,layer in ipairs(t) do
		if layer == self then
			return t[i + (forward and 1 or -1)] or t[forward and 1 or #t]
		end
	end
end

--layers geometry, drawing and hit testing

function layer:layers_bounding_box(strict)
	local x, y, w, h = 0, 0, 0, 0
	if self.layers then
		for _,layer in ipairs(self.layers) do
			x, y, w, h = box2d.bounding_box(x, y, w, h,
				layer:bounding_box(strict))
		end
	end
	return x, y, w, h
end

function layer:draw_layers(cr) --called in content space
	if not self.layers then return end
	for i = 1, #self.layers do
		self.layers[i]:draw(cr)
	end
end

function layer:hit_test_layers(x, y, reason) --called in content space
	if not self.layers then return end
	for i = #self.layers, 1, -1 do
		local widget, area = self.layers[i]:hit_test(x, y, reason)
		if widget then
			return widget, area
		end
	end
end

--border geometry and drawing

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

function layer:set_border_color(s) self:expand_attr('border_color', s) end
function layer:set_border_width(s) self:expand_attr('border_width', s) end
function layer:set_corner_radius(s) self:expand_attr('corner_radius', s) end

layer.border_width = 0 --no border
layer.corner_radius = 0 --square
layer.border_color = '#0000'
layer.border_dash = false
-- border stroke positioning relative to box edge.
-- -1..1 goes from inside to outside of box edge.
layer.border_offset = -1
--draw rounded corners with a modified bezier for smoother line-to-arc
--transitions. kappa=1 uses circle arcs instead.
layer.corner_radius_kappa = 1.2

--border edge widths relative to box rect at %-offset in border width.
--offset is in -1..1 where -1=inner edge, 0=center, 1=outer edge.
--returned widths are positive when inside and negative when outside box rect.
function layer:_border_edge_widths(offset)
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

function layer:border_pos(offset)
	local w, h = self:_border_edge_widths(offset)
	return w, h
end

--border rect at %-offset in border width.
function layer:border_rect(offset, size_offset)
	local w1, h1, w2, h2 = self:_border_edge_widths(offset)
	local w = self.w - w2 - w1
	local h = self.h - h2 - h1
	return box2d.offset(size_offset or 0, w1, h1, w, h)
end

function layer:get_border_outer_x() return (select(1, self:border_rect(1))) end
function layer:get_border_outer_y() return (select(2, self:border_rect(1))) end
function layer:get_border_outer_w() return (select(3, self:border_rect(1))) end
function layer:get_border_outer_h() return (select(4, self:border_rect(1))) end

--corner radius at pixel offset from the stroke's center on one dimension.
local function offset_radius(r, o)
	return r > 0 and math.max(0, r + o) or 0
end

--border rect at %-offset in border width, plus radii of rounded corners.
function layer:border_round_rect(offset, size_offset)
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

function layer:border_line_to(cr, x, y, q) end --stub (used by tablist)

--trace the border contour path at offset.
--offset is in -1..1 where -1=inner edge, 0=center, 1=outer edge.
function layer:border_path(cr, offset, size_offset)
	local x1, y1, w, h, r1x, r1y, r2x, r2y, r3x, r3y, r4x, r4y, k =
		self:border_round_rect(offset, size_offset)
	local x2, y2 = x1 + w, y1 + h
	cr:move_to(x1, y1+r1y)
	local line = self.border_line_to
	qarc(cr, x1+r1x, y1+r1y, r1x, r1y, 1, 1, k) --tl
	line(self, cr, x2-r2x, y1, 1)
	qarc(cr, x2-r2x, y1+r2y, r2x, r2y, 2, 1, k) --tr
	line(self, cr, x2, y2-r3y, 2)
	qarc(cr, x2-r3x, y2-r3y, r3x, r3y, 3, 1, k) --br
	line(self, cr, x1+r4x, y2, 3)
	qarc(cr, x1+r4x, y2-r4y, r4x, r4y, 4, 1, k) --bl
	line(self, cr, x1, y1+r1y, 4)
	cr:close_path()
end

function layer:border_visible()
	return
		self.border_width_left ~= 0
		or self.border_width_top ~= 0
		or self.border_width_right ~= 0
		or self.border_width_bottom ~= 0
end

function layer:draw_border(cr)
	if not self:border_visible() then return end

	--seamless drawing when all side colors are the same.
	if self.border_color_left == self.border_color_top
		and self.border_color_left == self.border_color_right
		and self.border_color_left == self.border_color_bottom
	then
		cr:new_path()
		cr:rgba(self.ui:rgba(self.border_color_bottom))
		if self.border_width_left == self.border_width_top
			and self.border_width_left == self.border_width_right
			and self.border_width_left == self.border_width_bottom
		then --stroke-based method (doesn't require path offseting; supports dashing)
			self:border_path(cr, 0)
			cr:line_width(self.border_width_left)
			if self.border_dash then
				cr:dash{self.border_dash}
			end
			cr:stroke()
		else --fill-based method (requires path offsetting; supports patterns)
			cr:fill_rule'even_odd'
			self:border_path(cr, -1)
			self:border_path(cr, 1)
			cr:fill()
		end
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
		cr:rgba(self.ui:rgba(self.border_color_left))
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
		cr:rgba(self.ui:rgba(self.border_color_top))
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
		cr:rgba(self.ui:rgba(self.border_color_right))
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
		cr:rgba(self.ui:rgba(self.border_color_bottom))
		cr:fill()
	end
end

--background geometry and drawing

function ui.expand:background_scale(scale)
	self.background_scale_x = scale
	self.background_scale_y = scale
end

function layer:set_background_scale(scale)
	self:expand_attr('background_scale', scale)
end

layer.background_type = 'color' --false, 'color', 'gradient', 'radial_gradient', 'image'
layer.background_hittable = true
--all backgrounds
layer.background_x = 0
layer.background_y = 0
layer.background_rotation = 0
layer.background_rotation_cx = 0
layer.background_rotation_cy = 0
layer.background_scale = 1
layer.background_scale_cx = 0
layer.background_scale_cy = 0
--solid color backgrounds
layer.background_color = false --no background
--gradient backgrounds
layer.background_colors = false --{[offset1], color1, ...}
--linear gradient backgrounds
layer.background_x1 = 0
layer.background_y1 = 0
layer.background_x2 = 0
layer.background_y2 = 0
--radial gradient backgrounds
layer.background_cx1 = 0
layer.background_cy1 = 0
layer.background_r1 = 0
layer.background_cx2 = 0
layer.background_cy2 = 0
layer.background_r2 = 0
--image backgrounds
layer.background_image = false

layer.background_operator = 'over'
-- overlapping between background clipping edge and border stroke.
-- -1..1 goes from inside to outside of border edge.
layer.background_clip_border_offset = 1

function layer:background_visible()
	return (
		(self.background_type == 'color' and self.background_color)
		or ((self.background_type == 'gradient'
			or self.background_type == 'radial_gradient')
			and self.background_colors and #self.background_colors > 0)
		or (self.background_type == 'image' and self.background_image)
	) and true or false
end

function layer:background_rect(size_offset)
	return self:border_rect(self.background_clip_border_offset, size_offset)
end

function layer:background_round_rect(size_offset)
	return self:border_round_rect(self.background_clip_border_offset, size_offset)
end

function layer:background_path(cr, size_offset)
	self:border_path(cr, self.background_clip_border_offset, size_offset)
end

function layer:set_background_scale(scale)
	self.background_scale_x = scale
	self.background_scale_y = scale
end

local mt = cairo.matrix()
function layer:paint_background(cr)
	cr:operator(self.background_operator)
	local bg_type = self.background_type
	if bg_type == 'color' then
		cr:rgba(self.ui:rgba(self.background_color))
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

layer.shadow_x = 0
layer.shadow_y = 0
layer.shadow_color = '#000'
layer.shadow_blur = 0
layer._shadow_blur_passes = 2

function layer:shadow_visible()
	return self.shadow_blur > 0 or self.shadow_x ~= 0 or self.shadow_y ~= 0
end

function layer:shadow_rect(size)
	if self:border_visible() then
		return self:border_rect(1, size)
	else
		return self:background_rect(size)
	end
end

function layer:shadow_round_rect(size)
	if self:border_visible() then
		return self:border_round_rect(1, size)
	else
		return self:background_round_rect(size)
	end
end

function layer:shadow_path(cr, size)
	if self:border_visible() then
		self:border_path(cr, 1, size)
	else
		self:background_path(cr, size)
	end
end

function layer:shadow_valid_key(t)
	local x, y, w, h, r1x, r1y, r2x, r2y, r3x, r3y, r4x, r4y, k =
		self:shadow_round_rect(0)
	return t.shadow_blur == self.shadow_blur
		and t.x == x and t.y == y and t.w == w and t.h == h
		and t.r1x == r1x and t.r1y == r1y and t.r2x == r2x and t.r2y == r2y
		and t.r3x == r3x and t.r3y == r3y and t.r4x == r4x and t.r4y == r4y
		and t.k == k
end

function layer:shadow_store_key(t)
	t.shadow_blur = self.shadow_blur
	t.x, t.y, t.w, t.h, t.r1x, t.r1y,
		t.r2x, t.r2y, t.r3x, t.r3y, t.r4x, t.r4y, t.k =
			self:shadow_round_rect(0)
end

function layer:draw_shadow(cr)
	if not self:shadow_visible() then return end
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
				self:shadow_path(scr, 0)
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
	cr:rgba(self.ui:rgba(self.shadow_color))
	cr:mask(t.blurred_surface)
	cr:translate(-sx, -sy)
end

--text geometry and drawing

function ui.expand:font(font)
	local name, weight, slant, size = font_db:parse_font(font)
	if name then self.font_name = name end
	if weight then self.font_weight = weight end
	if slant then self.font_slant = slant end
	if size then self.text_size = size end
end

function layer:set_font(font) self:expand_attr('font', font) end

layer.text_align = 'center'
layer.text_valign = 'middle'
layer.text_operator = 'over'
layer.text = nil
layer.font = 'Open Sans,14'
layer.text_color = '#fff'
layer.line_spacing = 1
layer.paragraph_spacing = 2
layer.text_dir = 'auto' --auto, rtl, ltr
layer.nowrap = false

function layer:text_visible()
	return self.text and self.text ~= '' and true or false
end

function layer:sync_text()
	if not self:text_visible() then return end
	if not self._text_tree
		or (not self._text_valid and self.text ~= self._text_tree[1])
		or self.text_dir    ~= self._text_tree.text_dir
		or self.font_name   ~= self._text_tree.font_name
		or self.font_weight ~= self._text_tree.font_weight
		or self.font_slant  ~= self._text_tree.font_slant
		or self.text_size   ~= self._text_tree.font_size
		or self.nowrap      ~= self._text_tree.nowrap
	then
		self._text_tree = self._text_tree or {}
		self._text_tree[1]          = self.text
		self._text_tree.text_dir    = self.text_dir
		self._text_tree.font_name   = self.font_name
		self._text_tree.font_weight = self.font_weight
		self._text_tree.font_slant  = self.font_slant
		self._text_tree.font_size   = self.text_size
		self._text_tree.nowrap      = self.nowrap
		self._text_segments = self.ui.tr:shape(self._text_tree)
		self._text_w = false --force layout
	end
	local cw, ch = self:content_size()
	local ha = self.text_align
	local va = self.text_valign
	local ls = self.line_spacing
	local ps = self.paragraph_spacing
	if    cw ~= self._text_w
		or ch ~= self._text_h
		or ha ~= self._text_ha
		or va ~= self._text_va
		or ls ~= self._text_tree.line_spacing
		or ps ~= self._text_tree.paragraph_spacing
	then
		self._text_w  = cw
		self._text_h  = ch
		self._text_ha = ha
		self._text_va = va
		self._text_ls = ls
		self._text_tree.line_spacing = ls
		self._text_tree.paragraph_spacing = ps
		self._text_segments:layout(0, 0, cw, ch, ha, va)
	end
	return self._text_segments
end

function layer:draw_text(cr)
	if not self:sync_text() then return end
	self._text_tree.color    = self.text_color
	self._text_tree.operator = self.text_operator
	self._text_segments:paint(cr)
end

function layer:text_bounding_box()
	if not self:sync_text() then return 0, 0, 0, 0 end
	return self._text_segments:bounding_box()
end

--content-box geometry, drawing and hit testing

function ui.expand:padding(s)
	self.padding_left, self.padding_top, self.padding_right,
		self.padding_bottom = args4(s, tonumber)
end

function layer:set_padding(s) self:expand_attr('padding', s) end

layer.padding = 0

function layer:padding_pos() --in box space
	return
		self.padding_left,
		self.padding_top
end

function layer:padding_rect() --in box space
	return
		self.padding_left,
		self.padding_top,
		self.w - self.padding_left - self.padding_right,
		self.h - self.padding_top - self.padding_bottom
end

function layer:to_content(x, y) --box space coord in content space
	local px, py = self:padding_pos()
	return x - px, y - py
end

function layer:from_content(x, y) --content space coord in box space
	local px, py = self:padding_pos()
	return px + x, py + y
end

--layer drawing & hit testing

layer.opacity = 1
layer.clip_content = false --'padding'/true, 'background', false

function layer:draw_content(cr) --called in own content space
	self:draw_layers(cr)
	self:draw_text(cr)
end

function layer:hit_test_content(x, y, reason) --called in own content space
	return self:hit_test_layers(x, y, reason)
end

function layer:content_bounding_box(strict)
	local x, y, w, h = self:layers_bounding_box(strict)
	return box2d.bounding_box(x, y, w, h, self:text_bounding_box())
end

function layer:after_draw(cr) --called in parent's content space; child intf.
	if not self.visible or self.opacity == 0 then return end
	if self.opacity <= 0 then return end

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

	self:draw_shadow(cr)

	local clip = bg or cc
	if clip then
		cr:save()
		cr:new_path()
		self:background_path(cr) --'background' clipping is implicit in 'padding'
		cr:clip()
		if bg then
			self:paint_background(cr)
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
		self:draw_border(cr)
	end
	local cx, cy = self:padding_pos()
	cr:translate(cx, cy)
	self:draw_content(cr)
	cr:translate(-cx, -cy)
	if clip then
		cr:restore()
	end

	if cc then
		self:draw_border(cr)
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
function layer:hit_test(x, y, reason)

	if not self.visible or self.opacity == 0 then return end

	local self_allowed =
		   (reason == 'activate' and self.activable)
		or (reason == 'drop' and self.tags[':drop_target'])
		or (reason == 'vscroll' and (self.vscrollable or self.scrollable or self.focused))
		or (reason == 'hscroll' and (self.hscrollable or self.scrollable or self.focused))

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
		self:border_path(cr, 1)
		if cr:in_fill(x, y) then --inside border outer edge
			cr:new_path()
			self:border_path(cr, -1)
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
		self:background_path(cr)
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

function layer:bounding_box(strict) --child interface
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

function layer:get_frame_clock()
	return self.window.frame_clock
end

function layer:invalidate()
	if self.window then
		self.window:invalidate()
	end
end

--the `hot` property which is managed by the window

function layer:get_hot()
	return self.ui.hot_widget == self
end

--the `active` property and tag which the widget must set manually

function layer:get_active()
	return self.ui.active_widget == self
end

function layer:set_active(active)
	if self.active == active then return end
	local active_widget = self.ui.active_widget
	if active_widget then
		active_widget:settag(':active', false)
		self.ui.active_widget = false
		active_widget:fire'deactivated'
		active_widget.window:fire('widget_deactivated', active_widget)
		active_widget.ui:fire('deactivated', active_widget)
	end
	if active then
		self.ui.active_widget = self
		self:settag(':active', true)
		self:fire'activated'
		self.window:fire('widget_activated', self)
		self.ui:fire('activated', self)
		self:focus()
	end
	self:invalidate()
end

function layer:activate()
	if not self.active then
		self.active = true
		self.active = false
	end
end

--utils in content space to use from draw_content() and hit_test_content()

function layer:content_size()
	return select(3, self:padding_rect())
end

function layer:content_rect() --in content space
	return 0, 0, select(3, self:padding_rect())
end
function layer:content_size()
	return select(3, self:padding_rect())
end
function layer:get_cw() return (select(3, self:padding_rect())) end
function layer:get_ch() return (select(4, self:padding_rect())) end

function layer:set_cw(cw) self.w = cw + (self.w - self.cw) end
function layer:set_ch(ch) self.h = ch + (self.h - self.ch) end

function layer:get_x2() return self.x + self.w end
function layer:get_y2() return self.y + self.h end

function layer:set_x2(x2) self.w = x2 - self.x end
function layer:set_y2(y2) self.h = y2 - self.y end

function layer:get_cx() return self.x + self.w / 2 end
function layer:get_cy() return self.y + self.h / 2 end

function layer:set_cx(cx) self.x = cx - self.w / 2 end
function layer:set_cy(cy) self.y = cy - self.h / 2 end

function layer:rect() return self.x, self.y, self.w, self.h end

--top layer ------------------------------------------------------------------

local view = layer:subclass'window_view'
window.view_class = view

--screen-wiping options that work with transparent windows
view.background_color = '#040404'
view.background_operator = 'source'

--parent layer interface

view.to_window = view.to_parent
view.from_window = view.from_parent

--widgets autoload -----------------------------------------------------------

local autoload = {
	scrollbar    = 'ui_scrollbox',
	scrollbox    = 'ui_scrollbox',
	button       = 'ui_button',
	checkbox     = 'ui_button',
	radiobutton  = 'ui_button',
	choicebutton = 'ui_button',
	slider       = 'ui_slider',
	toggle       = 'ui_slider',
	editbox      = 'ui_editbox',
	tab          = 'ui_tablist',
	tablist      = 'ui_tablist',
	menuitem     = 'ui_menu',
	menu         = 'ui_menu',
	image        = 'ui_image',
	grid         = 'ui_grid',
	popup        = 'ui_popup',
	dropdown     = 'ui_dropdown',
	colorpicker  = 'ui_colorpicker',
}

for widget, submodule in pairs(autoload) do
	ui['get_'..widget] = function()
		require(submodule)
		return ui[widget]
	end
end

return ui
