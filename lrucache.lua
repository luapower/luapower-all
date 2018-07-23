
--LRU cache.
--Written by Cosmin Apreutesei. Public Domain.

local dlist = require'dlist'

local cache = {}
cache.__index = cache

cache.max_size = 1

function cache:clear()
	if self.keys then
		for val in pairs(self.keys) do
			self:free_value(val)
		end
	end
	self.lru = dlist()
	self.values = {} --{key -> val}
	self.keys = {} --{val -> key}
	self.total_size = 0
	return self
end

function cache:new(t)
	t = t or {}
	local self = setmetatable(t, self)
	return self:clear()
end

setmetatable(cache, {__call = cache.new})

function cache:free()
	if self.keys then
		for val in pairs(self.keys) do
			self:free_value(val)
		end
		self.lru = false
		self.values = false
		self.keys = false
		self.total_size = 0
	end
end

function cache:free_size()
	return self.max_size - self.total_size
end

function cache:value_size(val) return 1 end --stub, size must be >= 0 always
function cache:free_value(val) end --stub

function cache:get(key)
	local val = self.values[key]
	if not val then return nil end
	self.lru:remove(val)
	self.lru:insert_first(val)
	return val
end

function cache:_remove(key, val)
	local val_size = self:value_size(val)
	self.lru:remove(val)
	self:free_value(val)
	self.values[key] = nil
	self.keys[val] = nil
	self.total_size = self.total_size - val_size
end

function cache:remove(key)
	local val = self.values[key]
	if not val then return nil end
	self:_remove(key, val)
	return val
end

function cache:remove_val(val)
	local key = self.keys[val]
	if not key then return nil end
	self:_remove(key, val)
	return key
end

function cache:remove_last()
	local val = self.lru.last
	if not val then return nil end
	self:_remove(self.keys[val], val)
	return val
end

function cache:put(key, val)
	local val_size = self:value_size(val)
	local old_val = self.values[key]
	if old_val then
		self.lru:remove(val)
		self.total_size = self.total_size - val_size
	end
	while self.lru.last and self.total_size + val_size > self.max_size do
		self:remove_last()
	end
	if not old_val then
		self.values[key] = val
		self.keys[val] = key
	end
	self.lru:insert_first(val)
	self.total_size = self.total_size + val_size
end

return cache
