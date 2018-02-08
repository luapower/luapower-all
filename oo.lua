
--object system with virtual properties and method overriding hooks.
--Written by Cosmin Apreutesei. Public Domain.

if not ... then require'oo_test'; return end

local Object = {classname = 'Object'}

local function class(super,...)
	return (super or Object):subclass(...)
end

function Object:subclass()
	return setmetatable({super = self, classname = ''}, getmetatable(self))
end

function Object:init(...) end

function Object:create(...)
	local o = setmetatable({super = self}, getmetatable(self))
	o:init(...)
	return o
end

local meta = {}

function meta.__call(o,...)
	return o:create(...)
end

function meta.__index(o,k)
	--some keys are not virtualizable to avoid infinite recursion,
	--but they are dynamically inheritable nonetheless.
	if k == 'getproperty' or type(k) == 'string' and k:find'^[gs]et_' then
		local super = rawget(o, 'super')
		return super and super[k]
	end
	return o:getproperty(k)
end

function meta.__newindex(o,k,v)
	o:setproperty(k,v)
end

local function noop() end
local function pass(...) return ... end

function Object:before(method_name, hook)
	local method = self[method_name] or pass
	rawset(self, method_name, function(self, ...)
		return method(self, hook(self, ...))
	end)
end

function Object:after(method_name, hook)
	local method = self[method_name] or pass
	rawset(self, method_name, function(self, ...)
		return hook(self, method(self, ...))
	end)
end

function Object:override(method_name, hook)
	local method = self[method_name] or noop
	rawset(self, method_name, function(self, ...)
		return hook(self, method, ...)
	end)
end

function Object:getproperty(k)
	if type(k) == 'string' then
		local get = self['get_'..k]
		if get then --virtual property
			return get(self, k)
		else
			local set = self['set_'..k]
			if set then --stored property
				local state = rawget(self, 'state')
				if state then
					return state[k]
				end
			end
		end
	end
	local super = rawget(self, 'super')
	if super then --inherited property
		return super[k]
	end
end

function Object:setproperty(k,v)
	if type(k) == 'string' then
		local get = self['get_'..k]
		if get then --virtual property
			local set = self['set_'..k]
			if set then --r/w property
				set(self, v)
			else --r/o property
				error(string.format('trying to set read only property "%s"', k))
			end
		else
			local set = self['set_'..k]
			if set then --stored property
				if not rawget(self, 'state') then
					rawset(self, 'state', {})
				end
				set(self, v) --if the setter breaks, the property is not updated
				self.state[k] = v
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
	else
		rawset(self, k, v)
	end
end

function Object:is(class)
	if self.super == class or self.classname == class then
		return true
	elseif self.super then
		return self.super:is(class)
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
			source = source.super
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

function Object:inherit(other, override)
	local properties = other:properties()
	for k,v in pairs(properties) do
		if (override or rawget(self, k) == nil)
			and k ~= 'classname' --keep the classname (preserve identity)
			and k ~= 'super' --keep super (preserve dynamic inheritance)
		then
			rawset(self, k, v)
		end
	end
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
	self:inherit(self.super)
	self.classname = self.classname --store the classname
	self.super = nil
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
	local ev, ns = event:match'^([^%.]*)%.([^%.]+)$'
	ev = ev or event
	if ev == '' then ev = nil end
	return ev, ns
end

function Object:on(event, func)
	local ev, ns = event_namespace(event)
	assert(ev, 'event name missing')
	self.observers = self.observers or {}
	self.observers[ev] = self.observers[ev] or {}
	table.insert(self.observers[ev], func)
	if ns then
		self.observers[ev][ns] = self.observers[ev][ns] or {}
		table.insert(self.observers[ev][ns], func)
	end
end

--remove a handler or all handlers of an event and/or namespace
local function indexof(v, t)
	for i=1,#t do
		if t[i] == v then
			return i
		end
	end
end
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
	if not self.observers then return end
	local ev, ns = event_namespace(event)
	if ev and ns then
		remove_all_ns(self.observers[ev], ns)
	elseif ev then
		self.observers[ev] = nil
	elseif ns then
		for _,t_ev in pairs(self.observers) do
			remove_all_ns(t_ev, ns)
		end
	end
end

--fire an event, i.e. call its handler method and all observers.
function Object:fire(event, ...)
	if self[event] then
		local ret = self[event](self, ...)
		if ret ~= nil then return ret end
	end
	local t = self.observers and self.observers[event]
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
local oo_state_fields = {state=1, super=1, observers=1}

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
			if type(k) == 'string' and k:find'^[gs]et_' then
				local what, prop = k:match'^([gs])et_(.*)'
				props_t[prop] = (props_t[prop] or '')..what
			else
				keys_t[k] = true
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

