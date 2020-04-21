
--http header values parsing and formatting.
--Written by Cosmin Apreutesei. Public Domain.

if not ... then require'anaf'; return end

local glue = require'glue'
local b64 = require'libb64'
local http_date = require'http_date'
local re = require'lpeg.re' --for tokens()
local uri = require'uri'
local base64 = b64.decode_string
local _ = string.format
local concat = table.concat

local headers = {}

--simple value parsers

function token(s)
	return s ~= '' and not s:find'[%z\1-\32\127%(%)<>@,;:\\"/%[%]%?={}]' and s
end

function name(s) --Some-Name -> some_name
	if s == '' then return end
	return (s:gsub('%-','_'):lower())
end

local function int(s) --"123" -> 123
	local n = tonumber(s)
	assert(n and math.floor(n) == n, 'invalid integer')
	return n
end

local function unquote(s)
	return (s:gsub('\\([^\\])', '%1'))
end

local function qstring(s) --'"a\"c"' -> 'a"c'
	s = s:match'^"(.-)"$'
	if not s then return end
	return unquote(s)
end

--simple compound value parsers (no comments or quoted strings involved)

--date is in UTC. use glue.time() not os.time() to get a timestamp from it!
local function date(s)
	return http_date.parse(s)
end

local url = glue.pass --urls are not parsed (replace with uri.parse if you want them parsed)

local function namesplit(s)
	local name = s:gmatch'[^,]+'
	return function()
		local s = name()
		return s and glue.trim(s)
	end
end

local function nameset(s) --"a,b" -> {a=true, b=true}
	local t = {}
	for s in namesplit(s) do
		t[name(s)] = true
	end
	return t
end

local function namelist(s) --"a,b" -> {'a','b'}
	local t = {}
	for s in namesplit(s) do
		t[#t+1] = name(s)
	end
	return t
end

--tokenized compound value parsers

local value_re = re.compile([[
	value         <- (quoted_string / comment / separator / token)* -> {}
	quoted_string <- ('"' {(quoted_pair / [^"])*} '"') -> unquote
	comment       <- {'(' (quoted_pair / comment / [^()])* ')'}
	separator     <- {[]()<>@,;:\"/[?={}]} / ' '
	token         <- {(!separator .)+}
	quoted_pair   <- '\' .
]], {
	unquote = unquote,
})

local function tokens(s) -- a,b, "a,b" ; (a,b) -> {a,",",b,",","a,b",";","(a,b)"}
	return value_re:match(s)
end

local function tfind(t, s, start, stop) --tfind({a1,...}, aN) -> N
	for i=start or 1,stop or #t do
		if t[i] == s then return i end
	end
end

local function tsplit(t, sep, start, stop) --{a1,...,aX,sep,aY,...,aZ} -> f; f() -> t,1,X; f() -> t,Y,Z
	start = start or 1
	stop = stop or #t
	local i,next_i = start,start
	return function()
		repeat
			if next_i > stop then return end
			i, next_i = next_i, (tfind(t, sep, next_i, stop) or stop+1)+1
		until next_i-1 - i > 0 --skip empty values
		return t, i, next_i-2
	end
end

local function kv(t, parsers, i, j) --k[=[v]] -> name(k), v|true|''
	local k,eq,v = unpack(t,i,j)
	k = name(k)
	if eq ~= '=' then v = true end
	if not v then v = '' end --the existence of '=' implies an empty value
	if parsers and parsers[k] then v = parsers[k](v) end
	return k,v
end

local function kvlist(t, sep, parsers, i, j) --k1[=[v1]]<sep>... -> {k1=v1|true|'',...}
	local dt = {}
	for t,ii,jj in tsplit(t,sep,i,j) do
		local k,v = kv(t,parsers,ii,jj)
		dt[k] = v
	end
	return dt
end

local function propertylist(s, parsers) --k1[=[v1]],... -> {k1=v1|true|'',...}
	return kvlist(tokens(s), ',', parsers)
end

local function valueparams(t, parsers, i, j) --value[;paramlist] -> t,i,j, params
	i,j = i or 1, j or #t
	local ii = tfind(t,';',i,j)
	local j_before_params = ii and ii-1 or j
	local params = ii and kvlist(t, ';', parsers, ii+1, j) or {}
	return t,i,j_before_params, params
end

local function valueparamslist(s, parsers) --value1[;paramlist1],... -> {value1=custom_t1|true,...}
	local split = tsplit(tokens(s), ',')
	return function()
		local t,i,j = split()
		if not t then return end
		return valueparams(t, parsers, i, j)
	end
end

--parsers for propertylist and valueparamslist: parse(string | true) -> value | nil
local function no_value(b) return b == true or nil end
local function must_value(s) return s ~= true and s or nil end
local function must_int(s) return s ~= true and int(s) or nil end
local function opt_int(s) return s == true or int(s) end
local function must_name(s) return s ~= true and name(s) or nil end
local function must_nameset(s) return s ~= true and nameset(s) or nil end
local function opt_nameset(s) return s == true or nameset(s) end

--individual value parsers per rfc-2616 section 14

local parse = {} --{header_name = parser(s) -> v | nil[,err] }
headers.parse = parse

local accept_parse = {q = tonumber}

function parse.accept(s) --#( type "/" subtype ( ";" token [ "=" ( token | quoted-string ) ] )* )
	local dt = {}
	for t,i,j, params in valueparamslist(s, accept_parse) do
		local type_, slash, subtype = unpack(t,i,j)
		assert(slash == '/' and subtype, 'invalid media type')
		type_, subtype = name(type_), name(subtype)
		dt[_('%s/%s', type_, subtype)] = params or {}
	end
	return dt
end

local function accept_list(s) ----1#( ( token | "*" ) [ ";" "q" "=" qvalue ] )
	local dt = {}
	for t,i,j, params in valueparamslist(s, accept_parse) do
		dt[name(t[i])] = params
	end
	return dt
end

parse.accept_charset = accept_list
parse.accept_encoding = accept_list
parse.accept_language = accept_list

function parse.accept_ranges(s) -- "none" | 1#( "bytes" | token )
	if s == 'none' then return {} end
	return nameset(s)
end

parse.accept_datetime = date
parse.age = int --seconds
parse.allow = nameset --#method

local function must_hex(len)
	return function(s)
		return s ~= true and #s == len and s:match'^[%x]+$' or nil
	end
end

local credentials_parsers = {
	realm = must_value,       --"realm" "=" quoted-string
	username = must_value,    --"username" "=" quoted-string
	uri = must_value,         --"uri" "=" request-uri   ; As specified by HTTP/1.1
	qop = must_name,          --"qop" "=" ( "auth" | "auth-int" | token )
	nonce = must_value,       --"nonce" "=" quoted-string
	cnonce = must_value,      --"cnonce" "=" quoted-string
	nc = must_hex(8),         --"nc" "=" 8LHEX
	response = must_hex(32),  --"response" "=" <"> 32LHEX <">
	opaque = must_value,      --"opaque" "=" quoted-string
	algorithm = must_name,    --"algorithm" "=" ( "MD5" | "MD5-sess" | token )
}

local function credentials(s) --basic base64-string | digest k=v,... per http://tools.ietf.org/html/rfc2617
	local scheme,s = s:match'^([^ ]+) (.*)$'
	if not scheme then return end
	scheme = name(scheme)
	if scheme == 'basic' then --basic base64("user:password")
		local user,pass = base64(s):match'^([^:]*):(.*)$'
		return {scheme = scheme, user = user, pass = pass}
	elseif scheme == 'digest' then
		local dt = propertylist(s, credentials_parsers)
		dt.scheme = scheme
		return dt
	else
		return {scheme = scheme, rest = s}
	end
end

parse.authorization = credentials
parse.proxy_authorization = credentials

local function must_urllist(s)
	if s == true then return end
	local dt = {}
	for s in glue.gsplit(s, ' ') do
		dt[#dt+1] = url(s)
	end
	return #dt > 0 and dt or nil
end

local function must_bool(s)
	if s == true then return end
	s = s:lower()
	if s ~= 'true' and s ~= 'false' then return end
	return s == 'true'
end

local challenge_parsers = {
	realm = must_value,          --"realm" "=" quoted-string
	domain = must_urllist,       --"domain" "=" <"> URI ( 1*SP URI ) <">
	nonce = must_value,          --"nonce" "=" quoted-string
	opaque = must_value,         --"opaque" "=" quoted-string
	stale = must_bool,           --"stale" "=" ( "true" | "false" )
	algorithm = must_name,       --"algorithm" "=" ( "MD5" | "MD5-sess" | token )
	qop = must_nameset,          --"qop" "=" <"> 1# ( "auth" | "auth-int" | token ) <">
}

local function challenges(s) --scheme k=v,... per http://tools.ietf.org/html/rfc2617
	local scheme,s = s:match'^([^ ]+) ?(.*)$'
	if not scheme then return end
	scheme = name(scheme)
	local dt = propertylist(s, challenge_parsers)
	dt.scheme = scheme
	return dt
end

parse.www_authenticate = challenges
parse.proxy_authenticate = challenges

local cc_parse = {
	no_cache = no_value,          --"no-cache"
	no_store = no_value,          --"no-store"
	max_age = must_int,           --"max-age" "=" delta-seconds
	max_stale = opt_int,          --"max-stale" [ "=" delta-seconds ]
	min_fresh = must_int,         --"min-fresh" "=" delta-seconds
	no_transform = no_value,      --"no-transform"
	only_if_cached = no_value,    --"only-if-cached"
	public = no_value,            --"public"
	private = opt_nameset,        --"private" [ "=" <"> 1#field-name <"> ]
	no_cache = opt_nameset,       --"no-cache" [ "=" <"> 1#field-name <"> ]
	no_store = no_value,          --"no-store"
	no_transform = no_value,      --"no-transform"
	must_transform = no_value,    --"must-transform"
	must_revalidate = no_value,   --"must-revalidate"
	proxy_revalidate = no_value,  --"proxy-revalidate"
	max_age = must_int,           --"max-age" "=" delta-seconds
	s_maxage = must_int,          --"s-maxage" "=" delta-seconds
}

function parse.cache_control(s)
	return propertylist(s, cc_parse)
end

parse.connection = nameset --1#(connection-token)
parse.content_encoding = namelist --1#(content-coding)
parse.content_language = nameset --1#(language-tag)
parse.content_length = int
parse.content_location = url

function parse.content_md5(s)
	return glue.tohex(base64(s))
end

function parse.content_range(s) --bytes <from>-<to>/<total> -> {from=,to=,total=,size=}
	local from,to,total = s:match'bytes (%d+)%-(%d+)/(%d+)'
	local t = {}
	t.from = tonumber(from)
	t.to = tonumber(to)
	t.total = tonumber(total)
	if t.from and t.to then t.size = t.to - t.from + 1 end
	return t
end

function parse.content_type(s) --type "/" subtype *( ";" name "=" value )
	local t,i,j, params = valueparams(tokens(s))
	if t[i+1] ~= '/' then return end
	params = params or {}
	params.media_type = name(concat(t,'',i,j))
	return params
end

parse.date = date

local function etag(s) --[ "W/" ] quoted-string -> {etag = s, weak = true|false}
	local weak_etag = s:match'^W/(.*)$'
	local etag = qstring(weak_etag or s)
	if not etag then return end
	return {etag = etag, weak = weak_etag ~= nil}
end

parse.etag = etag

local expect_parse = {['100_continue'] = no_value}

function parse.expect(s) --1#( "100-continue" | ( token "=" ( token | quoted-string ) ) )
	return propertylist(s, expect_parse)
end

parse.expires = date
parse.from = glue.pass --email-address

function parse.host(s) --host [ ":" port ]
	local host, port = s:match'^(.-) ?: ?(.*)$'
	if not host then
		host, port = s, 80
	else
		port = int(port)
		if not port then return end
	end
	host = host:lower()
	return {host = host, port = port}
end

local function etags(s) -- "*" | 1#( [ "W/" ] quoted-string )
	if s == '*' then return '*' end
	local dt = {}
	for t,i,j in tsplit(tokens(s), ',') do
		local weak,slash,etag = unpack(t,i,j)
		local is_weak = weak == 'W' and slash == '/'
		etag = is_weak and etag or weak
		dt[#dt+1] = {etag = etag, weak = is_weak}
	end
	return dt
end

parse.if_match = etags
parse.if_modified_since = date
parse.if_none_match = etags

function parse.if_range(s) -- etag | date
	local is_etag = s:match'^W/' or s:match'^"'
	return is_etag and etag(s) or date(s)
end

parse.if_unmodified_since = date
parse.last_modified = date
parse.location = url
parse.max_forwards = int

local pragma_parse = {no_cache = no_value}

function parse.pragma(s) -- 1#( "no-cache" | token [ "=" ( token | quoted-string ) ] )
	return propertylist(s, pragma_parse)
end

function parse.range(s) --bytes=<from>-<to> -> {from=,to=,size=}
	local from,to = s:match'bytes=(%d+)%-(%d+)'
	local t = {}
	t.from = tonumber(from)
	t.to = tonumber(to)
	if t.from and t.to then t.size = t.to - t.from + 1 end
	return t
end

parse.referer = url

function parse.retry_after(s) --date | seconds
	return int(s) or date(s)
end

function parse.server(s) --1*( ( token ["/" version] ) | comment )
	local dt = {}
	for t,i,j in tsplit(tokens(s), ',') do
		local product, slash, version = unpack(t,i,j)
		if slash == '/' then
			dt[name(product)] = version or true
		end
	end
	return dt
end

local te_parse = {trailers = no_value, q = must_int}

function parse.te(s) --#( "trailers" | ( transfer-extension [ accept-params ] ) )
	local dt = {}
	for t,i,j, params in valueparamslist(s, te_parse) do
		dt[name(t[i])] = params or true
	end
	return dt
end

parse.trailer = nameset --1#header-name

local trenc_parse = {chunked = no_value}

function parse.transfer_encoding(s) --1# ( "chunked" | token *( ";" name "=" ( token | quoted-string ) ) )
	local dt = {params = {}}
	for t,i,j, params in valueparamslist(s, trenc_parse) do
		local k = name(t[i])
		dt[#dt+1] = k
		dt.params[k] = params
	end
	return dt
end

function parse.upgrade(s) --1#product
	local dt = {}
	for t,i,j in tsplit(tokens(s), ',') do
		local protocol,slash,version = unpack(t,i,j)
		dt[name(protocol)] = version or true
	end
	return dt
end

parse.user_agent = string.lower --1*( product | comment )

function parse.vary(s) --( "*" | 1#field-name )
	if s == '*' then return '*' end
	return nameset(s)
end

function parse.via(s) --1#( [ protocol-name "/" ] protocol-version host [ ":" port ] [ comment ] )
	local dt = {}
	for t,i,j in tsplit(tokens(s), ',') do
		local proto = t[i+1] == '/' and t[i] or nil
		local o = proto and 2 or 0
		if o+j-i+1 < 2 then return end
		local ver, host = t[o+i], t[o+i+1]
		local port = t[o+i+2] ==':' and t[o+i+3] or nil
		local comment = t[o+i+2+(port and 2 or 0)]
		if comment == ',' then comment = nil end
		if ver and host then
			dt[#dt+1] = {
				protocol = proto and name(proto),
				version = ver:lower(),
				host = host:lower(),
				comment = comment
			}
		end
	end
	return dt
end

function parse.warning(s) --1#(code ( ( host [ ":" port ] ) | pseudonym ) text [date])
	local dt = {}
	for t,i,j in tsplit(tokens(s), ',') do
		local code, host, port, message, date
		if t[i+2] == ':' then
			code, host, port, message, date = unpack(t,i,j)
		else
			code, host, message, date = unpack(t,i,j)
		end
		dt[#dt+1] = {code = int(code), host = host:lower(), port = int(port), message = message}
	end
	return dt
end

function parse.dnt(s) return s == '1' end --means "do not track"

function parse.link(s) --</feed>; rel="alternate" (http://tools.ietf.org/html/rfc5988)
	--[[ --TODO
	Link           = "Link" ":" #link-value
	link-value     = "<" URI-Reference ">" *( ";" link-param )
	link-param     = ( ( "rel" "=" relation-types )
					  | ( "anchor" "=" <"> URI-Reference <"> )
					  | ( "rev" "=" relation-types )
					  | ( "hreflang" "=" Language-Tag )
					  | ( "media" "=" ( MediaDesc | ( <"> MediaDesc <"> ) ) )
					  | ( "title" "=" quoted-string )
					  | ( "title*" "=" ext-value )
					  | ( "type" "=" ( media-type | quoted-mt ) )
					  | ( link-extension ) )
	link-extension = ( parmname [ "=" ( ptoken | quoted-string ) ] )
					  | ( ext-name-star "=" ext-value )
	ext-name-star  = parmname "*" ; reserved for RFC2231-profiled
										  ; extensions.  Whitespace NOT
										  ; allowed in between.
	ptoken         = 1*ptokenchar
	ptokenchar     = "!" | "#" | "$" | "%" | "&" | "'" | "("
					  | ")" | "*" | "+" | "-" | "." | "/" | DIGIT
					  | ":" | "<" | "=" | ">" | "?" | "@" | ALPHA
					  | "[" | "]" | "^" | "_" | "`" | "{" | "|"
					  | "}" | "~"
	media-type     = type-name "/" subtype-name
	quoted-mt      = <"> media-type <">
	relation-types = relation-type
					  | <"> relation-type *( 1*SP relation-type ) <">
	relation-type  = reg-rel-type | ext-rel-type
	reg-rel-type   = LOALPHA *( LOALPHA | DIGIT | "." | "-" )
	ext-rel-type   = URI
	]]
	return s
end

function parse.refresh(s) --seconds; url=<url> (not standard but supported)
	local n, url = s:match'^(%d+) ?; ?url ?= ?'
	n = tonumber(n)
	return n and {url = url, pause = n}
end

headers.cookie_attr_parsers = {
	expires = date,
	['max-age'] = tonumber,
	domain = function(s) return s ~= '' and s:lower() or nil end,
	path = function(s) return s:sub(1, 1) == '/' and s or nil end,
}

local function cookie_value(s)
	return not s:find'[%z\1-\32\127",;\\]' and s
end

--cookies come as a list since they aren't allowed to be folded.
function parse.set_cookie(t)
	local dt = {}
	for _,s in ipairs(t) do
		local cookie = {}
		for s in s:gmatch'[^;]+' do --name=val; attr1=val1; ...
			if not cookie.name then --name=val | name="val" | name=
				local k, v = s:match'^%s*(.-)%s*=%s*(.-)%s*$'
				v = v:gsub('^"(.-)"$', '%1')
				k = token(k) --case-sensitive!
				v = k and cookie_value(v)
				--skip invalid cookies because they can't be given back anyway.
				if not k or not v then goto skip end
				cookie.name = k
				cookie.value = v
			else --attr=val | attr= | attr | ext
				local k, eq, v = s:match'^([^=]+)(=?)%s*(.-)%s*$'
				k = glue.trim(k):lower()
				if eq == '' then v = true end
				local parse = headers.cookie_attr_parsers[k]
				if parse then
					v = parse(v)
					cookie[k] = v
				elseif k ~= 'name' and k ~= 'value' then --attribute
					cookie[k] = v
				end
			end
		end
		if not cookie.name then goto skip end
		dt[#dt+1] = cookie
		::skip::
	end
	return dt
end

--NOTE: The newer rfc-6265 disallows multiple cookie headers, but if a client
--sends them anyway, they will come folded hence allowing comma as separator.
--Problem is, older rfc-2965 also specifies some sort of cookie attributes.
--If you ask me, I think it's a miracle that our computers even start when
--we plug them in. Something to be grateful for.
function parse.cookie(s)
	local dt = {}
	for s in s:gmatch'[^;,]+' do --name1=val1; ...
		local k, v = s:match'^%s*(.-)%s*=%s*(.-)%s*$'
		dt[k] = v:gsub('^"(.-)"$', '%1')
	end
	return dt
end

function parse.strict_transport_security(s) --http://tools.ietf.org/html/rfc6797
	--[[ --TODO
	  Strict-Transport-Security = "Strict-Transport-Security" ":"
                                 [ directive ]  *( ";" [ directive ] )

     directive                 = directive-name [ "=" directive-value ]
     directive-name            = token
     directive-value           = token | quoted-string
	]]
	return s
end

function parse.content_disposition(s)
	--[[ --TODO
	 content-disposition = "Content-Disposition" ":"
                              disposition-type *( ";" disposition-parm )
        disposition-type = "attachment" | disp-extension-token
        disposition-parm = filename-parm | disp-extension-parm
        filename-parm = "filename" "=" quoted-string
        disp-extension-token = token
        disp-extension-parm = token "=" ( token | quoted-string )
	]]
	return s
end

parse.x_requested_with = name   --"XMLHttpRequest"
parse.x_forwarded_for = nameset --client1, proxy1, proxy2
parse.x_forwarded_proto = name  --"https" | "http"
parse.x_powered_by = glue.pass  --PHP/5.2.1

--parsing API

function headers.parse_header(k, v)
	local uk = k:gsub('-', '_')
	if parse[uk] then return parse[uk](v) end
	return v --unknown header, return unparsed
end

--lazy parsing: headers.parsed(t) -> t; t.header_name -> parsed_value
function headers.parsed_headers(rawheaders)
	return setmetatable({}, {__index = function(self, k)
		local s = rawheaders[k]
		if s == nil then return nil end
		local v = headers.parse_header(k, s)
		rawset(self, k, v)
		return v
	end})
end

function headers.parse_headers(rawheaders)
	local t = {}
	for k, v in pairs(rawheaders) do
		t[k] = headers.parse_header(k, v)
	end
	return t
end

--formatting -----------------------------------------------------------------

local ci = string.lower
local base64 = b64.encode_string

local function int(v)
	glue.assert(math.floor(v) == v, 'integer expected')
	return v
end

local function date(t)
	return http_date.format(t, 'rfc1123')
end

--{k->true} -> k1,k2,...
local function klist(t, format)
	format = format or glue.pass
	if type(t) == 'table' then
		local dt = {}
		for k,v in pairs(t) do
			if v then
				dt[#dt+1] = format(k)
			end
		end
		return concat(dt, ',')
	else
		return format(t) --got them raw
	end
end

local function checkupper(s)
	assert(s == s:upper())
end
local function uppercaseklist(t)
	return klist(t, checkupper)
end

--{v1,v2,...} -> v1,v2,...
local function list(t, format)
	format = format or glue.pass
	if type(t) == 'table' then
		local dt = {}
		for i,v in ipairs(t) do
			dt[#dt+1] = format(v)
		end
		return concat(dt, ',')
	else
		return format(t) --got them raw
	end
end

local function cilist(t)
	return list(t, string.lower)
end

--{k1=v1,...} -> k1=v1,...
local function kvlist(kvt)
	local t = {}
	for k,v in pairs(kvt) do
		if v then
			t[#t+1] = v == true and k or _('%s=%s', k, v)
		end
	end
	return concat(t, ',')
end

--{name,k1=v1,...} -> name[; k1=v1 ...]
local function params(known)
	return function(s)
		return s
	end
end

--individual formatters per rfc-2616 section 14.

local format = {}
headers.format = format

--{from=,to=,size=} -> bytes=<from>-<to>
function format.range(v)
end

--{from=,to=,total=,size=} -> bytes <from>-<to>/<total>
function format.content_range(v)

end

function format.host(t)
	return t.host .. (t.port and ':' .. t.port or '')
end

local function q(s)
	return s:find'[ %,%;]")' and '"'..s..'"' or s
end

function format.cookie(t)
	local dt = {}
	for k,v in pairs(t) do
		assert(token(k), 'invalid cookie name')
		assert(cookie_value(v), 'invalid cookie value')
		dt[#dt+1] = _('%s=%s', k, q(v))
	end
	return #dt > 0 and concat(dt, ';')
end

function format.set_cookie(t)
	for k,c in pairs(t) do
		if type(c) == 'string' then c = {value = c} end
		assert(token(k), 'invalid cookie name')
		assert(cookie_value(c.value), 'invalid cookie value')
		local t = {}
		for k,v in pairs(t) do
			k = k:lower()
			assert(not k:find'[%z\1-32\127;=]',
				'invalid cookie attribute name')
			assert(v == true or not v:find'[%z\1-32\127;]',
				'invalid cookie attribute value')
			t[#t+1] = v == true and k or _('%s=%s', k, tostring(v))
		end
		local attrs = #t > 0 and ';'..concat(t, ';') or ''
		dt[#dt+1] = _('%s=%s%s', k, q(v), attrs)
	end
	return dt --return as table so it can be sent unfolded.
end

headers.nofold = { --headers that it isn't safe to fold.
	['set-cookie'] = true,
	['www-authenticate'] = true,
	['proxy-authenticate'] = true,
}

--general header fields
format.cache_control = kvlist --no_cache
format.connection = cilist
format.content_length = int
format.content_md5 = base64
format.content_type = params{charset = ci} --text/html; charset=iso-8859-1
format.date = date
format.pragma = nil --cilist?
format.trailer = headernames
format.transfer_encoding = cilist
format.upgrade = nil --http/2.0 shttp/1.3 irc/6.9 rta/x11
format.via = nil --1.0 fred 1.1 nowhere.com (apache/1.1)
format.warning = nil --list of '(%d%d%d) (.-) (.-) ?(.*)' --code agent text[ date]

--standard request headers
format.accept = cilist --paramslist?
format.accept_charset = cilist
format.accept_encoding = cilist
format.accept_language = cilist
format.authorization = ci --basic <password>
format.expect = cilist --100-continue
format.from = nil --user@example.com
format.if_match = nil --<etag>
format.if_modified_since = date
format.if_none_match = nil --etag
format.if_range = nil --etag
format.if_unmodified_since	= date
format.max_forwards = int
format.proxy_authorization = nil --basic <password>
format.referer = nil --it's an url but why parse it
format.te = cilist --"trailers deflate"
format.user_agent = nil --mozilla/5.0 (compatible; msie 9.0; windows nt 6.1; wow64; trident/5.0)

--non-standard request headers
format.x_requested_with = ci--xmlhttprequest
format.dnt = function(v) return v[#v]=='1' end --means "do not track"
format.x_forwarded_for = nil --client1 proxy1 proxy2

--standard response headers
format.accept_ranges = ci --"bytes"
format.age = int --seconds
format.allow = uppercaseklist --methods
format.content_disposition = params{filename = nil} --attachment; ...
format.content_encoding = cilist
format.content_language = cilist
format.content_location = url
format.etag = nil
format.expires = date
format.last_modified = date
format.link = nil --?
format.location = url
format.p3p = nil
format.proxy_authenticate = ci --basic
format.refresh = params{url = url} --seconds; ... (not standard but supported)
format.retry_after = int --seconds
format.server = nil
format.strict_transport_security = nil --eg. max_age=16070400; includesubdomains
format.vary = headernames
format.www_authenticate = ci

--non-standard response headers
format.x_Forwarded_proto = ci --https|http
format.x_powered_by = nil --PHP/5.2.1

function headers.format_header(k, v)
	local k = k:lower()
	if type(v) ~= 'string' then --strings pass-through unchanged.
		local f = format[k:gsub('-', '_')]
		if f then v = f(v) end
	end
	return k, v and tostring(v)
end

return headers
