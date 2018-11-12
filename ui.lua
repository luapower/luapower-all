
--Extensible UI toolkit in Lua.
--Written by Cosmin Apreutesei. Public Domain.

if not ... then DEMO=true; require'ui_demo'; return end

local oo = require'oo'
local events = require'events'
local glue = require'glue'
local box2d = require'box2d'
local easing = require'easing'
local color = require'color'
local boxblur = require'boxblur'
local amoeba = require'amoeba'
local time = require'time'
local cairo = require'cairo'
local tr = require'tr'

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

local function popval(t, v)
	local i = indexof(v, t)
	return i and pop(t, i)
end

local nilkey = {}
local function encode_nil(x) return x == nil and nilkey or x end
local function decode_nil(x) if x == nilkey then return nil end; return x; end

--object system --------------------------------------------------------------

local object = oo.object()

object:inherit(events)

function object:before_init()
	--Speed up class field lookup by having the final class statically inherit
	--all its fields. With this change, runtime patching of non-final classes
	--after the first instantiation doesn't have an effect anymore (it will
	--require calling inherit() manually on all those final classes).
	--That's ok, you shouldn't patch classes anyway.
	if not rawget(self.super, 'isfinalclass') then
		self.super:inherit()
		self.super.isfinalclass = true
	end
	--Speed up virtual property lookup without detaching/fattening the instance.
	--with this change, adding or overriding getters and setters through the
	--instance is not allowed anymore, that would patch the class instead!
	--TODO: remove this limitation somehow!
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

--install event handlers in object which forward events to self.
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

--create a r/w property which reads/writes to a "private field".
function object:stored_property(prop, priv)
	priv = priv or '_'..prop
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
	self:override('set_'..prop, function(self, inherited, val)
		val = val or false
		local old_val = self[prop] or false
		if val ~= old_val then
			inherited(self, val, old_val)
			return true --useful when overriding the setter further
		end
	end)
end

--change a property so that its setter is only called when the value changes
--and also '<prop>_changed' event is fired.
function object:track_changes(prop)
	local changed_event = prop..'_changed'
	self:override('set_'..prop, function(self, inherited, val)
		val = val or false
		local old_val = self[prop] or false
		if val ~= old_val then
			inherited(self, val, old_val)
			val = self[prop] --see if the value really changed.
			if val ~= old_val then
				self:fire(changed_event, val, old_val)
				return true --useful when overriding the setter further
			end
		end
	end)
end

--inhibit a property's getter and setter when using the property on the class.
--instead, set a private var on the class which serves as default value.
--NOTE: use this only _after_ defining the getter and setter.
function object:instance_only(prop)
	local priv = '_'..prop
	self:override('get_'..prop, function(self, inherited)
		if self:isinstance() then
			return inherited(self)
		else
			return self[priv] --get the default value
		end
	end)
	self:override('set_'..prop, function(self, inherited, val)
		if self:isinstance() then
			return inherited(self, val)
		else
			self[priv] = val --set the default value
		end
	end)
end

--validate a property when being set against a list of allowed values.
function object:enum_property(prop, values)
	if type(values) == 'string' then
		local s = values
		values = {}
		for val in s:gmatch'[^%s]+' do
			values[val] = true
		end
	end
	self:override('set_'..prop, function(self, inherited, val)
		if self:check(values[val], 'invalid value "%s" for %s', val, prop) then
			inherited(self, val)
		end
	end)
end

--error reporting

function object:warn(msg, ...)
	msg = string.format(msg, ...)
	io.stderr:write(msg)
	io.stderr:write'\n'
end

function object:check(ret, ...)
	if ret then return ret end
	self:warn(...)
end

--submodule autoloading

function object:autoload(autoload)
	for prop, submodule in pairs(autoload) do
		self['get_'..prop] = function()
			require(submodule)
			return self[prop]
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
	self.text = sel --for debugging

	--parents filter.
	if sel:find'>' then
		self.parent_tags = {} --{{tag,...}, ...}
		sel = sel:gsub('([^>]+)%s*>', function(s) -- tags... >
			local tags = collect(gmatch_tags(s))
			push(self.parent_tags, tags)
			return ''
		end)
	end

	--exclude tags filter.
	local t
	sel = sel:gsub('!([^%s]+)', function(tag)
		t = t or {}
		push(t, tag)
		return ''
	end)
	self.exclude_tags = t

	--tags filter.
	self.tags = collect(gmatch_tags(sel))

	--proc filter.
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

--check that none of the exclude_tags are found in tags table as keys
local function has_no_tags(exclude_tags, tags)
	for i,tag in ipairs(exclude_tags) do
		if tags[tag] then
			return false
		end
	end
	return true
end

function ui.selector:selects(elem)
	if not has_all_tags(self.tags, elem.tags) then
		return false
	end
	if self.exclude_tags then
		if not has_no_tags(self.exclude_tags, elem.tags) then
			return false
		end
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

--stylesheets ----------------------------------------------------------------

local stylesheet = ui.object:subclass'stylesheet'
ui.stylesheet = stylesheet

function stylesheet:after_init(ui)
	self.ui = ui
	self.tags = {} --{tag -> {sel1, ...}}
	self.parent_tags = {} --{tag -> {sel1, ...}}
	self.selectors = {} --{selector1, ...}
	self.first_state_sel_index = 1 --index of first selector with :state tags
end

function stylesheet:style(sel, attrs)

	if type(sel) == 'string' and sel:find(',', 1, true) then
		for sel in sel:gmatch'[^,]+' do
			self:style(sel, attrs)
		end
		return
	end
	local sel = self.ui:selector(sel)
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

--attr. value to use in styles for "same as the value of this other attr"
function ui:value_of(attr)
	return function(self)
		return self[attr]
	end
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
				attrs[attr] = init_val
			end
		end
	end

	--set transition attrs first so that elem:transition() can use them.
	--also because we don't want to transition the transition attrs.
	for attr, val in pairs(attrs) do
		if attr:find'^transition_' then
			elem:_save_initial_value(attr)
			if type(val) == 'function' then --computed value
				val = val(elem, attr)
			end
			elem[attr] = decode_nil(val)
		end
	end

	--set all attribute values into elem via transition().
	for attr, val in pairs(attrs) do
		if not attr:find'^transition_' then
			elem:_save_initial_value(attr)
			elem:transition(attr, decode_nil(val))
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
	if update_children then
		for _,layer in ipairs(elem) do
			self:update_element(layer, true)
		end
	end
end

function ui:style(sel, attrs)
	self.element.stylesheet:style(sel, attrs)
end

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

--transition animation objects -----------------------------------------------

local tran = ui.object:subclass'transition'
ui.transition = tran

tran.interpolate = {}
	--^ {attr_type -> func(self, d, x1, x2, xout) -> xout}

function tran:interpolate_function(elem, attr)
	local atype = self.ui:attr_type(attr)
	return self.interpolate[atype]
end

tran.duration = 0
tran.delay = 0
tran.ease = 'expo out'
tran.times = 1

function tran:after_init(ui, t, ...)

	self.ui = ui
	update(self, self.super, t, ...)

	--timing model
	self.clock = self.clock or ui:clock()
	self.start = self.clock + self.delay
	if not self.way then
		self.ease, self.way = self.ease:match'^([^%s_]+)[%s_]?(.*)'
		if self.way == '' then self.way = 'in' end
	end

	--animation model
	if self.from == nil then
		self.from = self.elem[self.attr]
		assert(self.from ~= nil, 'transition from nil value for "%s"', self.attr)
	end
	assert(self.to ~= nil, 'transition to nil value for "%s"', self.attr)
	self.interpolate = self:interpolate_function(self.elem, self.attr)
	self.end_value = self.to --store it for later

	--set the element value to a copy to avoid overwritting the original value
	--when updating with by-ref semantics.
	self.elem[self.attr] = self.interpolate(self, 1, self.from, self.from)
end

function tran:value_at(t)
	local d = easing.ease(self.ease, self.way, t)
	return self:interpolate(d, self.from, self.to, self.elem[self.attr])
end

function tran:update(clock)
	local t = (clock - self.start) / self.duration
	if t < 0 then --not started
		--nothing
	elseif t >= 1 then --finished, set to actual final value
		self.elem[self.attr] = self.to
	else --running, set to interpolated value
		self.elem[self.attr] = self:value_at(t)
	end
	local alive = t <= 1
	if not alive and self.times > 1 then --repeat in opposite direction
		self.times = self.times - 1
		self.start = clock + self.delay
		self.from, self.to = self.to, self.from
		if not self.repeated then
			self.to = self.backval
			self.repeated = true
		end
		alive = true
	end
	return alive
end

function tran:get_end_clock()
	return self.start + self.duration
end

--interpolators

function tran.interpolate:number(d, x1, x2)
	return lerp(d, 0, 1, tonumber(x1), tonumber(x2))
end

function tran.interpolate:color(d, c1, c2, c)
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

function tran.interpolate:gradient_colors(d, t1, t2, t)
	t = t or {}
	for i,arg1 in ipairs(t1) do
		local arg2 = t2[i]
		local atype = type(arg1) == 'number' and 'number' or 'color'
		t[i] = ui.transition.interpolate[atype](self, d, arg1, arg2, t[i])
	end
	return t
end

--element index --------------------------------------------------------------

ui.element_index = ui.object:subclass'element_index'

function ui.element_index:after_init(ui)
	self.ui = ui
end

function ui.element_index:add_element(elem)
	--TODO: add element to the index.
end

function ui.element_index:remove_element(elem)
	--TODO: remove element from the index.
end

function ui.element_index:find_elements(sel)
	--TODO: use the index to find the element faster.
	return self.ui:_find_elements(sel)
end

--element lists --------------------------------------------------------------

ui.element_list = ui.object:subclass'element_list'

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
-- 2) it inherits the class to get default values directly through `t`.
function element:override_create(inherited, ui, t, ...)
	local t = setmetatable(update({}, t, ...), {__index = self})
	return inherited(self, ui, t)
end

function element:init_fields(t)
	--set attributes in priority and/or lexicographic order.
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

--element tags & styles ------------------------------------------------------

element.tags = false
element.style = false
element.stylesheet = ui:stylesheet()

element:init_ignore{tags=1}

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

	if t and t.tags then
		add_tags(self.tags, t.tags)
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

function element:tags_tostring()
	local t = {}
	for tag, on in sortedpairs(self.tags) do
		if on then t[#t+1] = tag end
	end
	return table.concat(t, ' ')
end

function element:sync_styles()
	if not self._styles_valid then
		self.stylesheet:update_element(self)
		self._styles_valid = true
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

--element attribute transitions ----------------------------------------------

--can be used as a css value.
function element:end_value(attr)
	local tran = self.transitions and self.transitions[attr]
	if tran then
		while tran.next_transition do
			tran = tran.next_transition
		end
		return tran.end_value
	else
		return self[attr]
	end
end

element.blend_transition = {}

function element.blend_transition:replace(
	tran, attr, cur_val, end_val, cur_end_val,
	duration, ease, delay, times, backval, start_val
)
	if duration <= 0 and delay <= 0 then
		--instant transition: set the value immediately.
		if end_val ~= cur_val then
			self[attr] = end_val
			self:invalidate()
		end
		return nil --stop the current transition if any.
	elseif end_val == cur_end_val then
		--same end value: continue with the current transition if any.
		return tran
	else
		if start_val == nil then
			start_val = cur_val
		end
		return self.ui:transition{
			elem = self, attr = attr, to = end_val,
			duration = duration, ease = ease, delay = delay,
			times = times, backval = backval, from = start_val,
		}
	end
end

function element.blend_transition:restart(
	tran, attr, cur_val, end_val, cur_end_val,
	duration, ease, delay, times, backval, start_val
)
	if duration <= 0 and delay <= 0 then
		--instant transition: set the value immediately.
		if end_val ~= cur_val then
			self[attr] = end_val
			self:invalidate()
		end
		return nil --stop the current transition if any.
	else
		if start_val == nil then
			start_val = backval --restarting starts from `backval` by default!
		end
		return self.ui:transition{
			elem = self, attr = attr, to = end_val,
			duration = duration, ease = ease, delay = delay,
			times = times, backval = backval, from = start_val,
		}
	end
end

function element.blend_transition:wait(
	tran, attr, cur_val, end_val, cur_end_val,
	duration, ease, delay, times, backval, start_val
)
	if end_val == cur_end_val then
		--same end value: continue with the current transition if any.
		return tran
	else
		local new_tran = self.ui:transition{
			elem = self, attr = attr, to = end_val,
			duration = duration, ease = ease, delay = delay,
			times = times, backval = backval, from = cur_end_val,
		}
		if tran then
			tran.next_transition = new_tran
			return tran
		else
			return new_tran
		end
	end
end

element.transitions = false
element.transition_duration = tran.duration
element.transition_ease = tran.ease
element.transition_delay = tran.delay
element.transition_times = tran.times
element.transition_blend = 'replace'
element.transition_speed = 1

local function transition_args(t,
	attr, val, duration, ease, delay,
	times, backval, blend, speed, from
)
	return
	  t.attr or attr
	, t.val or val
	, t.duration or duration
	, t.ease or ease
	, t.delay or delay
	, t.times or times
	, t.backval or backval
	, t.blend or blend
	, t.speed or speed
	, t.from or from
end

function element:transition(
	attr, val, duration, ease, delay,
	times, backval, blend, speed, from
)
	if type(attr) == 'table' then
		attr, val, duration, ease, delay,
		times, backval, blend, speed, from =
			transition_args(attr)
	end

	--get default transition parameters from the element.
	local t = self['transition_'..attr]
	if t then
		if type(t) == 'table' then
			attr, val, duration, ease, delay,
			times, backval, blend, speed, from =
				transition_args(t,
					attr, val, duration, ease, delay,
					times, backval, blend, speed, from)
		end
		duration = duration or self['transition_duration_'..attr] or self.transition_duration
		ease = ease or self['transition_ease_'..attr] or self.transition_ease
		delay = delay or self['transition_delay_'..attr] or self.transition_delay
		times = times or self['transition_times_'..attr] or self.transition_times
		blend = blend or self['transition_blend_'..attr] or self.transition_blend
		speed = self['transition_speed_'..attr] or self.transition_speed
		from = self['transition_from_'..attr]
	else
		duration = duration or 0
		ease = ease or tran.ease
		delay = delay or tran.delay
		times = times or tran.times
		blend = blend or 'replace'
		speed = speed or 1
	end
	duration = duration / speed

	local cur_tran = self.transitions and self.transitions[attr]
	local cur_end_val = self:end_value(attr)
	local cur_val = self[attr]

	--values can be functions in style declarations.
	if type(val) == 'function' then
		val = val(self, attr)
	end

	--pass backval=nil on a repeat (yoyo) transition in order to transition
	--back to the initial value (the value before styles were applied) on
	--every reverse (even) loop.
	if times > 1 and backval == nil then
		backval = self:initial_value(attr)
	end

	local blend_func = self.blend_transition[blend]
	local tran = blend_func(self,
		cur_tran, attr, cur_val, val, cur_end_val,
		duration, ease, delay, times, backval, from
	)

	if tran then
		if tran ~= cur_tran then
			self.transitions = self.transitions or {}
			self.transitions[attr] = tran
		end
	elseif self.transitions then
		self.transitions[attr] = nil
	end

	if tran ~= cur_tran then
		self:invalidate()
	end
end

function element:sync_transitions()
	local tr = rawget(self, 'transitions')
	if not tr or not next(tr) then return end
	local clock = self.frame_clock
	if not clock then return end --not inside repaint
	for attr, tran in pairs(tr) do
		local alive = tran:update(clock)
		if not alive then
			tran = tran.next_transition
			tr[attr] = tran
		end
		self:invalidate(tran and tran.start)
	end
end

function element:transitioning(attr)
	return self.transactions and self.transactions[attr]
end

--element sync'ing -----------------------------------------------------------

function element:sync()
	self:sync_styles()
	self:sync_transitions()
	--sync children depth-first.
	for _,elem in ipairs(self) do
		elem:sync()
	end
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
	resizeable=1, fullscreenable=1, activable=1, autoquit=1, hideonclose=1,
	edgesnapping=1,
}

window:init_ignore{native_window=1, parent=1}
window:init_ignore(native_fields)

function window:create_native_window(t)
	return self.ui:native_window(t)
end

function window:override_init(inherited, ui, t)
	local show_it
	local win = t.native_window
	--parent can be given as the `parent` field or in place of the `ui` arg.
	local parent = t.parent
	if not parent and ui and (ui.islayer or ui.iswindow) then
		parent = ui
		ui = ui.ui
	end
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
	self.parent = parent

	if parent then

		function parent.before_free()
			self._parent = false
		end

		--Move window to preserve its relative position to parent if the parent
		--changed its relative position to its own window. Moving this window
		--when the parent's window is moved is automatic (`sticky` flag).
		local px0, py0 = parent:to_window(0, 0)
		function parent.before_sync()
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

	local function setcontext()
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

		--forward mouse wheel events to non-activable child popups, if any.
		--TODO: do this in nw in a portable way!
		for win in pairs(self.ui.windows) do
			if win.parent and win.parent.window == self
				and not win.activable
				and win.visible
			then
				local mx, my = win:from_screen(self:to_screen(mx, my))
				local _, _, pw, ph = win:client_rect()
				if box2d.hit(mx, my, 0, 0, pw, ph) then
					self.ui:_window_mousewheel(win, delta, mx, my, pdelta)
					return
				end
				--break because this is a hack which doesn't work with multiple
				--children because they are not given in z-order (fix this in nw).
				break
			end
		end

		local moved = self.mouse_x ~= mx or self.mouse_y ~= my
		setmouse(mx, my)
		if moved then
			self.ui:_window_mousemove(self, mx, my)
		end
		self.ui:_window_mousewheel(self, delta, mx, my, pdelta)
	end)

	win:on({'keydown', self}, function(win, key)
		setcontext()
		return self:_key_event('keydown', key)
	end)

	win:on({'keypress', self}, function(win, key)
		setcontext()
		return self:_key_event('keypress', key)
	end)

	win:on({'keyup', self}, function(win, key)
		setcontext()
		return self:_key_event('keyup', key)
	end)

	win:on({'keychar', self}, function(win, s)
		setcontext()
		self:_key_event('keychar', s)
	end)

	win:on({'repaint', self}, function(win)
		setcontext()
		if self.mouse_x then
			self.ui:_window_mousemove(self, self.mouse_x, self.mouse_y)
		end
		self.frame_clock = ui:clock()
		self:draw(self.cr)
		self.frame_clock = false
	end)

	win:on({'sync', self}, function(win)
		setcontext()
		self.frame_clock = ui:clock()
		self:sync()
		self.frame_clock = false
	end)

	win:on({'client_rect_changed', self}, function(win, cx, cy, cw, ch)
		if not cx then return end --hidden or minimized
		setcontext()
		self._cw = cw
		self._ch = ch
		self:fire('client_rect_changed', cx, cy, cw, ch)
		self:invalidate()
	end)

	self._cw, self._ch = win:client_size()

	function win.closing(win, closing_win)
		local reason = self._close_reason
		self._close_reason = false
		return self:closing(reason, closing_win.ui_window)
	end

	win:on({'closed', self}, function(win)
		self:fire('closed')
		self:free()
	end)

	win:on({'changed', self}, function(win, _, state)
		self:settag(':active', state.active)
		self:settag(':fullscreen', state.fullscreen)
	end)

	--create `window_*` events in ui.
	self:on('event', function(self, event, ...)
		if event == 'mousemove' then return end
		if not self.ui then return end --window was closed
		return self.ui:fire('window_'..event, self, ...)
	end)

	self.view = self:create_view()

	--tab navigation.
	self.view:on('keypress', function(view, key)
		if key == 'tab' then
			local next_widget = self:next_focusable_widget(not self.ui:key'shift')
			if next_widget then
				return next_widget:focus(true)
			end
		end
	end)

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
	self.native_window.ui_window = false
	self.view:free()
	self.view = false
	if self.own_native_window then
		self.native_window:close()
	end
	self.native_window = false
	self.ui.windows[self] = nil
end

--move frameless window by dragging it ---------------------------------------

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
		layer.start_drag = false --reset to default
		layer.drag = false --reset to default
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

--window geometry ------------------------------------------------------------

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

function window:client_size()
	return self._cw, self._ch
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
function window:get_cw() return self._cw end
function window:get_ch() return self._ch end
function window:set_cx(cx) self:client_rect(cx, nil, nil, nil) end
function window:set_cy(cy) self:client_rect(nil, cy, nil, nil) end
function window:set_cw(cw) self:client_rect(nil, nil, cw, nil) end
function window:set_ch(ch) self:client_rect(nil, nil, nil, ch) end

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

--window as a layer's parent -------------------------------------------------

function window:get_parent()
	return self._parent
end

function window:set_parent(parent)
	assert(not self._parent, 'changing the parent is NYI')
	if parent and parent.iswindow then
		parent = parent.view
	end
	self._parent = parent
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

--native window API forwarding -----------------------------------------------

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
function window:closing(reason, closing_win) end --stub
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
function window:showmodal()   self.native_window:showmodal() end
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

function window:_settooltip(text)
	return self.native_window:tooltip(text)
end

function window:get_cursor()
	return (self.native_window:cursor())
end

function window:set_cursor(cursor)
	self.native_window:cursor(cursor or 'arrow')
end

function window:mouse_pos() --window interface
	return self.mouse_x, self.mouse_y
end

--element query interface ----------------------------------------------------

function window:find(sel)
	local sel = ui:selector(sel):filter(function(elem)
		return elem.window == self
	end)
	return self.ui:find(sel)
end

function window:each(sel, f)
	return self:find(sel):each(f)
end

--window mouse events routing ------------------------------------------------

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

--window keyboard events routing ---------------------------------------------

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

function window:_key_event(event_name, key)
	local widget = self.focused_widget or self.view
	repeat
		if widget:fire(event_name, key) ~= nil then
			return true
		end
		if widget.iswindow and widget.parent then
			break --don't forward key presses from a child window to its parent.
		end
		widget = widget.parent
	until not widget
end

--window rendering -----------------------------------------------------------

function window:draw(cr)
	local exp = self._frame_expire_clock
	if exp and exp > self.frame_clock then
		--TODO: this still does blitting at 60fps when there are only in-delay
		--transitions, even if we skip drawing the screen.
		self.native_window:invalidate()
		return
	end
	self._frame_expire_clock = false
	cr:save()
	cr:new_path()
	self.view:sync()
	cr:restore()
	cr:save()
	cr:new_path()
	self.view:draw(cr)
	cr:restore()
	if cr:status() ~= 0 then --see if cairo didn't shutdown
		self:warn(cr:status_string())
	end
end

function window:sync()
	local exp = self._frame_expire_clock
	if exp and exp > self.frame_clock then
		self.native_window:invalidate()
		return
	end
	self._frame_expire_clock = false
	self.cr:save()
	self.cr:new_path()
	self.view:sync()
	self.cr:restore()
end

function window:invalidate(clock) --element interface; window intf.
	local invalidated = self._frame_expire_clock
	self._frame_expire_clock = clock
		and math.min(self._frame_expire_clock or 1/0, clock) or -1/0
	if not invalidated then
		self.native_window:invalidate()
	end
end

--ui colors, gradients, images -----------------------------------------------

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
			g:add_color_stop(offset, self:rgba(arg))
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
		local bundle = require'bundle'
		local f = bundle.fs_open(file)
		if not self:check(f, 'file not found: "%s"', file) then
			return
		end
		local bufread = f:buffered_read()
		local function read(buf, sz)
			return self:check(bufread(buf, sz))
		end
		local libjpeg = require'libjpeg'
		local img = self:check(libjpeg.open({read = read}))
		if not img then
			f:close()
			return
		end
		local bmp = self:check(img:load{accept = {bgra8 = true}})
		img:free()
		f:close()
		if not bmp then
			return
		end
		local sr = cairo.image_surface(bmp) --bmp is Lua-pinned to sr
		local patt = cairo.surface_pattern(sr) --sr is cairo-pinned to patt
		return {patt = patt, sr = sr}
	end
end
ui:memoize'image_pattern'

--ui fonts & text ------------------------------------------------------------

function ui:add_font_file(...) return self.tr:add_font_file(...) end
function ui:add_mem_font(...) return self.tr:add_mem_font(...) end

function ui:after_init()
	self.tr = tr()

	--use our own overridable rgba parser.
	function self.tr.rs.rgba(c)
		return self:rgba(c)
	end

	--add a font searcher for the google fonts repository.
	--$ git clone https://github.com/google/fonts media/fonts/gfonts
	local function find_font(font_db, name, weight, slant)
		local gfonts = require'gfonts'
		local file, real_weight = gfonts.font_file(name, weight, slant, true)
		local font = file and self:add_font_file(file, name, real_weight, slant)
		return font, real_weight
	end
	push(self.tr.rs.font_db.searchers, find_font)

	--add default fonts.
	--$ mgit clone fonts-awesome
	self:add_font_file('media/fonts/fa-regular-400.ttf', 'Font Awesome')
	self:add_font_file('media/fonts/fa-solid-900.ttf', 'Font Awesome Bold')
	self:add_font_file('media/fonts/fa-brands-400.ttf', 'Font Awesome Brands')
	--$ mgit clone fonts-material-icons
	self:add_font_file('media/fonts/MaterialIcons-Regular.ttf', 'Material Icons')
	--$ mgit clone fonts-ionicons
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

ui:style('layer :disabled', {
	background_color = '#222',
	text_color = '#666',
})

layer.cursor = false  --false or cursor name from nw

layer.drag_threshold = 0 --moving distance before start dragging
layer.max_click_chain = 1 --2 for getting doubleclick events etc.
layer.hover_delay = 1 --TODO: hover event delay

function layer:override_init(inherited, ui, t)
	if ui and (ui.islayer or ui.iswindow) then --ui is actually the parent
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
	local enabled = t.enabled and true or false
	if enabled ~= self._enabled then
		self._enabled = enabled
	end
	self.layer_index = t.layer_index
	self.parent = t.parent

	--create and/or attach layers
	for i,layer in ipairs(t) do
		if not layer.islayer then
			layer = layer.class(self.ui, self[layer.class], layer)
		end
		assert(layer.islayer)
		layer.parent = self
	end
end

function layer:before_free()
	self:unfocus()
	if self.hot then
		self.ui.hot_widget = false
		self.ui.hot_area = false
	end
	if self.active then
		self.ui.active_widget = false
	end
	self:_free_children()
	if self.parent then
		self.parent:remove_layer(self, true)
	end
end

--layer relative geometry & matrix -------------------------------------------

layer.x = 0
layer.y = 0
layer.w = 0
layer.h = 0
layer.rotation = 0
layer.rotation_cx = 0
layer.rotation_cy = 0
layer.scale = 1
layer.scale_x = false
layer.scale_y = false
layer.scale_cx = 0
layer.scale_cy = 0

local mt = cairo.matrix()
function layer:rel_matrix() --box matrix relative to parent's content space
	return mt:reset()
		:translate(self.x, self.y)
		:rotate_around(self.rotation_cx, self.rotation_cy,
			math.rad(self.rotation))
		:scale_around(self.scale_cx, self.scale_cy,
			self.scale_x or self.scale,
			self.scale_y or self.scale)
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

--convert point from own box space to parent content space.
function layer:from_box_to_parent(x, y)
	if self.pos_parent ~= self.parent then
		return self.parent:from_window(self:abs_matrix():point(x, y))
	else
		return self:rel_matrix():point(x, y)
	end
end

--convert point from parent content space to own box space.
function layer:from_parent_to_box(x, y)
	if self.pos_parent ~= self.parent then
		return self:abs_matrix():invert():point(self.parent:to_window(x, y))
	else
		return self:rel_matrix():invert():point(x, y)
	end
end

--convert point from own content space to parent content space.
function layer:to_parent(x, y)
	if self.pos_parent ~= self.parent then
		return self.parent:from_window(
			self:abs_matrix():translate(self:padding_pos()):point(x, y))
	else
		return self:rel_matrix():translate(self:padding_pos()):point(x, y)
	end
end

--convert point from parent content space to own content space.
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

--convert point from own content space to other's content space.
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

--layer parent property & child list -----------------------------------------

layer._parent = false

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

layer._pos_parent = false

function layer:get_pos_parent() --child interface
	return self._pos_parent or self._parent
end

function layer:set_pos_parent(parent)
	if parent and parent.iswindow then
		parent = parent.view
	end
	if parent == self.parent then
		parent = false
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
		return indexof(self, self.parent)
	else
		return self._layer_index
	end
end

function layer:move_layer(layer, index)
	local new_index = clamp(index, 1, #self)
	local old_index = indexof(layer, self)
	if old_index == new_index then return end
	table.remove(self, old_index)
	table.insert(self, new_index, layer)
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
	for _,layer in ipairs(self) do
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
	index = clamp(index or 1/0, 1, #self + 1)
	push(self, index, layer)
	layer._parent = self
	layer.window = self.window
	self:fire('layer_added', layer, index)
	layer:_update_enabled(layer.enabled)
end

function layer:remove_layer(layer, freeing) --parent interface
	assert(layer._parent == self)
	self:off({nil, layer})
	popval(self, layer)
	if not freeing then
		self:fire('layer_removed', layer)
	end
	layer._parent = false
	layer.window = false
	layer:_update_enabled(layer.enabled)
end

function layer:_free_children()
	while #self > 0 do
		self[#self]:free()
	end
end

--mouse event handling -------------------------------------------------------

function layer:mouse_pos()
	if not self.window.mouse_x then
		return false, false
	end
	return self:from_window(self.window:mouse_pos())
end

function layer:get_mouse_x() return (select(1, self:mouse_pos())) end
function layer:get_mouse_y() return (select(2, self:mouse_pos())) end

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

--layer.window property ------------------------------------------------------

function layer:get_window()
	return self._window
end

function layer:set_window(window)
	if self._window then
		self._window:off({nil, self})
	end
	self._window = window
	for i,layer in ipairs(self) do
		layer.window = window
	end
end

--layer.enabled property/tag -------------------------------------------------

function layer:get_enabled()
	return self._enabled and (not self.parent or self.parent.enabled)
end

function layer:_update_enabled(enabled)
	self:settag(':disabled', not enabled)
	for _,layer in ipairs(self) do
		layer:_update_enabled(enabled)
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

--layer.tooltip property -----------------------------------------------------

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

--layer focusing and keyboard event handling ---------------------------------

function layer:canfocus()
	return self.visible and self.focusable and self.enabled
end

function window:unfocus_focused_widget()
	if self.focused_widget then
		self.focused_widget:unfocus()
	end
end

function layer:unfocus()
	if not self.focused then return end
	self.window.focused_widget = false
	self:fire'lostfocus'
	self:settag(':focused', false)
	local parent = self.parent
	while parent and not parent.iswindow do
		parent:settag(':child_focused', false)
		parent = parent.parent
	end
	self.window:fire('lostfocus', self)
	self.ui:fire('lostfocus', self)
	self:invalidate()
end

function layer:focus(focus_children)
	if self:canfocus() then
		if not self.focused then
			self.window:unfocus_focused_widget()
			self:fire'gotfocus'
			self:settag(':focused', true)
			local parent = self.parent
			while parent and not parent.iswindow do
				parent:settag(':child_focused', true)
				parent = parent.parent
			end
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
	for _,layer in ipairs(self) do
		local focused_widget = layer.focused_widget
		if focused_widget then
			return focused_widget
		end
	end
end

layer.tabindex = 0
layer.tabgroup = 0
layer._taborder_algorithm = 'xy' --'xy', 'yx'

function layer:get_taborder_algorithm()
	return self:parent_value'_taborder_algorithm'
end

function layer:focusable_widgets(t, depth)
	if not self.visible then return end
	t = t or {}
	depth = depth or 1
	self._depth = depth
	for i,layer in ipairs(self) do
		if layer:canfocus() then
			layer._depth = depth + 1
			push(t, layer)
		else --add layers' focusable children recursively, depth-first.
			layer:focusable_widgets(t, depth + 1)
		end
	end
	table.sort(t, function(t1, t2)
		if t1.tabgroup == t2.tabgroup then
			if t1.tabindex == t2.tabindex then
				if t1.parent == t2.parent then
					local ax1, ay1 = t1.parent:to_window(t1.x, t1.y)
					local bx1, by1 = t2.parent:to_window(t2.x, t2.y)
					if self.taborder_algorithm == 'yx' then
						ax1, bx1, ay1, by1 = ay1, by1, ax1, bx1
					end
					if ax1 == bx1 then
						return ay1 < by1
					else
						return ax1 < bx1
					end
				else
					return t1.parent._depth < t2.parent._depth
				end
			else
				return t1.tabindex < t2.tabindex
			end
		elseif type(t1.tabgroup) == type(t2.tabgroup) then
			return  t1.tabgroup < t2.tabgroup
		else
			return type(t1.tabgroup) < type(t2.tabgroup)
		end
	end)
	return t
end

function layer:first_focusable_widget()
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

--layers geometry, drawing and hit testing -----------------------------------

function layer:children_bounding_box(strict)
	local x, y, w, h = 0, 0, 0, 0
	for _,layer in ipairs(self) do
		x, y, w, h = box2d.bounding_box(x, y, w, h,
			layer:bounding_box(strict))
	end
	return x, y, w, h
end

function layer:draw_children(cr) --called in content space
	for i = 1, #self do
		self[i]:draw(cr)
	end
end

function layer:hit_test_children(x, y, reason) --called in content space
	for i = #self, 1, -1 do
		local widget, area = self[i]:hit_test(x, y, reason)
		if widget then
			return widget, area
		end
	end
end

--border geometry and drawing ------------------------------------------------

layer.border_width = 0 --no border
layer.border_width_left   = false
layer.border_width_right  = false
layer.border_width_top    = false
layer.border_width_bottom = false
layer.corner_radius = 0 --square
layer.corner_radius_top_left    = false
layer.corner_radius_top_right   = false
layer.corner_radius_bottom_left = false
layer.corner_radius_bottom_right = false
layer.border_color = '#fff'
layer.border_color_left   = false
layer.border_color_right  = false
layer.border_color_top    = false
layer.border_color_bottom = false
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
	local bw = self.border_width
	local w1 = lerp(o, -1, 1, self.border_width_left or bw, 0)
	local h1 = lerp(o, -1, 1, self.border_width_top or bw, 0)
	local w2 = lerp(o, -1, 1, self.border_width_right or bw, 0)
	local h2 = lerp(o, -1, 1, self.border_width_bottom or bw, 0)
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

function layer:get_inner_x() return (select(1, self:border_rect(-1))) end
function layer:get_inner_y() return (select(2, self:border_rect(-1))) end
function layer:get_inner_w() return (select(3, self:border_rect(-1))) end
function layer:get_inner_h() return (select(4, self:border_rect(-1))) end
function layer:get_outer_x() return (select(1, self:border_rect(1))) end
function layer:get_outer_y() return (select(2, self:border_rect(1))) end
function layer:get_outer_w() return (select(3, self:border_rect(1))) end
function layer:get_outer_h() return (select(4, self:border_rect(1))) end

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

	local r = self.corner_radius
	local r1 = self.corner_radius_top_left or r
	local r2 = self.corner_radius_top_right or r
	local r3 = self.corner_radius_bottom_right or r
	local r4 = self.corner_radius_bottom_left or r

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
		self.border_width ~= 0
		or self.border_width_left ~= 0
		or self.border_width_top ~= 0
		or self.border_width_right ~= 0
		or self.border_width_bottom ~= 0
end

function layer:draw_border(cr)
	if not self:border_visible() then return end

	local border_color = self.border_color

	--seamless drawing when all side colors are the same.
	if self.border_color_left == self.border_color_top
		and self.border_color_left == self.border_color_right
		and self.border_color_left == self.border_color_bottom
	then
		cr:new_path()
		cr:rgba(self.ui:rgba(self.border_color_bottom or border_color))
		if self.border_width_left == self.border_width_top
			and self.border_width_left == self.border_width_right
			and self.border_width_left == self.border_width_bottom
		then --stroke-based method (doesn't require path offseting; supports dashing)
			self:border_path(cr, 0)
			cr:line_width(self.border_width_left or self.border_width)
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

	if border_color or self.border_color_left then
		cr:new_path()
		cr:move_to(x1, y1+r1y)
		qarc(cr, x1+r1x, y1+r1y, r1x, r1y, 1, .5, k)
		qarc(cr, X1+R1X, Y1+R1Y, R1X, R1Y, 1.5, -.5, K)
		cr:line_to(X1, Y2-R4Y)
		qarc(cr, X1+R4X, Y2-R4Y, R4X, R4Y, 5, -.5, K)
		qarc(cr, x1+r4x, y2-r4y, r4x, r4y, 4.5, .5, k)
		cr:close_path()
		cr:rgba(self.ui:rgba(self.border_color_left or border_color))
		cr:fill()
	end

	if border_color or self.border_color_top then
		cr:new_path()
		cr:move_to(x2-r2x, y1)
		qarc(cr, x2-r2x, y1+r2y, r2x, r2y, 2, .5, k)
		qarc(cr, X2-R2X, Y1+R2Y, R2X, R2Y, 2.5, -.5, K)
		cr:line_to(X1+R1X, Y1)
		qarc(cr, X1+R1X, Y1+R1Y, R1X, R1Y, 2, -.5, K)
		qarc(cr, x1+r1x, y1+r1y, r1x, r1y, 1.5, .5, k)
		cr:close_path()
		cr:rgba(self.ui:rgba(self.border_color_top or border_color))
		cr:fill()
	end

	if border_color or self.border_color_right then
		cr:new_path()
		cr:move_to(x2, y2-r3y)
		qarc(cr, x2-r3x, y2-r3y, r3x, r3y, 3, .5, k)
		qarc(cr, X2-R3X, Y2-R3Y, R3X, R3Y, 3.5, -.5, K)
		cr:line_to(X2, Y1+R2Y)
		qarc(cr, X2-R2X, Y1+R2Y, R2X, R2Y, 3, -.5, K)
		qarc(cr, x2-r2x, y1+r2y, r2x, r2y, 2.5, .5, k)
		cr:close_path()
		cr:rgba(self.ui:rgba(self.border_color_right or border_color))
		cr:fill()
	end

	if border_color or self.border_color_bottom then
		cr:new_path()
		cr:move_to(x1+r4x, y2)
		qarc(cr, x1+r4x, y2-r4y, r4x, r4y, 4, .5, k)
		qarc(cr, X1+R4X, Y2-R4Y, R4X, R4Y, 4.5, -.5, K)
		cr:line_to(X2-R3X, Y2)
		qarc(cr, X2-R3X, Y2-R3Y, R3X, R3Y, 4, -.5, K)
		qarc(cr, x2-r3x, y2-r3y, r3x, r3y, 3.5, .5, k)
		cr:close_path()
		cr:rgba(self.ui:rgba(self.border_color_bottom or border_color))
		cr:fill()
	end
end

--background geometry and drawing --------------------------------------------

layer.background_type = 'color'
	--^ false, 'color', 'gradient', 'radial_gradient', 'image'
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

--TODO: add 'auto' ?
function layer:detect_background_type()
	if self.background_type ~= 'auto' then
		return self.background_type
	elseif self.background_image then
		return 'image'
	elseif self.background_colors then
		return 'gradient'
	elseif self.background_color then
		return 'color'
	else
		return false
	end
end

function layer:background_visible()
	return (
		--TODO: add 'auto' ?
		--(self.background_type == 'auto' and self:detect_background_type())
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
				self.background_scale_x or self.background_scale,
				self.background_scale_y or self.background_scale)
			:invert())
	patt:extend(self.background_extend)
	cr:source(patt)
	cr:paint()
	cr:rgb(0, 0, 0) --release source
end

--box-shadow geometry and drawing --------------------------------------------

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

--parsing of '<align_x> <align_y>' property strings

local aligns_x = {
	left = 'left', center = 'center', right = 'right',
	l = 'left', c = 'center', r = 'right',
}
local aligns_y = {
	top = 'top', center = 'center', bottom = 'bottom',
	t = 'top', c = 'center', b = 'bottom',
}
function ui:_align(s)
	local a1, a2 = s:match'([^%s]+)%s*([^%s]*)'
	local ax = aligns_x[a1] or aligns_x[a2]
	local ay = aligns_y[a1] or aligns_y[a2]
	return self:check(ax and ay, 'invalid align: "%s"', s) and {ax, ay}
end
ui:memoize'_align'

function ui:align(s)
	local t = self:_align(s)
	if not t then return end
	return t[1], t[2]
end

--text geometry and drawing --------------------------------------------------

layer.text = false
layer.font = 'Open Sans,14'
layer.font_name   = false
layer.font_weight = false
layer.font_slant  = false
layer.font_size   = false
layer.nowrap      = false
layer.text_dir    = false
layer.text_color = '#fff'
layer.line_spacing = 1
layer.paragraph_spacing = 2
layer.text_dir = 'auto' --auto, rtl, ltr
layer.nowrap = false
layer.text_operator = 'over'

function layer:text_visible()
	return self.text and self.text ~= '' and true or false
end

--editable text is not sync'ed based on changes to the `text` property.
--see editbox implementation for details.
layer.text_editabe = false

layer:stored_property'text_align'
function layer:after_set_text_align(s)
	local ax, ay = self.ui:align(s)
	if not ax then return end
	self._text_align_x0 = ax
	self._text_align_y0 = ay
end
layer:nochange_barrier'text_align'
layer.text_align = 'center center'

layer:stored_property'text_align_x'
layer:enum_property('text_align_x', aligns_x)

layer:stored_property'text_align_y'
layer:enum_property('text_align_y', aligns_y)

function layer:text_aligns()
	return
		self._text_align_x or self._text_align_x0,
		self._text_align_y or self._text_align_y0
end

layer._text_tree = false
layer._text_segments = false

function layer:sync_text_shape()
	if not self:text_visible() then
		return
	end
	if not self._text_tree
		or (not self.text_editabe and self.text ~= self._text_tree[1])
		or self.font        ~= self._text_tree.font
		or self.font_name   ~= self._text_tree.font_name
		or self.font_weight ~= self._text_tree.font_weight
		or self.font_slant  ~= self._text_tree.font_slant
		or self.font_size   ~= self._text_tree.font_size
		or self.nowrap      ~= self._text_tree.nowrap
		or self.text_dir    ~= self._text_tree.text_dir
	then
		self._text_tree = self._text_tree or {}
		self._text_tree[1]          = self.text
		self._text_tree.font        = self.font
		self._text_tree.font_name   = self.font_name
		self._text_tree.font_weight = self.font_weight
		self._text_tree.font_slant  = self.font_slant
		self._text_tree.font_size   = self.font_size
		self._text_tree.nowrap      = self.nowrap
		self._text_tree.text_dir    = self.text_dir
		self._text_segments = self.ui.tr:shape(self._text_tree)
		self._text_w = false --invalidate wrap
		self._text_h = false --invalidate align
	end
	return self._text_segments
end

function layer:sync_text_wrap()
	local segs = self._text_segments
	if not segs then return nil end
	local cw = self:client_size()
	local ls = self.line_spacing
	local ps = self.paragraph_spacing
	if    cw ~= self._text_w
		or ls ~= self._text_tree.line_spacing
		or ps ~= self._text_tree.paragraph_spacing
	then
		self._text_w = cw
		self._text_tree.line_spacing = ls
		self._text_tree.paragraph_spacing = ps
		segs:wrap(cw)
		self._text_h = false --invalidate align
	end
	return segs
end

function layer:sync_text_align()
	local segs = self._text_segments
	if not segs then return nil end
	local cw, ch = self:client_size()
	local ha, va = self:text_aligns()
	if    ch ~= self._text_h
		or ha ~= self._text_ha
		or va ~= self._text_va
	then
		self._text_w  = cw
		self._text_h  = ch
		self._text_ha = ha
		self._text_va = va
		segs:align(0, 0, cw, ch, ha, va)
	end
	return segs
end

function layer:get_baseline()
	local segs = self._text_segments
	if not segs then return 0 end
	local lines = segs.lines
	return lines.y + lines.baseline
end

function layer:draw_text(cr)
	if not self:text_visible() then return end
	self._text_tree.color    = self.text_color
	self._text_tree.operator = self.text_operator
	self._text_segments:paint(cr)
end

function layer:text_bounding_box()
	if not self:text_visible() then
		return 0, 0, 0, 0
	end
	return self._text_segments:bounding_box()
end

--content-box geometry, drawing and hit testing ------------------------------

layer.padding = 0
layer.padding_left = false
layer.padding_right = false
layer.padding_top = false
layer.padding_bottom = false

function layer:get_pw()
	local p = self.padding
	return (self.padding_left or p) + (self.padding_right or p)
end
function layer:get_ph()
	local p = self.padding
	return (self.padding_top or p) + (self.padding_bottom or p)
end
function layer:get_pw1() return self.padding_left or self.padding end
function layer:get_ph1() return self.padding_top or self.padding end
function layer:get_pw2() return self.padding_right or self.padding end
function layer:get_ph2() return self.padding_bottom or self.padding end

function layer:padding_pos() --in box space
	local p = self.padding
	local px = self.padding_left or p
	local py = self.padding_top or p
	return px, py
end

function layer:padding_size()
	local p = self.padding
	local px1 = self.padding_left or p
	local py1 = self.padding_top or p
	local px2 = self.padding_right or p
	local py2 = self.padding_bottom or p
	return
		self.w - (px1 + px2),
		self.h - (py1 + py2)
end

layer.client_size = layer.padding_size

function layer:padding_rect() --in box space
	local p = self.padding
	local px1 = self.padding_left or p
	local py1 = self.padding_top or p
	local px2 = self.padding_right or p
	local py2 = self.padding_bottom or p
	return
		px1, py1,
		self.w - (px1 + px2),
		self.h - (py1 + py2)
end

function layer:client_rect() --in content space
	return 0, 0, self:padding_size()
end

function layer:get_cw()
	local p = self.padding
	local px1 = self.padding_left or p
	local px2 = self.padding_right or p
	return
		self.w - (px1 + px2)
end

function layer:get_ch()
	local p = self.padding
	local py1 = self.padding_top or p
	local py2 = self.padding_bottom or p
	return
		self.h - (py1 + py2)
end

function layer:set_cw(cw) self.w = cw + (self.w - self.cw) end
function layer:set_ch(ch) self.h = ch + (self.h - self.ch) end

--convert point from own box space to own content space.
function layer:to_content(x, y)
	local px, py = self:padding_pos()
	return x - px, y - py
end

--content point from own content space to own box space.
function layer:from_content(x, y)
	local px, py = self:padding_pos()
	return px + x, py + y
end

--layer drawing & hit testing ------------------------------------------------

layer.opacity = 1
layer.clip_content = false --'padding'/true, 'background', false

function layer:draw_content(cr) --called in own content space
	self:draw_children(cr)
	self:draw_text(cr)
end

function layer:hit_test_content(x, y, reason) --called in own content space
	return self:hit_test_children(x, y, reason)
end

function layer:content_bounding_box(strict)
	local x, y, w, h = self:children_bounding_box(strict)
	return box2d.bounding_box(x, y, w, h, self:text_bounding_box())
end

function layer:draw(cr) --called in parent's content space; child intf.

	if not self.visible or self.opacity <= 0 then
		return
	end

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

	if not self.visible or self.opacity <= 0 then return end

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

	--hit the content if inside the clip area.
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
	if not self.visible then
		return 0, 0, 0, 0
	end
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

function layer:invalidate(delay)
	if self.window then
		self.window:invalidate(delay)
	end
end

--layer.hot property which is managed by the window

function layer:get_hot()
	return self.ui.hot_widget == self
end

--layer.active property and tag which the widget must set manually

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
		self:focus(false)
	end
	self:invalidate()
end

function layer:activate()
	if not self.active then
		self.active = true
		self.active = false
	end
end

--geometry in the parent's content box.

function layer:get_cx() return self.x + self.w / 2 end
function layer:get_cy() return self.y + self.h / 2 end

function layer:set_cx(cx) self.x = cx - self.w / 2 end
function layer:set_cy(cy) self.y = cy - self.h / 2 end

function layer:get_x2() return self.x + self.w end
function layer:get_y2() return self.y + self.h end

function layer:set_x2(x2) self.w = x2 - self.x end
function layer:set_y2(y2) self.h = y2 - self.y end

function layer:size() return self.w, self.h end
function layer:rect() return self.x, self.y, self.w, self.h end

--layouting ------------------------------------------------------------------

layer.layout = false --false/'null', 'textbox', 'flexbox', 'grid'

--min client width/height used by flexible layouts and their children.
layer.min_cw = 0
layer.min_ch = 0

layer.layouts = {} --{layout_name -> layout_mixin}

layer:stored_property'layout'
function layer:after_set_layout(layout)
	local mixin = self.layouts[layout or 'null']
	if not self.ui:check(mixin, 'invalid layout "%s"', layout) then return end
	self:inherit(mixin, true)
end
layer:nochange_barrier'layout'

--used by layers that need to solve their layout on one axis completely
--before they can solve it on the other axis. any content-based layout with
--wrapped content is like that: can't know the height until wrapping the
--content which needs to know the width (and viceversa for vertical flow).
function layer:sync_layout_separate_axes()
	if not self.visible then return end
	local sync_x = self.layout_axis_order == 'xy'
	local axis_synced, other_axis_synced
	for phase = 1, 3 do
		other_axis_synced = axis_synced
		if sync_x then
			--sync the x-axis.
			self.w = self:sync_min_w(other_axis_synced)
			axis_synced = self:sync_layout_x(other_axis_synced)
		else
			--sync the y-axis.
			self.h = self:sync_min_h(other_axis_synced)
			axis_synced = self:sync_layout_y(other_axis_synced)
		end
		if axis_synced and other_axis_synced then
			break --both axes were solved before last phase.
		end
		sync_x = not sync_x
	end
	assert(axis_synced and other_axis_synced)
end

--null layout ----------------------------------------------------------------

local null_layout = object:subclass'null_layout'
layer.layouts.null = null_layout

--called on the window's view layer after all layers are sync'ed
--(styles and transitions are updated at this point).
function null_layout:sync_window_view(w, h)
	self.w = w
	self.h = h
end

--layouting system entry point: called on the window view layer.
--called by null-layout layers to layout themselves and their children.
function null_layout:sync_layout()
	if not self.visible then return end
	self:sync_text_shape()
	self:sync_text_wrap()
	self:sync_text_align()
	for _,layer in ipairs(self) do
		layer:sync_layout() --recurse
	end
end

--called by flexible layouts to know the minimum width of their children.
--width-in-height-out layouts call this before h and y are sync'ed.
function null_layout:sync_min_w()
	self._min_w = self.min_cw + self.pw
	return self._min_w
end

--called by flexible layouts to know the minimum height of their children.
--width-in-height-out layouts call this only after w and x are sync'ed.
function null_layout:sync_min_h()
	self._min_h = self.min_ch + self.ph
	return self._min_h
end

--called by flexible layouts to sync their children on one axis. in response,
--null-layouts sync themselves and their children on both axes when the
--second axis is synced.
function null_layout:sync_layout_x(other_axis_synced)
	if other_axis_synced then
		self:sync_layout()
	end
	return true
end
null_layout.sync_layout_y = null_layout.sync_layout_x

layer:inherit(null_layout, true)

--textbox layout -------------------------------------------------------------

local textbox = object:subclass'textbox_layout'
layer.layouts.textbox = textbox

function textbox:sync_window_view(w, h)
	self.min_cw = w - self.pw
	self.min_ch = h - self.ph
end

function textbox:sync_layout()
	if not self.visible then return end
	local segs = self:sync_text_shape()
	if not segs then
		self.cw = 0
		self.ch = 0
		return
	end
	self.cw = math.max(segs:min_w(), self.min_cw)
	self:sync_text_wrap()
	self.cw = math.max(segs.lines.max_ax, self.min_cw)
	self.ch = math.max(self.min_ch, segs.lines.spacing_h)
	self:sync_text_align()
end

function textbox:sync_min_w(other_axis_synced)
	local min_cw
	if not other_axis_synced or self.nowrap then
		local segs = self:sync_text_shape()
		min_cw = segs and segs:min_w() or 0
	else
		--height-in-width-out parent layout with wrapping text not supported
		min_cw = 0
	end
	min_cw = math.max(min_cw, self.min_cw)
	local min_w = min_cw + self.pw
	self._min_w = min_w
	return min_w
end

function textbox:sync_min_h(other_axis_synced)
	local min_ch
	if other_axis_synced or self.nowrap then
		local segs = self._text_segments
		min_ch = segs and segs.lines.spacing_h or 0
	else
		--height-in-width-out parent layout with wrapping text not supported
		min_ch = 0
	end
	min_ch = math.max(min_ch, self.min_ch)
	local min_h = min_ch + self.ph
	self._min_h = min_h
	return min_h
end

function textbox:sync_layout_x(other_axis_synced)
	if not other_axis_synced then
		self:sync_text_wrap()
		return true
	end
end

function textbox:sync_layout_y(other_axis_synced)
	if other_axis_synced then
		self:sync_text_align()
		return true
	end
end

--flexbox & grid layout utils ------------------------------------------------

local function items_sum(self, i, j, _MIN_W)
	local sum = 0
	local item_count = 0
	for i = i, j do
		local layer = self[i]
		if layer.visible then
			sum = sum + layer[_MIN_W]
			item_count = item_count + 1
		end
	end
	return sum, item_count
end

local function items_max(self, i, j, _MIN_W)
	local max = 0
	local item_count = 0
	for i = i, j do
		local layer = self[i]
		if layer.visible then
			max = math.max(max, layer[_MIN_W])
			item_count = item_count + 1
		end
	end
	return max, item_count
end

--stretch a line of items on the main axis.
local function stretch_items_main_axis(items, i, j, total_w, X, W, _MIN_W)

	--compute the fraction representing the total width.
	local total_fr = 0
	for i = i, j do
		local layer = items[i]
		if layer.visible then
			total_fr = total_fr + math.max(0, layer.fr)
		end
	end

	--compute the total overflow width and total free width.
	local total_overflow_w = 0
	local total_free_w = 0
	for i = i, j do
		local layer = items[i]
		if layer.visible then
			local min_w = layer[_MIN_W]
			local flex_w = total_w * math.max(0, layer.fr) / total_fr
			local overflow_w = math.max(0, min_w - flex_w)
			local free_w = math.max(0, flex_w - min_w)
			total_overflow_w = total_overflow_w + overflow_w
			total_free_w = total_free_w + free_w
		end
	end

	--distribute the overflow to children which have free space to
	--take it. each child shrinks to take in a part of the overflow
	--proportional to its percent of free space.
	local last_layer
	local x = 0
	for i = i, j do
		local layer = items[i]
		if layer.visible then
			local min_w = layer[_MIN_W]
			local flex_w = total_w * layer.fr / total_fr
			local w
			if min_w > flex_w then --overflow
				w = min_w
			else
				local free_w = flex_w - min_w
				local free_p = free_w / total_free_w
				local shrink_w = total_overflow_w * free_p
				if shrink_w ~= shrink_w then --total_free_w == 0
					shrink_w = 0
				end
				w = flex_w - shrink_w
			end
			layer[X] = x
			layer[W] = w
			x = x + w
			last_layer = layer
		end
	end
	--adjust last item's width for any rounding errors.
	if last_layer then
		last_layer[W] = total_w - last_layer[X]
	end

end

--starting x-offset and in-between spacing metrics for aligning.
local function align_metrics(align, container_w, items_w, item_count, START, END, LEFT, RIGHT, L, R)
	local x
	local spacing = 0
	if align == START or align == LEFT or align == L then
		x = 0
	elseif align == END or align == RIGHT or align == R then
		x = container_w - items_w
	elseif align == 'center' then
		x = (container_w - items_w) / 2
	elseif align == 'space_evenly' then
		spacing = (container_w - items_w) / (item_count + 1)
		x = spacing
	elseif align == 'space_around' then
		spacing = (container_w - items_w) / item_count
		x = spacing / 2
	elseif align == 'space_between' then
		spacing = (container_w - items_w) / (item_count - 1)
		x = 0
	end
	return x, spacing
end

--align a line of items on the main axis.
local function align_items_main_axis(items, i, j, x, spacing, X, W, _MIN_W)
	for i = i, j do
		local layer = items[i]
		if layer.visible then
			local w = layer[_MIN_W]
			layer[X] = x
			layer[W] = w
			x = x + w + spacing
		end
	end
end

--flexbox layout -------------------------------------------------------------

local flexbox = object:subclass'flexbox_layout'
layer.layouts.flexbox = flexbox

flexbox.sync_layout = layer.sync_layout_separate_axes
flexbox.layout_axis_order = 'xy'

--container properties
layer.flex_axis = 'x' --'x', 'y'
layer.flex_wrap = false -- true, false
layer.align_lines = 'stretch' --space_between, space_around, space_evenly
layer.align_cross = 'stretch' --baseline
layer.align_main  = 'stretch' --space_between, space_around, space_evenly
	--^align_*: stretch, start/top/left, end/bottom/right, center

--item properties
layer.align_cross_self = false --overrides parent.align_cross
layer.fr = 1 --stretch fraction

--generate pairs of methods for vertical and horizontal flexbox layouts.
local function gen_funcs(X, Y, W, H, LEFT, RIGHT, TOP, BOTTOM)

	local L = LEFT:sub(1, 1)
	local R = RIGHT:sub(1, 1)
	local T = TOP:sub(1, 1)
	local B = BOTTOM:sub(1, 1)

	local CW = 'c'..W
	local CH = 'c'..H
	local PW = 'p'..W
	local PH = 'p'..H
	local _MIN_W = '_min_'..W
	local _MIN_H = '_min_'..H

	local function items_min_h(self, i, j)
		return items_max(self, i, j, _MIN_H)
	end

	local function linewrap_next(self, i)
		i = i + 1
		if i > #self then
			return
		elseif not self.flex_wrap then
			return #self, i
		end
		local wrap_w = self[CW]
		local line_w = 0
		for j = i, #self do
			local layer = self[j]
			if layer.visible then
				if j > i and layer.break_before then
					return j-1, i
				end
				if layer.break_after then
					return j, i
				end
				local item_w = layer[_MIN_W]
				if line_w + item_w > wrap_w then
					return j-1, i
				end
				line_w = line_w + item_w
			end
		end
		return #self, i
	end

	local function linewrap(self)
		return linewrap_next, self, 0
	end

	local function min_cw(self, other_axis_synced)
		if self.flex_wrap then
			return items_max(self, 1, #self, _MIN_W)
		else
			return items_sum(self, 1, #self, _MIN_W)
		end
	end

	local function min_ch(self, other_axis_synced)
		if not other_axis_synced and self.flex_wrap then
			--width-in-height-out parent layout requesting min_w on a y-axis
			--wrapping flexbox (which is a height-in-width-out layout).
			return 0
		end
		local lines_h = 0
		for j, i in linewrap(self) do
			local line_h = items_min_h(self, i, j)
			lines_h = lines_h + line_h
		end
		return lines_h
	end

	--stretch a line of items on the main axis.
	local function stretch_items_x(self, i, j)
		stretch_items_main_axis(self, i, j, self[CW], X, W, _MIN_W)
	end

	local function align_metrics_x(self, align, items_w, item_count)
		return align_metrics(align, self[CW], items_w, item_count,
			'start', 'end', LEFT, RIGHT, L, R)
	end

	local function align_metrics_y(self, align, items_w, item_count)
		return align_metrics(align, self[CH], items_w, item_count,
			'start', 'end', TOP, BOTTOM, T, B)
	end

	--align a line of items on the main axis.
	local function align_items_x(self, i, j)
		local items_w, items_count = items_sum(self, i, j, _MIN_W)
		local x, spacing =
			align_metrics_x(self, self.align_main, items_w, item_count)
		align_items_main_axis(self, i, j, x, spacing, X, W, _MIN_W)
	end

	--stretch or align a flexbox's items on the main-axis.
	local function align_x(self)
		for j, i in linewrap(self) do
			if self.align_main == 'stretch' then
				stretch_items_x(self, i, j)
			else
				align_items_x(self, i, j)
			end
		end
		return true
	end

	--align a line of items on the cross-axis.
	local function align_items_y(self, i, j, line_y, line_h)
		local align = self.align_cross
		for i = i, j do
			local layer = self[i]
			if layer.visible then
				local align = layer.align_cross_self or align
				if align == 'stretch' then
					layer[Y] = line_y
					layer[H] = line_h
				else
					local item_h = layer[_MIN_H]
					layer[H] = item_h
					if align == TOP or align == 'start' then
						layer[Y] = line_y
					elseif align == BOTTOM or align == 'end' then
						layer[Y] = line_y + line_h - item_h
					elseif align == 'center' then
						layer[Y] = line_y + (line_h - item_h) / 2
					end
					--[[
					--TODO: baseline
					elseif align == 'baseline' and Y == 'y' then
						local baseline = 0
						for _,layer in ipairs(self) do
							if layer.visible then
								local segs = layer._text_segments
								if segs then
									baseline = math.max(baseline, segs.lines.baseline or 0)
								end
							end
						end
						layer.y = lines_y + baseline
					end
					]]
				end
			end
		end
	end

	--stretch or align a flexbox's items on the cross-axis.
	local function align_y(self, other_axis_synced)
		if not other_axis_synced and self.flex_wrap then
			--trying to lay out the y-axis before knowing the x-axis:
			--dismiss and wait for the 3rd pass.
			return
		end
		local lines_y, line_spacing, line_h
		if self.align_lines == 'stretch' then
			local lines_h = self[CH]
			local line_count = 0
			for _ in linewrap(self) do
				line_count = line_count + 1
			end
			line_h = lines_h / line_count
			lines_y = 0
			line_spacing = 0
		else
			local lines_h = 0
			local line_count = 0
			for j, i in linewrap(self) do
				local line_h = items_min_h(self, i, j)
				lines_h = lines_h + line_h
				line_count = line_count + 1
			end
			lines_y, line_spacing =
				align_metrics_y(self, self.align_lines, lines_h, line_count)
		end
		local y = lines_y
		for j, i in linewrap(self) do
			local line_h = line_h or items_min_h(self, i, j)
			align_items_y(self, i, j, y, line_h)
			y = y + line_h + line_spacing
		end
		return true
	end

	flexbox['min_cw_'..X..'_axis'] = min_cw
	flexbox['min_ch_'..X..'_axis'] = min_ch
	flexbox['sync_layout_'..X..'_axis'..'_x'] = align_x
	flexbox['sync_layout_'..X..'_axis'..'_y'] = align_y
end
gen_funcs('x', 'y', 'w', 'h', 'left', 'right', 'top', 'bottom')
gen_funcs('y', 'x', 'h', 'w', 'top', 'bottom', 'left', 'right')

function flexbox:sync_min_w(other_axis_synced)

	--sync all children first (bottom-up sync).
	for _,layer in ipairs(self) do
		if layer.visible then
			layer:sync_min_w(other_axis_synced) --recurse
		end
	end

	local min_cw = self.flex_axis == 'x'
		and self:min_cw_x_axis(other_axis_synced)
		 or self:min_ch_y_axis(other_axis_synced)

	min_cw = math.max(min_cw, self.min_cw)
	local min_w = min_cw + self.pw
	self._min_w = min_w
	return min_w
end

function flexbox:sync_min_h(other_axis_synced)

	--sync all children first (bottom-up sync).
	for _,layer in ipairs(self) do
		if layer.visible then
			layer:sync_min_h(other_axis_synced) --recurse
		end
	end

	local min_ch = self.flex_axis == 'x'
		and self:min_ch_x_axis(other_axis_synced)
		 or self:min_cw_y_axis(other_axis_synced)

	min_ch = math.max(min_ch, self.min_ch)
	local min_h = min_ch + self.ph
	self._min_h = min_h
	return min_h
end

function flexbox:sync_layout_x(other_axis_synced)

	local synced = self.flex_axis == 'x'
			and self:sync_layout_x_axis_x(other_axis_synced)
			 or self:sync_layout_y_axis_y(other_axis_synced)

	if synced then
		--sync all children last (top-down sync).
		for _,layer in ipairs(self) do
			if layer.visible then
				layer:sync_layout_x(other_axis_synced) --recurse
			end
		end
	end
	return synced
end

function flexbox:sync_layout_y(other_axis_synced)

	local synced = self.flex_axis == 'y'
		and self:sync_layout_y_axis_x(other_axis_synced)
		 or self:sync_layout_x_axis_y(other_axis_synced)

	if synced then
		--sync all children last (top-down sync).
		for _,layer in ipairs(self) do
			if layer.visible then
				layer:sync_layout_y(other_axis_synced) --recurse
			end
		end
	end
	return synced
end

function flexbox:sync_window_view(w, h)
	self.min_cw = w - self.pw
	self.min_ch = h - self.ph
end

--grid layout ----------------------------------------------------------------

local grid = object:subclass'grid_layout'
layer.layouts.grid = grid

--container properties
layer.grid_cols = {} --{fr1, ...}
layer.grid_rows = {} --{fr1, ...}
layer.col_gap = 0
layer.row_gap = 0
layer.align_x = 'stretch'
layer.align_y = 'stretch'

--item properties
layer.align_x_self = false
layer.align_y_self = false

--grid_pos property parsing

local function parse(self, s)
	if not s then return end
	local pos, sep, span = s:match'([^/]*)([/]?)(.*)'
	if not pos then return end
	pos = pos ~= '' and tonumber(pos)
	span = sep == '/' and tonumber(span)
	if pos ~= nil and span ~= nil and (pos or span) then
		return pos, span
	end
end
function ui:_grid_pos(s)
	local row, col = s:match'([^%s]+)%s+([^%s]+)'
	local row, row_span = parse(self, row)
	local col, col_span = parse(self, col)
	local valid = row ~= nil and col ~= nil
	if self:check(valid, 'invalid grid_pos: "%s"', s) then
		return {row, col, row_span, col_span}
	end
end
ui:memoize'_grid_pos'

function ui:grid_pos(s)
	local t = s and self:_grid_pos(s)
	if not t then return end
	return t[1], t[2], t[3], t[3]
end

--auto-positioning algorithm

--container properties
layer.grid_flow = 'x' --x, y, xr, yr, xb, yb, xrb, yrb
layer.grid_wrap = 1

--item properties
layer.grid_pos = false --'[row][/span] [col][/span]'
layer.grid_row = false
layer.grid_col = false
layer.grid_row_span = false
layer.grid_col_span = false

local function clip_span(row1, col1, row_span, col_span, max_row, max_col)
	local row2 = row1 + row_span - 1
	local col2 = col1 + col_span - 1
	--clip the span to grid boundaries
	row1 = clamp(row1, 1, max_row)
	col1 = clamp(col1, 1, max_col)
	row2 = clamp(row2, 1, max_row)
	col2 = clamp(col2, 1, max_col)
	--support negative spans
	if row1 > row2 then
		row1, row2 = row2, row1
	end
	if col1 > col2 then
		col1, col2 = col2, col1
	end
	row_span = row2 - row1 + 1
	col_span = col2 - col1 + 1
	return row1, col1, row_span, col_span
end

local function mark_occupied(t, row1, col1, row_span, col_span)
	local row2 = row1 + row_span - 1
	local col2 = col1 + col_span - 1
	for row = row1, row2 do
		t[row] = t[row] or {}
		for col = col1, col2 do
			t[row][col] = true
		end
	end
end

local function check_occupied(t, row1, col1, row_span, col_span)
	local row2 = row1 + row_span - 1
	local col2 = col1 + col_span - 1
	for row = row1, row2 do
		if t[row] then
			for col = col1, col2 do
				if t[row][col] then
					return true
				end
			end
		end
	end
	return false
end

function layer:sync_layout_grid_autopos()

	local flow = self.grid_flow --[y][r][b]
	local col_first = not flow:find('y', 1, true)
	local row_first = not col_first
	local flip_cols = flow:find('r', 1, true)
	local flip_rows = flow:find('b', 1, true)
	local grid_wrap = math.max(1, self.grid_wrap)
	local max_col = col_first and grid_wrap or 0
	local max_row = row_first and grid_wrap or 0

	local occupied = {}

	--position explicitly-positioned layers first and mark occupied cells.
	--grow the grid bounds to include layers outside wrap_row and wrap_col.
	local missing_indices, negative_indices
	for _,layer in ipairs(self) do
		if layer.visible then

			local row, col, row_span, col_span = ui:grid_pos(layer.grid_pos)
			row = layer.grid_row or row
			col = layer.grid_col or col
			row_span = layer.grid_row_span or row_span or 1
			col_span = layer.grid_col_span or col_span or 1

			if row or col then --explicit position
				row = row or 1
				col = col or 1
				if row > 0 and col > 0 then
					row, col, row_span, col_span =
						clip_span(row, col, row_span, col_span, 1/0, 1/0)

					mark_occupied(occupied, row, col, row_span, col_span)

					max_row = math.max(max_row, row + row_span - 1)
					max_col = math.max(max_col, col + col_span - 1)
				else
					negative_indices = true --solve these later
				end
			else --auto-positioned
				--negative spans are treated as positive.
				row_span = math.abs(row_span)
				col_span = math.abs(col_span)

				--grow grid bounds on the main axis to fit the widest layer.
				if col_first then
					max_col = math.max(max_col, col_span)
				else
					max_row = math.max(max_row, row_span)
				end

				missing_indices = true --solve these later
			end

			layer._grid_row = row
			layer._grid_col = col
			layer._grid_row_span = row_span
			layer._grid_col_span = col_span
		end
	end

	--position explicitly-positioned layers with negative indices
	--now that we know the grid bounds. these types of spans do not enlarge
	--the grid bounds, but instead are clipped to it.
	if negative_indices then
		for _,layer in ipairs(self) do
			if layer.visible then
				local row = layer._grid_row
				local col = layer._grid_col
				if row < 0 or col < 0 then
					local row_span = layer._grid_row_span
					local col_span = layer._grid_col_span
					if row < 0 then
						row = max_row + row + 1
					end
					if col < 0 then
						col = max_col + col + 1
					end
					row, col, row_span, col_span =
						clip_span(row, col, row_span, col_span, max_row, max_col)

					mark_occupied(occupied, row, col, row_span, col_span)

					layer._grid_row = row
					layer._grid_col = col
					layer._grid_row_span = row_span
					layer._grid_col_span = col_span
				end
			end
		end
	end

	--auto-wrap layers with missing explicit indices over non-occupied cells.
	--grow grid bounds on the cross-axis if needed but not on the main axis.
	--these types of spans are never clipped to the grid bounds.
	if missing_indices then
		local row, col = 1, 1
		for _,layer in ipairs(self) do
			if layer.visible and not layer._grid_row then
				local row_span = layer._grid_row_span
				local col_span = layer._grid_col_span

				while true do
					--check for wrapping.
					if col_first and col + col_span - 1 > max_col then
						col = 1
						row = row + 1
					elseif row_first and row + row_span - 1 > max_row then
						row = 1
						col = col + 1
					end
					if check_occupied(occupied, row, col, row_span, col_span) then
						--advance cursor by one cell.
						if col_first then
							col = col + 1
						else
							row = row + 1
						end
					else
						break
					end
				end

				mark_occupied(occupied, row, col, row_span, col_span)

				layer._grid_row = row
				layer._grid_col = col

				--grow grid bounds on the cross-axis.
				if col_first then
					max_row = math.max(max_row, row + row_span - 1)
				else
					max_col = math.max(max_col, col + col_span - 1)
				end

				--advance cursor to right after the span, without wrapping.
				if col_first then
					col = col + col_span
				else
					row = row + row_span
				end
			end
		end
	end

	--reverse the order of rows and/or columns depending on grid_flow.
	if flip_rows or flip_cols then
		for _,layer in ipairs(self) do
			if layer.visible then
				if flip_rows then
					layer._grid_row = max_row
						- layer._grid_row
						- layer._grid_row_span
						+ 2
				end
				if flip_cols then
					layer._grid_col = max_col
						- layer._grid_col
						- layer._grid_col_span
						+ 2
				end
			end
		end
	end

	self._grid_flip_rows = flip_rows and true or false
	self._grid_flip_cols = flip_cols and true or false
	self._grid_max_row = max_row
	self._grid_max_col = max_col
end

--layouting algorithm

local function gen_funcs(X, Y, W, H, COL, LEFT, RIGHT)

	local L = LEFT:sub(1, 1)
	local R = RIGHT:sub(1, 1)
	local CW = 'c'..W
	local PW = 'p'..W
	local MIN_CW = 'min_'..CW
	local _MIN_W = '_min_'..W
	local SYNC_MIN_W = 'sync_min_'..W
	local SYNC_LAYOUT_X = 'sync_layout_'..X
	local COL_GAP = COL..'_gap'
	local COLS = 'grid_'..COL..'s'
	local ALIGN_X = 'align_'..X
	local _COLS = '_grid_'..COL..'s'
	local _MAX_COL = '_grid_max_'..COL
	local _COL = '_grid_'..COL
	local _COL_SPAN = '_grid_'..COL..'_span'
	local _FLIP_COLS = '_grid_flip_'..COL..'s'

	grid[SYNC_MIN_W] = function(self, other_axis_synced)

		--sync all children first (bottom-up sync).
		for _,layer in ipairs(self) do
			if layer.visible then
				layer[SYNC_MIN_W](layer, other_axis_synced) --recurse
			end
		end

		local gap_w = self[COL_GAP]
		local max_col = self[_MAX_COL]
		local fr = self[COLS] --{fr1, ...}

		--compute the fraction representing the total width.
		local total_fr = 0
		for _,layer in ipairs(self) do
			if layer.visible then
				local col1 = layer[_COL]
				local col2 = col1 + layer[_COL_SPAN] - 1
				for col = col1, col2 do
					total_fr = total_fr + (fr[col] or 1)
				end
			end
		end

		--create pseudo-layers to apply flexbox stretching to later.
		local max_col = self[_MAX_COL]
		local cols = {}
		for col = 1, max_col do
			cols[col] = {
				visible = true,
				fr = fr[col] or 1,
				[_MIN_W] = 0,
				[X] = false,
				[W] = false,
			}
		end
		self[_COLS] = cols

		--compute the minimum widths for each column.
		for _,layer in ipairs(self) do
			if layer.visible then
				local col1 = layer[_COL]
				local col2 = col1 + layer[_COL_SPAN] - 1
				local span_min_w = layer[_MIN_W]

				local gap_col1 =
					col2 == 1 and col2 == max_col and 0
					or (col2 == 1 or col2 == max_col) and gap_w * .5
					or gap_w
				local gap_col2 =
					col2 == 1 and col2 == max_col and 0
					or (col2 == 1 or col2 == max_col) and gap_w * .5
					or gap_w

				if col1 == col2 then
					local item = cols[col1]
					local col_min_w = span_min_w + gap_col1 + gap_col2
					item[_MIN_W] = math.max(item[_MIN_W], col_min_w)
				else --merged columns: unmerge
					local span_fr = 0
					for col = col1, col2 do
						span_fr = span_fr + (fr[col] or 1)
					end
					for col = col1, col2 do
						local item = cols[col]
						local col_min_w = (fr[col] or 1) / span_fr * span_min_w
						col_min_w = col_min_w
							+ (col == col1 and gap_col1 or 0)
							+ (col == col2 and gap_col2 or 0)
						item[_MIN_W] = math.max(item[_MIN_W], col_min_w)
					end
				end
			end
		end

		local min_cw = 0
		for _,item in ipairs(cols) do
			min_cw = min_cw + item[_MIN_W]
		end

		min_cw = math.max(min_cw, self[MIN_CW])
		local min_w = min_cw + self[PW]
		self[_MIN_W] = min_w
		return min_w
	end

	grid[SYNC_LAYOUT_X] = function(self, other_axis_synced)

		local cols = self[_COLS]
		local gap_w = self[COL_GAP]
		local container_w = self[CW]
		local align = self[ALIGN_X]

		local START, END = 'start', 'end'
		if self[_FLIP_COLS] then
			START, END = END, START
		end

		if align == 'stretch' then
			stretch_items_main_axis(cols, 1, #cols, container_w, X, W, _MIN_W)
		else
			local items_w, item_count = items_sum(cols, 1, #cols, _MIN_W)
			local x, spacing =
				align_metrics(align, self[CW], items_w, item_count,
					START, END, LEFT, RIGHT, L, R)
			align_items_main_axis(cols, 1, #cols, x, spacing, X, W, _MIN_W)
		end

		local x = 0
		for _,layer in ipairs(self) do
			if layer.visible then
				local col1 = layer[_COL]
				local col2 = col1 + layer[_COL_SPAN] - 1
				local col_item1 = cols[col1]
				local col_item2 = cols[col2]
				local x1 = col_item1[X]
				local x2 = col_item2[X] + col_item2[W]
				local gap1 = (col1 == 1 and 0 or gap_w * .5)
				local gap2 = (col2 == #cols and 0 or gap_w * .5)
				layer[X] = x1 + gap1
				layer[W] = x2 - x1 - gap2 - gap1
			end
		end

		--sync all children last (top-down sync).
		for _,layer in ipairs(self) do
			if layer.visible then
				layer[SYNC_LAYOUT_X](layer, other_axis_synced) --recurse
			end
		end
		return true
	end

end
gen_funcs('x', 'y', 'w', 'h', 'col', 'left', 'right')
gen_funcs('y', 'x', 'h', 'w', 'row', 'top', 'bottom')

grid.layout_axis_order = 'xy'
function grid:sync_layout()
	self:sync_layout_grid_autopos()
	self:sync_layout_separate_axes()
end

function grid:sync_window_view(w, h)
	self.min_cw = w - self.pw
	self.min_ch = h - self.ph
end

--top layer (window.view) ----------------------------------------------------

local view = layer:subclass'window_view'
window.view_class = view

--screen-wiping options that work with transparent windows
view.background_color = '#040404'
view.background_operator = 'source'

--parent layer interface

view.to_window = view.to_parent
view.from_window = view.from_parent

--sync the layout recursively after all children are sync'ed.
function view:after_sync()
	self:sync_window_view(self.window:client_size())
	self:sync_layout()
end

--widgets autoload -----------------------------------------------------------

ui:autoload{
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
	colorpicker  = 'ui_colorpicker',
	dropdown     = 'ui_dropdown',
}

return ui
