
--recursive pretty printer with optional indentation and cycle detection.
--Written by Cosmin Apreutesei. Public Domain.

local pf = require'pp_format'

local to_string --fw. decl.

local cache = setmetatable({}, {__mode = 'kv'})
local opt = {parents = {}, sort_keys = true}
local function cached_to_string(v)
	local s = cache[v]
	if not s then
		s = to_string(v, opt)
		cache[v] = s
	end
	return s
end

local function virttype(v)
	return pf.is_stringable(v) and 'string' or type(v)
end

local type_order = {boolean = 1, number = 2, string = 3, table = 4}
local function cmp_func(t)
	local function cmp(a, b)
		local ta, tb = virttype(a), virttype(b)
		if ta == tb then
			if ta == 'boolean' then
				return (a and 1 or 0) < (b and 1 or 0)
			elseif ta == 'string' then
				return tostring(a) < tostring(b)
			elseif ta == 'number' then
				return a < b
			else
				local sa = cached_to_string(a)
				local sb = cached_to_string(b)
				if sa == sb then --keys look the same serialized, compare values
					return cmp(t[a], t[b])
				else
					return sa < sb
				end
			end
		else
			return type_order[ta] < type_order[tb]
		end
	end
	return cmp
end

local function sortedpairs(t)
	local keys = {}
	for k in pairs(t) do
		keys[#keys+1] = k
	end
	table.sort(keys, cmp_func(t))
	local i = 0
	return function()
		i = i + 1
		return keys[i], t[keys[i]]
	end
end

local function is_array_index_key(k, maxn)
	return
		maxn > 0
		and type(k) == 'number'
		and k == math.floor(k)
		and k >= 1
		and k <= maxn
end

local function pretty(v, write, depth, wwrapper,
							indent, parents, quote, line_term, onerror, sort_keys)

	line_term = line_term or '\n'

	if pf.is_serializable(v) then

		pf.write(v, write, quote)

	elseif getmetatable(v) and getmetatable(v).__pwrite then

		wwrapper = wwrapper or function(v)
			pretty(v, write, -1, wwrapper,
				nil, parents, quote, line_term, onerror, sort_keys)
		end
		getmetatable(v).__pwrite(v, write, wwrapper)

	elseif type(v) == 'table' then

		if parents then
			if parents[v] then
				write(onerror and onerror('cycle', v, depth) or 'nil --[[cycle]]')
				return
			end
			parents[v] = true
		end

		write'{'

		local first = true

		local maxn = 0
		for k,v in ipairs(v) do
			maxn = maxn + 1
			if first then
				first = false
			else
				write','
			end			if indent then
				write(line_term)
				write(indent:rep(depth))
			end
			pretty(v, write, depth + 1, wwrapper,
					indent, parents, quote, line_term, onerror, sort_keys)
		end

		local pairs = sort_keys and sortedpairs or pairs
		for k,v in pairs(v) do
			if not is_array_index_key(k, maxn) then
				if first then
					first = false
				else
					write','
				end
				if indent then
					write(line_term)
					write(indent:rep(depth))
				end
				if pf.is_stringable(k) then
					k = tostring(k)
				end
				if pf.is_identifier(k) then
					write(k); write'='
				else
					write'['
					pretty(k, write, depth + 1, wwrapper,
							indent, parents, quote, line_term, onerror, sort_keys)
					write']='
				end
				pretty(v, write, depth + 1, wwrapper,
						indent, parents, quote, line_term, onerror, sort_keys)
			end
		end

		if indent then
			write(line_term)
			write(indent:rep(depth-1))
		end

		write'}'

		if parents then
			parents[v] = nil
		end

	else
		write(onerror and onerror('unserializable', v, depth) or
					string.format('nil --[[unserializable %s]]', type(v)))
	end
end

local function args(opt, ...)
	if type(opt) == 'table' then
		return opt.indent, opt.parents, opt.quote, opt.line_term,
				opt.onerror, opt.sort_keys
	end
	return opt, ...
end

local function to_sink(write, v, ...)
	return pretty(v, write, 1, nil, args(...))
end

function to_string(v, ...) --fw. declared
	local buf = {}
	pretty(v, function(s) buf[#buf+1] = s end, 1, nil, args(...))
	return table.concat(buf)
end

local function to_file(file, v, ...)
	local f = assert(io.open(file, 'wb'))
	f:write'return '
	pretty(v, function(s) f:write(s) end, 1, nil, args(...))
	f:close()
end

local pp_opt = {indent = '   ', parents = {}, sort_keys = true}
local function pp(...)
	local t = {}
	local n = select('#',...)
	for i=1,n do
		local v = select(i,...)
		if type(v) == 'table' then
			t[i] = to_string(v, pp_opt)
		else
			t[i] = v
		end
	end
	print(unpack(t, 1, n))
	return ...
end

if not ... then require'pp_test' end

return setmetatable({
	write = to_sink,
	format = to_string,
	save = to_file,
	print = pp,
	pp = pp, --old API
}, {__call = function(self, ...)
	return pp(...)
end})
