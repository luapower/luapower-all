
--Doubly-linked lists in Lua.
--Written by Cosmin Apreutesei. Public Domain.

if not ... then require'linkedlist_test'; return end

local list = {}
list.__index = list

function list:new()
	return setmetatable({length = 0}, self)
end

setmetatable(list, {__call = list.new})

function list:clear()
	self.length = 0
	self.first = nil
	self.last = nil
end

function list:insert_first(t)
	assert(t)
	if self.first then
		self.first._prev = t
		t._next = self.first
		self.first = t
	else
		self.first = t
		self.last = t
	end
	self.length = self.length + 1
end

function list:insert_after(anchor, t)
	if not t then anchor, t = nil, anchor end
	if not anchor then anchor = self.last end
	assert(t)
	if anchor then
		assert(t ~= anchor)
		if anchor._next then
			anchor._next._prev = t
			t._next = anchor._next
		else
			self.last = t
		end
		t._prev = anchor
		anchor._next = t
		self.length = self.length + 1
	else
		self:insert_first(t)
	end
end

function list:insert_last(t)
	self:insert_after(nil, t)
end

function list:insert_before(anchor, t)
	if not t then anchor, t = nil, anchor end
	if not anchor then anchor = self.first end
	anchor = anchor and anchor._prev
	assert(t)
	if anchor then
		self:insert_after(anchor, t)
	else
		self:insert_first(t)
	end
end

function list:remove(t)
	assert(t)
	if t._next then
		if t._prev then
			t._next._prev = t._prev
			t._prev._next = t._next
		else
			assert(t == self.first)
			t._next._prev = nil
			self.first = t._next
		end
	elseif t._prev then
		assert(t == self.last)
		t._prev._next = nil
		self.last = t._prev
	else
		assert(t == self.first and t == self.last)
		self.first = nil
		self.last = nil
	end
	t._next = nil
	t._prev = nil
	self.length = self.length - 1
	return t
end

function list:remove_last()
	if not self.last then return end
	return self:remove(self.last)
end

function list:remove_first()
	if not self.first then return end
	return self:remove(self.first)
end

--iterating

function list:next(last)
	if last then
		return last._next
	else
		return self.first
	end
end

function list:items()
	return self.next, self
end

function list:prev(last)
	if last then
		return last._prev
	else
		return self.last
	end
end

function list:reverse_items()
	return self.prev, self
end

--utils

function list:copy()
	local list = self:new()
	for item in self:items() do
		list:push(item)
	end
	return list
end

return list
