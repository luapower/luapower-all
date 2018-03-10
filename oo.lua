
--object system with virtual properties and method overriding hooks.
--Written by Cosmin Apreutesei. Public Domain.

if not ... then require'oo_test'; return end

local function indexof(v, t) --index of element in array (from glue)
	for i=1,#t do
		if t[i] == v then
			return i
		end
	end
end

local Object = {classname = 'Object'}

local function class(super,...)
	return (super or Object):subclass(...)
end

local function is(obj, class)
	if type(obj) == 'table' and type(obj.is) == 'function' then
		return obj:is(class)
	else
		return false
	end
end

function Object:subclass()
	return setmetatable({super = self, classname = ''}, getmetatable(self))
end

function Object:init(...) return ... end

function Object:create(...)
	local o = setmetatable({super = self}, getmetatable(self))
	o:init(...)
	return o
end

local meta = {}

function meta.__call(o,...)
	return o:create(...)
end

--note: this is the perf. bottleneck of the entire module.
function meta:__index(k)
	if type(k) == 'string' then
		--some keys are not virtualizable to avoid infinite recursion,
		--but they are dynamically inheritable nonetheless.
		if k ~= '__getters' and k ~= '__setters' then
			if k == 'super' then --'super' is not even inheritable
				return nil
			end
			local getters = self.__getters
			local get = getters and getters[k]
			if get then --virtual property
				return get(self, k)
			end
		end
	end
	local super = rawget(self, 'super')
	return super and super[k] --inherited property
end

local function create_table(t, k)
	local v = rawget(t, k)
	if v ~= nil then
		return v
	end
	v = {}
	rawset(t, k, v)
	setmetatable(v, v)
	local super = rawget(t, 'super')
	if super then
		v.__index = create_table(super, k)
	end
	return v
end

function meta:__newindex(k,v)
	if type(k) ~= 'string' then
		rawset(self, k, v)
		return
	end
	local setters = self.__setters
	local set = setters and setters[k]
	if set then --r/w property
		set(self, v)
		return
	end
	local getters = self.__getters
	local get = getters and getters[k]
	if get then --r/o property
		error(string.format('trying to set read only property "%s"', k))
	elseif k:find'^get_' then --install getter
		local getters = create_table(self, '__getters')
		self.__getters[k:sub(5)] = v
	elseif k:find'^set_' then --install setter
		local setters = create_table(self, '__setters')
		self.__setters[k:sub(5)] = v
	elseif k:find'^before_' then --install before hook
		local method_name = k:match'^before_(.*)'
		self:before(method_name, v)
	elseif k:find'^after_' then --install after hook
		local method_name = k:match'^after_(.*)'
		self:after(method_name, v)
	elseif k:find'^override_' then --install override hook
		local method_name = k:match'^override_(.*)'
		self:override(method_name, v)
	else
		rawset(self, k, v)
	end
end

local function install(self, combine, method_name, hook)
	if method_name:find'^get_' then
		local prop = method_name:sub(5)
		local method = combine(self.__getters and self.__getters[prop], hook)
		self[method_name] = method
	elseif method_name:find'^set_' then
		local prop = method_name:sub(5)
		local method = combine(self.__setters and self.__setters[prop], hook)
		self[method_name] = method
	else
		rawset(self, method_name, combine(self[method_name], hook))
	end
end

local function before(method, hook)
	if method then
		return function(self, ...)
			hook(self, ...)
			return method(self, ...)
		end
	else
		return hook
	end
end
function Object:before(method_name, hook)
	install(self, before, method_name, hook)
end

local function after(method, hook)
	if method then
		return function(self, ...)
			method(self, ...)
			return hook(self, ...)
		end
	else
		return hook
	end
end
function Object:after(method_name, hook)
	install(self, after, method_name, hook)
end

local function noop() return end
local function override(method, hook)
	local method = method or noop
	return function(self, ...)
		return hook(self, method, ...)
	end
end
function Object:override(method_name, hook)
	install(self, override, method_name, hook)
end

function Object:is(class)
	local super = rawget(self, 'super')
	if super == class or self.classname == class then
		return true
	elseif super then
		return super:is(class)
	else
		return false
	end
end

--returns iterator<k,v,source>; iterates bottom-up in the inheritance chain
function Object:allpairs()
	local source = self
	local k,v
	return function()
		k,v = next(source,k)
		if k == nil then
			source = rawget(source, 'super')
			if source == nil then return nil end
			k,v = next(source)
		end
		return k,v,source
	end
end

--returns all properties including the inherited ones and their current values
function Object:properties()
	local values = {}
	for k,v,source in self:allpairs() do
		if values[k] == nil then
			values[k] = v
		end
	end
	return values
end

local function copy_table(dst, src, k, override)
	local st = rawget(src, k)
	if st then
		local dt = rawget(dst, k)
		if dt == nil then
			dt = {}
			rawset(dst, k, dt)
		end
		for k,v in pairs(st) do
			if override or rawget(dt, k) == nil then
				rawset(dt, k, v)
			end
		end
	else
		local super = rawget(src, 'super')
		if super then
			return copy_table(dst, super, k)
		end
	end
end

function Object:inherit(other, override)
	if not is(other, Object) then --plain table, treat is as mixin
		for k,v in pairs(other) do
			if override or self[k] == nil then
				self[k] = v --not rawsetting so that meta-methods apply
			end
		end
		return
	end
	other = other or rawget(self, 'super')
	local properties = other:properties()
	for k,v in pairs(properties) do
		if (override or rawget(self, k) == nil)
			and k ~= 'classname' --keep the classname (preserve identity)
			and k ~= 'super' --keep super (preserve dynamic inheritance)
			and k ~= '__getters' --getters are deep-copied
			and k ~= '__setters' --getters are deep-copied
		then
			rawset(self, k, v)
		end
	end
	--copy getters and setters
	copy_table(self, other, '__getters', override)
	copy_table(self, other, '__setters', override)

	--copy metafields if metatables are different
	local src_meta = getmetatable(other)
	local dst_meta = getmetatable(self)
	if src_meta ~= dst_meta then
		for k,v in pairs(src_meta) do
			if override or rawget(dst_meta, k) == nil then
				rawset(dst_meta, k, v)
			end
		end
	end
	return self
end

function Object:detach()
	self:inherit(rawget(self, 'super'))
	self.classname = self.classname --store the classname
	rawset(self, 'super', nil)
	return self
end

function Object:gen_properties(names, getter, setter)
	for k in pairs(names) do
		if getter then
			self['get_'..k] = function(self) return getter(self, k) end
		end
		if setter then
			self['set_'..k] = function(self, v) return setter(self, k, v) end
		end
	end
end

--events

local function event_namespace(event) --parse 'event', 'event.ns' or '.ns'
	if type(event) == 'table' then
		return unpack(event)
	end
	local ev, ns = event:match'^([^%.]*)%.(.*)$'
	ev = ev or event
	if ev == '' then ev = nil end
	return ev, ns
end

--register a function to be called for a specific event type
function Object:on(event, func)
	local ev, ns = event_namespace(event)
	assert(ev, 'event name missing')
	self.__observers = self.__observers or {}
	self.__observers[ev] = self.__observers[ev] or {}
	table.insert(self.__observers[ev], func)
	if ns then
		self.__observers[ev][ns] = self.__observers[ev][ns] or {}
		table.insert(self.__observers[ev][ns], func)
	end
end

--remove a handler or all handlers of an event and/or namespace
local function remove_all(t, v)
	while true do
		local i = indexof(v, t)
		if not i then return end
		table.remove(t, i)
	end
end
local function remove_all_ns(t_ev, ns)
	local t_ns = t_ev and t_ev[ns]
	if not t_ns then return end
	for _,f in ipairs(t_ns) do
		remove_all(t_ev, f)
	end
	t_ev[ns] = nil
end
function Object:off(event)
	if not self.__observers then return end
	local ev, ns = event_namespace(event)
	if ev and ns then
		remove_all_ns(self.__observers[ev], ns)
	elseif ev then
		self.__observers[ev] = nil
	elseif ns then
		for _,t_ev in pairs(self.__observers) do
			remove_all_ns(t_ev, ns)
		end
	else
		self.__observers = nil
	end
end

--fire an event, i.e. call its handler method and all observers.
function Object:fire(event, ...)
	if self[event] then
		local ret = self[event](self, ...)
		if ret ~= nil then return ret end
	end
	local t = self.__observers and self.__observers[event]
	if t then
		for i = 1, #t do
			local handler = t[i]
			local ret = handler(self, ...)
			if ret ~= nil then return ret end
		end
	end
	if event ~= 'event' then
		return self:fire('event', event, ...)
	end
end

--debugging

local function pad(s, n) return s..(' '):rep(n - #s) end

local props_conv = {g = 'r', s = 'w', gs = 'rw', sg = 'rw'}
local oo_state_fields = {super=1, __getters=1, __setters=1, __observers=1}

function Object:inspect(show_oo)
	local glue = require'glue'
	--collect data
	local supers = {} --{super1,...}
	local keys = {} --{super = {key1 = true,...}}
	local props = {} --{super = {prop1 = true,...}}
	local sources = {} --{key = source}
	local source, keys_t, props_t
	for k,v,src in self:allpairs() do
		if sources[k] == nil then sources[k] = src end
		if src ~= source then
			source = src
			keys_t = {}
			props_t = {}
			keys[source] = keys_t
			props[source] = props_t
			supers[#supers+1] = source
		end
		if sources[k] == src then
			keys_t[k] = true
		end
	end
	if self.__getters then
		for prop in pairs(self.__getters) do
			if prop ~= '__index' then
				props_t[prop] = 'g'
			end
		end
	end
	if self.__setters then
		for prop in pairs(self.__setters) do
			if prop ~= '__index' then
				props_t[prop] = (props_t[prop] or '')..'s'
			end
		end
	end

	--print values
	for i,super in ipairs(supers) do
		if show_oo or super ~= Object then
			print('from '..(
				super == self and
					('self'..(super.classname ~= ''
						and ' ('..super.classname..')' or ''))
					or 'super #'..tostring(i-1)..(super.classname ~= ''
						and ' ('..super.classname..')' or '')
					)..':')
			for k,v in glue.sortedpairs(props[super]) do
				print('    '..pad(k..' ('..props_conv[v]..')', 16),
					tostring(super[k]))
			end
			for k in glue.sortedpairs(keys[super]) do
				local oo = oo_state_fields[k] or Object[k] ~= nil
				if show_oo or not oo then
					print('  '..(oo and '* ' or '  ')..pad(k, 16),
						tostring(super[k]))
				end
			end
		end
	end
end

setmetatable(Object, meta)

return setmetatable({
	class = class,
	is = is,
	Object = Object,
}, {
	__index = function(t,k)
		return function(super, ...)
			if type(super) == 'string' then
				super = t[super]
			end
			local cls = class(super, ...)
			cls.classname = k
			t[k] = cls
			return cls
		end
	end
})

