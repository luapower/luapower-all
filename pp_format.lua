--pretty-printing of non-structured types

local type, tostring = type, tostring
local string_format, string_dump = string.format, string.dump
local math_huge, math_floor = math.huge, math.floor

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
		int64 = ffi.new'int64_t'
		uint64 = ffi.new'uint64_t'
	end
	return ffi.istype(v, int64) or ffi.istype(v, uint64)
end

local function format_int64(v)
	return tostring(v)
end

local function write_int64(v, write)
	write(format_int64(v))
end

local function format(v, quote)
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

local function write(v, write, quote)
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

return {
	is_identifier = is_identifier,
	is_dumpable = is_dumpable,
	is_serializable = is_serializable,
	is_stringable = is_stringable,

	format_string = format_string,
	format_number = format_number,
	format_function = format_function,
	format_int64 = format_int64,

	write_string = write_string,
	write_number = write_number,
	write_function = write_function,
	write_int64 = write_int64,

	format = format,
	write = write,
}
