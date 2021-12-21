
--MySQL client library ffi binding.
--Written by Cosmin Apreutesei. Public domain.

--Supports MySQL Connector/C 6.1.
--Based on MySQL 5.7 manual.

if not ... then require'mysql_test'; return end

local ffi = require'ffi'
local bit = require'bit'
require'mysql_h'

local C
local M = {}

--select a mysql client library implementation.
local function bind(lib)
	if not C then
		if not lib or lib == 'mysql' then
			C = ffi.load(ffi.abi'win' and 'libmysql' or 'mysqlclient')
		elseif lib == 'mariadb' then
			C = ffi.load'mariadb'
		elseif type(lib) == 'string' then
			C = ffi.load(lib)
		else
			C = lib
		end
		M.C = C
	end
	return M
end

M.bind = bind

--we compare NULL pointers against NULL instead of nil for compatibility with luaffi.
local NULL = ffi.cast('void*', nil)

local function ptr(p) --convert NULLs to nil
	if p == NULL then return nil end
	return p
end

local function cstring(data) --convert null-term non-empty C strings to lua strings
	if data == NULL or data[0] == 0 then return nil end
	return ffi.string(data)
end

--error reporting

local function myerror(mysql, stacklevel)
	local err = cstring(C.mysql_error(mysql))
	if not err then return end
	error(string.format('mysql error: %s', err), stacklevel or 3)
end

local function checkz(mysql, ret)
	if ret == 0 then return end
	myerror(mysql, 4)
end

local function checkh(mysql, ret)
	if ret ~= NULL then return ret end
	myerror(mysql, 4)
end

local function enum(e, prefix)
	local v = type(e) == 'string' and (prefix and C[prefix..e] or C[e]) or e
	return assert(v, 'invalid enum value')
end

--client library info

function M.thread_safe()
	bind()
	return C.mysql_thread_safe() == 1
end

function M.client_info()
	bind()
	return cstring(C.mysql_get_client_info())
end

function M.client_version()
	bind()
	return tonumber(C.mysql_get_client_version())
end

--connections

local function bool_ptr(b)
	return ffi.new('my_bool[1]', b or false)
end

local function uint_bool_ptr(b)
	return ffi.new('uint32_t[1]', b or false)
end

local function uint_ptr(i)
	return ffi.new('uint32_t[1]', i)
end

local function proto_ptr(proto) --proto is 'MYSQL_PROTOCOL_*' or mysql.C.MYSQL_PROTOCOL_*
	return ffi.new('uint32_t[1]', enum(proto))
end

local function ignore_arg()
	return nil
end

local option_encoders = {
	MYSQL_ENABLE_CLEARTEXT_PLUGIN = bool_ptr,
	MYSQL_OPT_LOCAL_INFILE = uint_bool_ptr,
	MYSQL_OPT_PROTOCOL = proto_ptr,
	MYSQL_OPT_READ_TIMEOUT = uint_ptr,
	MYSQL_OPT_WRITE_TIMEOUT = uint_ptr,
	MYSQL_OPT_USE_REMOTE_CONNECTION = ignore_arg,
	MYSQL_OPT_USE_EMBEDDED_CONNECTION = ignore_arg,
	MYSQL_OPT_GUESS_CONNECTION = ignore_arg,
	MYSQL_SECURE_AUTH = bool_ptr,
	MYSQL_REPORT_DATA_TRUNCATION = bool_ptr,
	MYSQL_OPT_RECONNECT = bool_ptr,
	MYSQL_OPT_SSL_VERIFY_SERVER_CERT = bool_ptr,
	MYSQL_ENABLE_CLEARTEXT_PLUGIN = bool_ptr,
	MYSQL_OPT_CAN_HANDLE_EXPIRED_PASSWORDS = bool_ptr,
}

function M.connect(t, ...)
	bind()
	local host, user, pass, db, charset, port
	local unix_socket, flags, options, attrs
	local key, cert, ca, capath, cipher
	if type(t) == 'string' then
		host, user, pass, db, charset, port = t, ...
	else
		host, user, pass, db, charset, port = t.host, t.user, t.pass, t.db, t.charset, t.port
		unix_socket, flags, options, attrs = t.unix_socket, t.flags, t.options, t.attrs
		key, cert, ca, capath, cipher = t.key, t.cert, t.ca, t.capath, t.cipher
	end
	port = port or 0

	local client_flag = 0
	if type(flags) == 'number' then
		client_flag = flags
	elseif flags then
		for k,v in pairs(flags) do
			local flag = enum(k, 'MYSQL_') --'CLIENT_*' or mysql.C.MYSQL_CLIENT_* enum
			client_flag = v and bit.bor(client_flag, flag) or bit.band(client_flag, bit.bnot(flag))
		end
	end

	local mysql = assert(C.mysql_init(nil))
	ffi.gc(mysql, C.mysql_close)

	if options then
		for k,v in pairs(options) do
			local opt = enum(k) --'MYSQL_OPT_*' or mysql.C.MYSQL_OPT_* enum
			local encoder = option_encoders[k]
			if encoder then v = encoder(v) end
			assert(C.mysql_options(mysql, opt, ffi.cast('const void*', v)) == 0, 'invalid option')
		end
	end

	if attrs then
		for k,v in pairs(attrs) do
			assert(C.mysql_options4(mysql, C.MYSQL_OPT_CONNECT_ATTR_ADD, k, v) == 0)
		end
	end

	if key then
		checkz(mysql, C.mysql_ssl_set(mysql, key, cert, ca, capath, cipher))
	end

	checkh(mysql, C.mysql_real_connect(mysql, host, user, pass, db, port, unix_socket, client_flag))

	if charset then mysql:set_charset(charset) end

	return mysql
end

local conn = {} --connection methods

function conn.close(mysql)
	C.mysql_close(mysql)
	ffi.gc(mysql, nil)
end

function conn.set_charset(mysql, charset)
	checkz(mysql, C.mysql_set_character_set(mysql, charset))
end

function conn.select_db(mysql, db)
	checkz(mysql, C.mysql_select_db(mysql, db))
end

function conn.change_user(mysql, user, pass, db)
	checkz(mysql, C.mysql_change_user(mysql, user, pass, db))
end

function conn.set_multiple_statements(mysql, yes)
	checkz(mysql, C.mysql_set_server_option(mysql, yes and C.MYSQL_OPTION_MULTI_STATEMENTS_ON or
																			 C.MYSQL_OPTION_MULTI_STATEMENTS_OFF))
end

--connection info

function conn.charset(mysql)
	return cstring(C.mysql_character_set_name(mysql))
end

function conn.charset_info(mysql)
	local info = ffi.new'MY_CHARSET_INFO'
	checkz(C.mysql_get_character_set_info(mysql, info))
	assert(info.name ~= NULL)
	assert(info.csname ~= NULL)
	return {
		number = info.number,
		state = info.state,
		name = cstring(info.csname), --csname and name are inverted from the spec
		collation = cstring(info.name),
		comment = cstring(info.comment),
		dir = cstring(info.dir),
		mbminlen = info.mbminlen,
		mbmaxlen = info.mbmaxlen,
	}
end

function conn.ping(mysql)
	local ret = C.mysql_ping(mysql)
	if ret == 0 then
		return true
	elseif C.mysql_error(mysql) == C.MYSQL_CR_SERVER_GONE_ERROR then
		return false
	end
	myerror(mysql)
end

function conn.thread_id(mysql)
	return C.mysql_thread_id(mysql) --NOTE: result is cdata on x64!
end

function conn.stat(mysql)
	return cstring(checkh(mysql, C.mysql_stat(mysql)))
end

function conn.server_info(mysql)
	return cstring(checkh(mysql, C.mysql_get_server_info(mysql)))
end

function conn.host_info(mysql)
	return cstring(checkh(mysql, C.mysql_get_host_info(mysql)))
end

function conn.server_version(mysql)
	return tonumber(C.mysql_get_server_version(mysql))
end

function conn.proto_info(...)
	return C.mysql_get_proto_info(...)
end

function conn.ssl_cipher(mysql)
	return cstring(C.mysql_get_ssl_cipher(mysql))
end

--transactions

function conn.commit(mysql) checkz(mysql, C.mysql_commit(mysql)) end
function conn.rollback(mysql) checkz(mysql, C.mysql_rollback(mysql)) end
function conn.set_autocommit(mysql, yes)
	checkz(mysql, C.mysql_autocommit(mysql, yes == nil or yes))
end

--queries

function conn.escape_tobuffer(mysql, data, size, buf, sz)
	size = size or #data
	assert(sz >= size * 2 + 1)
	return tonumber(C.mysql_real_escape_string(mysql, buf, data, size))
end

function conn.escape(mysql, data, size)
	size = size or #data
	local sz = size * 2 + 1
	local buf = ffi.new('uint8_t[?]', sz)
	sz = conn.escape_tobuffer(mysql, data, size, buf, sz)
	return ffi.string(buf, sz)
end

function conn.query(mysql, data, size)
	checkz(mysql, C.mysql_real_query(mysql, data, size or #data))
end

--query info

function conn.field_count(...)
	return C.mysql_field_count(...)
end

local minus1_uint64 = ffi.cast('uint64_t', ffi.cast('int64_t', -1))
function conn.affected_rows(mysql)
	local n = C.mysql_affected_rows(mysql)
	if n == minus1_uint64 then myerror(mysql) end
	return tonumber(n)
end

function conn.insert_id(...)
	return C.mysql_insert_id(...) --NOTE: result is cdata on x64!
end

function conn.errno(conn)
	local err = C.mysql_errno(conn)
	if err == 0 then return end
	return err
end

function conn.sqlstate(mysql)
	return cstring(C.mysql_sqlstate(mysql))
end

function conn.warning_count(...)
	return C.mysql_warning_count(...)
end

function conn.info(mysql)
	return cstring(C.mysql_info(mysql))
end

--query results

function conn.next_result(mysql) --multiple statement queries return multiple results
	local ret = C.mysql_next_result(mysql)
	if ret == 0 then return true end
	if ret == -1 then return false end
	myerror(mysql)
end

function conn.more_results(mysql)
	return C.mysql_more_results(mysql) == 1
end

local function result_function(func)
	return function(mysql)
		local res = checkh(mysql, C[func](mysql))
		return ffi.gc(res, C.mysql_free_result)
	end
end

conn.store_result = result_function'mysql_store_result'
conn.use_result = result_function'mysql_use_result'

local res = {} --result methods

function res.free(res)
	C.mysql_free_result(res)
	ffi.gc(res, nil)
end

function res.row_count(res)
	return tonumber(C.mysql_num_rows(res))
end

function res.field_count(...)
	return C.mysql_num_fields(...)
end

function res.eof(res)
	return C.mysql_eof(res) ~= 0
end

--field info

local field_type_names = {
	[ffi.C.MYSQL_TYPE_DECIMAL]     = 'decimal',    --DECIMAL or NUMERIC
	[ffi.C.MYSQL_TYPE_TINY]        = 'tinyint',
	[ffi.C.MYSQL_TYPE_SHORT]       = 'smallint',
	[ffi.C.MYSQL_TYPE_LONG]        = 'int',
	[ffi.C.MYSQL_TYPE_FLOAT]       = 'float',
	[ffi.C.MYSQL_TYPE_DOUBLE]      = 'double',     --DOUBLE or REAL
	[ffi.C.MYSQL_TYPE_NULL]        = 'null',
	[ffi.C.MYSQL_TYPE_TIMESTAMP]   = 'timestamp',
	[ffi.C.MYSQL_TYPE_LONGLONG]    = 'bigint',
	[ffi.C.MYSQL_TYPE_INT24]       = 'mediumint',
	[ffi.C.MYSQL_TYPE_DATE]        = 'date',       --pre mysql 5.0, storage = 4 bytes
	[ffi.C.MYSQL_TYPE_TIME]        = 'time',
	[ffi.C.MYSQL_TYPE_DATETIME]    = 'datetime',
	[ffi.C.MYSQL_TYPE_YEAR]        = 'year',
	[ffi.C.MYSQL_TYPE_NEWDATE]     = 'date',       --mysql 5.0+, storage = 3 bytes
	[ffi.C.MYSQL_TYPE_VARCHAR]     = 'varchar',
	[ffi.C.MYSQL_TYPE_BIT]         = 'bit',
	[ffi.C.MYSQL_TYPE_TIMESTAMP2]  = 'timestamp',  --mysql 5.6+, can store fractional seconds
	[ffi.C.MYSQL_TYPE_DATETIME2]   = 'datetime',   --mysql 5.6+, can store fractional seconds
	[ffi.C.MYSQL_TYPE_TIME2]       = 'time',       --mysql 5.6+, can store fractional seconds
	[ffi.C.MYSQL_TYPE_NEWDECIMAL]  = 'decimal',    --mysql 5.0+, Precision math DECIMAL or NUMERIC
	[ffi.C.MYSQL_TYPE_ENUM]        = 'enum',
	[ffi.C.MYSQL_TYPE_SET]         = 'set',
	[ffi.C.MYSQL_TYPE_TINY_BLOB]   = 'tinyblob',
	[ffi.C.MYSQL_TYPE_MEDIUM_BLOB] = 'mediumblob',
	[ffi.C.MYSQL_TYPE_LONG_BLOB]   = 'longblob',
	[ffi.C.MYSQL_TYPE_BLOB]        = 'text',       --TEXT or BLOB
	[ffi.C.MYSQL_TYPE_VAR_STRING]  = 'varchar',    --VARCHAR or VARBINARY
	[ffi.C.MYSQL_TYPE_STRING]      = 'char',       --CHAR or BINARY
	[ffi.C.MYSQL_TYPE_GEOMETRY]    = 'spatial',    --Spatial field
}

local binary_field_type_names = {
	[ffi.C.MYSQL_TYPE_BLOB]        = 'blob',
	[ffi.C.MYSQL_TYPE_VAR_STRING]  = 'varbinary',
	[ffi.C.MYSQL_TYPE_STRING]      = 'binary',
}

local field_flag_names = {
	[ffi.C.MYSQL_NOT_NULL_FLAG]         = 'not_null',
	[ffi.C.MYSQL_PRI_KEY_FLAG]          = 'pri_key',
	[ffi.C.MYSQL_UNIQUE_KEY_FLAG]       = 'unique_key',
	[ffi.C.MYSQL_MULTIPLE_KEY_FLAG]     = 'key',
	[ffi.C.MYSQL_BLOB_FLAG]             = 'is_blob',
	[ffi.C.MYSQL_UNSIGNED_FLAG]         = 'unsigned',
	[ffi.C.MYSQL_ZEROFILL_FLAG]         = 'zerofill',
	[ffi.C.MYSQL_BINARY_FLAG]           = 'is_binary',
	[ffi.C.MYSQL_ENUM_FLAG]             = 'is_enum',
	[ffi.C.MYSQL_AUTO_INCREMENT_FLAG]   = 'autoincrement',
	[ffi.C.MYSQL_TIMESTAMP_FLAG]        = 'is_timestamp',
	[ffi.C.MYSQL_SET_FLAG]              = 'is_set',
	[ffi.C.MYSQL_NO_DEFAULT_VALUE_FLAG] = 'no_default',
	[ffi.C.MYSQL_ON_UPDATE_NOW_FLAG]    = 'on_update_now',
	[ffi.C.MYSQL_NUM_FLAG]              = 'is_number',
}

local function field_type_name(info)
	local type_flag = tonumber(info.type)
	local field_type = field_type_names[type_flag]
	--charsetnr 63 changes CHAR into BINARY, VARCHAR into VARBYNARY, TEXT into BLOB
	field_type = info.charsetnr == 63 and binary_field_type_names[type_flag] or field_type
	return field_type
end

--convenience field type fetcher (less garbage)
function res.field_type(res, i)
	assert(i >= 1 and i <= res:field_count(), 'index out of range')
	local info = C.mysql_fetch_field_direct(res, i-1)
	local unsigned = bit.bor(info.flags, C.MYSQL_UNSIGNED_FLAG) ~= 0
	return field_type_name(info), tonumber(info.length), unsigned, info.decimals
end

function res.field_info(res, i)
	assert(i >= 1 and i <= res:field_count(), 'index out of range')
	local info = C.mysql_fetch_field_direct(res, i-1)
	local t = {
		name       = cstring(info.name, info.name_length),
		org_name   = cstring(info.org_name, info.org_name_length),
		table      = cstring(info.table, info.table_length),
		org_table  = cstring(info.org_table, info.org_table_length),
		db         = cstring(info.db, info.db_length),
		catalog    = cstring(info.catalog, info.catalog_length),
		def        = cstring(info.def, info.def_length),
		length     = tonumber(info.length),
		max_length = tonumber(info.max_length),
		decimals   = info.decimals,
		charsetnr  = info.charsetnr,
		type_flag  = tonumber(info.type),
		type       = field_type_name(info),
		flags      = info.flags,
		extension  = ptr(info.extension),
	}
	for flag, name in pairs(field_flag_names) do
		t[name] = bit.band(flag, info.flags) ~= 0
	end
	return t
end

--convenience field name fetcher (less garbage)
function res.field_name(res, i)
	assert(i >= 1 and i <= res:field_count(), 'index out of range')
	local info = C.mysql_fetch_field_direct(res, i-1)
	return cstring(info.name, info.name_length)
end

--convenience field iterator, shortcut for: for i=1,res:field_count() do local field = res:field_info(i) ... end
function res.fields(res)
	local n = res:field_count()
	local i = 0
	return function()
		if i == n then return end
		i = i + 1
		return i, res:field_info(i)
	end
end

--row data fetching and parsing

ffi.cdef('double strtod(const char*, char**);')
local function parse_int(data, sz) --using strtod to avoid string creation
	return ffi.C.strtod(data, nil)
end

local function parse_float(data, sz)
	return tonumber(ffi.cast('float', ffi.C.strtod(data, nil))) --because windows is missing strtof()
end

local function parse_double(data, sz)
	return ffi.C.strtod(data, nil)
end

ffi.cdef('int64_t strtoll(const char*, char**, int) ' ..(ffi.os == 'Windows' and ' asm("_strtoi64")' or '') .. ';')
local function parse_int64(data, sz)
	return ffi.C.strtoll(data, nil, 10)
end

ffi.cdef('uint64_t strtoull(const char*, char**, int) ' ..(ffi.os == 'Windows' and ' asm("_strtoui64")' or '') .. ';')
local function parse_uint64(data, sz)
	return ffi.C.strtoull(data, nil, 10)
end

local function parse_bit(data, sz)
 	data = ffi.cast('uint8_t*', data) --force unsigned
	local n = data[0] --this is the msb: bit fields always come in big endian byte order
	if sz > 6 then --we can cover up to 6 bytes with only Lua numbers
		n = ffi.new('uint64_t', n)
	end
	for i=1,sz-1 do
		n = n * 256 + data[i]
	end
	return n
end

local function parse_date_(data, sz)
	assert(sz >= 10)
	local z = ('0'):byte()
	local year  = (data[0] - z) * 1000 + (data[1] - z) * 100 + (data[2] - z) * 10 + (data[3] - z)
	local month = (data[5] - z) * 10 + (data[6] - z)
	local day   = (data[8] - z) * 10 + (data[9] - z)
	return year, month, day
end

local function parse_time_(data, sz)
	assert(sz >= 8)
	local z = ('0'):byte()
	local hour = (data[0] - z) * 10 + (data[1] - z)
	local min  = (data[3] - z) * 10 + (data[4] - z)
	local sec  = (data[6] - z) * 10 + (data[7] - z)
	local frac = 0
	for i = 9, sz-1 do
		frac = frac * 10 + (data[i] - z)
	end
	return hour, min, sec, frac
end

local function format_date(year, month, day)
	return string.format('%04d-%02d-%02d', year, month, day)
end

local function format_time(hour, min, sec, frac)
	if frac and frac ~= 0 then
		return string.format('%02d:%02d:%02d.%d', hour, min, sec, frac)
	else
		return string.format('%02d:%02d:%02d', hour, min, sec)
	end
end

local function datetime_tostring(t)
	local date, time
	if t.year then
		date = format_date(t.year, t.month, t.day)
	end
	if t.sec then
		time = format_time(t.hour, t.min, t.sec, t.frac)
	end
	if date and time then
		return date .. ' ' .. time
	else
		return assert(date or time)
	end
end

local datetime_meta = {__tostring = datetime_tostring}
local function datetime(t)
	return setmetatable(t, datetime_meta)
end

local function parse_date(data, sz)
	local year, month, day = parse_date_(data, sz)
	return datetime{year = year, month = month, day = day}
end

local function parse_time(data, sz)
	local hour, min, sec, frac = parse_time_(data, sz)
	return datetime{hour = hour, min = min, sec = sec, frac = frac}
end

local function parse_datetime(data, sz)
	local year, month, day = parse_date_(data, sz)
	local hour, min, sec, frac = parse_time_(data + 11, sz - 11)
	return datetime{year = year, month = month, day = day, hour = hour, min = min, sec = sec, frac = frac}
end

local field_decoders = { --other field types not present here are returned as strings, unparsed
	[ffi.C.MYSQL_TYPE_TINY] = parse_int,
	[ffi.C.MYSQL_TYPE_SHORT] = parse_int,
	[ffi.C.MYSQL_TYPE_LONG] = parse_int,
	[ffi.C.MYSQL_TYPE_FLOAT] = parse_float,
	[ffi.C.MYSQL_TYPE_DOUBLE] = parse_double,
	[ffi.C.MYSQL_TYPE_TIMESTAMP] = parse_datetime,
	[ffi.C.MYSQL_TYPE_LONGLONG] = parse_int64,
	[ffi.C.MYSQL_TYPE_INT24] = parse_int,
	[ffi.C.MYSQL_TYPE_DATE] = parse_date,
	[ffi.C.MYSQL_TYPE_TIME] = parse_time,
	[ffi.C.MYSQL_TYPE_DATETIME] = parse_datetime,
	[ffi.C.MYSQL_TYPE_NEWDATE] = parse_date,
	[ffi.C.MYSQL_TYPE_TIMESTAMP2] = parse_datetime,
	[ffi.C.MYSQL_TYPE_DATETIME2] = parse_datetime,
	[ffi.C.MYSQL_TYPE_TIME2] = parse_time,
	[ffi.C.MYSQL_TYPE_YEAR] = parse_int,
	[ffi.C.MYSQL_TYPE_BIT] = parse_bit,
}

local unsigned_decoders = {
	[ffi.C.MYSQL_TYPE_LONGLONG] = parse_uint64,
}

local function mode_flags(mode)
	local assoc   = mode and mode:find'a'
	local numeric = not mode or not assoc or mode:find'n'
	local decode  = not mode or not mode:find's'
	local packed  = mode and mode:find'[an]'
	local fetch_fields = assoc or decode --if assoc we need field_name, if decode we need field_type
	return numeric, assoc, decode, packed, fetch_fields
end

local function fetch_row(res, numeric, assoc, decode, field_count, fields, t)
	local values = C.mysql_fetch_row(res)
	if values == NULL then
		if res.conn ~= NULL then --buffered read: check for errors
			myerror(res.conn, 4)
		end
		return nil
	end
	local sizes = C.mysql_fetch_lengths(res)
	for i=0,field_count-1 do
		local v = values[i]
		if v ~= NULL then
			local decoder
			if decode then
				local ftype = tonumber(fields[i].type)
				local unsigned = bit.bor(fields[i].flags, C.MYSQL_UNSIGNED_FLAG) ~= 0
				decoder = unsigned and unsigned_decoders[ftype] or field_decoders[ftype] or ffi.string
			else
				decoder = ffi.string
			end
			v = decoder(values[i], tonumber(sizes[i]))
			if numeric then
				t[i+1] = v
			end
			if assoc then
				local k = ffi.string(fields[i].name, fields[i].name_length)
				t[k] = v
			end
		end
	end
	return t
end

function res.fetch(res, mode, t)
	local numeric, assoc, decode, packed, fetch_fields = mode_flags(mode)
	local field_count = C.mysql_num_fields(res)
	local fields = fetch_fields and C.mysql_fetch_fields(res)
	local row = fetch_row(res, numeric, assoc, decode, field_count, fields, t or {})
	if not row then return nil end
	if packed then
		return row
	else
		return true, unpack(row)
	end
end

function res.rows(res, mode, t)
	local numeric, assoc, decode, packed, fetch_fields = mode_flags(mode)
	local field_count = C.mysql_num_fields(res)
	local fields = fetch_fields and C.mysql_fetch_fields(res)
	local i = 0
	res:seek(1)
	return function()
		local row = fetch_row(res, numeric, assoc, decode, field_count, fields, t or {})
		if not row then return nil end
		i = i + 1
		if packed then
			return i, row
		else
			return i, unpack(row)
		end
	end
end

function res.tell(...)
	return C.mysql_row_tell(...)
end

function res.seek(res, where) --use in conjunction with res:row_count()
	if type(where) == 'number' then
		C.mysql_data_seek(res, where-1)
	else
		C.mysql_row_seek(res, where)
	end
end

--reflection

local function list_function(func)
	return function(mysql, wild)
		local res = checkh(mysql, C[func](mysql, wild))
		return ffi.gc(res, C.mysql_free_result)
	end
end

conn.list_dbs = list_function'mysql_list_dbs'
conn.list_tables = list_function'mysql_list_tables'
conn.list_processes = result_function'mysql_list_processes'

--remote control

function conn.kill(mysql, pid)
	checkz(mysql, C.mysql_kill(mysql, pid))
end

function conn.shutdown(mysql, level)
	checkz(mysql, C.mysql_shutdown(mysql, enum(level or C.MYSQL_SHUTDOWN_DEFAULT, 'MYSQL_')))
end

function conn.refresh(mysql, t) --options are 'REFRESH_*' or mysql.C.MYSQL_REFRESH_* enums
	local options = 0
	if type(t) == 'number' then
		options = t
	else
		for k,v in pairs(t) do
			if v then
				options = bit.bor(options, enum(k, 'MYSQL_'))
			end
		end
	end
	checkz(mysql, C.mysql_refresh(mysql, options))
end

function conn.dump_debug_info(mysql)
	checkz(mysql, C.mysql_dump_debug_info(mysql))
end

--prepared statements

local function sterror(stmt, stacklevel)
	local err = cstring(C.mysql_stmt_error(stmt))
	if not err then return end
	error(string.format('mysql error: %s', err), stacklevel or 3)
end

local function stcheckz(stmt, ret)
	if ret == 0 then return end
	sterror(stmt, 4)
end

local function stcheckbool(stmt, ret)
	if ret == 1 then return end
	sterror(stmt, 4)
end

local function stcheckh(stmt, ret)
	if ret ~= NULL then return ret end
	sterror(stmt, 4)
end

function conn.prepare(mysql, query)
	local stmt = checkh(mysql, C.mysql_stmt_init(mysql))
	ffi.gc(stmt, C.mysql_stmt_close)
	stcheckz(stmt, C.mysql_stmt_prepare(stmt, query, #query))
	return stmt
end

local stmt = {} --statement methods

function stmt.close(stmt)
	stcheckbool(stmt, C.mysql_stmt_close(stmt))
	ffi.gc(stmt, nil)
end

function stmt.exec(stmt)
	stcheckz(stmt, C.mysql_stmt_execute(stmt))
end

function stmt.next_result(stmt)
	local ret = C.mysql_stmt_next_result(stmt)
	if ret == 0 then return true end
	if ret == -1 then return false end
	sterror(stmt)
end

function stmt.store_result(stmt)
	stcheckz(stmt, C.mysql_stmt_store_result(stmt))
end

function stmt.free_result(stmt)
	stcheckbool(stmt, C.mysql_stmt_free_result(stmt))
end

function stmt.row_count(stmt)
	return tonumber(C.mysql_stmt_num_rows(stmt))
end

function stmt.affected_rows(stmt)
	local n = C.mysql_stmt_affected_rows(stmt)
	if n == minus1_uint64 then sterror(stmt) end
	return tonumber(n)
end

function stmt.insert_id(...)
	return C.mysql_stmt_insert_id(...)
end

function stmt.field_count(stmt)
	return tonumber(C.mysql_stmt_field_count(stmt))
end

function stmt.param_count(stmt)
	return tonumber(C.mysql_stmt_param_count(stmt))
end

function stmt.errno(stmt)
	local err = C.mysql_stmt_errno(stmt)
	if err == 0 then return end
	return err
end

function stmt.sqlstate(stmt)
	return cstring(C.mysql_stmt_sqlstate(stmt))
end

function stmt.result_metadata(stmt)
	local res = stcheckh(stmt, C.mysql_stmt_result_metadata(stmt))
	return res and ffi.gc(res, C.mysql_free_result)
end

function stmt.fields(stmt)
	local res = stmt:result_metadata()
	if not res then return nil end
	local fields = res:fields()
	return function()
		local i, info = fields()
		if not i then
			res:free()
		end
		return i, info
	end
end

function stmt.fetch(stmt)
	local ret = C.mysql_stmt_fetch(stmt)
	if ret == 0 then return true end
	if ret == C.MYSQL_NO_DATA then return false end
	if ret == C.MYSQL_DATA_TRUNCATED then return true, 'truncated' end
	sterror(stmt)
end

function stmt.reset(stmt)
	stcheckz(stmt, C.mysql_stmt_reset(stmt))
end

function stmt.tell(...)
	return C.mysql_stmt_row_tell(...)
end

function stmt.seek(stmt, where) --use in conjunction with stmt:row_count()
	if type(where) == 'number' then
		C.mysql_stmt_data_seek(stmt, where-1)
	else
		C.mysql_stmt_row_seek(stmt, where)
	end
end

function stmt.write(stmt, param_number, data, size)
	stcheckz(stmt, C.mysql_stmt_send_long_data(stmt, param_number, data, size or #data))
end

function stmt.update_max_length(stmt)
	local attr = ffi.new'my_bool[1]'
	stcheckz(stmt, C.mysql_stmt_attr_get(stmt, C.STMT_ATTR_UPDATE_MAX_LENGTH, attr))
	return attr[0] == 1
end

function stmt.set_update_max_length(stmt, yes)
	local attr = ffi.new('my_bool[1]', yes == nil or yes)
	stcheckz(stmt, C.mysql_stmt_attr_set(stmt, C.STMT_ATTR_CURSOR_TYPE, attr))
end

function stmt.cursor_type(stmt)
	local attr = ffi.new'uint32_t[1]'
	stcheckz(stmt, C.mysql_stmt_attr_get(stmt, C.STMT_ATTR_CURSOR_TYPE, attr))
	return attr[0]
end

function stmt.set_cursor_type(stmt, cursor_type)
	local attr = ffi.new('uint32_t[1]', enum(cursor_type, 'MYSQL_'))
	stcheckz(stmt, C.mysql_stmt_attr_set(stmt, C.STMT_ATTR_CURSOR_TYPE, attr))
end

function stmt.prefetch_rows(stmt)
	local attr = ffi.new'uint32_t[1]'
	stcheckz(stmt, C.mysql_stmt_attr_get(stmt, C.STMT_ATTR_PREFETCH_ROWS, attr))
	return attr[0]
end

function stmt.set_prefetch_rows(stmt, n)
	local attr = ffi.new('uint32_t[1]', n)
	stcheckz(stmt, C.mysql_stmt_attr_set(stmt, C.STMT_ATTR_PREFETCH_ROWS, attr))
end

--prepared statements / bind buffers

--see http://dev.mysql.com/doc/refman/5.7/en/c-api-prepared-statement-type-codes.html
local bb_types_input = {
	--conversion-free types
	tinyint    = ffi.C.MYSQL_TYPE_TINY,
	smallint   = ffi.C.MYSQL_TYPE_SHORT,
	int        = ffi.C.MYSQL_TYPE_LONG,
	integer    = ffi.C.MYSQL_TYPE_LONG,       --alias of int
	bigint     = ffi.C.MYSQL_TYPE_LONGLONG,
	float      = ffi.C.MYSQL_TYPE_FLOAT,
	double     = ffi.C.MYSQL_TYPE_DOUBLE,
	time       = ffi.C.MYSQL_TYPE_TIME,
	date       = ffi.C.MYSQL_TYPE_DATE,
	datetime   = ffi.C.MYSQL_TYPE_DATETIME,
	timestamp  = ffi.C.MYSQL_TYPE_TIMESTAMP,
	text       = ffi.C.MYSQL_TYPE_STRING,
	char       = ffi.C.MYSQL_TYPE_STRING,
	varchar    = ffi.C.MYSQL_TYPE_STRING,
	blob       = ffi.C.MYSQL_TYPE_BLOB,
	binary     = ffi.C.MYSQL_TYPE_BLOB,
	varbinary  = ffi.C.MYSQL_TYPE_BLOB,
	null       = ffi.C.MYSQL_TYPE_NULL,
	--conversion types (can only use one of the above C types)
	mediumint  = ffi.C.MYSQL_TYPE_LONG,
	real       = ffi.C.MYSQL_TYPE_DOUBLE,
	decimal    = ffi.C.MYSQL_TYPE_BLOB,
	numeric    = ffi.C.MYSQL_TYPE_BLOB,
	year       = ffi.C.MYSQL_TYPE_SHORT,
	tinyblob   = ffi.C.MYSQL_TYPE_BLOB,
	tinytext   = ffi.C.MYSQL_TYPE_BLOB,
	mediumblob = ffi.C.MYSQL_TYPE_BLOB,
	mediumtext = ffi.C.MYSQL_TYPE_BLOB,
	longblob   = ffi.C.MYSQL_TYPE_BLOB,
	longtext   = ffi.C.MYSQL_TYPE_BLOB,
	bit        = ffi.C.MYSQL_TYPE_LONGLONG, --MYSQL_TYPE_BIT is not available for input params
	set        = ffi.C.MYSQL_TYPE_BLOB,
	enum       = ffi.C.MYSQL_TYPE_BLOB,
}

local bb_types_output = {
	--conversion-free types
	tinyint    = ffi.C.MYSQL_TYPE_TINY,
	smallint   = ffi.C.MYSQL_TYPE_SHORT,
	mediumint  = ffi.C.MYSQL_TYPE_INT24,      --int32
	int        = ffi.C.MYSQL_TYPE_LONG,
	integer    = ffi.C.MYSQL_TYPE_LONG,       --alias of int
	bigint     = ffi.C.MYSQL_TYPE_LONGLONG,
	float      = ffi.C.MYSQL_TYPE_FLOAT,
	double     = ffi.C.MYSQL_TYPE_DOUBLE,
	real       = ffi.C.MYSQL_TYPE_DOUBLE,
	decimal    = ffi.C.MYSQL_TYPE_NEWDECIMAL, --char[]
	numeric    = ffi.C.MYSQL_TYPE_NEWDECIMAL, --char[]
	year       = ffi.C.MYSQL_TYPE_SHORT,
	time       = ffi.C.MYSQL_TYPE_TIME,
	date       = ffi.C.MYSQL_TYPE_DATE,
	datetime   = ffi.C.MYSQL_TYPE_DATETIME,
	timestamp  = ffi.C.MYSQL_TYPE_TIMESTAMP,
	char       = ffi.C.MYSQL_TYPE_STRING,
	binary     = ffi.C.MYSQL_TYPE_STRING,
	varchar    = ffi.C.MYSQL_TYPE_VAR_STRING,
	varbinary  = ffi.C.MYSQL_TYPE_VAR_STRING,
	tinyblob   = ffi.C.MYSQL_TYPE_TINY_BLOB,
	tinytext   = ffi.C.MYSQL_TYPE_TINY_BLOB,
	blob       = ffi.C.MYSQL_TYPE_BLOB,
	text       = ffi.C.MYSQL_TYPE_BLOB,
	mediumblob = ffi.C.MYSQL_TYPE_MEDIUM_BLOB,
	mediumtext = ffi.C.MYSQL_TYPE_MEDIUM_BLOB,
	longblob   = ffi.C.MYSQL_TYPE_LONG_BLOB,
	longtext   = ffi.C.MYSQL_TYPE_LONG_BLOB,
	bit        = ffi.C.MYSQL_TYPE_BIT,
	--conversion types (can only use one of the above C types)
	null       = ffi.C.MYSQL_TYPE_TINY,
	set        = ffi.C.MYSQL_TYPE_BLOB,
	enum       = ffi.C.MYSQL_TYPE_BLOB,
}

local number_types = {
	[ffi.C.MYSQL_TYPE_TINY]      = 'int8_t[1]',
	[ffi.C.MYSQL_TYPE_SHORT]     = 'int16_t[1]',
	[ffi.C.MYSQL_TYPE_LONG]      = 'int32_t[1]',
	[ffi.C.MYSQL_TYPE_INT24]     = 'int32_t[1]',
	[ffi.C.MYSQL_TYPE_LONGLONG]  = 'int64_t[1]',
	[ffi.C.MYSQL_TYPE_FLOAT]     = 'float[1]',
	[ffi.C.MYSQL_TYPE_DOUBLE]    = 'double[1]',
}

local uint_types = {
	[ffi.C.MYSQL_TYPE_TINY]      = 'uint8_t[1]',
	[ffi.C.MYSQL_TYPE_SHORT]     = 'uint16_t[1]',
	[ffi.C.MYSQL_TYPE_LONG]      = 'uint32_t[1]',
	[ffi.C.MYSQL_TYPE_INT24]     = 'uint32_t[1]',
	[ffi.C.MYSQL_TYPE_LONGLONG]  = 'uint64_t[1]',
}

local time_types = {
	[ffi.C.MYSQL_TYPE_TIME]      = true,
	[ffi.C.MYSQL_TYPE_DATE]      = true,
	[ffi.C.MYSQL_TYPE_DATETIME]  = true,
	[ffi.C.MYSQL_TYPE_TIMESTAMP] = true,
}

local time_struct_types = {
	[ffi.C.MYSQL_TYPE_TIME] = ffi.C.MYSQL_TIMESTAMP_TIME,
	[ffi.C.MYSQL_TYPE_DATE] = ffi.C.MYSQL_TIMESTAMP_DATE,
	[ffi.C.MYSQL_TYPE_DATETIME] = ffi.C.MYSQL_TIMESTAMP_DATETIME,
	[ffi.C.MYSQL_TYPE_TIMESTAMP] = ffi.C.MYSQL_TIMESTAMP_DATETIME,
}

local params = {} --params bind buffer methods
local params_meta = {__index = params}
local fields = {} --params bind buffer methods
local fields_meta = {__index = fields}

-- "varchar(200)" -> "varchar", 200; "decimal(10,4)" -> "decimal", 12; "int unsigned" -> "int", nil, true
local function parse_type(s)
	s = s:lower()
	local unsigned = false
	local rest = s:match'(.-)%s+unsigned$'
	if rest then s, unsigned = rest, true end
	local rest, sz = s:match'^%s*([^%(]+)%s*%(%s*(%d+)[^%)]*%)%s*$'
	if rest then
		s, sz = rest, assert(tonumber(sz), 'invalid type')
		if s == 'decimal' or s == 'numeric' then --make room for the dot and the minus sign
			sz = sz + 2
		end
	end
	return s, sz, unsigned
end

local function bind_buffer(bb_types, meta, types)
	local self = setmetatable({}, meta)

	self.count = #types
	self.buffer = ffi.new('MYSQL_BIND[?]', #types)
	self.data = {} --data buffers, one for each field
	self.lengths = ffi.new('unsigned long[?]', #types) --length buffers, one for each field
	self.null_flags = ffi.new('my_bool[?]', #types) --null flag buffers, one for each field
	self.error_flags = ffi.new('my_bool[?]', #types) --error (truncation) flag buffers, one for each field

	for i,typedef in ipairs(types) do
		local stype, size, unsigned = parse_type(typedef)
		local btype = assert(bb_types[stype], 'invalid type')
		local data
		if stype == 'bit' then
			if btype == C.MYSQL_TYPE_LONGLONG then --for input: use unsigned int64 and ignore size
				data = ffi.new'uint64_t[1]'
				self.buffer[i-1].is_unsigned = 1
				size = 0
			elseif btype == C.MYSQL_TYPE_BIT then --for output: use mysql conversion-free type
				size = size or 64 --if missing size, assume maximum
				size = math.ceil(size / 8)
				assert(size >= 1 and size <= 8, 'invalid size')
				data = ffi.new('uint8_t[?]', size)
			end
		elseif number_types[btype] then
			assert(not size, 'fixed size type')
			data = ffi.new(unsigned and uint_types[btype] or number_types[btype])
			self.buffer[i-1].is_unsigned = unsigned
			size = ffi.sizeof(data)
		elseif time_types[btype] then
			assert(not size, 'fixed size type')
			data = ffi.new'MYSQL_TIME'
			data.time_type = time_struct_types[btype]
			size = 0
		elseif btype == C.MYSQL_TYPE_NULL then
			assert(not size, 'fixed size type')
			size = 0
		else
			assert(size, 'missing size')
			data = size > 0 and ffi.new('uint8_t[?]', size) or nil
		end
		self.null_flags[i-1] = true
		self.data[i] = data
		self.lengths[i-1] = 0
		self.buffer[i-1].buffer_type = btype
		self.buffer[i-1].buffer = data
		self.buffer[i-1].buffer_length = size
		self.buffer[i-1].is_null = self.null_flags + (i - 1)
		self.buffer[i-1].error = self.error_flags + (i - 1)
		self.buffer[i-1].length = self.lengths + (i - 1)
	end
	return self
end

local function params_bind_buffer(types)
	return bind_buffer(bb_types_input, params_meta, types)
end

local function fields_bind_buffer(types)
	return bind_buffer(bb_types_output, fields_meta, types)
end

local function bind_check_range(self, i)
	assert(i >= 1 and i <= self.count, 'index out of bounds')
end

--realloc a buffer using supplied size. only for varsize fields.
function params:realloc(i, size)
	bind_check_range(self, i)
	assert(ffi.istype(self.data[i], 'uint8_t[?]'), 'attempt to realloc a fixed size field')
	local data = size > 0 and ffi.new('uint8_t[?]', size) or nil
	self.null_flags[i-1] = true
	self.data[i] = data
	self.lengths[i-1] = 0
	self.buffer[i-1].buffer = data
	self.buffer[i-1].buffer_length = size
end

fields.realloc = params.realloc

function fields:get_date(i)
	bind_check_range(self, i)
	local btype = tonumber(self.buffer[i-1].buffer_type)
	local date = btype == C.MYSQL_TYPE_DATE or btype == C.MYSQL_TYPE_DATETIME or btype == C.MYSQL_TYPE_TIMESTAMP
	local time = btype == C.MYSQL_TYPE_TIME or btype == C.MYSQL_TYPE_DATETIME or btype == C.MYSQL_TYPE_TIMESTAMP
	assert(date or time, 'not a date/time type')
	if self.null_flags[i-1] == 1 then return nil end
	local tm = self.data[i]
	return
		date and tm.year or nil,
		date and tm.month or nil,
		date and tm.day or nil,
		time and tm.hour or nil,
		time and tm.minute or nil,
		time and tm.second or nil,
		time and tonumber(tm.second_part) or nil
end

function params:set_date(i, year, month, day, hour, min, sec, frac)
	bind_check_range(self, i)
	local tm = self.data[i]
	local btype = tonumber(self.buffer[i-1].buffer_type)
	local date = btype == C.MYSQL_TYPE_DATE or btype == C.MYSQL_TYPE_DATETIME or btype == C.MYSQL_TYPE_TIMESTAMP
	local time = btype == C.MYSQL_TYPE_TIME or btype == C.MYSQL_TYPE_DATETIME or btype == C.MYSQL_TYPE_TIMESTAMP
	assert(date or time, 'not a date/time type')
	local tm = self.data[i]
	tm.year        = date and math.max(0, math.min(year  or 0, 9999)) or 0
	tm.month       = date and math.max(1, math.min(month or 0, 12)) or 0
	tm.day         = date and math.max(1, math.min(day   or 0, 31)) or 0
	tm.hour        = time and math.max(0, math.min(hour  or 0, 59)) or 0
	tm.minute      = time and math.max(0, math.min(min   or 0, 59)) or 0
	tm.second      = time and math.max(0, math.min(sec   or 0, 59)) or 0
	tm.second_part = time and math.max(0, math.min(frac  or 0, 999999)) or 0
	self.null_flags[i-1] = false
end

function params:set(i, v, size)
	bind_check_range(self, i)
	v = ptr(v)
	if v == nil then
		self.null_flags[i-1] = true
		return
	end
	local btype = tonumber(self.buffer[i-1].buffer_type)
	if btype == C.MYSQL_TYPE_NULL then
		error('attempt to set a null type param')
	elseif number_types[btype] then --this includes bit type which is LONGLONG
		self.data[i][0] = v
		self.null_flags[i-1] = false
	elseif time_types[btype] then
		self:set_date(i, v.year, v.month, v.day, v.hour, v.min, v.sec, v.frac)
	else --var-sized types and raw bit blobs
		size = size or #v
		local bsize = tonumber(self.buffer[i-1].buffer_length)
		assert(bsize >= size, 'string too long')
		ffi.copy(self.data[i], v, size)
		self.lengths[i-1] = size
		self.null_flags[i-1] = false
	end
end

function fields:get(i)
	bind_check_range(self, i)
	local btype = tonumber(self.buffer[i-1].buffer_type)
	if btype == C.MYSQL_TYPE_NULL or self.null_flags[i-1] == 1 then
		return nil
	end
	if number_types[btype] then
		return self.data[i][0] --ffi converts this to a number or int64 type, which maches result:fetch() decoding
	elseif time_types[btype] then
		local t = self.data[i]
		if t.time_type == C.MYSQL_TIMESTAMP_TIME then
			return datetime{hour = t.hour, min = t.minute, sec = t.second, frac = tonumber(t.second_part)}
		elseif t.time_type == C.MYSQL_TIMESTAMP_DATE then
			return datetime{year = t.year, month = t.month, day = t.day}
		elseif t.time_type == C.MYSQL_TIMESTAMP_DATETIME then
			return datetime{year = t.year, month = t.month, day = t.day,
								hour = t.hour, min = t.minute, sec = t.second, frac = tonumber(t.second_part)}
		else
			error'invalid time'
		end
	else
		local sz = math.min(tonumber(self.buffer[i-1].buffer_length), tonumber(self.lengths[i-1]))
		if btype == C.MYSQL_TYPE_BIT then
			return parse_bit(self.data[i], sz)
		else
			return ffi.string(self.data[i], sz)
		end
	end
end

function fields:is_null(i) --returns true if the field is null
	bind_check_range(self, i)
	local btype = self.buffer[i-1].buffer_type
	return btype == C.MYSQL_TYPE_NULL or self.null_flags[i-1] == 1
end

function fields:is_truncated(i) --returns true if the field value was truncated
	bind_check_range(self, i)
	return self.error_flags[i-1] == 1
end

local varsize_types = {
	char       = true,
	binary     = true,
	varchar    = true,
	varbinary  = true,
	tinyblob   = true,
	tinytext   = true,
	blob       = true,
	text       = true,
	mediumblob = true,
	mediumtext = true,
	longblob   = true,
	longtext   = true,
	bit        = true,
	set        = true,
	enum       = true,
}

function stmt.bind_result_types(stmt, maxsize)
	local types = {}
	local field_count = stmt:field_count()
	local res = stmt:result_metadata()
	if not res then return nil end
	for i=1,field_count do
		local ftype, size, unsigned, decimals = res:field_type(i)
		if ftype == 'decimal' then
			ftype = string.format('%s(%d,%d)', ftype, size-2, decimals)
		elseif varsize_types[ftype] then
			size = math.min(size, maxsize or 65535)
			ftype = string.format('%s(%d)', ftype, size)
		end
		ftype = unsigned and ftype..' unsigned' or ftype
		types[i] = ftype
	end
	res:free()
	return types
end

function stmt.bind_params(stmt, ...)
	local types = type((...)) == 'string' and {...} or ... or {}
	assert(stmt:param_count() == #types, 'wrong number of param types')
	local bb = params_bind_buffer(types)
	stcheckz(stmt, C.mysql_stmt_bind_param(stmt, bb.buffer))
	return bb
end

function stmt.bind_result(stmt, arg1, ...)
	local types
	if type(arg1) == 'string' then
		types = {arg1, ...}
	elseif type(arg1) == 'number' then
		types = stmt:bind_result_types(arg1)
	elseif arg1 then
		types = arg1
	else
		types = stmt:bind_result_types()
	end
	assert(stmt:field_count() == #types, 'wrong number of field types')
	local bb = fields_bind_buffer(types)
	stcheckz(stmt, C.mysql_stmt_bind_result(stmt, bb.buffer))
	return bb
end

--publish methods

ffi.metatype('MYSQL', {__index = conn})
ffi.metatype('MYSQL_RES', {__index = res})
ffi.metatype('MYSQL_STMT', {__index = stmt})

--publish classes (for introspection, not extending)

M.conn = conn
M.res = res
M.stmt = stmt
M.params = params
M.fields = fields

return M
