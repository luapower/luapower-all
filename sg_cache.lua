--cache class: provides shared caching for scene graphs elements.
--an element's fields "invalid" and "nocache" are used for cache control.
--a cache object's method "free" is used for freeing the object.
local glue = require'glue'

local Cache = {} --if you have shared nodes between scene graphs, then share the cache too.

local weak_keys = {__mode = 'k'} --the cache is weak: when elements go, associated objects go too.

function Cache:new()
	local objects = setmetatable({}, weak_keys) --we rely on objects ability to free resources on their __gc.
	return glue.merge({objects = objects}, self)
end

function Cache:get(e)
	if e.invalid or e.nocache then
		self:release(e)
		return
	end
	return self.objects[e]
end

function Cache:set(e,o)
	assert(self.objects[e] == nil, 'cache: object alreay set')
	self.objects[e] = o
end

function Cache:release(e) --clear cached objects of e
	local o = self.objects[e]
	if o then
		if o.free then o:free() end
		self.objects[e] = nil
	end
end

function Cache:release_all(e) --clear cached objects of e and its children
	if type(e) ~= 'table' then return end
	self:release(e)
	for k,v in pairs(e) do
		self:release_all(k)
		self:release_all(v)
	end
end

function Cache:clear()
	for e in pairs(self.objects) do
		self:release(e)
	end
	self.objects = {}
end

function Cache:free()
	self:clear()
	self.objects = nil
end

return Cache
