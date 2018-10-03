
--Pub/sub mixin for object systems.
--Written by Cosmin Apreutesei. Public Domain.

local events = {}

local function indexof(v, t) --index of element in array (from glue)
	for i=1,#t do
		if t[i] == v then
			return i
		end
	end
end

local function event_namespace(event) --parse 'event', 'event.ns' or '.ns'
	if type(event) == 'table' then
		return event[1], event[2] --event, ns
	end
	local ev, ns = event:match'^([^%.]*)%.([^%.]+)$'
	ev = ev or event
	if ev == '' then ev = nil end
	return ev, ns
end

--register a function to be called for a specific event type
function events:on(event, func)
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
function events:off(event)
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

function events:once(event, func)
	local ev, ns = event_namespace(event)
	assert(not ns) --TODO: fix this after implementing multiple namespaces
	local id = {}
	local ev = {ev, id}
	self:on(ev, function(...)
		self:off(ev)
		return func(...)
	end)
end

--fire an event, i.e. call its handler method and all observers.
function events:fire(event, ...)
	if self[event] then
		local ret = self[event](self, ...)
		if ret ~= nil then return ret end
	end
	local t = self.__observers and self.__observers[event]
	if t then
		local i = 1
		while true do
			local handler = t[i]
			if not handler then break end --list end or handler removed
			local ret = handler(self, ...)
			if ret ~= nil then return ret end
			if t[i] ~= handler then
				--handler was removed from inside itself, stay at i
			else
				i = i + 1
			end
		end
	end
	if event ~= 'event' then
		return self:fire('event', event, ...)
	end
end

--tests

if not ... then

local obj = {}
for k,v in pairs(events) do obj[k] = v end
local n = 0
local t = {}
local function handler_func(order)
	return function(self, a, b, c)
		assert(a == 3)
		assert(b == 5)
		assert(c == nil)
		n = n + 1
		table.insert(t, order)
	end
end

obj:on('testing.ns1', handler_func(2))
obj:on('testing.ns2', handler_func(3))
obj:on('testing.ns3', handler_func(4))
obj.testing = handler_func(1)

obj:fire('testing', 3, 5)
assert(#t == 4)
assert(t[1] == 1)
assert(t[2] == 2)
assert(t[3] == 3)
assert(t[4] == 4)

t = {}
obj:off'.ns2'
obj:fire('testing', 3, 5)
assert(#t == 3)
assert(t[1] == 1)
assert(t[2] == 2)
assert(t[3] == 4)

t = {}
obj:off'testing'
obj:fire('testing', 3, 5)
assert(#t == 1)
assert(t[1] == 1)

end


return events
