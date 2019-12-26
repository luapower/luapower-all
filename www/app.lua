
--main entry point for all URIs that are not static files.
--provides a hi-level web API and dispatches URIs to individual actions.

local glue = require'glue'
local pp = require'pp'
local actions = require'actions'
local luapower = require'luapower'
local cjson = require'cjson'
local ngx = ngx

cjson.encode_sparse_array(false, 0, 0) --encode all sparse arrays

local app = {ngx = false}
setmetatable(app, app)
app._G = app
app.__index = _G
setfenv(1, app)

--logging API ----------------------------------------------------------------

function log(...)
    ngx.log(ngx.DEBUG, ...)
end

--config API -----------------------------------------------------------------

--cached config function. config values may come from `var` statements from
--nginx.conf or from env vars.
--NOTE: env. vars must be declared in nginx.conf to pass through.
local conf = {}
local null = conf
function config(var, default)
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

--request API ----------------------------------------------------------------

HEADERS, METHOD, POST, PATH, ARGS, QUERY, GET = nil --for strict mode

local function init_request()
	HEADERS = ngx.req.get_headers()
	METHOD = ngx.req.get_method()
	if METHOD == 'POST' then
		ngx.req.read_body()
		if HEADERS.content_type == 'application/json' then
			POST = cjson.decode(ngx.req.get_body_data())
		else
			POST = ngx.req.get_post_args()
		end
	end
	PATH = ngx.var.uri --TODO: path is unescaped as a whole, not each component
	ARGS = {}
	for s in PATH:gmatch'[^/]+' do
		ARGS[#ARGS+1] = s
	end
	QUERY = ngx.var.query_string
	GET = ngx.req.get_uri_args()
end

--output API -----------------------------------------------------------------

local outbuf

function out(s)
	outbuf[#outbuf+1] = tostring(s)
end

function print(...)
	local n = select('#', ...)
	for i=1,n do
		out(tostring((select(i, ...))))
		if i < n then
			out'\t'
		end
	end
	out'\n'
end

app.pp = pp

local mime_types = {
	txt = 'text/plain',
	html = 'text/html',
	json = 'application/json',
}

function setmime(ext)
	ngx.header.content_type = assert(mime_types[ext])
end

redirect = ngx.redirect
sleep = ngx.sleep

--filesystem API -------------------------------------------------------------

function wwwpath(file) --file -> path (if exists)
	local www = config'www_dir'
	if not file then return www end
	assert(not file:find('..', 1, true))
	return www..'/'..file
end

--socket API -----------------------------------------------------------------

function connect(ip, port)
	local skt = ngx.socket.tcp()
	skt:settimeout(5000)
	skt:setkeepalive()
	local ok, err = skt:connect(ip, port)
	if not ok then return nil, err end
	return skt
end
newthread = ngx.thread.spawn
wait = ngx.thread.wait

--action API -----------------------------------------------------------------

luapower.luapower_dir = config'luapower_dir' --setup luapower

local api = {
	setmime = setmime,
	out = out,
	print = print,
	redirect = redirect,
	wwwpath = wwwpath,
	grep_enabled = true,
	sleep = sleep,
	connect = connect,
}
glue.update(actions.app, api)

function run()
	--init global and request contexts
	local oldindex = __index
	__index = __index._G -- _G is replaced on each request
	__index.print = print --replace print for pp
	setfenv(pp.pp, __index) --replace _G for pp.pp
	__index.coroutine = require'coroutine' --nginx for windows doesn't include it
	init_request()
	actions.app.POST = POST
	--decide on the action: unknown actions go to the default action.
	local act = ARGS[1]
	if not act or not actions.action[act] or act == 'default' then
		act = 'default'
	else
		table.remove(ARGS, 1)
	end
	--find and run the action
	outbuf = {}
	local handler = actions.action[act]
	handler(unpack(ARGS))
	ngx.print(table.concat(outbuf))
end

return app
