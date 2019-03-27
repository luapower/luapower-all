
--hi-level thread primitives based on pthread and luastate.
--Written by Cosmin Apreutesei. Public Domain.

if not ... then require'thread_test'; return; end

local pthread = require'pthread'
local luastate = require'luastate'
local glue = require'glue'
local ffi = require'ffi'
local addr = glue.addr
local ptr = glue.ptr

local thread = {}

--shareable objects ----------------------------------------------------------

--objects that implement the shareable interface can be shared
--between Lua states when passing args in and out of Lua states.

local typemap = {} --{ctype_name = {identify=f, decode=f, encode=f}}

--shareable pointers
local function pointer_class(in_ctype, out_ctype)
	local class = {}
	function class.identify(p)
		return ffi.istype(in_ctype, p)
	end
	function class.encode(p)
		return {addr = addr(p)}
	end
	function class.decode(t)
		return ptr(out_ctype or in_ctype, t.addr)
	end
	return class
end

function thread.shared_object(name, class)
	if typemap[name] then return end --ignore duplicate registrations
	typemap[name] = class
end

function thread.shared_pointer(in_ctype, out_ctype)
	thread.shared_object(in_ctype, pointer_class(in_ctype, out_ctype))
end

thread.shared_pointer'lua_State*'
thread.shared_pointer('pthread_t', 'pthread_t*')
thread.shared_pointer('pthread_mutex_t', 'pthread_mutex_t*')
thread.shared_pointer('pthread_rwlock_t', 'pthread_rwlock_t*')
thread.shared_pointer('pthread_cond_t', 'pthread_cond_t*')

--identify a shareable object and encode it.
local function encode_shareable(x)
	for typename, class in pairs(typemap) do
		if class.identify(x) then
			local t = class.encode(x)
			t.type = typename
			return t
		end
	end
end

--decode an encoded shareable object
local function decode_shareable(t)
	return typemap[t.type].decode(t)
end

--encode all shareable objects in a packed list of args
function thread._encode_args(t)
	t.shared = {} --{i1,...}
	for i=1,t.n do
		local e = encode_shareable(t[i])
		if e then
			t[i] = e
			--put the indices of encoded objects aside for identification
			--and easy traversal when decoding
			table.insert(t.shared, i)
		end
	end
	return t
end

--decode all encoded shareable objects in a packed list of args
function thread._decode_args(t)
	for _,i in ipairs(t.shared) do
		t[i] = decode_shareable(t[i])
	end
	return t
end

--events ---------------------------------------------------------------------

ffi.cdef[[
typedef struct {
	int flag;
	pthread_mutex_t mutex;
	pthread_cond_t cond;
} thread_event_t;
]]

function thread.event(set)
	local e = ffi.new'thread_event_t'
	pthread.mutex(nil, e.mutex)
	pthread.cond(nil, e.cond)
	e.flag = set and 1 or 0
	return e
end

local event = {}

local function set(self, val)
	self.mutex:lock()
	self.flag = val
	self.cond:broadcast()
	self.mutex:unlock()
end

function event:set()
	set(self, 1)
end

function event:clear()
	set(self, 0)
end

function event:isset()
	self.mutex:lock()
	local ret = self.flag == 1
	self.mutex:unlock()
	return ret
end

function event:wait(timeout)
	self.mutex:lock()
	local cont = true
	while cont do
		if self.flag == 1 then
			self.mutex:unlock()
			return true
		end
		cont = self.cond:wait(self.mutex, timeout)
	end
	self.mutex:unlock()
	return false
end

ffi.metatype('thread_event_t', {__index = event})

thread.shared_pointer('thread_event_t', 'thread_event_t*')

--queues ---------------------------------------------------------------------

local queue = {}
queue.__index = queue

function thread.queue(maxlen)
	assert(not maxlen or (math.floor(maxlen) == maxlen and maxlen >= 1),
		'invalid queue max. length')
	local state = luastate.open() --values will be kept on the state's stack
	return setmetatable({
		state          = state,
		mutex          = pthread.mutex(),
		cond_not_empty = pthread.cond(),
		cond_not_full  = pthread.cond(),
		maxlen         = maxlen,
	}, queue)
end

function queue:free()
	self.cond_not_full:free();  self.cond_not_full = nil
	self.cond_not_empty:free(); self.cond_not_empty = nil
	self.state:close();         self.state = nil
	self.mutex:free();          self.mutex = nil
end

function queue:maxlength()
	return self.maxlen
end

local function queue_length(self)
	return self.state:gettop()
end

local function queue_isfull(self)
	return self.maxlen and queue_length(self) == self.maxlen
end

local function queue_isempty(self)
	return queue_length(self) == 0
end

function queue:length()
	self.mutex:lock()
	local ret = queue_length(self)
	self.mutex:unlock()
	return ret
end

function queue:isfull()
	self.mutex:lock()
	local ret = queue_isfull(self)
	self.mutex:unlock()
	return ret
end

function queue:isempty()
	self.mutex:lock()
	local ret = queue_isempty(self)
	self.mutex:unlock()
	return ret
end

function queue:push(val, timeout)
	self.mutex:lock()
	while queue_isfull(self) do
		if not self.cond_not_full:wait(self.mutex, timeout) then
			self.mutex:unlock()
			return false, 'timeout'
		end
	end
	local was_empty = queue_isempty(self)
	self.state:push(val)
	local len = queue_length(self)
	if was_empty then
		self.cond_not_empty:broadcast()
	end
	self.mutex:unlock()
	return true, len
end

local function queue_remove(self, index, timeout)
	self.mutex:lock()
	while queue_isempty(self) do
		if not self.cond_not_empty:wait(self.mutex, timeout) then
			self.mutex:unlock()
			return false, 'timeout'
		end
	end
	local was_full = queue_isfull(self)
	local val = self.state:get(index)
	self.state:remove(index)
	local len = queue_length(self)
	if was_full then
		self.cond_not_full:broadcast()
	end
	self.mutex:unlock()
	return true, val, len
end

function queue:pop(timeout)
	return queue_remove(self, -1, timeout)
end

--NOTE: this is O(N) where N = self:length().
function queue:shift(timeout)
	return queue_remove(self, 1, timeout)
end

function queue:peek(i)
	i = i or 1
	self.mutex:lock()
	local len = queue_length(self)
	if i <= 0 then
		i = len + i + 1  -- index -1 is top
	end
	if i < 1 or i > len then
		self.mutex:unlock()
		return false
	end
	local val = self.state:get(i)
	self.mutex:unlock()
	return true, val
end

--queues / shareable interface

function queue:identify()
	return getmetatable(self) == queue
end

function queue:encode()
	return {
		state_addr          = addr(self.state),
		mutex_addr          = addr(self.mutex),
		cond_not_full_addr  = addr(self.cond_not_full),
		cond_not_empty_addr = addr(self.cond_not_empty),
		maxlen              = self.maxlen,
	}
end

function queue.decode(t)
	return setmetatable({
		state          = ptr('lua_State*',       t.state_addr),
		mutex          = ptr('pthread_mutex_t*', t.mutex_addr),
		cond_not_full  = ptr('pthread_cond_t*',  t.cond_not_full_addr),
		cond_not_empty = ptr('pthread_cond_t*',  t.cond_not_empty_addr),
		maxlen         = t.maxlen,
	}, queue)
end

thread.shared_object('queue', queue)

--threads --------------------------------------------------------------------

function thread.init_state(state)
	state:openlibs()
	state:push{[0] = arg[0]} --used by some modules to get the exe dir
	state:setglobal'arg'
	if package.loaded.bundle_loader then
		local bundle_luastate = require'bundle_luastate'
		bundle_luastate.init_bundle(state)
	end
end

function thread.new(func, ...)
	local state = luastate.open()
	thread.init_state(state)
	state:push(function(func, args)

	   local ffi = require'ffi'
		local pthread = require'pthread'
		local luastate = require'luastate'
		local glue = require'glue'
		local thread = require'thread'
	   local cast = ffi.cast
	   local addr = glue.addr

		local function pass(ok, ...)
			local retvals = ok and thread._encode_args(glue.pack(...)) or {err = ...}
			rawset(_G, '__ret', retvals) --is this the only way to get them out?
		end
	   local function worker()
	   	local t = thread._decode_args(args)
	   	pass(xpcall(func, debug.traceback, glue.unpack(t)))
	   end

		--worker_cb is anchored by luajit along with the function it frames.
	   local worker_cb = cast('void *(*)(void *)', worker)
	   return addr(worker_cb)
	end)
	local args = glue.pack(...)
	local encoded_args = thread._encode_args(args)
	local worker_cb_ptr = ptr(state:call(func, encoded_args))
	local pthread = pthread.new(worker_cb_ptr)

	return setmetatable({
			pthread = pthread,
			state = state,
			args = args, --keep args to avoid shareables from being collected
		}, thread)
end

thread.__index = thread

function thread:join()
	self.pthread:join()
	self.args = nil --release args
	--get the return values of worker function
	self.state:getglobal'__ret'
	local retvals = self.state:get()
	self.state:close()
	--propagate the error
	if retvals.err then
		error(retvals.err, 2)
	end
	return glue.unpack(thread._decode_args(retvals))
end

--threads / shareable interface

function thread:identify()
	return getmetatable(self) == thread
end

function thread:encode()
	return {
		pthread_addr = addr(self.pthread),
		state_addr   = addr(self.state),
	}
end

function thread.decode(t)
	return setmetatable({
		pthread = ptr('pthread_t*', t.thread_addr),
		state   = ptr('lua_State*', t.state_addr),
	}, thread)
end

thread.shared_object('thread', thread)

--thread pools ---------------------------------------------------------------

local pool = {}
pool.__index = pool

local function pool_worker(q)
	while true do
		print('waiting for task', q:length())
		local _, task = q:shift()
		print'got task'
		task()
	end
end

function thread.pool(n)
	local t = {}
	t.queue = thread.queue(1)
	for i = 1, n do
		t[i] = thread.new(pool_worker, t.queue)
	end
	return setmetatable(t, pool)
end

function pool:join()
	for i = #self, 1, -1 do
		self[i]:join()
		self[i] = nil
	end
	self.queue:free()
	self.queue = nil
end

function pool:push(task, timeout)
	return self.queue:push(task, timeout)
end


return thread
