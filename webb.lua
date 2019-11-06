--[==[

	webb | main module
	Written by Cosmin Apreutesei. Public Domain.

Exports

	glue

CONFIG

	config'base_url'                        optional, for absurl()

CONFIG API

	config(name[, default_val]) -> val      get/set config value
	config{name->val}                       set multiple config values
	S(name[, default_val])                  get/set internationalized string

ENVIRONMENT

	once(f[, clear_cache[, k]])             memoize for current request
	env([t]) -> t                           per-request shared environment

REQUEST

	headers([name]) -> s|t                  get header or all
	method([method]) -> s|b                 get/check http method
	post([name]) -> s | t | nil             get POST arg or all
	args([n|name]) -> s | t | nil           get path element or GET arg or all
	scheme([s]) -> s | t|f                  get/check request scheme
	host([s]) -> s | t|f                    get/check request host
	port([p]) -> p | t|f                    get/check server port
	email(user) -> s                        get email address of user
	client_ip() -> s                        get client's ip address

ARG PARSING

	id_arg(s) -> n | nil                    validate int arg with slug
	str_arg(s) -> s | nil                   validate/trim non-empty string arg
	enum_arg(s, values...) -> s | nil       validate enum arg
	list_arg(s[, arg_f]) -> t               validate comma-separated list arg

OUTPUT

	out(s1,...)                             output a string
	push_out([f])                           push output function or buffer
	pop_out() -> s                          pop output function and flush it
	stringbuffer([t]) -> f(s1,...)/f()->s   create a string buffer
	record(f) -> s                          run f and collect out() calls
	out_buffering() -> t | f                check if we're buffering output
	setheader(name, val)                    set a header (unless we buffering)
	print(...)                              like Lua's print but uses out()

HTML ENCODING

	html(s) -> s                            escape html

URL ENCODING & DECODING

	url([path], [params]) -> t | s          encode/decode/update url
	absurl([path]) -> s                     get the absolute url for a path
	slug(id, s) -> s                        encode id and s to `s-id`

RESPONSE

	http_error(code[, msg])                 raise a http error
	redirect(url[, status])                 exit with "302 moved temporarily"
	check(ret[, err]) -> ret                exit with "404 file not found"
	allow(ret[, err]) -> ret                exit with "403 forbidden"
	check_etag(s)                           exit with "304 not modified"

JSON ENCODING/DECODING

	json(s) -> t                            decode json
	json(t) -> s                            encode json

FILESYSTEM

	basepath([file]) -> path                get filesystem path (unchecked)
	filepath(file) -> path                  get filesystem path (must exist)
	readfile(file) -> s                     get file contents
	readfile.filename <- s|f(filename)      set virtual file contents

MUSTACHE TEMPLATES

	render_string(s[, env]) -> s            render a template from a string
	render_file(file[, env]) -> s           render a template from a file
	mustache_wrap(s) -> s                   wrap a template in <script> tag
	template(name) -> s                     get template contents
	template.name <- s|f(name)              set template contents or handler
	render(name[, env]) -> s                render template

LUAPAGES TEMPLATES

	include_string(s, [env], [name], ...)   run LuaPages script
	include(file, [env], ...)               run LuaPages script

LUA SCRIPTS

	run_string(s, [env], args...) -> ret    run Lua script
	run(file, [env], args...) -> ret        run Lua script

HTML FILTERS

	filter_lang(s, lang) -> s               filter <t> tags and :lang attrs
	filter_comments(s) -> s                 filter <!-- --> comments

FILE CONCATENATION LISTS

	catlist_files(s) -> {file1,...}         parse a .cat file
	catlist(file, args...)                  output a .cat file

TODO

	* more preprocessors: markdown, coffeescript, sass, minimifiers
	* css & js minifiers

API DOCS

	once(f[, clear_cache[, k]])

Memoize 0-arg or 1-arg function for current request. If clear_cache is
true, then clear the cache (either for the entire function or for arg `k`).

	env([t]) -> t

Per-request shared environment. Scripts run with `render()`,
`include()`, `run()` run in this environment by default. If the `t` argument
is given, an inherited environment is created.


]==]

glue = require'glue'

--cached config function -----------------------------------------------------

local conf = {}
local null = conf
function config(var, default)
	if type(var) == 'table' then
		for var, val in pairs(var) do
			config(var, val)
		end
		return
	end
	local val = conf[var]
	if val == nil then
		val = os.getenv(var:upper())
		if val == nil then
			val = ngx.var[var]
			if val == nil then
				val = default
			end
		end
		conf[var] = val == nil and null or val
	end
	if val == null then
		return nil
	else
		return val
	end
end

--separate config function for internationalizing strings.
local S_ = {}
function S(name, val)
	if val and not S_[name] then
		S_[name] = val
	end
	return S_[name] or name
end

--per-request environment ----------------------------------------------------

--per-request memoization.
local NIL = {}
local function enc(v) if v == nil then return NIL else return v end end
local function dec(v) if v == NIL then return nil else return v end end
function once(f, clear_cache, ...)
	if clear_cache then
		local t = ngx.ctx[f]
		if t then
			if select('#', ...) == 0 then
				t = {}
				ngx.ctx[f] = t
			else
				local k = ...
				t[enc(k)] = nil
			end
		end
	else
		return function(k)
			local t = ngx.ctx[f]
			if not t then
				t = {}
				ngx.ctx[f] = t
			end
			local v = t[enc(k)]
			if v == nil then
				v = f(k)
				t[enc(k)] = enc(v)
			else
				v = dec(v)
			end
			return v
		end
	end
end

--per-request shared environment to use in all app code.
function env(t)
	local env = ngx.ctx.env
	if not env then
		env = {__index = _G}
		setmetatable(env, env)
		ngx.ctx.env = env
	end
	if t then
		t.__index = env
		return setmetatable(t, t)
	else
		return env
	end
end

--request API ----------------------------------------------------------------

local _method = once(function()
	return ngx.req.get_method()
end)

function method(which)
	if which then
		return _method():lower() == which:lower()
	else
		return _method():lower()
	end
end

local _headers = once(function()
	return ngx.req.get_headers()
end)

function headers(h)
	if h then
		return _headers()[h]
	else
		return _headers()
	end
end

local _args = once(function()
	local t = {}
	for s in glue.gsplit(ngx.var.uri, '/', 2, true) do
		t[#t+1] = ngx.unescape_uri(s)
	end
	glue.update(t, ngx.req.get_uri_args()) --add in the query args
	return t
end)

function args(v)
	if v then
		return _args()[v]
	else
		return _args()
	end
end

local _post_args = once(function()
	if not method'post' then return end
	ngx.req.read_body()
	local ct = headers'Content-Type'
	if ct:find'^application/x%-www%-form%-urlencoded' then
		return ngx.req.get_post_args()
	elseif ct:find'^application/json' then
		return json(ngx.req.get_body_data())
	else
		return ngx.req.get_body_data()
	end
end)

function post(v)
	if v then
		local t = _post_args()
		return t and t[v]
	else
		return _post_args()
	end
end

function scheme(s)
	if s then
		return scheme() == s
	end
	return headers'X-Forwarded-Proto' or ngx.var.scheme
end

function host(s)
	if s then
		return host() == s
	end
	return ngx.var.host
end

function port(p)
	if p then
		return port() == tonumber(p)
	end
	return tonumber(headers'X-Forwarded-Port' or ngx.var.server_port)
end

function email(user)
	return string.format('%s@%s', assert(user), host())
end

function client_ip()
	return ngx.var.remote_addr
end

--arg validation

function id_arg(s)
	if not s or type(s) == 'number' then return s end
	local n = tonumber(s:match'(%d+)$') --strip any slug
	return n and n >= 0 and n or nil
end

function str_arg(s)
	s = glue.trim(s or '')
	return s ~= '' and s or nil
end

function enum_arg(s, ...)
	for i=1,select('#',...) do
		if s == select(i,...) then
			return s
		end
	end
	return nil
end

function list_arg(s, arg_f)
	local s = str_arg(s)
	if not s then return nil end
	arg_f = arg_f or str_arg
	local t = {}
	for s in glue.gsplit(s, ',') do
		table.insert(t, arg_f(s))
	end
	return t
end

--output API -----------------------------------------------------------------

function out_buffering()
	return ngx.ctx.outfunc ~= nil
end

local function default_outfunc(...)
	--TODO: call tostring() on all args
	ngx.print(...)
end

function stringbuffer(t)
	t = t or {}
	return function(...)
		local n = select('#',...)
		if n == 0 then --flush it
			return table.concat(t)
		end
		for i=1,n do
			local s = select(i,...)
			t[#t+1] = tostring(s)
		end
	end
end

function push_out(f)
	ngx.ctx.outfunc = f or stringbuffer()
	if not ngx.ctx.outfuncs then
		ngx.ctx.outfuncs = {}
	end
	table.insert(ngx.ctx.outfuncs, ngx.ctx.outfunc)
end

function pop_out()
	if not ngx.ctx.outfunc then return end
	local s = ngx.ctx.outfunc()
	local outfuncs = ngx.ctx.outfuncs
	table.remove(outfuncs)
	ngx.ctx.outfunc = outfuncs[#outfuncs]
	return s
end

function out(s, ...)
	if s == nil then return end --prevent flushing the buffer needlessly
	local outfunc = ngx.ctx.outfunc or default_outfunc
	outfunc(s, ...)
end

local function pass(...)
	return pop_out(), ...
end
function record(out_content, ...)
	push_out()
	return pass(out_content(...))
end

function setheader(name, val)
	if out_buffering() then
		return
	end
	ngx.header[name] = val
end

local function print_wrapper(print)
	return function(...)
		if not ngx.headers_sent then
			ngx.header.content_type = 'text/plain'
		end
		print(...)
		ngx.flush()
	end
end

--print functions for debugging with no output buffering and flushing.

print = print_wrapper(glue.printer(ngx.print, tostring))

local pp_ = require'pp'

pp = print_wrapper(glue.printer(function(v)
	if type(v) == 'table' then
		pp_.write(ngx.print, v, '   ', {})
	else
		ngx.print(v)
	end
end)
)
--html encoding --------------------------------------------------------------

function html(s)
	if s == nil then return '' end
	return (tostring(s):gsub('[&"<>\\]', function(c)
		if c == '&' then return '&amp;'
		elseif c == '"' then return '\"'
		elseif c == '\\' then return '\\\\'
		elseif c == '<' then return '&lt;'
		elseif c == '>' then return '&gt;'
		else return c end
	end))
end

--url encoding/decoding ------------------------------------------------------

local function url_path(path)
	if type(path) == 'table' then --encode
		local t = {}
		for i,s in ipairs(path) do
			t[i] = ngx.escape_uri(s)
		end
		return #t > 0 and table.concat(t, '/') or nil
	else --decode
		local t = {}
		for s in glue.gsplit(path, '/', 1, true) do
			t[#t+1] = ngx.unescape_uri(s)
		end
		return t
	end
end

local function url_params(params)
	if type(params) == 'table' then --encode
		return ngx.encode_args(params)
	else --decode
		return ngx.decode_args(params)
	end
end

--use cases:
--  decode url: url('a/b?a&b=1') -> {'a', 'b', a=true, b='1'}
--  encode url: url{'a', 'b', a=true, b='1'} -> 'a/b?a&b=1'
--  update url: url('a/b?a&b=1', {'c', b=2}) -> 'c/b?a&b=2'
--  decode params only: url(nil, 'a&b=1') -> {a=true, b=1}
--  encode params only: url(nil, {a=true, b=1}) -> 'a&b=1'
function url(path, params)
	if type(path) == 'string' then --decode or update url
		local t
		local i = path:find('?', 1, true)
		if i then
			t = url_path(path:sub(1, i-1))
			glue.update(t, url_params(path:sub(i + 1)))
		else
			t = url_path(path)
		end
		if params then --update url
			glue.update(t, params) --also updates any path elements
			return url(t) --re-encode url
		else --decode url
			return t
		end
	elseif path then --encode url
		local s1 = url_path(path)
		--strip away the array part so that ngx.encode_args() doesn't complain
		local t = {}
		for k,v in pairs(path) do
			if type(k) ~= 'number' then
				t[k] = v
			end
		end
		local s2 = next(t) ~= nil and url_params(t) or nil
		return (s1 or '') .. (s1 and s2 and '?' or '') .. (s2 or '')
	else --encode or decode params only
		return url_params(params)
	end
end

--[[
ngx.say(require'pp'.format(url('a/b?a&b=1')))
ngx.say(url{'a', 'b', a=true, b=1})
ngx.say()
ngx.say(require'pp'.format(url('?a&b=1')))
ngx.say(url{'', a=true, b=1})
ngx.say()
ngx.say(require'pp'.format(url('a/b?')))
ngx.say(url{'a', 'b', ['']=true})
ngx.say()
ngx.say(require'pp'.format(url('a/b')))
ngx.say(url{'a', 'b'})
ngx.say()
ngx.say(url('a/b?a&b=1', {'c', b=2}))
ngx.say()
ngx.say(require'pp'.format(url(nil, 'a&b=1')))
ngx.say(url(nil, {a=true, b=1}))
ngx.say()
]]

function absurl(path)
	path = path or ''
	return config'base_url' or
		scheme()..'://'..host()..
			(((scheme'https' and port(443)) or
			  (scheme'http' and port(80))) and '' or ':'..port())..path
end

function slug(id, s)
	s = glue.trim(s or '')
		:gsub('[%s_;:=&@/%?]', '-') --turn separators into dashes
		:gsub('%-+', '-')           --compress dashes
		:gsub('[^%w%-%.,~]', '')    --strip chars that would be url-encoded
		:lower()
	assert(id >= 0)
	return (s ~= '' and s..'-' or '')..tostring(id)
end

--response API ---------------------------------------------------------------

function http_error(code, msg)
	local t = {type = 'http', http_code = code, message = msg}
	function t:__tostring()
		return tostring(code)..(msg ~= nil and ' '..tostring(msg) or '')
	end
	setmetatable(t, t)
	error(t, 2)
end

redirect = ngx.redirect

function check(ret, err)
	if ret then return ret end
	http_error(404, err)
end

function allow(ret, err)
	if ret then return ret, err end
	http_error(403, err)
end

function check_etag(s)
	if out_buffering() or not method'get' then
		return
	end
	local etag0 = headers'if_none_match'
	local etag = ngx.md5(s)
	if etag0 == etag then
		http_error(304)
	end
	--send etag to client as weak etag so that nginx gzip filter still apply
	setheader('ETag', 'W/'..etag)
end

--json API -------------------------------------------------------------------

local cjson = require'cjson'
cjson.encode_sparse_array(false, 0, 0) --encode all sparse arrays

local function remove_nulls(t)
	if t == cjson.null then
		return nil
	elseif type(t) == 'table' then
		for k,v in pairs(t) do
			t[k] = remove_nulls(v)
		end
	end
	return t
end

function json(v)
	if type(v) == 'table' then
		return cjson.encode(v)
	elseif type(v) == 'string' then
		return remove_nulls(cjson.decode(v))
	else
		error('invalid arg '..type(v))
	end
end

--filesystem API -------------------------------------------------------------

function basepath(file)
	return assert(config('www_dir', 'www'))..(file and '/'..file or '')
end

local fs = require'fs'

function filepath(file) --file -> path (if exists)
	if file:find('..', 1, true) then return end --trying to escape
	local path = basepath(file)
	if not fs.is(path) then return end
	return path
end

local function readfile_call(files, file)
	local f = files[file]
	if type(f) == 'function' then
		return f()
	elseif f then
		return f
	else
		local s = glue.readfile(basepath(file))
		return glue.assert(s, 'file not found: %s', file)
	end
end

readfile = {} --{filename -> content | handler(filename)}
setmetatable(readfile, {__call = readfile_call})

--mustache html templates ----------------------------------------------------

local function underscores(name)
	return name:gsub('-', '_')
end

local mustache = require'mustache'

function render_string(s, data, partials)
	return (mustache.render(s, data or env(), partials))
end

function render_file(file, data, partials)
	return render_string(readfile(file), data, partials)
end

function mustache_wrap(s, name)
	return '<script type="text/x-mustache" id="'..name..
		'_template">\n'..s..'\n</script>\n'
end

local function check_template(name, file)
	glue.assert(not template[name], 'duplicate template "%s" in %s', name, file)
end

--TODO: make this parser more robust so we can have <script> tags in templates
--without the <{{undefined}}/script> hack (mustache also needs it though).
local function mustache_unwrap(s, t, file)
	t = t or {}
	local i = 0
	for name,s in s:gmatch('<script%s+type=?"text/x%-mustache?"%s+'..
		'id="?(.-)_template"?>(.-)</script>') do
		name = underscores(name)
		if t == template then
			check_template(name, file)
		end
		t[name] = s
		i = i + 1
	end
	return t, i
end

local template_names = {} --keep template names in insertion order

local function add_template(template, name, s)
	name = underscores(name)
	rawset(template, name, s)
	table.insert(template_names, name)
end

--gather all the templates from the filesystem
local load_templates = glue.memoize(function()
	local t = {}
	for file, d in fs.dir(basepath()) do
		assert(file)
		if file:find'%.html%.mu$' and fs.is(basepath(file), 'file') then
			t[#t+1] = file
		end
	end
	table.sort(t)
	for i,file in ipairs(t) do
		local s = readfile(file)
		local _, i = mustache_unwrap(s, template, file)
		if i == 0 then --must be without the <script> tag
			local name = file:gsub('%.html%.mu$', '')
			name = underscores(name)
			check_template(name, file)
			template[name] = s
		end
	end
end)

local function template_call(template, name)
	load_templates()
	if not name then
		return template_names
	else
		name = underscores(name)
		local s = glue.assert(template[name], 'template not found: %s', name)
		if type(s) == 'function' then
			s = s()
		end
		return s
	end
end

template = {} --{template = html | handler(name)}
setmetatable(template, {__call = template_call, __newindex = add_template})

local partials = {}
local function get_partial(partials, name)
	return template(name)
end
setmetatable(partials, {__index = get_partial})

function render(name, data)
	return render_string(template(name), data, partials)
end

--LuaPages templates ---------------------------------------------------------

local lp = require'lp'

local function compile_string(s, chunkname)
	lp.setoutfunc'out'
	local f = lp.compile(s, chunkname)
	return function(_env, ...)
		setfenv(f, _env or env())
		f(...)
	end
end

local compile = glue.memoize(function(file)
	return compile_string(readfile(file), '@'..file)
end)

function include_string(s, env, chunkname, ...)
	return compile_string(s, chunkname)(env, ...)
end

function include(file, env, ...)
	compile(file)(env, ...)
end

--Lua scripts ----------------------------------------------------------------

local function compile_lua_string(s, chunkname)
	local f = assert(loadstring(s, chunkname))
	return function(_env, ...)
		setfenv(f, _env or env())
		return f(...)
	end
end

local compile_lua = glue.memoize(function(file)
	return compile_lua_string(readfile(file), file)
end)

function run_string(s, env, ...)
	return compile_lua_string(s)(env, ...)
end

function run(file, env, ...)
	return compile_lua(file)(env, ...)
end

--html filters ---------------------------------------------------------------

function filter_lang(s, lang)
	local lang0 = lang

	--replace <t class=lang>
	s = s:gsub('<t class=([^>]+)>(.-)</t>', function(lang, html)
		assert(not html:find('<t class=', 1, true), html)
		if lang ~= lang0 then return '' end
		return html
	end)

	--replace attr:lang="val" and attr:lang=val
	local function repl_attr(attr, lang, val)
		if lang ~= lang0 then return '' end
		return attr .. val
	end
	s = s:gsub('(%s[%w_%:%-]+)%:(%a?%a?)(=%b"")', repl_attr)
	s = s:gsub('(%s[%w_%:%-]+)%:(%a?%a?)(=[^%s>]*)', repl_attr)

	return s
end

function filter_comments(s)
	return (s:gsub('<!%-%-.-%-%->', ''))
end

--concatenated files preprocessor --------------------------------------------

--NOTE: duplicates are ignored to allow require()-like functionality
--when composing file lists from independent modules (see jsfile and cssfile).
function catlist_files(s)
	s = s:gsub('//[^\n\r]*', '') --strip out comments
	local already = {}
	local t = {}
	for file in s:gmatch'([^%s]+)' do
		if not already[file] then
			already[file] = true
			table.insert(t, file)
		end
	end
	return t
end

--NOTE: can also concatenate actions if the actions module is loaded.
--NOTE: favors plain files over actions because it can generate etags without
--actually reading the files.
function catlist(listfile, ...)
	local js = listfile:find'%.js%.cat$'
	local sep = js and ';\n' or '\n'

	--generate and check etag
	local t = {} --etag seeds
	local c = {} --output generators

	for i,file in ipairs(catlist_files(readfile(listfile))) do
		if readfile[file] then --virtual file
			table.insert(t, readfile(file))
			table.insert(c, function() out(readfile(file)) end)
		else
			local path = filepath(file)
			if path then --plain file, get its mtime
				local mtime = fs.attr(path, 'mtime')
				table.insert(t, tostring(mtime))
				table.insert(c, function() out(readfile(file)) end)
			elseif action then --file not found, try an action
				local s, found = record(action, file, ...)
				if found then
					table.insert(t, s)
					table.insert(c, function() out(s) end)
				else
					glue.assert(false, 'file not found: %s', file)
				end
			else
				glue.assert(false, 'file not found: %s', file)
			end
		end
	end
	check_etag(table.concat(t, '\0'))

	--output the content
	for i,f in ipairs(c) do
		f()
		out(sep)
	end
end

