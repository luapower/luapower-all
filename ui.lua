
--Extensible UI toolkit in Lua.
--Written by Cosmin Apreutesei. Public Domain.

if not ... then DEMO=true; require'ui_demo'; return end

--pure-Lua libs.
local oo = require'oo'
local events = require'events'
local glue = require'glue'
local box2d = require'box2d'
local easing = require'easing'
local color = require'color'
--C bindings.
local ffi = require'ffi'
local nw = require'nw'
local time = require'time'
local cairo = require'cairo'
local boxblur = require'boxblur'
local tr = require'tr'

local zone = glue.noop
local zone = require'jit.zone' --enable for profiling

local min = math.min
local max = math.max
local abs = math.abs
local floor = math.floor
local ceil = math.ceil
local push = table.insert
local pop = table.remove

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
local binsearch = glue.binsearch
local index = glue.index

local function popval(t, v)
	local i = indexof(v, t)
	return i and pop(t, i)
end

local nilkey = {}
local function encode_nil(x) return x == nil and nilkey or x end
local function decode_nil(x) if x == nilkey then return nil end; return x; end

local function snap(x, enable)
	return enable and floor(x + .5) or x
end

local function snap_xw(x, w, enable)
	if not enable then return x, w end
	local x1 = floor(x + .5)
	local x2 = floor(x + w + .5)
	return x1, x2 - x1
end

local function snap_up(x, enable)
	return enable and ceil(x) or x
end

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
	--This optimization prevents overriding of getters/setters on instances.
	self.__setters = self.__setters
	self.__getters = self.__getters
end

--error reporting ------------------------------------------------------------

function object:warn(...)
	io.stderr:write(string.format(...))
	io.stderr:write(debug.traceback())
	io.stderr:write'\n'
end

function object:check(ret, ...)
	if ret then return ret end
	self:warn(...)
end

--method and property decorators ---------------------------------------------

--generic method memoizer that can memoize getters and setters too.
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

--install event handlers in `object` that forward events to self.
function object:forward_events(object, event_names)
	for event in pairs(event_names) do
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

--forward method calls to a sub-component.
function object:forward_methods(component_name, methods)
	for method, wrap in pairs(methods) do
		self[method] = function(self,...)
			local e = self[component_name]
			return wrap(e[method](e, ...))
		end
	end
end

--create a property which reads/writes to/from a sub-component's property.
function object:forward_property(prop, sub, readonly)
	assert(not self.__getters[prop])
	local sub, sub_prop = sub:match'^(.-)%.(.*)$'
	self['get_'..prop] = function(self)
		return self[sub][sub_prop]
	end
	if not readonly then
		self['set_'..prop] = function(self, value)
			self[sub][sub_prop] = value
		end
	end
end

function object:forward_properties(sub, prefix, t)
	if not t then sub, prefix, t = sub, '', prefix end
	for prop, sub_prop in pairs(t) do
		sub_prop = type(sub_prop) == 'string' and sub_prop or prop
		self:forward_property(prefix..prop, sub..'.'..sub_prop)
	end
end

--create a r/w property which reads/writes to/from a private field.
function object:stored_property(prop, after_set)
	assert(not self.__getters[prop])
	local priv = '_'..prop
	self['get_'..prop] = function(self)
		return self[priv]
	end
	if after_set then
		self['set_'..prop] = function(self, val)
			local val = val or false
			self[priv] = val
			after_set(self, val)
		end
	else
		self['set_'..prop] = function(self, val)
			self[priv] = val or false
		end
	end
end

function object:stored_properties(t, after_set)
	for k in pairs(t) do
		self:stored_property(k, after_set and after_set(k))
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

--validate a property when being set against a list of allowed values.
function object:enum_property(prop, values)
	if type(values) == 'string' then --'val1 ...'
		local s = values
		values = {}
		for val in s:gmatch'[^%s]+' do
			values[val] = val
		end
	end
	local keys = index(values)
	self:override('set_'..prop, function(self, inherited, key)
		local val = values[key]
		if self:check(val, 'invalid value "%s" for %s', key, prop) then
			inherited(self, val)
		end
	end)
	self:override('get_'..prop, function(self, inherited)
		return keys[inherited(self)]
	end)
end

--submodule autoloading ------------------------------------------------------

function object:autoload(autoload)
	for prop, submodule in pairs(autoload) do
		local getter = 'get_'..prop
		local setter = 'set_'..prop
		self[getter] = function(self)
			self.super[getter] = nil
			--^remove getter to allow a class default to be set instead.
			require(submodule)
			return self[prop]
		end
	end
end

--module object --------------------------------------------------------------

local ui = object:subclass'ui'
ui.object = object

function ui:override_create(inherited, ...) --singleton
	local instance = inherited(self, ...)
	function self:create() return instance end
	return instance
end

function ui:after_init()
	self.app = nw:app()

	self:forward_events(self.app, {
		quitting=1,
		activated=1, deactivated=1, wakeup=1,
		hidden=1, unhidden=1,
		displays_changed=1,
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
function ui:get_app_id(id)         return nw.app_id end
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
function ui.inherited(self, attr)
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

function tran:interpolate_function(attr)
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
	self.interpolate = self:interpolate_function(self.attr)
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
	if t > 1 and self.times > 1 then --repeat in opposite direction
		self.times = self.times - 1
		self.start = clock + self.delay
		self.from, self.to = self.to, self.from
		if not self.repeated then
			self.to = self.backval
			self.repeated = true
		end
		return self:update(clock)
	end
	return t
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
	self._elements = {} --{elem -> true}
	self._element_index = self:element_index()
end

function ui:_add_element(elem)
	self._elements[elem] = true
	self._element_index:add_element(elem)
end

function ui:_remove_element(elem)
	self._elements[elem] = nil
	self._element_index:remove_element(elem)
end

function ui:_find_elements(sel, elems)
	local res = self:element_list()
	if elems then
		for _,elem in ipairs(elems) do
			if sel:selects(elem) then
				push(res, elem)
			end
		end
	else
		for elem in pairs(self._elements) do
			if sel:selects(elem) then
				push(res, elem)
			end
		end
	end
	return res
end

function ui.element_list:each(f)
	for _,elem in ipairs(self) do
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

--override the element constructor so that it can take multiple init-table
--args but present init() with a single init table that also contains
--class defaults for virtual properties, and a single array table that
--adds together the array parts of all the init tables. also, make the
--constructor work with different call styles, see below.
function element:override_create(inherited, ...)

	local ui = ...
	local parent
	local arg1
	if ui.isui then --called as `ui:<element>{}`
		arg1 = 2
	elseif ui.iselement then --called as `parent:<element>{}`
		arg1 = 2
		parent = ui
		ui = parent.ui
	else --called as `<element>{}`, infer `ui` from the `parent` field.
		arg1 = 1
		ui = nil
	end

	local dt = {} --hash part
	local at --array part

	--statically inherit class defaults for writable properties, to be set by
	--init_fields() if if they were user-supplied.
	--NOTE: adding more default values to the class after the first
	--instantiation has no effect on further instantiations because we make
	--a shortlist of only the properties that have defaults.
	local wt = rawget(self, '__writable_props_with_defaults')
	if not wt then
		wt = {}
		self.__writable_props_with_defaults = wt --make a shortlist
		local setters = self.__setters
		while setters do
			for k in pairs(setters) do --prop has a setter
				if self[k] ~= nil then --prop has a class default
					push(wt, k)
				end
			end
			setters = setters.__index
		end
	end
	for _,k in ipairs(wt) do
		dt[k] = self[k]
	end

	for i = arg1, select('#', ...) do
		local t = select(i, ...)
		if t then
			for k,v in pairs(t) do
				if type(k) == 'number' and floor(k) == k then --array part
					at = at or {}
					push(at, v)
				else --hash part
					dt[k] = v
				end
			end
		end
	end

	parent = dt.parent or parent
	if not ui and parent then
		ui = parent.ui
	end
	dt.ui = ui
	dt.parent = parent
	assert(ui, 'ui arg missing')

	--dynamically inherit class defaults for plain fields, to be applied
	--manually in overrides of init().
	setmetatable(dt, {__index = self})

	return inherited(self, dt, at)
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

function element:after_init(t)
	self.ui = t.ui
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
	self.tags = {}
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

function element:settag(tag, op, next_frame)
	local had_tag = self.tags[tag]
	if op == '~' then
		self.tags[tag] = not had_tag
		self._styles_valid = false
		self:invalidate(next_frame)
	elseif op and not had_tag then
		self.tags[tag] = true
		self._styles_valid = false
		self:invalidate(next_frame)
	elseif not op and had_tag then
		self.tags[tag] = false
		self._styles_valid = false
		self:invalidate(next_frame)
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
function element:end_value(attr, val)
	local tr = self.transitions
	local tran = tr and tr[attr]
	if tran then
		while tran.next_transition do
			tran = tran.next_transition
		end
	end
	if val == nil then --get
		if tran then
			return tran.end_value
		else
			return self[attr]
		end
	else --set
		if tran then
			tran.end_value = val
		else
			self[attr] = val
		end
	end
end

element.blend_transition = {}

function element.blend_transition:replace(
	tran, attr, cur_val, end_val, cur_end_val,
	duration, ease, delay, times, backval, start_val, clock
)
	if duration <= 0 and delay <= 0 then
		--instant transition: set the value immediately.
		if end_val ~= cur_val then
			self[attr] = end_val
			self:invalidate(true)
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
			times = times, backval = backval, from = start_val, clock = clock,
		}
	end
end

function element.blend_transition:replace_value(
	tran, attr, cur_val, end_val, cur_end_val,
	duration, ease, delay, times, backval, start_val, clock
)
	if tran then
		--update the current transition.
		tran.end_value = end_val
		tran.to = end_val
		return tran
	elseif duration <= 0 and delay <= 0 then
		--instant transition: set the value immediately.
		if end_val ~= cur_val then
			self[attr] = end_val
			self:invalidate(true)
		end
		return nil --stop the current transition if any.
	else
		if start_val == nil then
			start_val = cur_val
		end
		return self.ui:transition{
			elem = self, attr = attr, to = end_val,
			duration = duration, ease = ease, delay = delay,
			times = times, backval = backval, from = start_val, clock = clock,
		}
	end
end

function element.blend_transition:restart(
	tran, attr, cur_val, end_val, cur_end_val,
	duration, ease, delay, times, backval, start_val, clock
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
			times = times, backval = backval, from = start_val, clock = clock,
		}
	end
end

function element.blend_transition:wait(
	tran, attr, cur_val, end_val, cur_end_val,
	duration, ease, delay, times, backval, start_val, clock
)
	if end_val == cur_end_val then
		--same end value: continue with the current transition if any.
		return tran
	else
		local new_tran = self.ui:transition{
			elem = self, attr = attr, to = end_val,
			duration = duration, ease = ease, delay = delay,
			times = times, backval = backval, from = cur_end_val, clock = clock,
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

element.transition_x = false
element.transition_y = false

local function transition_args(t,
	attr, val, duration, ease, delay,
	times, backval, blend, speed, from, clock
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
	, t.clock or clock
end

function element:transition(
	attr, val, duration, ease, delay,
	times, backval, blend, speed, from, clock
)
	if type(attr) == 'table' then
		attr, val, duration, ease, delay,
		times, backval, blend, speed, from, clock =
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

	local cur_tran = self.transitions and self.transitions[attr] or nil
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
		duration, ease, delay, times, backval, from, clock
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
		self:invalidate(true)
	end
end

function element:sync_transitions()
	local tr = rawget(self, 'transitions')
	if not tr or not next(tr) then return end
	for attr, tran in pairs(tr) do
		local t = tran:update(self.clock)
		if t < 0 then --not started, wait for it
			self:invalidate(tran.start)
		elseif t > 1 then --finished, replace it
			local tran = tran.next_transition
			tr[attr] = tran
			if tran then
				self:invalidate(tran.start)
			end
		else --running, invalidate the next frame!
			self:invalidate(true)
		end
	end
end

function element:transitioning(attr)
	return self.transitions and self.transitions[attr]
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

function window:override_init(inherited, t)
	local show_it
	local win = t.native_window
	local parent = t.parent
	if parent and parent.iswindow then
		parent = parent.view
	end
	self.ui = t.ui
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
			self:free()
		end

		--Move window to preserve its relative position to parent if the parent
		--changed its relative position to its own window. Moving this window
		--when the parent's window is moved is automatic (`sticky` flag).
		local px0, py0 = parent:to_window(0, 0)
		function parent.before_sync()
			if self.dead then return end
			local px1, py1 = parent:to_window(0, 0)
			local dx = px1 - px0
			local dy = py1 - py0
			if dx ~= 0 or dy ~= 0 then
				local x0, y0 = self.native_window:frame_rect()
				self.native_window:frame_rect(x0 + dx, y0 + dy)
				px0, py0 = px1, py1
			end
		end

	end

	inherited(self, t)

	self:forward_events(win, {
		activated=1, deactivated=1, wakeup=1,
		shown=1, hidden=1,
		minimized=1, unminimized=1,
		maximized=1, unmaximized=1,
		entered_fullscreen=1, exited_fullscreen=1,
		changed=1,
		sizing=1,
		frame_rect_changed=1, frame_moved=1, frame_resized=1,
		client_moved=1, client_resized=1,
		magnets=1,
		free_cairo=1, free_bitmap=1,
		scalingfactor_changed=1,
		--TODO: dispatch to widgets: 'dropfiles', 'dragging',
	})

	self.clock = self.ui:clock()

	self.mouse_x = win:mouse'x' or false
	self.mouse_y = win:mouse'y' or false

	local function setcontext()
		self.clock = self.ui:clock()
		self.bitmap = win:bitmap()
		self.cr = self.bitmap:cairo()
	end

	self.setcontext = setcontext

	local function setmouse(mx, my)
		setcontext()
		local moved = self.mouse_x ~= mx or self.mouse_y ~= my
		if moved then
			self.mouse_x = mx
			self.mouse_y = my
		end
		return moved
	end

	if win:frame() == 'none' then

		win:on({'hittest', self}, function(win, mx, my, where)
			if setmouse(mx, my) then
				self.ui:_window_mousemove(self, mx, my)
			end
			local hw = self.ui.hot_widget
			if hw and hw ~= self.view then
				return false --cancel test
			end
			return self:fire('hittest', mx, my, where)
		end)

	else

		win:on({'mousemove', self}, function(win, mx, my)

			if setmouse(mx, my) then
				self.ui:_window_mousemove(self, mx, my)
			end
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
		if setmouse(mx, my) then
			self.ui:_window_mousemove(self, mx, my)
		end
		self['mouse_'..button] = true
		self.ui:_window_mousedown(self, button, mx, my, click_count)
	end)

	win:on({'click', self}, function(win, button, count, mx, my)
		return self.ui:_window_click(self, button, count, mx, my)
	end)

	win:on({'mouseup', self}, function(win, button, mx, my, click_count)
		if setmouse(mx, my) then
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

		if setmouse(mx, my) then
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

	self._user_cw = false
	self._user_ch = false
	self.sync_count = 0
	win:on({'sync', self}, function(win)
		self:sync()
	end)

	win:on({'repaint', self}, function(win)
		setcontext()
		self:draw(self.cr)
		if self.mouse_x then
			self.ui:_window_mousemove(self, self.mouse_x, self.mouse_y)
		end
	end)

	win:on({'client_resized', self}, function(win, cw, ch)
		if not cw then return end --hidden or minimized
		self._cw = cw
		self._ch = ch
	end)

	self._cw, self._ch = win:client_size()

	win:on({'sizing', self}, function(win, when, how, t)
		if how == 'move' then return end
		if not t then return end
		local cw, ch = win:client_size()
		local _, _, w, h = win:frame_rect()
		local dw = w - cw
		local dh = h - ch
		local cw, ch = t.w - dw, t.h - dh
		self._user_cw = false
		self._user_ch = false
		self:sync_size(cw, ch)
		local cw, ch = self.view:size()
		t.w = math.max(t.w, cw + dw)
		t.h = math.max(t.h, ch + dh)
	end)

	win:on({'closing', self}, function(win, reason, closing_win, ...)
		closing_win = closing_win and closing_win.ui_window
		return self:fire('closing', reason, closing_win, ...)
	end)

	win:on({'closed', self}, function(win)
		self:fire('closed')
		self:free()
	end)

	self:on('activated', function(self)
		if self.focused_widget then
			self.focused_widget:settag(':window_active', true)
			self.focused_widget:fire'window_activated'
		end
	end)

	self:on('deactivated', function(self)
		if self.focused_widget then
			self.focused_widget:settag(':window_active', false)
			self.focused_widget:fire'window_deactivated'
		end
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

function window:override_free(inherited)
	if self.dead then return end
	local win = self.native_window
	win:off{nil, self}
	win.ui_window = false
	self.view:free()
	self.view = false
	self.native_window = false
	if self.own_native_window then
		win:close()
	end
	self._parent = false
	self.ui.windows[self] = nil
	inherited(self)
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

function window:client_size(cw, ch)
	if cw or ch then
		if self:isinstance() then
			self.native_window:client_size(cw or self._cw, ch or self._ch)
			self._cw, self._ch = self.native_window:client_size()
		else
			if cw then self._cw = cw end
			if ch then self._ch = ch end
		end
	else
		return self._cw, self._ch
	end
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
function window:get_cw() return self._cw end
function window:get_ch() return self._ch end
function window:set_cx(cx) self:client_rect(cx, nil, nil, nil) end
function window:set_cy(cy) self:client_rect(nil, cy, nil, nil) end
function window:set_cw(cw) self:client_rect(nil, nil, cw, nil) end
function window:set_ch(ch) self:client_rect(nil, nil, nil, ch) end

function window:minsize(...) return self.native_window:minsize(...) end
function window:maxsize(...) return self.native_window:maxsize(...) end

function window:get_min_cw() return (select(1, self.native_window:minsize())) end
function window:get_min_ch() return (select(2, self.native_window:minsize())) end
function window:get_max_cw() return (select(1, self.native_window:maxsize())) end
function window:get_max_ch() return (select(2, self.native_window:maxsize())) end
function window:set_min_cw(cw) self.native_window:minsize(cw, nil) end
function window:set_min_ch(ch) self.native_window:minsize(nil, ch) end
function window:set_max_cw(cw) self.native_window:maxsize(cw, nil) end
function window:set_max_ch(ch) self.native_window:maxsize(nil, ch) end

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
	closeable=0, activable=0, minimizable=0, maximizable=0, resizeable=0,
	fullscreenable=0, frame=0, transparent=0, corner_radius=0, sticky=0,
}
for prop, writable in pairs(props) do
	local priv = '_'..prop
	window['get_'..prop] = function(self)
		local nwin = self.native_window
		return nwin[prop](nwin)
	end
	if writable == 1 then
		window['set_'..prop] = function(self, value)
			local nwin = self.native_window
			nwin[prop](nwin, value)
		end
	end
end

--methods
function window:close(force)  self.native_window:close(force) end
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
	local sel = self.ui:selector(sel):filter(function(elem)
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
			if self.hot_area then
				widget:settag(':hot_'..self.hot_area, false)
			end
			self.hot_area = area
			if widget then
				window.cursor = widget:getcursor(area)
				widget:settag(':hot_'..area, true)
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

	if self.active_widget then
		self.active_widget:_mousemove(mx, my, self.hot_area)
	else
		local hit_widget, hit_area = window:hit_test(mx, my, 'activate')
		self:_set_hot_widget(window, hit_widget, mx, my, hit_area)
		if hit_widget and hit_widget.enabled then
			hit_widget:_mousemove(mx, my, hit_area)
		end
	end

	if self.drag_widget then
		self.drag_widget:_drag(mx, my)
		local widget, area = window:hit_test(mx, my, 'drop')
		if widget then
			if not self:accept_drop(self.drag_widget, widget, mx, my, area) then
				widget = nil
			end
		end
		if self.drop_widget ~= (widget or false) then
			if self.drop_widget then
				self.drag_widget:_leave_drop_target(self.drop_widget)
				self.drop_widget:_drag_leave(self.drag_widget)
				self.drop_widget = false
				self.drop_area = false
			end
			if widget then
				self.drag_widget:_enter_drop_target(widget, area)
				widget:_drag_enter(self.drag_widget, area)
				self.drop_widget = widget
				self.drop_area = area
			end
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
		self:_set_hot_widget(window, false)
	end
end

function ui:_widget_mousemove(widget, mx, my, area)
	if not self.drag_widget and widget == self.drag_start_widget then
		--TODO: make this diff. in window space!
		local dx = abs(self.drag_mx - mx)
		local dy = abs(self.drag_my - my)
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

	local widget = self.active_widget or self.hot_widget
	if widget then
		widget:_mousedown(button, mx, my, self.hot_area)
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
		return self.active_widget:_click(button, count, mx, my, self.hot_area)
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
	if widget.draggable_area and widget.draggable_area ~= area then return end
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

	--trigger mouseup before finishing dragging so that self.dragging is
	--available for differentiating a drag from a click.
	local widget = self.active_widget or self.hot_widget
	if widget then
		widget:_mouseup(button, mx, my, self.hot_area)
	end

	if self.drag_button == button then
		if self.drag_widget then
			if self.drop_widget then
				self.drop_widget:_drop(self.drag_widget, mx, my, self.drop_area)
				self.drag_widget:settag(':dropping', false)
			end
			self.drag_widget:_ended_dragging()
			self.drag_start_widget:_end_drag()
			for elem in pairs(self._elements) do
				if elem.islayer and elem.tags[':drop_target'] then
					elem:settag(':drop_target', false)
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
		if widget:fire(event_name, key) then
			return true
		end
		if widget.iswindow then
			break --don't forward key presses from a child window to its parent.
		end
		if event_name == 'keypress' then
			if widget:keypress_text(key) then
				return true
			end
		elseif event_name == 'keychar' then
			if widget:keychar_text(key) then
				return true
			end
		end
		widget = widget.parent
	until not widget
end


--window sync'ing & rendering ------------------------------------------------

function window:sync()
	local cw = self._user_cw
	local ch = self._user_ch
	if not cw then
		cw, ch = self:client_size()
	end
	self:sync_size(cw, ch)
	--enlarge the window to contain the view.
	local vw, vh = self.view:size()
	if vw > cw or vh > ch then
		self._user_cw = cw
		self._user_ch = ch
		cw = math.max(cw, vw)
		ch = math.max(ch, vh)
		self:client_size(cw, ch)
	end
end

function window:sync_size(cw, ch)
	self:setcontext()
	self.syncing = true
	self.sync_count = self.sync_count + 1
	self.cr:save()
	self.cr:new_path()
	self.view:sync_with_window(cw, ch)
	self.cr:restore()
	self.syncing = false
	self:check(not self:invalid(), 'invalid after sync()')
end

function window:draw(cr)
	cr:save()
	cr:new_path()
	self.view:draw(cr)
	cr:restore()
	if cr:status() ~= 0 then --see if cairo didn't shutdown
		self:warn(cr:status_message())
	end
end

function window:invalidate(invalid_clock) --element interface; window intf.
	if invalid_clock == true then --animation
		invalid_clock = self.clock + 1/1000
	end
	if self.syncing then
		if (invalid_clock or -1/0) < self.clock then
			self:warn'invalidate() called inside sync()'
			print(debug.traceback())
		end
	end
	self.native_window:invalidate(invalid_clock)
end

function window:invalid()
	return self.native_window:invalid(self.clock)
end

function window:validate()
	self.native_window:validate(self.clock)
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

local double_array = ffi.typeof'double[?]'
function ui:_dash(dashes)
	return double_array(#dashes, dashes)
end
ui:memoize'_dash'
function ui:dash(dashes, offset)
	if not dashes then return false, 0 end
	return self:_dash(dashes), #dashes, offset
end

function ui:open_file(file)
	local bundle = require'bundle'
	return self:check(bundle.fs_open(file), 'file not found: "%s"', file)
end

function ui:image_pattern(file)
	local ext = file:match'%.([^%.]+)$'
	if ext == 'jpg' or ext == 'jpeg' then
		local libjpeg = require'libjpeg'
		local f = self:open_file(file)
		if not f then return end
		local bufread = f:buffered_read()
		local function read(buf, sz)
			return self:check(bufread(buf, sz))
		end
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

ui.use_default_fonts = true
ui.default_fonts_path = 'media/fonts'

function ui:add_default_fonts(dir)
	local dir = self.default_fonts_path
	--$ mgit clone fonts-open-sans
	self:add_font_file(dir..'/OpenSans-Regular.ttf', 'Open Sans')
	--$ mgit clone fonts-ionicons
	self:add_font_file(dir..'/ionicons.ttf', 'Ionicons')
end

ui.use_google_fonts = false
ui.google_fonts_path = 'media/fonts/gfonts'

--add a font searcher for the google fonts repository.
--for this to work you need to get the fonts:
--$ git clone https://github.com/google/fonts media/fonts/gfonts
function ui:add_gfonts_searcher()
	local gfonts = require'gfonts'
	gfonts.root_dir = self.google_fonts_path
	local function find_font(font_db, name, weight, slant)
		local file, real_weight = gfonts.font_file(name, weight, slant, true)
		local font = file and self:add_font_file(file, name, real_weight, slant)
		return font, real_weight
	end
	push(self.tr.rs.font_db.searchers, find_font)
end

function ui:after_init()
	self.tr = tr()

	--use our own overridable rgba parser.
	function self.tr.rs.rgba(c)
		return self:rgba(c)
	end

	if self.use_default_fonts then
		self:add_default_fonts()
	end
	if self.use_google_fonts then
		self:add_gfonts_searcher()
	end
end

function ui:before_free()
	self.tr:free()
	self.tr = false
end

--layers ---------------------------------------------------------------------

local layer = element:subclass'layer'
ui.layer = layer

layer.visible = true
layer.enabled = true
layer.activable = true --can be clicked and set as hot
layer.vscrollable = false --enable mouse wheel when hot
layer.hscrollable = false --enable mouse horiz. wheel when hot
layer.focusable = false --can be focused
layer.draggable = false --can be dragged
layer.draggable_area = false --area that dragging can be initiated from
layer.drag_group = false
layer.accept_drag_groups = {} --{drag_group->true|area}
layer.drag_hit_mode = 'bbox' --'bbox', 'shape', 'pointer'
layer.mousedown_activate = false --activate/deactivate on left mouse down/up

ui:style('layer !:enabled', {
	background_color = '#222',
	text_color = '#666',
	text_selection_color = '#6663',
})

ui:style('layer :drop_target', {
	background_color = '#2048',
})

ui:style('layer :drag_over', {
	border_width = 1,
	border_color = '#90f',
	border_dash = {4, 2},
})

layer.cursor = false  --false or cursor name from nw

layer.drag_threshold = 0 --moving distance before start dragging
layer.click_chain       = 1 --2 for doubleclick events, etc.
layer.rightclick_chain  = 1 --2 for rightdoubleclick events, etc.
layer.middleclick_chain = 1 --2 for middledoubleclick events, etc.

layer:init_ignore{parent=1, layer_index=1, enabled=1, layers=1, class=1}
layer.tags = ':enabled'

function layer:after_init(t, array_part)
	--setting parent after _enabled updates the `enabled` tag only once!
	--setting layer_index before parent inserts the layer at its index directly.
	local enabled = t.enabled and true or false
	if enabled ~= self._enabled then
		self._enabled = enabled
	end
	self.layer_index = t.layer_index
	self.parent = t.parent

	--create and/or attach child layers
	if array_part then
		for _,layer in ipairs(array_part) do
			if type(layer) == 'string' then
				layer = {text = layer}
			end
			if not layer.islayer then
				local class = layer.class or self.super
				if type(class) == 'string' then --look-up a built-in class
					class = self.ui:check(self.ui[class], 'invalid class: "%s"', class)
				end
				layer = class(self.ui, self[layer.class], layer)
			end
			assert(layer.islayer)
			layer.parent = self
		end
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
	self.parent = false
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
layer.scale_cx = 0
layer.scale_cy = 0
layer.snap_x = true --snap to pixels on x-axis
layer.snap_y = true --snap to pixels on y-axis

function layer:snapx(x) return snap(x, self.snap_x) end
function layer:snapy(y) return snap(y, self.snap_y) end
function layer:snapxw(x, w) return snap_xw(x, w, self.snap_x) end
function layer:snapyh(y, h) return snap_xw(y, h, self.snap_y) end
function layer:snapcx(cx) return snap(cx-self.cx, self.snap_x)+self.cx end
function layer:snapcy(cy) return snap(cy-self.cy, self.snap_y)+self.cy end

local mt = cairo.matrix()
function layer:rel_matrix() --box matrix relative to parent's content space
	mt:reset():translate(self:snapx(self.x), self:snapy(self.y))
	local rot = self.rotation
	if rot ~= 0 then
		mt:rotate_around(self.rotation_cx, self.rotation_cy, math.rad(rot))
	end
	local scale = self.scale
	if scale ~= 1 then
		mt:scale_around(self.scale_cx, self.scale_cy, self.scale)
	end
	return mt
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

--bounding box of a rectangle in another layer's content box.
function layer:rect_bbox_in(other, x, y, w, h)
	local x1, y1 = self:to_other(other, x,     y)
	local x2, y2 = self:to_other(other, x + w, y)
	local x3, y3 = self:to_other(other, x,     y + h)
	local x4, y4 = self:to_other(other, x + w, y + h)
	local bx1 = min(x1, x2, x3, x4)
	local bx2 = max(x1, x2, x3, x4)
	local by1 = min(y1, y2, y3, y4)
	local by2 = max(y1, y2, y3, y4)
	return bx1, by1, bx2 - bx1, by2 - by1
end

--bounding box of a list of points in another layer's content box.
function layer:points_bbox_in(other, t) --t: {x1, y1, x2, y2, ...}
	local n = #t
	assert(n >= 2 and n % 2 == 0)
	local x1, y1, x2, y2 = 1/0, 1/0, -1/0, -1/0
	for i = 1, n, 2 do
		local x, y = t[i], t[i+1]
		local x, y = self:to_other(other, x, y)
		x1 = min(x1, x)
		y1 = min(y1, y)
		x2 = max(x2, x)
		y2 = max(y2, y)
	end
	return x1, y1, x2-x1, y2-y1
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
		if self.hot then
			self.ui.hot_widget = false
		end
		if self.active then
			self.ui.active_widget = false
		end
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
	self:fire('layer_moved', new_index, old_index)
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

function layer:remove_layer(layer) --parent interface
	assert(layer._parent == self)
	self:off({nil, layer})
	popval(self, layer)
	self:fire('layer_removed', layer)
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

layer.text_active = false

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
	self:fire('mousemove_'..area, mx, my)
	self.ui:_widget_mousemove(self, mx, my, area)
end

function layer:_mouseenter(mx, my, area)
	local mx, my = self:from_window(mx, my)
	self:settag(':hot', true)
	self:settag(':hot_'..area, true)
	self:fire('mouseenter', mx, my, area)
	self.window:_settooltip(self.tooltip)
end

function layer:_mouseleave()
	self.window:_settooltip(false)
	self:fire'mouseleave'
	local area = self.ui.hot_area
	self:settag(':hot', false)
	self:settag(':hot_'..area, false)
end

function layer:_mousedown(button, mx, my, area)
	local mx, my = self:from_window(mx, my)
	local event = button == 'left' and 'mousedown' or button..'mousedown'
	if self.mousedown_activate then
		self.active = true
	end
	self:fire(event, mx, my, area)
	self:fire(event..'_'..area, mx, my)
	self.ui:_widget_mousedown(self, button, mx, my, area)
end

function layer:_mouseup(button, mx, my, area)
	local mx, my = self:from_window(mx, my)
	local event = button == 'left' and 'mouseup' or button..'mouseup'
	self:fire(event, mx, my, area)
	self:fire(event..'_'..area, mx, my)
	if self.ui and self.active and self.mousedown_activate then
		self.active = false
	end
end

layer.click_chain_text = 3

function layer:_click(button, count, mx, my, area)
	local mx, my = self:from_window(mx, my)
	local event =
		count == 1 and 'click'
		or count == 2 and 'doubleclick'
		or count == 3 and 'tripleclick'
		or count == 4 and 'quadrupleclick'
	local event = button == 'left' and event or button..event
	self:fire(event, mx, my, area)
	self:fire(event..'_'..area, mx, my)
	local cc1 = (button == 'left' and '' or button)..'click_chain'
	local cc2 = area and cc1..'_'..area
	local click_chain = cc2 and self[cc2] or self[cc1]
	if count >= click_chain then
		return true --stop the click chain
	end
end

function layer:_mousewheel(delta, mx, my, area, pdelta)
	self:fire('mousewheel', delta, mx, my, area, pdelta)
	self:fire('mousewheel_'..area, delta, mx, my, pdelta)
end

--called on a potential drop target widget to accept the dragged widget.
function layer:_accept_drag_widget(widget, mx, my, area)
	if mx then
		mx, my = self:from_window(mx, my)
	end
	return self:accept_drag_widget(widget, mx, my, area)
end

--return true to accept a dragged widget. if mx/my/area are nil
--then return true if there's at least one area that would accept the widget.
function layer:accept_drag_widget(widget, mx, my, area)
	local accept_area = self.accept_drag_groups[widget.drag_group]
	return accept_area and (accept_area == true or accept_area == area)
end

--called on the dragged widget to accept a potential drop target widget.
function layer:accept_drop_widget(widget, area) return true; end

--called on the dragged widget once upon entering a new drop target.
function layer:_enter_drop_target(widget, area)
	self:settag(':dropping', true)
	self:fire('enter_drop_target', widget, area)
end

--called on the dragged widget once upon leaving a drop target.
function layer:_leave_drop_target(widget)
	self:fire('leave_drop_target', widget)
	self:settag(':dropping', false)
end

--called on the drop target when the dragged widget enters it.
function layer:_drag_enter(widget, area)
	self:settag(':drag_over', true)
	self:fire('drag_enter', widget, area)
end

--called on the drop target when the dragged widget leaves it.
function layer:_drag_leave(widget)
	self:settag(':drag_over', false)
	self:fire('drag_leave', widget)
end

layer.dragging = false

--called on the dragged widget when dragging starts.
function layer:_started_dragging()
	self.dragging = true
	self.ui.dragged_widget = self
	self:settag(':dragging', true)
	self:fire'started_dragging'
end

--called on the dragged widget when dragging ends.
function layer:_ended_dragging()
	self.dragging = false
	self.ui.dragged_widget = false
	self:settag(':dragging', false)
	self:fire'ended_dragging'
end

function layer:_set_drop_target(drag_widget)
	if self.visible and self.enabled then
		if self.ui:accept_drop(drag_widget, self) then
			self:settag(':drop_target', true)
		end
		for _,layer in ipairs(self) do
			layer:_set_drop_target(drag_widget)
		end
	end
end

--called on drag_start_widget to initiate a drag operation.
function layer:_start_drag(button, mx, my, area)
	local widget, dx, dy = self:start_drag(button, mx, my, area)
	if widget then
		self:settag(':drag_source', true)
		for win in pairs(self.ui.windows) do
			if win.visible then
				win.view:_set_drop_target(widget)
			end
		end
		widget:_started_dragging()
	end
	return widget, dx, dy
end

--stub: return a widget to drag.
function layer:start_drag(button, mx, my, area)
	return self
end

function layer:_end_drag() --called on the drag_start_widget
	self:settag(':drag_source', false)
	self:fire('end_drag', self.ui.drag_widget)
end

function layer:_drop(widget, mx, my, area) --called on the drop target
	local mx, my = self:from_window(mx, my)
	self:settag(':drag_over', false)
	self:fire('drop', widget, mx, my, area)
end

function layer:_drag(mx, my) --called on the dragged widget
	local pmx, pmy, dmx, dmy
	pmx, pmy = self.parent:from_window(mx, my)
	dmx, dmy = self:to_parent(self.ui.drag_mx, self.ui.drag_my)
	self:fire('drag', pmx - dmx, pmy - dmy)
end

--default behavior: drag the widget from the initial grabbing point.
function layer:drag(dx, dy)
	local x0, y0 = self.x, self.y
	local x1 = x0 + dx
	local y1 = y0 + dy
	if x1 ~= x0 or y1 ~= y0 then
		self.x = x1
		self.y = y1
		self:invalidate()
	end
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
	self:settag(':enabled', enabled)
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
	local fw = self.focused_widget
	if not fw then return end
	fw:unfocus()
end

function layer:unfocus()
	if not self.focused then return end
	self.window.focused_widget = false
	self:fire'lostfocus'
	self:settag(':focused', false)
	self:settag(':window_active', false)
	local parent = self.parent
	while parent and not parent.iswindow do
		parent:settag(':child_focused', false)
		parent = parent.parent
	end
	self:unfocus_text()
	self.window:fire('lostfocus', self)
	self.ui:fire('lostfocus', self)
end

function layer:focus(focus_children)
	if self:canfocus() then
		if not self.focused then
			self.window:unfocus_focused_widget()
			self:fire'gotfocus'
			self:settag(':focused', true)
			self:settag(':window_active', self.window.active)
			local parent = self.parent
			while parent and not parent.iswindow do
				parent:settag(':child_focused', true)
				parent = parent.parent
			end
			self:focus_text()
			self.window.focused_widget = self
			self.window:fire('widget_gotfocus', self)
			self.ui:fire('gotfocus', self)
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

function layer:children_bbox(strict)
	local x, y, w, h = 0, 0, 0, 0
	for _,layer in ipairs(self) do
		x, y, w, h = box2d.bounding_box(x, y, w, h,
			layer:bbox(strict))
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
layer.border_color = '#888'
layer.border_color_left   = false
layer.border_color_right  = false
layer.border_color_top    = false
layer.border_color_bottom = false
layer.border_dash = false --true, false, {on_width1, off_width1, ...}
layer.border_dash_offset = 0
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
		local scale = min(self.w / (w1 + w2), self.h / (h1 + h2))
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
	return r > 0 and max(0, r + o) or 0
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
	local maxx = max(r1x + r2x, r3x + r4x)
	local maxy = max(r1y + r4y, r2y + r3y)
	if maxx > W or maxy > H then
		local scale = min(W / maxx, H / maxy)
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
	cr:rotate(floor(min(q1, q1 + qlen) - 2) * math.pi / 2)
	local r = ry
	local k = r * kappa * k
	local x1, y1, x2, y2, x3, y3, x4, y4 = 0, -r, k, -r, r, -k, r, 0
	if qlen < 0 then --reverse curve
		x1, y1, x2, y2, x3, y3, x4, y4 = x4, y4, x3, y3, x2, y2, x1, y1
		qlen = abs(qlen)
	end
	if qlen ~= 1 then
		assert(qlen == .5)
		local first = q1 == floor(q1)
		x1, y1, x2, y2, x3, y3, x4, y4 =
			bezier_split(first, qlen, x1, y1, x2, y2, x3, y3, x4, y4)
	end
	cr:line_to(x1, y1)
	cr:curve_to(x2, y2, x3, y3, x4, y4)
	cr:restore()
end

--draw a rounded corner: q1 is the quadrant starting top-left going clockwise.
--qlen is in 90deg units and can only be +/- .5 or 1 if k ~= 1.
function layer:corner_path(cr, cx, cy, rx, ry, q1, qlen, k)
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
	local qarc = self.corner_path
	qarc(self, cr, x1+r1x, y1+r1y, r1x, r1y, 1, 1, k) --tl
	line(self, cr, x2-r2x, y1, 1)
	qarc(self, cr, x2-r2x, y1+r2y, r2x, r2y, 2, 1, k) --tr
	line(self, cr, x2, y2-r3y, 2)
	qarc(self, cr, x2-r3x, y2-r3y, r3x, r3y, 3, 1, k) --br
	line(self, cr, x1+r4x, y2, 3)
	qarc(self, cr, x1+r4x, y2-r4y, r4x, r4y, 4, 1, k) --bl
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
			cr:dash(self.ui:dash(self.border_dash, self.border_dash_offset))
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
	local qarc = self.corner_path

	if border_color or self.border_color_left then
		cr:new_path()
		cr:move_to(x1, y1+r1y)
		qarc(self, cr, x1+r1x, y1+r1y, r1x, r1y, 1, .5, k)
		qarc(self, cr, X1+R1X, Y1+R1Y, R1X, R1Y, 1.5, -.5, K)
		cr:line_to(X1, Y2-R4Y)
		qarc(self, cr, X1+R4X, Y2-R4Y, R4X, R4Y, 5, -.5, K)
		qarc(self, cr, x1+r4x, y2-r4y, r4x, r4y, 4.5, .5, k)
		cr:close_path()
		cr:rgba(self.ui:rgba(self.border_color_left or border_color))
		cr:fill()
	end

	if border_color or self.border_color_top then
		cr:new_path()
		cr:move_to(x2-r2x, y1)
		qarc(self, cr, x2-r2x, y1+r2y, r2x, r2y, 2, .5, k)
		qarc(self, cr, X2-R2X, Y1+R2Y, R2X, R2Y, 2.5, -.5, K)
		cr:line_to(X1+R1X, Y1)
		qarc(self, cr, X1+R1X, Y1+R1Y, R1X, R1Y, 2, -.5, K)
		qarc(self, cr, x1+r1x, y1+r1y, r1x, r1y, 1.5, .5, k)
		cr:close_path()
		cr:rgba(self.ui:rgba(self.border_color_top or border_color))
		cr:fill()
	end

	if border_color or self.border_color_right then
		cr:new_path()
		cr:move_to(x2, y2-r3y)
		qarc(self, cr, x2-r3x, y2-r3y, r3x, r3y, 3, .5, k)
		qarc(self, cr, X2-R3X, Y2-R3Y, R3X, R3Y, 3.5, -.5, K)
		cr:line_to(X2, Y1+R2Y)
		qarc(self, cr, X2-R2X, Y1+R2Y, R2X, R2Y, 3, -.5, K)
		qarc(self, cr, x2-r2x, y1+r2y, r2x, r2y, 2.5, .5, k)
		cr:close_path()
		cr:rgba(self.ui:rgba(self.border_color_right or border_color))
		cr:fill()
	end

	if border_color or self.border_color_bottom then
		cr:new_path()
		cr:move_to(x1+r4x, y2)
		qarc(self, cr, x1+r4x, y2-r4y, r4x, r4y, 4, .5, k)
		qarc(self, cr, X1+R4X, Y2-R4Y, R4X, R4Y, 4.5, -.5, K)
		cr:line_to(X2-R3X, Y2)
		qarc(self, cr, X2-R3X, Y2-R3Y, R3X, R3Y, 4, -.5, K)
		qarc(self, cr, x2-r3x, y2-r3y, r3x, r3y, 3.5, .5, k)
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
layer.background_extend = 'repeat' --false, 'repeat', 'reflect'
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
layer.background_image_format = '%s'

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
		local img_file = string.format(
			self.background_image_format,
			self.background_image
		)
		local img = self.ui:image_pattern(img_file)
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
layer.shadow_blur_passes = 2

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
	if not t.shadow_blur then return end
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
	local passes = self.shadow_blur_passes
	local radius = self.shadow_blur
	local spread = radius * passes

	--check if the cached shadow image is still valid
	if not self:shadow_valid_key(t) then

		local blur = t.blur
		local grow_blur = blur and blur.max_radius < spread
		local max_radius = spread * (grow_blur and 2 or 1)
		local bx, by, bw, bh = self:shadow_rect(max_radius)
		local new_blur = grow_blur or not blur or bw > t.bw or bh > t.bh

		--store cache invalidation keys
		self:shadow_store_key(t)

		if new_blur then

			t.blur = boxblur.new(bw, bh, 'g8', max_radius)
			t.bx, t.by, t.bw, t.bh = bx, by, bw, bh

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

		else
			t.blur:invalidate()
		end

		if t.blurred_surface then
			t.blurred_surface:free()
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
layer.clip_content = false --true, 'background', false

function layer:draw_content(cr) --called in own content space
	self:draw_children(cr)
	self:draw_text_selection(cr)
	self:draw_text(cr)
	self:draw_caret(cr)
end

function layer:hit_test_content(x, y, reason) --called in own content space
	local widget, area = self:hit_test_text(x, y, reason)
	if not widget then
		return self:hit_test_children(x, y, reason)
	end
	return widget, area
end

function layer:content_bbox(strict)
	local x, y, w, h = self:children_bbox(strict)
	return box2d.bounding_box(x, y, w, h, self:text_bbox())
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
		self:background_path(cr) --'background' clipping is implicit here
		cr:clip()
		if bg then
			self:paint_background(cr)
		end
		if cc == true then
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
		or (reason == 'vscroll' and self.vscrollable)
		or (reason == 'hscroll' and self.hscrollable)

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
	if cc and in_bg then --'background' clipping is implicit here
		if cc == true then
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

function layer:bbox(strict) --child interface
	if not self.visible then
		return 0, 0, 0, 0
	end
	local x, y, w, h = 0, 0, 0, 0
	local cc = self.clip_content
	if strict or not cc then
		x, y, w, h = self:content_bbox(strict)
		if cc then
			x, y, w, h = box2d.clip(x, y, w, h, self:background_rect())
			if cc == true then
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

function layer:get_clock()
	return self.window.clock
end

function layer:invalidate(invalid_clock)
	if not self.window then return end
	self.window:invalidate(invalid_clock)
end

function layer:validate()
	if not self.window then return end
	self.window:validate()
end

function layer:revalidate(invalid_clock)
	self:invalidate(invalid_clock)
	self:validate()
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

--layer scrolling.

function window:make_visible(x, y, w, h) end --not asking window's parent

function layer:make_visible(x, y, w, h)
	if not self.parent then return end
	if not x then --make visible self's outer rectangle.
		x, y, w, h = self:border_rect(1)
		x, y = self:to_content(x, y)
	end
	local bx, by, bw, bh = self:rect_bbox_in(self.parent, x, y, w, h)
	self.parent:fire('make_visible', bx, by, bw, bh)
end

--text property --------------------------------------------------------------

layer._text = false
layer._text_valid = true
layer.maxlen = 4096

function layer:get_text()
	if not self._text_valid then
		if not self.text_segments then
			assert(self:sync_text_shape()) --truncate _text
		end
		self._text = self.text_segments.text_runs:string()
		self._text_valid = true
	end
	return self._text
end

function layer:set_text(s)
	s = s or false
	if self._text_valid or self.text_segments then
		if s == self.text then
			return false
		end
	elseif s == self._text then
		return false
	end
	self:clear_undo_stack()
	if not s then
		self._text = false
		self._text_valid = true
		self._text_tree = false
		self.text_segments = false
		self.text_selection = false
	elseif self.text_selection then
		self._text = ''
		self._text_valid = false
		self.text_selection:select_all()
		self.text_selection:replace(s, nil, nil, self.maxlen)
	elseif self.text_segments then
		self._text = ''
		self._text_valid = false
		self.text_segments:replace(0, 1/0, s, nil, nil, self.maxlen)
	else
		self._text = s
		self._text_valid = false --because we're not truncating it here
	end
	self._text_w = false --invalidate wrap
	self._text_h = false --invalidate align
	self:invalidate()
	self:fire'text_changed'
end

layer:init_priority{text=1/0}

--text typing

function layer:type_text(s)
	local maxlen = self.maxlen - self.text_len
	if self.text_selection:replace(s, nil, nil, maxlen) then
		self._text = ''
		self._text_valid = false
		self._text_w = false --invalidate wrap
		self._text_h = false --invalidate align
		self:invalidate()
		self:fire'text_changed'
		return true
	end
end

--related `selected_text` property

function layer:get_selected_text(s)
	local sel = self.text_selection
	return sel and sel:string()
end

function layer:set_selected_text(s)
	return self:type_text(s)
end

--data binding ---------------------------------------------------------------

layer:stored_property'value'

function layer:validate_value(val) return val end --stub

function layer:value_text(val) --stub
	if type(val) == 'nil' or type(val) == 'boolean' then
		return string.format('<%s>', tostring(val))
	end
	return tostring(val)
end

function layer:value_changed(val) --stub
	self.text = self:value_text(val)
end

function layer:set_value(val)
	local old_val = self.value
	if val == old_val then return end
	val = self:validate_value(val, old_val)
	if val == old_val then return end
	self:fire('value_changed', val, old_val)
	return true
end

--text geometry & drawing ----------------------------------------------------

layer.font = 'Open Sans,14'
layer.font_name   = false
layer.font_weight = false
layer.font_slant  = false
layer.font_size   = false
layer.nowrap      = false
layer.text_dir    = false
layer.text_color = '#fff'
layer.text_opacity = 1
layer.line_spacing = 1.2
layer.hardline_spacing = 1.5
layer.paragraph_spacing = 2.5
layer.text_dir = 'auto' --auto, rtl, ltr
layer.nowrap = false
layer.text_operator = 'over'
layer.text_align_x = 'center' --left, right, center, auto
layer.text_align_y = 'center' --top, bottom, center

function layer:text_visible()
	return self._text and true or false
end

--parsing of '<align_x> <align_y>' property strings

layer:stored_property'text_align_x'
layer:stored_property'text_align_y'
layer:enum_property('text_align_x', {
	left = 'left', center = 'center', right = 'right', auto = 'auto',
})
layer:enum_property('text_align_y', {
	top = 'top', center = 'center', bottom = 'bottom',
})

layer._text_tree = false
layer.text_segments = false

function layer:sync_text_shape()
	if not self:text_visible() then
		return
	end
	local t = self._text_tree
	if not t
		or self.maxlen      ~= t.maxlen
		or self.font        ~= t.font
		or self.font_name   ~= t.font_name
		or self.font_weight ~= t.font_weight
		or self.font_slant  ~= t.font_slant
		or self.font_size   ~= t.font_size
		or self.nowrap      ~= t.nowrap
		or self.text_dir    ~= t.text_dir
	then
		if not t then
			t = {}
			self._text_tree = t
		end
		t[1] = self.text_segments
			and self.text --truncated
			or self._text --raw
		t.maxlen      = self.maxlen
		t.font        = self.font
		t.font_name   = self.font_name
		t.font_weight = self.font_weight
		t.font_slant  = self.font_slant
		t.font_size   = self.font_size
		t.nowrap      = self.nowrap
		t.text_dir    = self.text_dir
		self.text_segments = self.ui.tr:shape(t)
		self._text_w = false --invalidate wrap
		self._text_h = false --invalidate align
		self.text_selection = false --invalidate selection
	end
	return self.text_segments
end

function layer:sync_text_wrap()
	local segs = self.text_segments
	if not segs then return nil end
	local cw = self:client_size()
	local ls = self.line_spacing
	local hs = self.hardline_spacing
	local ps = self.paragraph_spacing
	if    cw ~= self._text_w
		or ls ~= self._text_tree.line_spacing
		or hs ~= self._text_tree.hardline_spacing
		or ps ~= self._text_tree.paragraph_spacing
	then
		self._text_w = cw
		self._text_tree.line_spacing = ls
		self._text_tree.hardline_spacing = hs
		self._text_tree.paragraph_spacing = ps
		segs:wrap(cw)
		self._text_h = false --invalidate align
	end
	return segs
end

function layer:sync_text_align()
	local segs = self.text_segments
	if not segs then return nil end
	local cw, ch = self:client_size()
	local ha = self.text_align_x
	local va = self.text_align_y
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
	if self.text_selectable and not self.text_selection then
		self.text_selection = self:create_text_selection(segs)
		self.text_selection.cursor2.insert_mode = self.insert_mode
	end
	return segs
end

function layer:get_baseline()
	if not self:text_visible() then return end
	return self.text_segments.lines.baseline
end

function layer:draw_text(cr)
	local segs = self.text_segments
	if not segs then return end
	self._text_tree.color    = self.text_color
	self._text_tree.opacity  = self.text_opacity
	self._text_tree.operator = self.text_operator
	local x1, y1, x2, y2 = cr:clip_extents()
	segs:clip(x1, y1, x2-x1, y2-y1)
	segs:paint(cr)
end

function layer:text_bbox()
	if not self:text_visible() then
		return 0, 0, 0, 0
	end
	return self.text_segments:bbox()
end

--text caret & selection drawing ---------------------------------------------

layer.caret_width = 1
layer.caret_color = '#fff'
layer.caret_opacity = 1

layer.text_selectable = false
layer.text_selection = false --selection object
layer.text_selection_color = '#66f6'

--hiding the caret and dimming the selection while the window is inactive.
ui:style('layer !:window_active', {
	caret_opacity = 0,
	text_selection_color = '#66f3',
})

ui:style('layer :insert_mode', {
	caret_color = '#fff6',
})

--blinking the caret.
ui:style('layer :focused !:insert_mode :window_active', {
	caret_opacity = 0,
	transition_caret_opacity = function(self)
		return self.text_editable
	end,
	transition_delay_caret_opacity = function(self)
		return self.ui.caret_blink_time
	end,
	transition_times_caret_opacity = 1/0, --blink indefinitely
	transition_blend_caret_opacity = 'restart',
})

function layer:create_text_selection(segs)
	local sel = segs:selection()
	if not sel then return end --invalid font

	--reset the caret blinking whenever a cursor is being acted upon,
	--regardles of whether it changes position or not.
	local c1, c2 = sel:cursors()
	local set = c1.set
	function c1.set(...)
		self:blink_caret()
		return set(...)
	end
	local set = c2.set
	function c2.set(...)
		self:blink_caret()
		return set(...)
	end

	--scroll to view the caret and fire the `caret_moved` event.
	function sel.changed(sel, cursor)
		self:fire('selection_changed', cursor)
		self:invalidate()
		if cursor == sel.cursor2 then
			self:run_after_layout(function()
				self:make_visible_caret()
				self:fire'caret_moved'
			end)
		end
	end

	self:_sync_text_cursor_props(sel)

	return sel
end

function layer:blink_caret()
	if not self.focused then return end
	if not self.caret_visible then
		self.caret_visible = true
		self:invalidate()
	end
	self:transition{
		attr = 'caret_opacity',
		val = self:end_value'caret_opacity',
	}
end

function layer:caret_rect()
	local x, y, w, h = self.text_selection.cursor2:rect(self.caret_width)
	local x, w = self:snapxw(x, w)
	local y, h = self:snapyh(y, h)
	return x, y, w, h
end

function layer:caret_visibility_rect()
	local x, y, w, h = self:caret_rect()
	--enlarge the caret rect to contain the line spacing.
	local line = self.text_selection.cursor2.seg.line
	local y = y + line.ascent - line.spaced_ascent
	local h = line.spaced_ascent - line.spaced_descent
	return x, y, w, h
end

function layer:draw_caret(cr)
	if not self.focused then return end
	if not self.caret_visible then return end
	local x, y, w, h = self:caret_rect()
	local r, g, b, a = self.ui:rgba(self.caret_color)
	a = a * self.caret_opacity
	cr:rgba(r, g, b, a)
	cr:new_path()
	cr:rectangle(x, y, w, h)
	cr:fill()
end

function layer:draw_selection_rect(x, y, w, h, cr)
	cr:rectangle(x, y, w, h)
	cr:fill()
end
function layer:draw_text_selection(cr)
	local sel = self.text_selection
	if not sel then return end
	if sel:empty() then return end
	cr:rgba(self.ui:rgba(self.text_selection_color))
	cr:new_path()
	sel:rectangles(self.draw_selection_rect, self, cr)
end

function layer:make_visible_caret()
	local segs = self.text_segments
	local lines = segs.lines
	local sx, sy = lines.x, lines.y
	local cw, ch = self:client_size()
	local x, y, w, h = self:caret_visibility_rect()
	lines.x, lines.y = box2d.scroll_to_view(x-sx, y-sy, w, h, cw, ch, sx, sy)
	self:make_visible(self:caret_visibility_rect())
end

--insert_mode property

layer.insert_mode = false
layer:stored_property'insert_mode'

function layer:after_set_insert_mode(value)
	if self.text_selection then
		self.text_selection.cursor2.insert_mode = value
	end
	self:settag(':insert_mode', value)
end

--text mouse interaction (moving the caret & drag-selecting) -----------------

layer.cursor_text = 'text'
layer.cursor_selection = 'arrow'

function layer:hit_test_text(x, y, reason)
	if reason == 'activate' and self.activable then
		self:validate()
		if self.text_selection then
			if self.text_selection:hit_test(x, y) then
				return self, 'text_selection'
			elseif self.text_editable then
				return self, 'text'
			elseif self.text_segments:hit_test(x, y) then
				return self, 'text'
			end
		elseif self.text_segments and self.text_segments:hit_test(x, y) then
			return self, 'static_text'
		end
	end
end

function layer:doubleclick_text(x, y)
	if not self.text_selection then return end
	self.text_selection:select_word()
end

function layer:tripleclick_text(x, y)
	if not self.text_selection then return end
	self.text_selection:select_line()
end

function layer:mousedown_text(x, y)
	if not self.text_selection then return end
	if not self.ui:key'shift' then
		self:validate()
		self.text_selection.cursor2:move('pos', x, y)
	end
	self.text_selection:reset()
	self.active = true
end

function layer:mousemove_text(x, y)
	if not self.active then return end
	self:validate()
	self.text_selection.cursor2:move('pos', x, y)
end

function layer:mouseup_text()
	self.active = false
end

layer.doubleclick_text_selection = layer.doubleclick_text
layer.tripleclick_text_selection = layer.tripleclick_text
layer.mousedown_text_selection   = layer.mousedown_text
layer.mousemove_text_selection   = layer.mousemove_text
layer.mouseup_text_selection     = layer.mouseup_text

--text keyboard interaction (moving the caret, selecting and editing) --------

layer.text_editable = false

layer.text_multiline = true
layer.paragraph_first = true --enter for paragraph, ctrl+enter for newline
layer.paragraph_separator = '\u{2029}' --PS
layer.line_separator = false --use OS default from keychar()

function layer:filter_input_text(s)
	if self.text_multiline then
		return
			s:gsub('\u{2029}', '') --PS
				:gsub('\u{2028}', '') --LS
				:gsub('[%z\1-\31\127]', '')
	end
	return s:gsub('[%z\1-\8\11\12\14-\31\127]', '') --allow \t \n \r
end

--text length in codepoints.
function layer:get_text_len()
	local segs = self:sync_text_shape()
	return segs and segs.text_runs.len or 0
end

function layer:focus_text()
	local sel = self.text_selection
	if not sel then return end
	if not self.active then
		sel:select_all()
		self.caret_visible = sel:empty()
	else
		self.caret_visible = true
	end
end

function layer:unfocus_text()
	local sel = self.text_selection
	if not sel then return end
	self.caret_visible = false
	sel.cursor2:move('offset', 0)
	sel:reset()
end

function layer:keychar_text(s)
	if not self.text_selection then return end
	if not self.text_editable then return end
	s = self:filter_input_text(s)
	if s == '' then return end
	self:undo_group'typing'
	self:type_text(s)
end

function layer:keypress_text(key)
	local sel = self.text_selection
	if not sel then return end

	local shift = self.ui:key'shift'
	local ctrl = self.ui:key'ctrl'
	local shift_ctrl = shift and ctrl
	local shift_only = shift and not ctrl
	local ctrl_only = ctrl and not shift
	local key_only = not ctrl and not shift

	if key == 'right' or key == 'left' then
		self:undo_group()
		local dir = key == 'right' and 'next' or 'prev'
		local mode = ctrl and 'word' or nil
		if shift then
			return sel.cursor2:move('rel_cursor', dir, mode, nil, true)
		else
			local c1, c2 = sel:cursors()
			if sel:empty() then
				if c1:move('rel_cursor', dir, mode, nil, true) then
					c2:set(c1)
					return true
				end
			else
				local c1, c2 = c1, c2
				if key == 'left' then
					c1, c2 = c2, c1
				end
				return c1:set(c2)
			end
		end
	elseif
		key == 'up' or key == 'down'
		or key == 'pageup' or key == 'pagedown'
		or key == 'home' or key == 'end'
	then
		local what, by
		if key == 'up' then
			what, by = 'rel_line', -1
		elseif key == 'down' then
			what, by = 'rel_line', 1
		elseif key == 'pageup' then
			what, by = 'rel_page', -1
		elseif key == 'pagedown' then
			what, by = 'rel_page', 1
		elseif key == 'home' then
			what, by = 'offset', 0
		elseif key == 'end' then
			what, by = 'offset', 1/0
		end
		self:undo_group()
		local moved = sel.cursor2:move(what, by)
		if not shift then
			sel.cursor1:set(sel.cursor2)
		end
		return moved
	elseif key_only and key == 'insert' then
		self.insert_mode = not self.insert_mode
		return true
	elseif (key_only and key == 'delete') or key == 'backspace' then
		if self.text_editable then
			self:undo_group'delete'
			if sel:empty() then
				sel.cursor2:move('rel_cursor',
					key == 'delete' and 'next' or 'prev', 'char')
			end
			return self:type_text''
		end
	elseif key == 'enter' and (key_only or ctrl_only or shift_only) then
		if self.text_editable and self.text_multiline then
			local sep = self.paragraph_first == key_only
				and self.paragraph_separator
				or self.line_separator
			if sep then
				self:undo_group'typing'
				self:type_text(sep)
				return true
			end
		end
	elseif ctrl and key == 'A' then
		self:undo_group()
		return sel:select_all()
	elseif (ctrl and key == 'C') or (ctrl_only and key == 'insert') then
		local s = sel:string()
		if s ~= '' then
			self.ui:setclipboard(s, 'text')
			return true
		end
	elseif (ctrl and key == 'X') or (shift_only and key == 'delete') then
		if self.text_editable then
			local s = sel:string()
			if s ~= '' then
				self.ui:setclipboard(s, 'text')
				self:undo_group'cut'
				self:type_text''
				return true
			end
		end
	elseif (ctrl and key == 'V') or (shift_only and key == 'insert') then
		if self.text_editable then
			local s = self.ui:getclipboard'text'
			s = s and self:filter_input_text(s)
			if s and s ~= '' then
				self:undo_group'paste'
				self:type_text(s)
				return true
			end
		end
	elseif ctrl and key == 'Z' then
		return self:undo()
	elseif (ctrl and key == 'Y') or (shift_ctrl and key == 'Z') then
		return self:redo()
	end
end

--forwarded text cursor properties (see `tr` for meaning) --------------------

local text_cursor_properties = {
	park_home = true,
	park_end = true,
	unique_offsets = false,
	wrapped_space = true,
}

for name, default in pairs(text_cursor_properties) do
	local prop = 'text_cursor_'..name
	local priv = '_'..prop
	layer[priv] = default
	layer['set_'..prop] = function(self, val)
		local sel = self.text_selection
		if not sel then --class default or invalid font
			self[priv] = val
		else
			sel.cursor1[name] = val
			sel.cursor2[name] = val
		end
	end
	layer['get_'..prop] = function(self, val)
		local sel = self.text_selection
		if not sel then
			return self[priv]
		else
			return sel.cursor2[name]
		end
	end
end

--forward text_cursor_* properties to cursor objects.
function layer:_sync_text_cursor_props(sel)
	for name in pairs(text_cursor_properties) do
		local priv = '_text_cursor_'..name
		sel.cursor1[name] = self[priv]
		sel.cursor2[name] = self[priv]
	end
end

--text undo/redo -------------------------------------------------------------

function layer:clear_undo_stack()
	self.undo_stack = false
	self.redo_stack = false
end

function layer:save_state(state)
	local sel = self.text_selection
	state.cursor1_seg_i = sel.cursor1.seg.index
	state.cursor2_seg_i = sel.cursor2.seg.index
	state.cursor1_i = sel.cursor1.i
	state.cursor2_i = sel.cursor2.i
	state.cursor1_x = sel.cursor1.x
	state.cursor2_x = sel.cursor2.x
	state.text = self.text
	return state
end

function layer:load_state(state)
	local sel = self.text_selection
	sel:select_all()
	self:type_text(state.text)
	local segs = self.text_selection.segments
	sel.cursor1.seg = assert(segs[state.cursor1_seg_i])
	sel.cursor2.seg = assert(segs[state.cursor2_seg_i])
	sel.cursor1.i = state.cursor1_i
	sel.cursor2.i = state.cursor2_i
	sel.cursor1.x = state.cursor1_x
	sel.cursor2.x = state.cursor2_x
	self:invalidate()
end

function layer:_undo_redo(undo_stack, redo_stack)
	if not undo_stack then return end
	local state = pop(undo_stack)
	if not state then return end
	push(redo_stack, self:save_state{type = 'undo'})
	self:load_state(state)
	return true
end

function layer:undo()
	return self:_undo_redo(self.undo_stack, self.redo_stack)
end

function layer:redo()
	return self:_undo_redo(self.redo_stack, self.undo_stack)
end

function layer:undo_group(type)
	if not type then
		--cursor moved, force an undo group on the next editing operation.
		self.force_undo_group = true
		return
	end
	local top = self.undo_stack and self.undo_stack[#self.undo_stack]
	if not top or top.type ~= type or self.force_undo_group then
		self.undo_stack = self.undo_stack or {}
		self.redo_stack = self.redo_stack or {}
		push(self.undo_stack, self:save_state{type = type})
		self.force_undo_group = false
	end
end

function layer:get_text_modified()
	return self.undo_stack and #self.undo_stack > 0
end

--layouting ------------------------------------------------------------------

layer.layout = false --false/'null', 'textbox', 'flexbox', 'grid'

--min client width/height used by flexible layouts and their children.
layer.min_cw = 0
layer.min_ch = 0

layer.layouts = {} --{layout_name -> layout_mixin}

layer:stored_property('layout', function(self, layout)
	local mixin = self.layouts[layout or 'null']
	if not self.ui:check(mixin, 'invalid layout "%s"', layout) then return end
	self:inherit(mixin, true)
end)
layer:nochange_barrier'layout'

--used by layers that need to solve their layout on one axis completely
--before they can solve it on the other axis. any content-based layout with
--wrapped content is like that: can't know the height until wrapping the
--content which needs to know the width (and viceversa for vertical flow).
function layer:sync_layout_separate_axes(axis_order, min_w, min_h)
	if not self.visible then return end
	local sync_x = (axis_order or self.layout_axis_order) == 'xy'
	local axis_synced, other_axis_synced
	for phase = 1, 3 do
		other_axis_synced = axis_synced
		if sync_x then
			--sync the x-axis.
			self.w = max(self:sync_min_w(other_axis_synced), min_w or -1/0)
			axis_synced = self:sync_layout_x(other_axis_synced)
		else
			--sync the y-axis.
			self.h = max(self:sync_min_h(other_axis_synced), min_h or -1/0)
			axis_synced = self:sync_layout_y(other_axis_synced)
		end
		if axis_synced and other_axis_synced then
			break --both axes were solved before last phase.
		end
		sync_x = not sync_x
	end
	assert(axis_synced and other_axis_synced)
end

function layer:sync_layout_children()
	for _,layer in ipairs(self) do
		layer:sync_layout() --recurse
	end
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
	self.x, self.w = self:snapxw(self.x, self.w)
	self.y, self.h = self:snapyh(self.y, self.h)
	if self:sync_text_shape() then
		self:sync_text_wrap()
		self:sync_text_align()
	end
	self:sync_layout_children()
end

--called by flexible layouts to know the minimum width of their children.
--width-in-height-out layouts call this before h and y are sync'ed.
function null_layout:sync_min_w()
	self._min_w = snap_up(self.min_cw + self.pw, self.snap_x)
	return self._min_w
end

--called by flexible layouts to know the minimum height of their children.
--width-in-height-out layouts call this only after w and x are sync'ed.
function null_layout:sync_min_h()
	self._min_h = snap_up(self.min_ch + self.ph, self.snap_y)
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
	self.cw = max(segs:min_w(), self.min_cw)
	self:sync_text_wrap()
	self.cw = max(segs.lines.max_ax, self.min_cw)
	self.ch = max(self.min_ch, segs.lines.spaced_h)
	self.x, self.w = self:snapxw(self.x, self.w)
	self.y, self.h = self:snapyh(self.y, self.h)
	self:sync_text_align()
	self:sync_layout_children()
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
	min_cw = max(min_cw, self.min_cw)
	local min_w = snap_up(min_cw + self.pw, self.snap_x)
	self._min_w = min_w
	return min_w
end

function textbox:sync_min_h(other_axis_synced)
	local min_ch
	if other_axis_synced or self.nowrap then
		local segs = self.text_segments
		min_ch = segs and segs.lines.spaced_h or 0
	else
		--height-in-width-out parent layout with wrapping text not supported
		min_ch = 0
	end
	min_ch = max(min_ch, self.min_ch)
	local min_h = snap_up(min_ch + self.ph, self.snap_y)
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
		self:sync_layout_children()
		return true
	end
end

--stuff common to flexbox & grid layouts -------------------------------------

layer.align_items_x = 'stretch' --how all items as a group are x-aligned
layer.align_items_y = 'stretch' --how all items as a group are y-aligned
layer.item_align_x = 'stretch' --how each item is x-aligned in its stretch
layer.item_align_y = 'stretch' --how each item is y-aligned in its stretch
layer.align_x = false --override item_align_x for this item
layer.align_y = false --override item_align_y for this item
	--^all: stretch, start/top/left, end/bottom/right, center
	--^+main axis: space_between, space_around, space_evenly
	--^+cross axis: baseline

layer.moving = false
layer.moving_layer = false
layer.moving_x = false
layer.moving_y = false

function layer:get_inlayout()
	return self.visible and (not self.dragging or self.moving)
end

local function items_sum(self, i, j, _MIN_W)
	local sum_w = 0
	local item_count = 0
	for i = i, j do
		local layer = self[i]
		if layer.visible then
			sum_w = sum_w + layer[_MIN_W]
			item_count = item_count + 1
		end
	end
	return sum_w, item_count
end

local function items_max(self, i, j, _MIN_W)
	local max_w = 0
	local item_count = 0
	for i = i, j do
		local layer = self[i]
		if layer.visible then
			max_w = max(max_w, layer[_MIN_W])
			item_count = item_count + 1
		end
	end
	return max_w, item_count
end

--compute a single item's stretched width and aligned width.
local function stretched_item_widths(
	layer, total_w, total_fr, total_overflow_w, total_free_w, align,
	_MIN_W
)
	local min_w = layer[_MIN_W]
	local flex_w = total_w * layer.fr / total_fr
	local sw --stretched width
	if min_w > flex_w then --overflow
		sw = min_w
	else
		local free_w = flex_w - min_w
		local free_p = free_w / total_free_w
		local shrink_w = total_overflow_w * free_p
		if shrink_w ~= shrink_w then --total_free_w == 0
			shrink_w = 0
		end
		sw = flex_w - shrink_w
	end
	return sw, align == 'stretch' and sw or min_w
end

--stretch a line of items on the main axis.
local function stretch_items_main_axis(
	items, i, j, total_w, item_align_x, moving,
	set_item_x, set_moving_item_x,
	X, W, _MIN_W, ALIGN_X, END, RIGHT
)
	--compute the fraction representing the total width.
	local total_fr = 0
	for i = i, j do
		local layer = items[i]
		if layer.inlayout then
			total_fr = total_fr + max(0, layer.fr)
		end
	end
	total_fr = max(1, total_fr) --treat sub-unit fractions like css flexbox

	--compute the total overflow width and total free width.
	local total_overflow_w = 0
	local total_free_w = 0
	for i = i, j do
		local layer = items[i]
		if layer.inlayout then
			local min_w = layer[_MIN_W]
			local flex_w = total_w * max(0, layer.fr) / total_fr
			local overflow_w = max(0, min_w - flex_w)
			local free_w = max(0, flex_w - min_w)
			total_overflow_w = total_overflow_w + overflow_w
			total_free_w = total_free_w + free_w
		end
	end

	--compute the stretched width of the moving layer to make room for it.
	local moving_layer, moving_x, moving_w, moving_sw
	if moving then
		local layer = items[j]
		assert(layer.moving)
		local align = layer[ALIGN_X] or item_align_x
		local sw, w = stretched_item_widths(
			layer, total_w, total_fr, total_overflow_w, total_free_w, align,
			_MIN_W
		)

		moving_layer = layer
		moving_x = layer[X]
		moving_w = w
		moving_sw = sw
		j = j-1
	end

	--distribute the overflow to children which have free space to
	--take it. each child shrinks to take in a part of the overflow
	--proportional to its percent of free space.
	local sx = 0 --stretched x-coord
	for i = i, j do
		local layer = items[i]
		if layer.inlayout then

			--compute item's stretched width.
			local align = layer[ALIGN_X] or item_align_x
			local sw, w = stretched_item_widths(
				layer, total_w, total_fr, total_overflow_w, total_free_w, align,
				_MIN_W
			)

			--align item inside the stretched segment defined by (sx, sw).
			local x = sx
			if align == END or align == RIGHT then
				x = sx + sw - w
			elseif align == 'center' then
				x = sx + (sw - w) / 2
			end

			if moving_x and moving_x < x + w / 2 then
				set_moving_item_x(moving_layer, i, x, moving_w)

				--reserve space for the moving layer.
				sx = sx + moving_sw
				x = x + moving_sw
				moving_x = false
			end

			set_item_x(layer, x, w, moving)
			sx = sx + sw
		end
	end
end

--start offset and inter-item spacing for aligning items on the main-axis.
local function align_metrics(
	align, container_w, items_w, item_count,
	END, RIGHT
)
	local x = 0
	local spacing = 0
	if align == END or align == RIGHT then
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
	end
	return x, spacing
end

--align a line of items on the main axis.
local function align_items_main_axis(
	items, i, j, sx, spacing, moving,
	set_item_x, set_moving_item_x,
	X, W, _MIN_W
)
	--compute the spaced width of the moving layer to make room for it.
	local moving_layer, moving_x, moving_w, moving_sw
	if moving then
		local layer = items[j]
		assert(layer.moving)
		local w = layer[_MIN_W]

		moving_layer = layer
		moving_x = layer[X]
		moving_w = w
		moving_sw = w + spacing
		j = j-1
	end

	for i = i, j do
		local layer = items[i]
		if layer.inlayout then
			local x, w = sx, layer[_MIN_W]
			local sw = w + spacing

			if moving_x and moving_x < x + w / 2 then
				set_moving_item_x(moving_layer, i, x, moving_w)

				--reserve space for the moving layer.
				sx = sx + moving_sw
				x = x + moving_sw
				moving_x = false
			end

			set_item_x(layer, x, w, moving)

			sx = sx + sw
		end
	end
end

--flexbox layout -------------------------------------------------------------

local flexbox = object:subclass'flexbox_layout'
layer.layouts.flexbox = flexbox

flexbox.sync_layout = layer.sync_layout_separate_axes
flexbox.layout_axis_order = 'xy'

--container properties
layer.flex_flow = 'x' --'x', 'y'
layer.flex_wrap = false -- true, false

--item properties
layer.fr = 1 --stretch fraction: 0..inf

--generate pairs of methods for vertical and horizontal flexbox layouts.
local function gen_funcs(X, Y, W, H, LEFT, RIGHT, TOP, BOTTOM)

	local CW = 'c'..W
	local CH = 'c'..H
	local PW = 'p'..W
	local PH = 'p'..H
	local _MIN_W = '_min_'..W
	local _MIN_H = '_min_'..H
	local SNAP_X = 'snap_'..X
	local SNAP_Y = 'snap_'..Y

	local ALIGN_ITEMS_X = 'align_items_'..X
	local ALIGN_ITEMS_Y = 'align_items_'..Y
	local ITEM_ALIGN_X = 'item_align_'..X
	local ITEM_ALIGN_Y = 'item_align_'..Y
	local ALIGN_X = 'align_'..X
	local ALIGN_Y = 'align_'..Y
	local START_X = 'start'
	local START_Y = 'start'
	local END_X = 'end'
	local END_Y = 'end'

	--special items_min_h() for baseline align.
	--requires that the children are already sync'ed on y-axis.
	local function items_min_h_baseline(self, i, j)
		local max_ascent = -1/0
		local max_descent = -1/0
		for i = i, j do
			local layer = self[i]
			if layer.visible then
				local baseline = layer.baseline or layer.h
				max_ascent = max(max_ascent, baseline)
				max_descent = max(max_descent, layer._min_h - baseline)
			end
		end
		return max_ascent + max_descent, max_ascent
	end

	local function items_min_h(self, i, j, align_baseline)
		if align_baseline then
			return items_min_h_baseline(self, i, j)
		end
		return (items_max(self, i, j, _MIN_H))
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
			return (items_max(self, 1, #self, _MIN_W))
		else
			return (items_sum(self, 1, #self, _MIN_W))
		end
	end

	local function min_ch(self, other_axis_synced, align_baseline)
		if not other_axis_synced and self.flex_wrap then
			--width-in-height-out parent layout requesting min_w on a y-axis
			--wrapping flexbox (which is a height-in-width-out layout).
			return 0
		end
		local lines_h = 0
		for j, i in linewrap(self) do
			local line_h = items_min_h(self, i, j, align_baseline)
			lines_h = lines_h + line_h
		end
		return lines_h
	end

	local function set_item_x(layer, x, w, moving)
		x, w = snap_xw(x, w, layer[SNAP_X])
		local set = moving and layer.transition or layer.end_value
		set(layer, X, x)
		set(layer, W, w)
	end

	local function set_moving_item_x(layer, i, x, w)
		--layer[X] = x
		--layer[W] = w
	end

	--stretch and align a line of items on the main axis.
	local function stretch_items_x(self, i, j, moving)
		stretch_items_main_axis(
			self, i, j, self[CW], self[ITEM_ALIGN_X], moving,
			set_item_x, set_moving_item_x,
			X, W, _MIN_W, ALIGN_X, END_X, RIGHT)
	end

	local function align_metrics_x(self, align, items_w, item_count)
		return align_metrics(align, self[CW], items_w, item_count,
			END_X, RIGHT)
	end

	local function align_metrics_y(self, align, items_h, item_count)
		return align_metrics(align, self[CH], items_h, item_count,
			END_Y, BOTTOM)
	end

	--align a line of items on the main axis.
	local function align_items_x(self, i, j, align, moving)
		if align == 'stretch' then
			stretch_items_x(self, i, j, moving)
		else
			local x, spacing
			if align == START_X or align == LEFT then
				x, spacing = 0, 0
			else
				local items_w, item_count = items_sum(self, i, j, _MIN_W)
				x, spacing = align_metrics_x(self, align, items_w, item_count)
			end
			align_items_main_axis(
				self, i, j, x, spacing, moving,
				set_item_x, set_moving_item_x,
				X, W, _MIN_W)
		end
	end

	--stretch or align a flexbox's items on the main-axis.
	local function align_x(self)
		local align = self[ALIGN_ITEMS_X]
		local moving = self.moving_layer and true or false
		for j, i in linewrap(self) do
			align_items_x(self, i, j, align, moving)
		end
		return true
	end

	--align a line of items on the cross-axis.
	local function align_items_y(self, i, j, line_y, line_h, line_baseline)
		local snap_y = self[SNAP_Y]
		local align = self[ITEM_ALIGN_Y]
		for i = i, j do
			local layer = self[i]
			if layer.visible then
				local align = layer[ALIGN_Y] or align
				local y, h
				if align == 'stretch' then
					y = line_y
					h = line_h
				else
					local item_h = layer[_MIN_H]
					if align == TOP or align == START_Y then
						y = line_y
						h = item_h
					elseif align == BOTTOM or align == END_Y then
						y = line_y + line_h - item_h
						h = item_h
					elseif align == 'center' then
						y = line_y + (line_h - item_h) / 2
						h = item_h
					elseif line_baseline then
						y = line_baseline - (layer.baseline or layer.h)
					end
				end
				if line_baseline then
					y = snap(y, snap_y)
				else
					y, h = snap_xw(y, h, layer[SNAP_Y])
					layer:end_value(H, h)
				end
				if not layer.moving then
					layer:end_value(Y, y)
				else
					--TODO: layer[_DEST_Y] = y
				end
			end
		end
	end

	--stretch or align a flexbox's items on the cross-axis.
	local function align_y(self, other_axis_synced, align_baseline)
		if not other_axis_synced and self.flex_wrap then
			--trying to lay out the y-axis before knowing the x-axis:
			--dismiss and wait for the 3rd pass.
			return
		end

		local lines_y, line_spacing, line_h
		local align = self[ALIGN_ITEMS_Y]
		if align == 'stretch' then
			local lines_h = self[CH]
			local line_count = 0
			for _ in linewrap(self) do
				line_count = line_count + 1
			end
			line_h = lines_h / line_count
			lines_y = 0
			line_spacing = 0
		elseif align == TOP or align == START_Y then
			lines_y, line_spacing = 0, 0
		else
			local lines_h = 0
			local line_count = 0
			for j, i in linewrap(self) do
				local line_h = items_min_h(self, i, j, align_baseline)
				lines_h = lines_h + line_h
				line_count = line_count + 1
			end
			lines_y, line_spacing =
				align_metrics_y(self, align, lines_h, line_count)
		end
		local y = lines_y
		for j, i in linewrap(self) do
			local line_h, line_baseline = line_h
			if not line_h then
				line_h, line_baseline = items_min_h(self, i, j, align_baseline)
			end
			align_items_y(self, i, j, y, line_h, line_baseline)
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

	local min_cw = self.flex_flow == 'x'
		and self:min_cw_x_axis(other_axis_synced)
		 or self:min_ch_y_axis(other_axis_synced)

	min_cw = max(min_cw, self.min_cw)
	local min_w = min_cw + self.pw
	self._min_w = min_w
	return min_w
end

function flexbox:sync_min_h(other_axis_synced)

	local align_baseline = self.flex_flow == 'x'
		and self.item_align_y == 'baseline'

	--sync all children first (bottom-up sync).
	for _,layer in ipairs(self) do
		if layer.visible then
			local item_h = layer:sync_min_h(other_axis_synced) --recurse
			--for baseline align also layout the children because we need
			--their baseline. we can do this here because we already know
			--we won't stretch them beyond their min_h in this case.
			if align_baseline then
				layer.h = snap(item_h, self.snap_y)
				layer:sync_layout_y(other_axis_synced)
			end
		end
	end

	local min_ch = self.flex_flow == 'x'
		and self:min_ch_x_axis(other_axis_synced, align_baseline)
		 or self:min_cw_y_axis(other_axis_synced)

	min_ch = max(min_ch, self.min_ch)
	local min_h = min_ch + self.ph
	self._min_h = min_h
	return min_h
end

function flexbox:sync_layout_x(other_axis_synced)

	local synced = self.flex_flow == 'x'
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

	if self.flex_flow == 'x' and self.item_align_y == 'baseline' then
		--chilren already sync'ed in sync_min_h().
		return self:sync_layout_x_axis_y(other_axis_synced, true)
	end

	local synced = self.flex_flow == 'y'
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

--faster hit-testing for non-wrapped flexboxes.
local function cmp_ys(items, i, y)
	return items[i].visible and items[i].y < y -- < < [=] = < <
end
local function cmp_xs(items, i, x)
	return items[i].visible and items[i].x < x -- < < [=] = < <
end
function flexbox:hit_test_flexbox_item(x, y)
	local cmp = self.flex_flow == 'y' and cmp_ys or cmp_xs
	local coord = self.flex_flow == 'y' and y or x
	return max(1, (binsearch(coord, self, cmp) or #self + 1) - 1)
end

function flexbox:override_hit_test_children(inherited, x, y, reason)
	if #self < 2 or self.flex_wrap then
		return inherited(self, x, y, reason)
	end
	local i = self:hit_test_flexbox_item(x, y)
	return self[i]:hit_test(x, y, reason)
end

--faster clipped drawing for non-wrapped flexboxes.
function flexbox:override_draw_children(inherited, cr)
	if #self < 1 or self.flex_wrap then
		return inherited(self, cr)
	end
	local x1, y1, x2, y2 = cr:clip_extents()
	local i = self:hit_test_flexbox_item(x1, y1)
	local j = self:hit_test_flexbox_item(x2, y2)
	for i = i, j do
		self[i]:draw(cr)
	end
end

--grid layout ----------------------------------------------------------------

local grid = object:subclass'grid_layout'
layer.layouts.grid = grid

--container properties

layer.grid_cols = {} --{fr1, ...}
layer.grid_rows = {} --{fr1, ...}
layer.grid_gap = 0
layer.grid_col_gap = false
layer.grid_row_gap = false

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
layer.grid_min_lines = 0

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
	local grid_wrap = max(1, self.grid_wrap)
	local max_col = col_first and grid_wrap or self.grid_min_lines
	local max_row = row_first and grid_wrap or self.grid_min_lines

	local occupied = {}

	--position explicitly-positioned layers first and mark occupied cells.
	--grow the grid bounds to include layers outside wrap_row and wrap_col.
	local missing_indices, negative_indices
	for _,layer in ipairs(self) do
		if layer.visible then

			local row, col, row_span, col_span = self.ui:grid_pos(layer.grid_pos)
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

					max_row = max(max_row, row + row_span - 1)
					max_col = max(max_col, col + col_span - 1)
				else
					negative_indices = true --solve these later
				end
			else --auto-positioned
				--negative spans are treated as positive.
				row_span = abs(row_span)
				col_span = abs(col_span)

				--grow grid bounds on the main axis to fit the widest layer.
				if col_first then
					max_col = max(max_col, col_span)
				else
					max_row = max(max_row, row_span)
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
					max_row = max(max_row, row + row_span - 1)
				else
					max_col = max(max_col, col + col_span - 1)
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

	local CW = 'c'..W
	local PW = 'p'..W
	local MIN_CW = 'min_'..CW
	local _MIN_W = '_min_'..W
	local SNAP_X = 'snap_'..X
	local SYNC_MIN_W = 'sync_min_'..W
	local SYNC_LAYOUT_X = 'sync_layout_'..X
	local COLS = 'grid_'..COL..'s'
	local COL_GAP = 'grid_'..COL..'_gap'
	local ALIGN_ITEMS_X = 'align_items_'..X
	local ITEM_ALIGN_X = 'item_align_'..X
	local ALIGN_X = 'align_'..X
	local _COLS = '_'..COLS
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

		local gap_w = self[COL_GAP] or self.grid_gap
		local max_col = self[_MAX_COL]
		local fr = self[COLS] --{fr1, ...}

		--compute the fraction representing the total width.
		local total_fr = 0
		for _,layer in ipairs(self) do
			if layer.inlayout then
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
				inlayout = true,
				fr = fr[col] or 1,
				[_MIN_W] = 0,
				[X] = false,
				[W] = false,
				[SNAP_X] = self[SNAP_X],
				end_value = function(self,k,v) self[k] = v end,
			}
		end
		self[_COLS] = cols

		--compute the minimum widths for each column.
		for _,layer in ipairs(self) do
			if layer.inlayout then
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
					item[_MIN_W] = max(item[_MIN_W], col_min_w)
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
						item[_MIN_W] = max(item[_MIN_W], col_min_w)
					end
				end
			end
		end

		local min_cw = 0
		for _,item in ipairs(cols) do
			min_cw = min_cw + item[_MIN_W]
		end

		min_cw = max(min_cw, self[MIN_CW])
		local min_w = min_cw + self[PW]
		self[_MIN_W] = min_w
		return min_w
	end

	local function set_item_x(layer, x, w, moving)
		x, w = snap_xw(x, w, layer[SNAP_X])
		local set = moving and layer.transition or layer.end_value
		set(layer, X, x)
		set(layer, W, w)
	end

	local function set_moving_item_x(layer, i, x, w)
		--moving NYI
	end

	grid[SYNC_LAYOUT_X] = function(self, other_axis_synced)

		local cols = self[_COLS]
		local gap_w = self[COL_GAP] or self.grid_gap
		local container_w = self[CW]
		local align_items_x = self[ALIGN_ITEMS_X]
		local item_align_x = self[ITEM_ALIGN_X]
		local snap_x = self[SNAP_X]

		local START, END = 'start', 'end'
		if self[_FLIP_COLS] then
			START, END = END, START
		end

		if align_items_x == 'stretch' then
			stretch_items_main_axis(
				cols, 1, #cols, container_w, 'stretch', false,
				set_item_x, set_moving_item_x,
				X, W, _MIN_W, ALIGN_X, END, RIGHT)
		else
			local items_w, item_count = items_sum(cols, 1, #cols, _MIN_W)
			local x, spacing
			if align_items_x == START or align_items_x == LEFT then
				x, spacing = 0, 0
			else
				x, spacing = align_metrics(
					align_items_x, self[CW], items_w, item_count,
					END, RIGHT)
			end
			align_items_main_axis(cols, 1, #cols, x, spacing, false,
				set_item_x, set_moving_item_x,
				X, W, _MIN_W)
		end

		local x = 0
		for _,layer in ipairs(self) do
			if layer.inlayout then

				local col1 = layer[_COL]
				local col2 = col1 + layer[_COL_SPAN] - 1
				local col_item1 = cols[col1]
				local col_item2 = cols[col2]
				local x1 = col_item1[X]
				local x2 = col_item2[X] + col_item2[W]

				local gap1 = (col1 == 1 and 0 or gap_w * .5)
				local gap2 = (col2 == #cols and 0 or gap_w * .5)
				x1 = x1 + gap1
				x2 = x2 - gap2

				local align = layer[ALIGN_X] or item_align_x
				local x, w
				if align == 'stretch' then
					x, w = x1, x2 - x1
				elseif align == START or align == LEFT then
					x, w = x1, layer[_MIN_W]
				elseif align == END or align == RIGHT then
					w = layer[_MIN_W]
					x = x2 - w
				elseif align == 'center' then
					w = layer[_MIN_W]
					x = x1 + (x2 - x1 - w) / 2
				end
				layer[X], layer[W] = snap_xw(x, w, snap_x)
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

--flexbox drop target --------------------------------------------------------

local placeholder = ui.layer:subclass'placeholder'

function layer:setup_placeholder(widget, index)
	local p = self.placeholder
	if not p then
		p = placeholder{
			parent = self,
			background_color = '#333',
		}
		self.placeholder = p
	else
		p.visible = true
	end
	p.padding        = widget.padding
	p.padding_left   = widget.padding_left
	p.padding_right  = widget.padding_right
	p.padding_top    = widget.padding_top
	p.padding_bottom = widget.padding_bottom
	p.min_cw = widget.min_cw
	p.min_ch = widget.min_ch
	p.layer_index = index
	self:invalidate()
end

function layer:override_accept_drag_widget(inherited, widget, mx, my, area)
	if not inherited(self, widget, mx, my, area) then return end
	if self.layout ~= 'flexbox' then return end
	if self.flex_wrap then return end
	if widget.parent ~= self then return end
	widget.moving = true
	self.moving_layer = widget
	widget:to_front()
	self:settag(':item_moving', true)
	--local x, y = widget:to_other(self.parent, 0, 0)
	--local w, h = widget:size()
	--local i = mx and self:flexbox_drop_index(x, y, w, h)
	--if i then
	--	self:setup_placeholder(widget, i)
	--end
	return true
end

function layer:drag_leave()
	local p = self.placeholder
	if p then
		p.visible = false
		self:invalidate()
	end
end

function layer:drop(layer)
	if not layer.moving then return end
	self:settag(':item_moving', false)
	self.moving_layer.moving = false
	self.moving_layer = false
	--local p = self.placeholder
	--p.visible = false
	--local i = p.layer_index
	--if layer.parent == self then --moving
	--	--
	--end
	--self:add_layer(layer, p.layer_index)
end

--[[
function layer:override_hit_test_content(inherited, x, y, reason)
	if reason == 'drop' and self.layout == 'flexbox' then
		print(self:flexbox_drop_index(self.drag_widget:rect())
	end
	return inherited(self, x, y, reason)
end
]]

--top layer (window.view) ----------------------------------------------------

local view = layer:subclass'window_view'
ui.window_view = view
window.view_class = view

--screen-wiping options that work with transparent windows
view.background_color = '#040404f0'
view.background_operator = 'source'

--parent layer interface

view.to_window = view.to_parent
view.from_window = view.from_parent

function view:sync_with_window(w, h)
	self:sync()
	self:sync_window_view(w, h)
	zone'sync_layout'
	self:sync_layout()
	zone()
	self:run_after_layout_funcs()
end

function view:run_after_layout_funcs()
	local funcs = self._after_layout_funcs
	if not funcs then return end
	for i=1,funcs.n do
		funcs[i]()
	end
	self._after_layout_funcs.n = 0
end

function layer:run_after_layout(func)
	if not self.window then return end
	local funcs = attr(self.window.view, '_after_layout_funcs')
	funcs.n = (funcs.n or 0) + 1
	funcs[funcs.n] = func
	self:invalidate()
end

--widgets autoload -----------------------------------------------------------

ui:autoload{
	scrollbar    = 'ui_scrollbox',
	scrollbox    = 'ui_scrollbox',
	teaxtarea    = 'ui_scrollbox',
	editbox      = 'ui_editbox',
	button       = 'ui_button',
	checkbox     = 'ui_button',
	radio        = 'ui_button',
	radiolist    = 'ui_button',
	choicebutton = 'ui_button',
	slider       = 'ui_slider',
	toggle       = 'ui_slider',
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
