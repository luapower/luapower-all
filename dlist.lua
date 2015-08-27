
--doubly linked lists: dlists make insert, remove and move operations fast,
--and access by index slow.
--Written by Cosmin Apreutesei. Public Domain.

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

function list:push(t)
	assert(t)
	if self.last then
		self.last._next = t
		t._prev = self.last
		self.last = t
	else
		self.first = t
		self.last = t
	end
	self.length = self.length + 1
end

function list:unshift(t)
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

function list:insert(t, after)
	assert(t)
	if not after then
		return self:push(t)
	end
	assert(t ~= after)
	if after._next then
		after._next._prev = t
		t._next = after._next
	else
		self.last = t
	end
	t._prev = after
	after._next = t
	self.length = self.length + 1
end

function list:pop()
	if not self.last then return end
	local t = self.last
	if t._prev then
		t._prev._next = nil
		self.last = t._prev
		t._prev = nil
	else
		self.first = nil
		self.last = nil
	end
	self.length = self.length - 1
	return t
end

function list:shift()
	if not self.first then return end
	local t = self.first
	if t._next then
		t._next._prev = nil
		self.first = t._next
		t._next = nil
	else
		self.first = nil
		self.last = nil
	end
	self.length = self.length - 1
	return t
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


if not ... then require'dlist_test' end


return list
