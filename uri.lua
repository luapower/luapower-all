
-- URI parsing and formatting in Lua.
-- Written by Cosmin Apreutesei. Public Domain.

--[[
TODO: absolute path from base path + relative path (RFC 2396)
TODO: absolute uri from base uri + relative path + args override
TODO: add authority and userinfo fields like luasocket.url?
TODO: add params for each path segments? for the whole path? browsers change params to query params.
TODO: expose format_path, format_query, parse_path, parse_query and provide alternative ways of formatting and parsing them:
  - "var[]=v1&var[]=v2&var[k]=v3" => {var={v1,v2,[k]=v3}} - make an array only when you see [], otherwise throw an error.
  - "var=v1&var=v2" => {var={v1,v2}} - make an array when you see duplicate values.
]]

local glue = require'glue'
local add = table.insert

--formatting

--escape all characters except `unreserved`, `sub-delims` and the characters
--in the unreserved list, plus the characters in the reserved list.
local function esc(c)
	return ('%%%02x'):format(c:byte())
end
local function escape(s, reserved, unreserved)
	s = s:gsub('[^A-Za-z0-9%-%._~!%$&\'%(%)%*%+,;=' .. (unreserved or '').. ']', esc)
	if reserved and reserved ~= '' then
		s = s:gsub('[' .. reserved .. ']', esc)
	end
	return s
end

local function format_arg(t, k, v)
	k = k:gsub(' ', '+')
	k = escape(k, '&=')
	if v == true then
		add(t, k)
	elseif v then
		v = tostring(v):gsub(' ', '+')
		add(t, k .. '=' .. escape(v, '&'))
	end
end

local function format_args(t)
	local dt = {}
	if #t > 0 then --list form
		for i = 1, #t, 2 do
			local k, v = t[i], t[i+1]
			format_arg(dt, k, v)
		end
	else
		for k, v in glue.sortedpairs(t) do
			format_arg(dt, k, v)
		end
	end
	return table.concat(dt, '&')
end

local function format_path(t)
	local dt = {}
	for i = 1, #t do
		dt[i] = escape(t[i], '/')
	end
	return table.concat(dt, '/')
end

--args override query; segments override path.
local function format(t)
	local scheme = (t.scheme and escape(t.scheme) .. ':' or '')
	local pass = t.pass and ':' .. escape(t.pass) or ''
	local user = t.user and escape(t.user) .. pass .. '@' or ''
	local port = t.port and ':' .. escape(t.port) or ''
	local host = t.host and '//' .. user .. escape(t.host) .. port or ''
	local path = t.segments and format_path(t.segments)
		or t.path and escape(t.path, '', '/') or ''
	local query = t.args and (next(t.args) and '?' .. format_args(t.args) or '')
		or t.query and '?' .. escape((t.query:gsub(' ', '+'))) or ''
	local fragment = t.fragment and '#' .. escape(t.fragment) or ''
	return scheme .. host .. path .. query .. fragment
end

--parsing

local function unescape(s)
	return (s:gsub('%%(%x%x)', function(hex)
		return string.char(tonumber(hex, 16))
	end))
end

local function parse_path(s) --[segment[/segment...]]
	local t = {}
	for s in glue.gsplit(s, '/') do
		add(t, unescape(s))
	end
	return t
end

--argument order is retained by having the keys and values in the array part.
--duplicate keys form a list of values.
local function parse_args(s) --var[=[val]]&|;...
	local t = {}
	for s in glue.gsplit(s, '[&;]+') do
		local k, eq, v = s:match'^([^=]*)(=?)(.*)$'
		k = unescape(k:gsub('+', ' '))
		v = unescape(v:gsub('+', ' '))
		if eq == '' then v = true end
		t[k] = v
		add(t, k)
		add(t, v)
	end
	return t
end

--[scheme:](([//[user[:pass]@]host[:port][/path])|path)[?query][#fragment]
--NOTE: t.query is unusable if args names/values contain `&` or `=`.
--NOTE: t.path is unusable if the path segments contain `/`.
local function parse(s, t)
	t = t or {}
	s = s:gsub('#(.*)', function(s)
		t.fragment = unescape(s)
		return ''
	end)
	s = s:gsub('%?(.*)', function(s)
		t.query = unescape(s)
		t.args = parse_args(s)
		return ''
	end)
	s = s:gsub('^([a-zA-Z%+%-%.]*):', function(s)
		t.scheme = unescape(s)
		return ''
	end)
	s = s:gsub('^//([^/]*)', function(s)
		t.host = unescape(s)
		return ''
	end)
	if t.host then
		t.host = t.host:gsub('^(.-)@', function(s)
			t.user = unescape(s)
			return ''
		end)
		t.host = t.host:gsub(':(.*)', function(s)
			t.port = unescape(s)
			return ''
		end)
		if t.user then
			t.user = t.user:gsub(':(.*)', function(s)
				t.pass = unescape(s)
				return ''
			end)
		end
	end
	if s ~= '' then
		t.segments = parse_path(s)
		t.path = unescape(s)
	end
	return t
end

--[[TODO:
https://github.com/fire/luasocket/blob/master/src/url.lua
--build a path from a base path and a relative path
local function absolute_path(base_path, relative_path)
    if string.sub(relative_path, 1, 1) == "/" then return relative_path end
    local path = string.gsub(base_path, "[^/]*$", "")
    path = path .. relative_path
    path = string.gsub(path, "([^/]*%./)", function (s)
        if s ~= "./" then return s else return "" end
    end)
    path = string.gsub(path, "/%.$", "/")
    local reduced
    while reduced ~= path do
        reduced = path
        path = string.gsub(reduced, "([^/]*/%.%./)", function (s)
            if s ~= "../../" then return "" else return s end
        end)
    end
    path = string.gsub(reduced, "([^/]*/%.%.)$", function (s)
        if s ~= "../.." then return "" else return s end
    end)
    return path
end

--build an absolute URL from a base and a relative URL according to RFC 2396
local function absolute(base_url, relative_url)
	if type(base_url) == 'table' then
		base_parsed = base_url
		base_url = build(base_parsed)
	else
		base_parsed = parse(base_url)
	end
	local relative_parsed = parse(relative_url)
   if not base_parsed then return relative_url
   elseif not relative_parsed then return base_url
   elseif relative_parsed.scheme then return relative_url
   else
        relative_parsed.scheme = base_parsed.scheme
        if not relative_parsed.authority then
            relative_parsed.authority = base_parsed.authority
            if not relative_parsed.path then
                relative_parsed.path = base_parsed.path
                if not relative_parsed.params then
                    relative_parsed.params = base_parsed.params
                    if not relative_parsed.query then
                        relative_parsed.query = base_parsed.query
                    end
                end
            else
                relative_parsed.path = absolute_path(base_parsed.path or "",
                    relative_parsed.path)
            end
        end
        return build(relative_parsed)
    end
end
]]

if not ... then require 'uri_test' end

return {
	escape = escape,
	format = format,
	parse = parse,
	unescape = unescape,
	format_args = format_args,
	parse_args = parse_args,
	format_path = format_path,
	parse_path = parse_path,
}
