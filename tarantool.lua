
--Tarantool client for LuaJIT.
--Written by Cosmin Apreutesei. Public Domain.

if not ... then require'tarantool_test'; return end

local ffi     = require'ffi'
local bit     = require'bit'
local mp      = require'msgpack'
local b64     = require'base64'
local sha1    = require'sha1'.sha1
local errors  = require'errors'
local glue    = require'glue'

local u8a     = glue.u8a
local u8p     = glue.u8p
local buffer  = glue.buffer
local empty   = glue.empty
local memoize = glue.memoize
local object  = glue.object

local check_io, checkp, check, protect = errors.tcp_protocol_errors'tarantool'

local c = {host = '127.0.0.1', port = 3301, timeout = 5, tracebacks = false}

function c.log(severity, ...)
	local logging = c.logging
	if not logging then return end
	logging.log(severity, 'taran', ...)
end

function c.dbg  (...) c.log(''    , ...) end
function c.note (...) c.log('note', ...) end

--IPROTO_*
local OK            = 0
local SELECT        = 1
local INSERT        = 2
local REPLACE       = 3
local UPDATE        = 4
local DELETE        = 5
local AUTH          = 7
local EVAL          = 8
local UPSERT        = 9
local CALL          = 10
local EXECUTE       = 11
local NOP           = 12
local PREPARE       = 13
local PING          = 0x40
local REQUEST_TYPE  = 0x00
local SYNC          = 0x01
local SPACE_ID      = 0x10
local INDEX_ID      = 0x11
local LIMIT         = 0x12
local OFFSET        = 0x13
local ITERATOR      = 0x14
local KEY           = 0x20
local TUPLE         = 0x21
local FUNCTION_NAME = 0x22
local USER_NAME     = 0x23
local EXPR          = 0x27
local OPS           = 0x28
local OPTIONS       = 0x2b
local DATA          = 0x30
local ERROR         = 0x31
local METADATA      = 0x32
local BIND_METADATA = 0x33
local BIND_COUNT    = 0x34
local SQL_TEXT      = 0x40
local SQL_BIND      = 0x41
local SQL_INFO      = 0x42
local STMT_ID       = 0x43
local FIELD_NAME    = 0x00
local FIELD_TYPE    = 0x01
local FIELD_COLL    = 0x02
local FIELD_IS_NULLABLE = 0x03
local FIELD_IS_AUTOINCREMENT = 0x04
local FIELD_SPAN    = 0x05
local STREAM_ID     = 0x0a
local SQL_INFO_ROW_COUNT         = 0
local SQL_INFO_AUTOINCREMENT_IDS = 1

-- default views
local VIEW_SPACE = 281
local VIEW_INDEX = 289

-- index info
local INDEX_SPACE_NAME = 2
local INDEX_INDEX_NAME = 2

local function xor_strings(s1, s2)
	assert(#s1 == #s2)
	local n = #s1
	local p1 = ffi.cast(u8p, s1)
	local p2 = ffi.cast(u8p, s2)
	local b = u8a(n)
	for i = 0, n-1 do
		b[i] = bit.bxor(p1[i], p2[i])
	end
	return ffi.string(b, n)
end

local request, tselect --fw. decl.

local MP_DECIMAL = 1
local MP_UUID    = 2

--NOTE: only works with luapower's ldecnumber which has frompacked().
local function decode_decimal(mp, p, i, len)
	local ldecnumber = require'ldecnumber'
	local i2 = i + len
	local i1, scale = mp:decode_next(p, i2, i)
	local s = ffi.string(p+i1, i2-i1) --lame that we have to intern a string for this.
	return ldecnumber.frompacked(s, scale)
end

local function decode_uuid(mp, p, i, len) --16 bytes binary UUID
	return ffi.string(p+i, len)
end

c.connect = protect(function(opt)
	local c = object(c, opt)
	c.note('connect', '%s:%s user=%s', c.host, c.port, c.user or '')
	c:clear_metadata_cache()
	if not c.tcp then
		local sock = require'sock'
		c.tcp = sock.tcp
		c.clock = sock.clock
	end
	c.tcp = check_io(c, c.tcp()) --pin it so that it's closed automatically on error.
	local expires = opt.expires or c.clock() + (opt.timeout or c.timeout)
	check_io(c, c.tcp:connect(c.host, c.port, expires))
	c._b = buffer()
	c.mp = opt.mp or mp.new()
	c.mp.error = function(err) checkp(c, false, '%s', err) end
	c.mp.decoder[MP_DECIMAL] = decode_decimal
	c.mp.decoder[MP_UUID   ] = decode_uuid
	c._mb = mp:encoding_buffer()
	local b = c._b(64)
	check_io(c, c.tcp:recvn(b, 64, expires)) --greeting
	local salt = ffi.string(check_io(c, c.tcp:recvn(b, 64, expires)), 44)
	if c.user then
		local body = {[USER_NAME] = c.user}
		if c.password and c.password ~= '' then
			local salt = b64.decode(salt):sub(1, 20)
			local s1 = sha1(c.password)
			local s2 = sha1(s1)
			local s3 = sha1(salt .. s2)
			local scramble = xor_strings(s1, s3)
			body[TUPLE] = mp.array('chap-sha1', scramble)
		end
		request(c, AUTH, body, expires)
	end
	return c
end)

c.stream = function(c)
	c.last_stream_id = (c.last_stream_id or 0) + 1
	return object(c, {stream_id = c.last_stream_id})
end

c.close = function(c)
	c.note('close', '%s:%s', c.host, c.port)
	return c.tcp:close()
end

--[[local]] function request(c, req_type, body, expires)
	local expires = expires or c.clock() + c.timeout
	c.sync_num = (c.sync_num or 0) + 1
	local header = {
		[SYNC] = c.sync_num,
		[REQUEST_TYPE] = req_type,
		[STREAM_ID] = c.stream_id,
	}
	local mp = c.mp
	local mb = c._mb
	local req = mb:reset():encode_map(header):encode_map(body):tostring()
	local len = mb:reset():encode_int(#req):tostring()
	check_io(c, c.tcp:send(len .. req))
	local size = check_io(c, c.tcp:recvn(c._b(5), 5, expires))
	local _, size = mp:decode_next(size, 5)
	local s = check_io(c, c.tcp:recvn(c._b(size), size, expires))
	local i, res_header = mp:decode_next(s, size)
	checkp(c, res_header[SYNC] == c.sync_num)
	local i, res_body = mp:decode_next(s, size, i)
	local code = res_header[REQUEST_TYPE]
	if code ~= OK then
		check(c, false, res_body[ERROR])
	end
	return res_body
end

local function resolve_space(c, space)
	return type(space) == 'number' and space or c._lookup_space(space)
end

local function resolve_index(c, space, index)
	index = index or 0
	local space = resolve_space(c, space)
	return space, type(index) == 'number' and index or c._lookup_index(space, index)
end

c.clear_metadata_cache = function(c)
	c._lookup_space = memoize(function(space)
		local t = tselect(c, VIEW_SPACE, INDEX_SPACE_NAME, space)
		return check(c, t[1] and t[1][1], "no space '%s'", space)
	end)
	c._lookup_index = memoize(function(spaceno, index)
		if not spaceno then return end
		local t = tselect(c, VIEW_INDEX, INDEX_INDEX_NAME, {spaceno, index})
		return check(c, t[1] and t[1][2], "no index '%s'", index)
	end)
end

local function key_arg(key)
	return mp.toarray(type(key) == 'table' and key or key == nil and {} or {key})
end

local function fields(t)
	if not t then return end
	local dt = {}
	for i, t in ipairs(t) do
		dt[i] = {
			name      = t[FIELD_NAME],
			type      = t[FIELD_TYPE],
			collation = t[FIELD_COLL],
			not_null  = not t[FIELD_IS_NULLABLE],
			autoinc   = t[FIELD_IS_AUTOINCREMENT],
			span      = t[FIELD_SPAN],
		}
	end
	return dt
end

local function apply_sqlinfo(dt, t)
	if t then --update query
		dt.affected_rows = t[SQL_INFO_ROW_COUNT]
		dt.autoinc_ids   = t[SQL_INFO_AUTOINCREMENT_IDS]
	end
	return dt
end

local function exec_response(res)
	return apply_sqlinfo(res[DATA] or {}, res[SQL_INFO]), fields(res[METADATA])
end

--[[local]] function tselect(c, space, index, key, opt)
	opt = opt or empty
	local space, index = resolve_index(c, space, index)
	local body = {
		[SPACE_ID] = space,
		[INDEX_ID] = index,
		[KEY] = key_arg(key),
	}
	body[LIMIT] = opt.limit or 0xFFFFFFFF
	body[OFFSET] = opt.offset or 0
	body[ITERATOR] = opt.iterator
	local expires = opt.expires or c.clock() + (opt.timeout or c.timeout)
	return exec_response(request(c, SELECT, body, expires))
end
c.select = protect(tselect)

c.insert = protect(function(c, space, tuple)
	return request(c, INSERT, {
		[SPACE_ID] = resolve_space(c, space),
		[TUPLE] = mp.toarray(tuple),
	})[DATA]
end)

c.replace = protect(function(c, space, tuple)
	return request(c, REPLACE, {
		[SPACE_ID] = resolve_space(c, space),
		[TUPLE] = mp.toarray(tuple),
	})[DATA]
end)

c.update = protect(function(c, space, index, key, oplist)
	local space, index = resolve_index(c, space, index)
	return request(c, UPDATE, {
		[SPACE_ID] = space,
		[INDEX_ID] = index,
		[KEY] = key_arg(key),
		[TUPLE] = mp.toarray(oplist),
	})[DATA]
end)

c.delete = protect(function(c, space, key)
	local space, index = resolve_index(c, space, index)
	return request(c, DELETE, {
		[SPACE_ID] = space,
		[INDEX_ID] = index,
		[KEY] = key_arg(key),
	})[DATA]
end)

c.upsert = protect(function(c, space, index, key, oplist)
	return request(c, UPSERT, {
		[SPACE_ID] = resolve_space(c, space),
		[INDEX_ID] = index,
		[OPS] = oplist,
		[TUPLE] = key_arg(key),
	})[DATA]
end)

c.eval = protect(function(c, expr, ...)
	if type(expr) == 'function' then
		expr = require'pp'.format(expr)
		expr = string.format('return assert(%s)(...)', expr)
	end
	return unpack(request(c, EVAL, {[EXPR] = expr, [TUPLE] = mp.array(...)})[DATA])
end)

c.call = protect(function(c, fn, ...)
	return unpack(request(c, CALL, {[FUNCTION_NAME] = fn, [TUPLE] = mp.array(...)})[DATA])
end)

c.exec = protect(function(c, sql, params, xopt, param_meta)
	if param_meta and param_meta.has_named_params then --pick params from named keys
		local t = params
		params = {}
		for i,f in ipairs(param_meta) do
			if f.index then
				params[i] = t[f.index]
			else
				params[i] = t[f.name]
			end
		end
	end
	c.dbg('exec', '%s', sql)
	return exec_response(request(c, EXECUTE, {
		[STMT_ID] = type(sql) == 'number' and sql or nil,
		[SQL_TEXT] = type(sql) == 'string' and sql or nil,
		[SQL_BIND] = params,
		[OPTIONS] = xopt or empty,
	}))
end)

local st = {}

local function params(t)
	t = fields(t)
	local j = 0
	for i,f in ipairs(t) do
		if f.name:sub(1, 1) == ':' then
			f.name = f.name:sub(2)
			t.has_named_params = true
		else
			j = j + 1
			f.index = j
		end
	end
	return t
end

c.prepare = protect(function(c, sql)
	local res = request(c, PREPARE, {
		[SQL_TEXT] = type(sql) == 'string' and sql or nil,
	})
	return object(st, {
		id = res[STMT_ID],
		conn = c,
		fields = fields(res[METADATA]),
		params = params(res[BIND_METADATA]),
	})
end)

function st:exec(params, xopt)
	return self.conn:exec(self.id, params, xopt, self.params)
end

local unprepare = protect(function(c, stmt_id)
	return request(c, PREPARE, {[STMT_ID] = stmt_id})[STMT_ID]
end)
function st:free()
	return unprepare(self.conn, self.id)
end

c.ping = protect(function(c)
	return request(c, PING, empty)
end)

local function esc_quote(s) return "''" end
function c.esc(s)
	return s:gsub("'", esc_quote)
end

return c
