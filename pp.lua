
--Recursive pretty printer with optional indentation and cycle detection.
--Written by Cosmin Apreutesei. Public Domain.

if not ... then require'pp_test'; return end

local type, tostring = type, tostring
local string_format, string_dump = string.format, string.dump
local math_huge, math_floor = math.huge, math.floor

--pretty printing for non-structured types -----------------------------------

local escapes = { --don't add unpopular escapes here
	['\\'] = '\\\\',
	['\t'] = '\\t',
	['\n'] = '\\n',
	['\r'] = '\\r',
}

local function escape_byte_long(c1, c2)
	return string_format('\\%03d%s', c1:byte(), c2)
end
local function escape_byte_short(c)
	return string_format('\\%d', c:byte())
end
local function quote_string(s, quote)
	s = s:gsub('[\\\t\n\r]', escapes)
	s = s:gsub(quote, '\\%1')
	s = s:gsub('([^\32-\126])([0-9])', escape_byte_long)
	s = s:gsub('[^\32-\126]', escape_byte_short)
	return s
end

local function format_string(s, quote)
	return string_format('%s%s%s', quote, quote_string(s, quote), quote)
end

local function write_string(s, write, quote)
	write(quote); write(quote_string(s, quote)); write(quote)
end

local keywords = {}
for i,k in ipairs{
	'and',       'break',     'do',        'else',      'elseif',    'end',
	'false',     'for',       'function',  'goto',      'if',        'in',
	'local',     'nil',       'not',       'or',        'repeat',    'return',
	'then',      'true',      'until',     'while',
} do
	keywords[k] = true
end

local function is_stringable(v)
	if type(v) == 'table' then
		return getmetatable(v) and getmetatable(v).__tostring and true or false
	else
		return type(v) == 'string'
	end
end

local function is_identifier(v)
	if is_stringable(v) then
		v = tostring(v)
		return not keywords[v] and v:find('^[a-zA-Z_][a-zA-Z_0-9]*$') ~= nil
	else
		return false
	end
end

local hasinf = math_huge == math_huge - 1
local function format_number(v)
	if v ~= v then
		return '0/0' --NaN
	elseif hasinf and v == math_huge then
		return '1/0' --writing 'math.huge' would not make it portable, just wrong
	elseif hasinf and v == -math_huge then
		return '-1/0'
	elseif v == math_floor(v) and v >= -2^31 and v <= 2^31-1 then
		return string_format('%d', v) --printing with %d is faster
	else
		return string_format('%0.17g', v)
	end
end

local function write_number(v, write)
	write(format_number(v))
end

local function is_dumpable(f)
	return type(f) == 'function' and debug.getinfo(f, 'Su').what ~= 'C'
end

local function format_function(f)
	return string_format('loadstring(%s)', format_string(string_dump(f, true)))
end

local function write_function(f, write, quote)
	write'loadstring('; write_string(string_dump(f, true), write, quote); write')'
end

local ffi, int64, uint64
local function is_int64(v)
	if type(v) ~= 'cdata' then return false end
	if not int64 then
		ffi = require'ffi'
		int64 = ffi.typeof'int64_t'
		uint64 = ffi.typeof'uint64_t'
	end
	return ffi.istype(v, int64) or ffi.istype(v, uint64)
end

local function format_int64(v)
	return tostring(v)
end

local function write_int64(v, write)
	write(format_int64(v))
end

local function format_value(v, quote)
	quote = quote or "'"
	if v == nil or type(v) == 'boolean' then
		return tostring(v)
	elseif type(v) == 'number' then
		return format_number(v)
	elseif is_stringable(v) then
		return format_string(tostring(v), quote)
	elseif is_dumpable(v) then
		return format_function(v)
	elseif is_int64(v) then
		return format_int64(v)
	else
		error('unserializable', 0)
	end
end

local function is_serializable(v)
	return type(v) == 'nil' or type(v) == 'boolean' or type(v) == 'number'
		or is_stringable(v) or is_dumpable(v) or is_int64(v)
end

local function write_value(v, write, quote)
	quote = quote or "'"
	if v == nil or type(v) == 'boolean' then
		write(tostring(v))
	elseif type(v) == 'number' then
		write_number(v, write)
	elseif is_stringable(v) then
		write_string(tostring(v), write, quote)
	elseif is_dumpable(v) then
		write_function(v, write, quote)
	elseif is_int64(v) then
		write_int64(v, write)
	else
		error('unserializable', 0)
	end
end

--pretty-printing for tables -------------------------------------------------

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
	return is_stringable(v) and 'string' or type(v)
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
			elseif a == nil then --can happen when comparing values
				return false
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

local function pretty(v, write, depth, wwrapper, indent,
	parents, quote, line_term, onerror, sort_keys, filter)

	if not filter(v) then
		return
	end

	if is_serializable(v) then

		write_value(v, write, quote)

	elseif getmetatable(v) and getmetatable(v).__pwrite then

		wwrapper = wwrapper or function(v)
			pretty(v, write, -1, wwrapper, nil,
				parents, quote, line_term, onerror, sort_keys, filter)
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
			if filter(v, k) then
				if first then
					first = false
				else
					write','
				end
				if indent then
					write(line_term)
					write(indent:rep(depth))
				end
				pretty(v, write, depth + 1, wwrapper, indent,
					parents, quote, line_term, onerror, sort_keys, filter)
			end
		end

		local pairs = sort_keys and sortedpairs or pairs
		for k,v in pairs(v) do
			if not is_array_index_key(k, maxn) and filter(v, k) then
				if first then
					first = false
				else
					write','
				end
				if indent then
					write(line_term)
					write(indent:rep(depth))
				end
				if is_stringable(k) then
					k = tostring(k)
				end
				if is_identifier(k) then
					write(k); write'='
				else
					write'['
					pretty(k, write, depth + 1, wwrapper, indent,
						parents, quote, line_term, onerror, sort_keys, filter)
					write']='
				end
				pretty(v, write, depth + 1, wwrapper, indent,
					parents, quote, line_term, onerror, sort_keys, filter)
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
			string_format('nil --[[unserializable %s]]', type(v)))
	end
end

local function nofilter() return true end

local function args(opt, ...)
	local
		indent, parents, quote, line_term, onerror,
		sort_keys, filter
	if type(opt) == 'table' then
		indent, parents, quote, line_term, onerror,
		sort_keys, filter =
			opt.indent, opt.parents, opt.quote, opt.line_term, opt.onerror,
			opt.sort_keys, opt.filter
	else
		indent, parents, quote, line_term, onerror,
		sort_keys, filter = opt, ...
	end
	line_term = line_term or '\n'
	filter = filter or nofilter
	return
		indent, parents, quote, line_term, onerror,
		sort_keys, filter
end

local function to_sink(write, v, ...)
	return pretty(v, write, 1, nil, args(...))
end

function to_string(v, ...) --fw. declared
	local buf = {}
	pretty(v, function(s) buf[#buf+1] = s end, 1, nil, args(...))
	return table.concat(buf)
end

local function to_openfile(f, v, ...)
	f:write'return '
	pretty(v, function(s) f:write(s) end, 1, nil, args(...))
end

local function to_file(file, v, ...)
	local f = assert(io.open(file, 'wb'))
	to_openfile(f, v, ...)
	f:close()
end

local function to_stdout(v, ...)
	return to_openfile(io.stdout, v, ...)
end

local pp_opt = {
	indent = '   ',
	parents = {},
	sort_keys = true,
	filter = function(v, k)
		return type(v) ~= 'function' and type(k) ~= 'function'
	end,
}
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

return setmetatable({

	--these can be exposed too if needed:
	--
	--is_identifier = is_identifier,
	--is_dumpable = is_dumpable,
	--is_serializable = is_serializable,
	--is_stringable = is_stringable,
	--
	--format_value = format_value,
	--write_value = write_value,

	write = to_sink,
	format = to_string,
	stream = to_openfile,
	save = to_file,
	print = to_stdout,
	pp = pp, --old API

}, {__call = function(self, ...)
	return pp(...)
end})
