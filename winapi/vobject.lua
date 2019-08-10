
--oo/oo-system/vobject: object model with virtual properties
--and method overriding hooks.
--Written by Cosmin Apreutesei. Public Domain.

local events = require'events'

--subclassing defined by super:__subclass(derived).
--introspection is in terms of class:__super().
setfenv(1, require'winapi')

function subclass(class, super)
	if super and super.__subclass then super:__subclass(class) end
	return class
end

function class(super)
	return subclass({}, super)
end

function isinstance(object, class) --defined in terms of object:__super()
	if type(object) ~= 'table' then return false end
	if not object.__super then return false end
	local super = object:__super()
	if super == nil then return false end
	if super == class then return true end
	return isinstance(super, class)
end

--subclassing and instantiation ----------------------------------------------

VObject = class()

VObject.__meta = {}

--class constructor (subclassing).
function VObject:__subclass(c)
	c.__meta = c.__meta or {}
	c.__meta.__index = c --dynamically inherit class fields
	c.__meta.__class = c --for introspection
	merge(c.__meta, self.__meta) --statically inherit instance metamethods
	c.__index = self --dynamically inherit super class fields
	c.__newindex = self.__newindex --before, after, override.
	c.__call = self.__call --statically inherit super class metamethods
	c.__gc = self.__gc
	setmetatable(c, c) --class metamethods are class methods
end

--object constructor (instantiation).
--assumed a stub by subclasses, so they don't use callsuper().
function VObject:__init(...) end

function VObject:__call(...) --don't override this, override __init instead.
	local o = setmetatable({}, self.__meta)
	o:__init(...)
	return o
end

update(VObject, events) --on(), off(), fire()

--Implement pseudo-class methods:
--	function Foo:before_bar(...) end
--	function Foo:after_bar(...) end
--	function Foo:override_bar(inherited, ...)
--		local result = inherited(self, ...)
--	end
function VObject:__newindex(k, v)
	if type(k) == 'string' then
		if k:find'^before_' then
			local method = k:match'^before_(.*)'
			local f = self[method]
			self[method] = function(...)
				v(...)
				return f(...)
			end
			return
		elseif k:find'^after_' then
			local method = k:match'^after_(.*)'
			local f = self[method]
			self[method] = function(...)
				f(...)
				return v(...)
			end
			return
		elseif k:find'^override_' then
			local method = k:match'^override_(.*)'
			local f = self[method]
			self[method] = function(self, ...)
				return v(self, f, ...)
			end
			return
		end
	end
	rawset(self, k, v)
end

setmetatable(VObject, VObject)

--introspection --------------------------------------------------------------

function VObject:__super() --must work for both instances and classes
	return getmetatable(self).__class or self.__index
end

function VObject:__supers() --returns iterator<class> with all super classes, bottom up
	return function(_,o)
		return o:__super()
	end,nil,self
end

function VObject:__allpairs() --returns iterator<k,v,source>; iterates from bottom up
	local source = self
	local k,v
	return function()
		k,v = next(source,k)
		if k == nil then
			source = source:__super()
			if source == nil then return nil end
			k,v = next(source)
		end
		return k,v,source
	end
end

function VObject:__pairs()
	local t = {}
	for k,v in self:__allpairs() do
		if t[k] == nil then t[k] = v end
	end
	return pairs(t)
end

function VObject:__properties()
	local t = {} --{property_name = class_where_it_was_last_redefined}
	for k,_,source in self:__allpairs() do
		if t[k] == nil then t[k] = source end
	end
	return pairs(t)
end

--virtual properties ---------------------------------------------------------

--indexing attribute <name> returns the result of class:get_<name>().
--setting <value> on attribute <name> calls class:set_<name>(value).
--if there's a setter but no getter, <value> gets stored in table
--object.__state and class:set_<name>(value) is called.
--a property with a getter but no setter cannot be assigned to.
--a property with no getter and no setter is rawset.

local VObject_subclass = VObject.__subclass

function VObject:__subclass(c) --class constructor
	VObject_subclass(self,c)
	c.__meta.__index = function(o,k)
		local v = c[k]
		if v ~= nil then return v end --class property or method
		if type(k) == 'string' then
			local get = c['get_'..k]
			if get then return get(o) end --virtual property
		end
	end
	c.__meta.__newindex = function(o,k,v)
		if type(k) == 'string' then
			local set = c['set_'..k]
			if set then --r/w or w/o property
				set(o,v)
				return
			elseif c['get_'..k] then --r/o property
				error(string.format('trying to set read only property "%s"', k), 2)
			end
		end
		rawset(o,k,v)
	end
end

function VObject:__gen_vproperties(names, getter, setter)
	for k in pairs(names) do
		if getter then
			self['get_'..k] = function(self) return getter(self, k) end
		end
		if setter then
			self['set_'..k] = function(self, v) return setter(self, k, v) end
		end
	end
end

--introspection

function VObject:get___class()
	return getmetatable(self).__class
end

function VObject:__vproperties() --returns iter() -> property, {get = class, set = class}
	local t = {}
	for k,v,source in self:__allpairs(self) do
		if type(k) == 'string' and k:find'^get_' or k:find'^set_' then
			local k,what = k:sub(5), k:sub(1,3)
			local t = t[k] or {}; t[k] = t[k] or t
			if what == 'get' and t.get == nil then t.get = source end
			if what == 'set' and t.set == nil then t.set = source end
		end
	end
	return pairs(t)
end

--showcase

if not ... then

do
	--subclassing
	local c = class(VObject)
	local init
	function c:__init(...) init = true end --dummy constructor
	local o = c('hi', 'there')
	assert(init)
	assert(o.unknown == nil) --non-existent property
	--isinstance
	assert(isinstance(o, c) == true)
	assert(isinstance(o, VObject) == true)
	assert(isinstance(o, o) == false)
	--introspection
	for k,v,source in o:__allpairs() do _G.print(k,source) end
	o.own_property = true
	for k,v in o:__properties() do _G.print(k,v) end
	for c in o:__supers() do _G.print(c, o:__super(), o:__super():__super()) end
end

do
	local STATUS = 'OK'
	local c = class(VObject)
	function c:__init(...) print('init:', ...) end
	function c:get_status() return STATUS end
	function c:set_status(s) STATUS = s end
	function c:set_text(s) end
	local o = c('hi', 'there')
	assert(o.status == 'OK') --virtual property get
	o.status = 'EVEN BETTER' --virtual property set
	assert(o.__state == nil) --no active properties yet
	o.text = 'hello' --active property set
	assert(o.text == 'hello') --active property get
	assert(o.__state.text == o.text) --confirm the active property
	assert(o.unknown == nil) --non-existent property
	assert(o[1234] == nil) --non-existent property
	assert(o[false] == nil) --non-existent property
	--isinstance
	assert(isinstance(o, VObject) == true)
	assert(isinstance(o, c) == true)
	assert(isinstance(o, o) == false)
	--introspection
	for k,v in o:__vproperties() do _G.print(k, v.get, v.set) end
end

end

