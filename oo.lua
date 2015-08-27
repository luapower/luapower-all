
--object system with virtual properties and method overriding hooks.
--Written by Cosmin Apreutesei. Public Domain.

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
	if k == 'getproperty' then --'getproperty' is not virtualizable to avoid infinite recursion
		return rawget(o, 'super').getproperty --...but it is inheritable
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
	if type(k) == 'string' and rawget(self, 'get_'..k) then --virtual property
		return rawget(self, 'get_'..k)(self, k)
	elseif rawget(self, 'set_'..k) then --stored property
		if rawget(self, 'state') then
			return self.state[k]
		end
	elseif rawget(self, 'super') then --inherited property
		return rawget(self, 'super')[k]
	end
end

function Object:setproperty(k,v)
	if type(k) == 'string' then
		if rawget(self, 'get_'..k) then --virtual property
			if rawget(self, 'set_'..k) then --r/w property
				rawget(self, 'set_'..k)(self, v)
			else --r/o property
				error(string.format('trying to set read only property "%s"', k))
			end
		elseif rawget(self, 'set_'..k) then --stored property
			if not rawget(self, 'state') then rawset(self, 'state', {}) end
			rawget(self, 'set_'..k)(self, v) --if the setter breaks, the property is not updated
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
	else
		rawset(self, k, v)
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
			and k ~= 'classname' --we keep our classname (we don't change our identity)
			and k ~= 'super' --we keep our super (we don't change the dynamic inheritance)
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
end

function Object:detach()
	self:inherit(self.super)
	self.classname = self.classname --if we're an instance, we would have no classname
	self.super = nil
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

local function pad(s, n) return s..(' '):rep(n - #s) end

local props_conv = {g = 'r', s = 'w', gs = 'rw', sg = 'rw'}

function Object:inspect()
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
		print('from '..(
					super == self and ('self'..(super.classname ~= '' and ' ('..super.classname..')' or ''))
					or 'super #'..tostring(i-1)..(super.classname ~= '' and ' ('..super.classname..')' or '')
				)..':')
		for k,v in glue.sortedpairs(props[super]) do
			print('   '..pad(k..' ('..props_conv[v]..')', 16), tostring(super[k]))
		end
		for k in glue.sortedpairs(keys[super]) do
			if k ~= 'super' and k ~= 'state' and k ~= 'classname' then
				print('   '..pad(k, 16), tostring(super[k]))
			end
		end
	end
end

setmetatable(Object, meta)

if not ... then require'oo_test' end

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

