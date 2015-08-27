
--n-tuple implementation based on an index tree.
--Cosmin Apreutesei. Public domain.

if not ... then require'tuple_test'; return end

local weakvals_meta = {__mode = 'v'}

--make a table with weak values.
local function weakvals(t)
	return setmetatable(t or {}, weakvals_meta)
end

--make a table with strong values, i.e. make a table.
local function strongvals(t)
	return t or {}
end

--convert nils and NaNs to be used as table keys.
local NIL = {}
local NAN = {}
local function tokey(v)
	return v == nil and NIL or v ~= v and NAN or v
end

--make a new tuple space, with weak or strong references.
--using strong references is faster but dead tuples won't get collected
--until the space is released.
local function space(weak, index, tuples)

	local weakvals = weak and weakvals or strongvals
	index = weakvals(index) --{k1 = index1}; index1 = {k2 = index2}
	tuples = weakvals(tuples) --{index1 = tuple(k1), index2 = tuple(k1, k2)}

	--find a matching tuple by going through the index tree.
	local function find(n, ...)
		local t = {}
		local index = index
		for i = 1, n do
			local k = tokey(select(i, ...))
			index = index[k]
			if not index then
				return
			end
		end
		return tuples[index]
	end

	--add a new tuple to the index tree.
	local function add(n, tuple)
		local index = index
		for i = 1, n do
			local k = tokey(tuple[i])
			local t = index[k]
			if not t then
				t = weakvals()
				index[k] = t
			end
			if weak and i < n then
				tuple[t] = true --anchor index table in the tuple.
			end
			index = t
		end
		tuples[index] = tuple
		return tuple
	end

	--get a matching tuple, or make a new one and add it to the index.
	local function tuple_vararg(...)
		local n = select('#', ...)
		return find(n, ...) or add(n, {n = n, ...})
	end

	--same as above, but for a fixed number of elements.
	local function tuple_narg(n, ...)
		local tuple = find(n, ...)
		if not tuple then
			tuple = {n = n}
			for i = 1, n do
				tuple[i] = select(i, ...)
			end
			tuple = add(n, tuple)
		end
		return tuple
	end

	--same as above, but using a table as input.
	local function tuple_array(tuple)
		local n = tuple.n or #tuple
		return find(n, unpack(tuple, 1, n)) or add(n, tuple)
	end

	return tuple_vararg, tuple_narg, tuple_array
end

--tuple class

local tuple = {}
local tuple_meta = {__index = tuple, __newindex = false}

local function wrap(t)
	return setmetatable(t, tuple_meta)
end

function tuple:unpack(i, j)
	return unpack(self, i, self.n)
end

tuple_meta.__call = tuple.unpack

function tuple_meta:__tostring()
	local t = {}
	for i=1,self.n do
		t[i] = tostring(self[i])
	end
	return string.format('(%s)', table.concat(t, ', '))
end

--integration with the pp module.
function tuple_meta:__pwrite(write, write_value)
	write'tuple('; write_value(self[1])
	for i=2,self.n do
		write','; write_value(self[i])
	end
	write')'
end

--tuple space module

local space_module

function space_module(weak, ...)
	local tuple_vararg, tuple_narg, tuple_array = space(weak, ...)
	return setmetatable({
		space = space_module,
		narg = function(n, ...)
			return wrap(tuple_narg(n, ...))
		end,
		from_array = function(t)
			return wrap(tuple_array(t))
		end,
	}, {
		__call = function(_, ...)
			return wrap(tuple_vararg(...))
		end
	})
end

--default weak tuple space module

return space_module(true)
