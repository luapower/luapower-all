
--ffi binding for Firebird's client library. Supports Firebird 2.5.

--Based on firebird's latest ibase.h with the help of the Interbase 6 API Guide.
--NOTE: all connections involved in a multi-database transaction should run on the same OS thread.
--NOTE: avoid sharing a connection between two threads, although fbclient itself is thread-safe from v2.5 on.
--TODO: tie attachments to gc? how about transactions, statements, blobs handles? (make ref. tables weak then?)
--TODO: info API or at least some re-wrapping
--TODO: salvage any tests?
--[=[

fbclient.caller() -> caller

fbclient.connect(db, [user], [pass], [charset]) -> conn
fbclient.connect(options_t) -> conn; options_t: role, client_library, dpb

fbclient.create_db(db, [user], [pass], [charset], [db_charset], [page_size]) -> conn
fbclient.create_db_sql(sql[, client_library]) -> conn

conn:clone() -> conn
conn:close()

conn:drop_db()
conn:cancel_operation()
conn:version_info()

fbclient.start_transaction({[conn] = true | options_t, ..}; options_t: access, isolation, lock_timeout, tpb
conn:start_transaction([access], [isolation], [lock_timeout]) -> tran
conn:start_transaction(options_t) -> tran; options_t: access, isolation, lock_timeout, tpb
conn:start_transaction_sql(sql) -> tran

tran:commit()
tran:rollback()
tran:commit_retaining()
tran:rollback_retaining()

tran:exec_immediate(sql[, conn])

conn:commit_all()
conn:rollback_all()

tran:prepare(sql[, conn]) -> stmt
stmt:set_cursor_name(name)
stmt:run()
stmt:fetch()
stmt:close()
stmt:type() -> s

stmt:close_all_blobs()
stmt:close_cursor()
conn:close_all_statements()
tran:close_all_statements()

--sugar

stmt.fields[i]
stmt.fields.<name>
stmt.params[i]
stmt.params.<name>
	:get() -> v
	:set(v)

stmt.params:get(i|name)
stmt.params:set(i|name, v)
stmt.fields:get(i|name)
stmt.fields:set(i|name, v)

stmt:setparams(p1,...) -> stmt
stmt:values() -> v1,...
stmt:values(f1,...) -> v1,...
stmt:row() -> {name1 = v1, ...}

stmt:exec(p1,...) -> iter() -> v1, ...
tran:exec_on(conn, sql, p1,...) -> iter() -> v1, ...
tran:exec(sql, ...) -> iter() -> v1, ...

conn:exec(sql, ...)
conn:exec_immediate(sql)


]=]

local ffi = require'ffi'
require'fbclient_h'
local glue = require'glue'
local dpb_encode = require'fbclient_dpb'
local tpb_encode = require'fbclient_tpb'

local fbclient = {}

--helpers

local function count(t, limit) --count the elements in t optionally upto some limit
	local n = 0
	for _ in pairs(t) do
		n = n + 1
		if n == limit then break end
	end
	return n
end

local function deepcopy(t) --deepcopy table t without cycle detection
	local dt = {}
	for k,v in pairs(t) do
		dt[k] = type(t) == 'table' and deepcopy(v) or v
	end
	return dt
end

--caller object through which to make error-handled calls to fbclient

function fbclient.caller(client_library)
	client_library = client_library or 'fbclient'
	local C = ffi.load(client_library)

	local sv  = ffi.new'ISC_STATUS[20]' --status vector, required by most firebird calls
	local psv = ffi.new('ISC_STATUS*[1]', ffi.cast('ISC_STATUS*', sv)) --pointer to it
	local msgsize = 2048
	local msg = ffi.new('uint8_t[?]', msgsize) --message buffer, for error reporting

	local function status()
		return not (sv[0] == 1 and sv[1] ~= 0), sv[1]
	end

	local function errcode() --'isc_io_error'
		local ok, err = status()
		if ok then return end
		local errcodes = require'fbclient_errcodes'
		return errcodes[err]
	end

	local function errors() --{'msg1', 'msg2'}
		if status() then return end
		local errlist = {}
		while C.fb_interpret(msg, msgsize, ffi.cast('const ISC_STATUS**', psv)) ~= 0 do
			errlist[#errlist+1] = ffi.string(msg)
		end
		return errlist
	end

	local function sqlcode() --n
		if status() then return end
		return C.isc_sqlcode(sv)
	end

	local function sqlstate() --'00000'
		if status() then return end
		C.fb_sqlstate(msg, sv)
		return ffi.string(msg, 5)
	end

	local function sqlerror(sqlcode) --'message'
		C.isc_sql_interprete(sqlcode, msg, msgsize)
		return ffi.string(msg)
	end

	local function pcall(fname, ...)
		local ret = C[fname](sv, ...)
		local ok, err = status()
		if ok then return true, ret end
		return false, err
	end

	local function call(fname, ...)
		local ok, err = pcall(fname, ...)
		if ok then return err end
		local errlist = table.concat(errors(), '\n')
		error(string.format('%s() error: %s\n%s', fname, err, errlist))
	end

	local function ib_version() --returns major, minor
		return
			C.isc_get_client_major_version(),
			C.isc_get_client_minor_version()
	end

	return {
		client_library = client_library,
		C = C,
		--error-handled API callers
		pcall = pcall,
		call = call,
		--error reporting API
		status = status,
		sqlcode = sqlcode,
		sqlstate = sqlstate,
		sqlerror = sqlerror,
		errors = errors,
		--client library info API
		ib_version,
	}
end

--connections

local conn = {}
local conn_meta = {__index = conn}

local function attach(client_library, attach_function, sql, db, dpb)
	--caller object
	local caller = fbclient.caller(client_library)

	--connection handle
	local dbh = ffi.new'isc_db_handle[1]'
	if sql then
		caller.call(attach_function, dbh, nil, #sql, sql, 3, nil)
	else
		local dpb_s = dpb_encode(dpb)
		caller.call(attach_function, #db, db, dbh, dpb_s and #dpb_s or 0, dpb_s)
	end

	--connection object
	local cn = setmetatable({}, conn_meta)
	cn.dbh = dbh
	cn.caller = caller
	cn.call = caller.call
	cn.spool_limit = 0   --fb 2.5+ only: enable recycling of statement handles
	cn.spool = {}        --statement handle pool to reuse statement objects
	cn.transactions = {} --keep track of transactions spanning this connection
	cn.statements = {}   --keep track of statements made against this connection
	if db then
		cn.db = db --for cloning
		cn.dpb = glue.update({}, dpb) --for cloning
		cn.clonable = true
	end
	return cn
end

local function attach_args(create, t, ...)
	local db, user, pass, charset --common args, available as both positional args and explicit table args
	local db_charset, page_size --additional common args available for db creation only
	local role, client_library, user_dpb --special args, only available as named args
	assert(t, 'invalid arguments')
	if type(t) == 'string' then
		db, user, pass, charset, db_charset, page_size = t, ...
	else
		db, user, pass, charset, db_charset, page_size = t.db, t.user, t.pass, t.charset, t.db_charset, t.page_size
		role, client_library, user_dpb = t.role, t.client_library, t.dpb
	end
	local dpb = {}
	dpb.isc_dpb_user_name = user
	dpb.isc_dpb_password = pass
	dpb.isc_dpb_lc_ctype = charset
	dpb.isc_dpb_sql_role_name = role
	if create then
		dpb.isc_dpb_set_db_charset = db_charset
		dpb.isc_dpb_page_size = page_size
	end
	glue.merge(dpb, user_dpb) --user's dpb shouldn't overwrite explicit args
	if create and not dpb.isc_dpb_sql_dialect then
		dpb.isc_dpb_sql_dialect = 3
	end
	return client_library, db, dpb
end

function fbclient.connect(...)
	local client_library, db, dpb = attach_args(nil, ...)
	return attach(client_library, 'isc_attach_database', nil, db, dpb)
end

function fbclient.create_db(...)
	local client_library, db, dpb = attach_args(true, ...)
	return attach(client_library, 'isc_create_database', nil, db, dpb)
end

function fbclient.create_db_sql(sql, client_library) --CREATE DATABASE statement
	return attach(client_library, 'isc_dsql_execute_immediate', sql, nil, nil)
end

--create a new connection using the same arguments those of a running connection
function conn:clone()
	assert(self.clonable, 'not clonable')
	local dpb = deepcopy(self.dpb)
	return attach(self.caller.client_library, 'isc_attach_database', nil, self.db, dpb)
end

function conn:close()
	self:rollback_all()
	self.call('isc_detach_database', self.dbh)
end

function conn:drop_db()
	self:rollback_all()
	self.call('isc_drop_database', self.dbh)
end

local fb_cancel_operation_codes = {
	disable = 1, --disable any pending fb_cancel_raise
	enable  = 2, --enable any pending fb_cancel_raise
	raise   = 3, --cancel any request on db_handle ASAP (at the next rescheduling point) and return an error.
	abort   = 4,
}

--NOTE: don't call this from the main thread (where the signal handler is registered).
function conn:cancel_operation(opt)
	opt = glue.assert(fb_cancel_operation_codes[opt or 'fb_cancel_raise'], 'invalid option %s', opt)
	self.call('fb_cancel_operation', self.dbh, opt)
end

function conn:version_info()
	local ver={}
	local function helper(p, s)
		ver[#ver+1] = ffi.string(s)
	end
	assert(self.caller.C.isc_version(self.dbh, helper, nil) == 0, 'isc_version() error')
	return ver
end

--transactions

local tran = {}
local tran_meta = {__index = tran}

local function wrap_tran(trh, call, connections) --wrap a transaction handle into a tran object
	local tr = setmetatable({}, tran_meta)
	tr.trh = trh
	tr.call = call
	tr.connections = connections
	tr.statements = {} --keep track of statements made on this transaction
	local n = 0
	for conn in pairs(connections) do --register transaction to all connections
		conn.transactions[tr] = true
		n = n + 1
	end
	if n == 1 then
		tr.conn = next(connections)
	end
	return tr
end

--start a transaction spawning multiple connections using a table {[conn] = true | tpb_t, ...}.
--tpb_t defaults to {isc_tpb_write = true, isc_tpb_concurrency = true, isc_tpb_wait = true}.
local function start_tran(t)
	local n = count(t)
	assert(n > 0, 'no connections')
	local teb = ffi.new('ISC_TEB[?]', n)
	local pin = {} --pin tpb strings to prevent garbage collecting
	local connections = {}
	local i = 0
	for conn, tpb in pairs(t) do
		local tpb_s = tpb_encode(tpb ~= true and tpb or nil)
		teb[i].teb_database = conn.dbh
		teb[i].teb_tpb_length = tpb_s and #tpb_s or 0
		teb[i].teb_tpb = tpb_s
		pin[tpb_s] = true
		connections[conn] = true
		i = i + 1
	end
	local call = next(t).call --any caller would do
	local trh = ffi.new'isc_tr_handle[1]'
	call('isc_start_multiple', trh, n, teb)
	return wrap_tran(trh, call, connections)
end

local function tran_args(t, ...)
	if not t then return true end --tran args are optional
	local access, isolation, lock_timeout --common args, available as both positional args and explicit table args
	local user_tpb --special needs args, only available as table args
	if type(t) == 'string' then
		access, isolation, lock_timeout = t, ...
	else
		access, isolation, lock_timeout, user_tpb = t.access, t.isolation, t.lock_timeout, t.tpb
	end
	local tpb = {}
	glue.assert(not access or access == 'read' or access == 'write', 'invalid argument')
	glue.assert(not isolation
					or isolation == 'consistency'
					or isolation == 'concurrency'
					or isolation == 'read commited'
					or isolation == 'read commited no record version', 'invalid argument')
	tpb.isc_tpb_read = access == 'read' or nil
	tpb.isc_tpb_write = access == 'write' or nil
	tpb.isc_tpb_consistency = isolation == 'consistency' or nil
	tpb.isc_tpb_concurrency = isolation == 'concurrency' or nil
	tpb.isc_tpb_read_committed = isolation == 'read commited' or isolation == 'read commited no record version' or nil
	tpb.isc_tpb_rec_version = isolation == 'read commited' or nil
	tpb.isc_tpb_wait = lock_timeout and lock_timeout > 0 or nil
	tpb.isc_tpb_nowait = lock_timeout == 0 or nil
	tpb.isc_tpb_lock_timeout = lock_timeout and lock_timeout > 0 and lock_timeout or nil
	glue.merge(tpb, user_tpb)
	return tpb
end

function fbclient.start_transaction(t)
	local dt = {}
	for conn, opt in pairs(t) do
		dt[conn] = tran_args(opt)
	end
	return start_tran(dt)
end

function conn:start_transaction(...)
	return start_tran({[self] = tran_args(...)})
end

function conn:start_transaction_sql(sql) --SET TRANSACTION statement
	local trh = ffi.new'isc_tr_handle[1]'
	self.call('isc_dsql_execute_immediate', self.dbh, trh, #sql, sql, 3, nil)
	return wrap_tran(trh, self.call, {[self] = true})
end

local function tran_close(self, close_function)
	self:close_all_statements()
	self.call(close_function, self.trh)
	for conn in pairs(self.connections) do
		conn.transactions[self] = nil
		self.connections[conn] = nil
	end
end

function tran:commit()
	tran_close(self, 'isc_commit_transaction')
end

function tran:rollback()
	tran_close(self, 'isc_rollback_transaction')
end

function tran:commit_retaining()
	self.call('isc_commit_retaining', self.trh)
end

function tran:rollback_retaining()
	self.call('isc_rollback_retaining', self.trh)
end

local function check_conn(tr, conn)
	if conn then
		assert(tr.connections[conn], 'invalid connection')
		return conn
	else
		assert(tr.conn, 'connection required')
		return tr.conn
	end
end

function tran:exec_immediate(sql, conn)
	conn = check_conn(self, conn)
	self.call('isc_dsql_execute_immediate', conn.dbh, self.trh, #sql, sql, 3, nil)
end

function conn:commit_all()
	for tran in pairs(self.transactions) do
		tran:commit()
	end
end

function conn:rollback_all()
	for tran in pairs(self.transactions) do
		tran:rollback()
	end
end

--statements

local sqltype_names = glue.index{
	SQL_TEXT        = 452,
	SQL_VARYING     = 448,
	SQL_SHORT       = 500,
	SQL_LONG        = 496,
	SQL_FLOAT       = 482,
	SQL_DOUBLE      = 480,
	SQL_D_FLOAT     = 530,
	SQL_TIMESTAMP   = 510,
	SQL_BLOB        = 520,
	SQL_ARRAY       = 540,
	SQL_QUAD        = 550,
	SQL_TYPE_TIME   = 560,
	SQL_TYPE_DATE   = 570,
	SQL_INT64       = 580,
	SQL_NULL        = 32766, --Firebird 2.5+
}

local sqlsubtype_names = glue.index{ --isc_blob_*
	untyped    = 0,
	text       = 1,
	blr        = 2,
	acl        = 3,
	ranges     = 4,
	summary    = 5,
	format     = 6,
	tra        = 7,
	extfile    = 8,
	debug_info = 9,
}

--computes buflen for a certain sqltype,sqllen pair.
local function sqldata_buflen(sqltype, sqllen)
	if sqltype == 'SQL_VARYING' then
		return sqllen + SHORT_SIZE
	elseif sqltype == 'SQL_NULL' then
		return 0
	else
		return sqllen
	end
end

--this does three things:
--1) allocate SQLDA/SQLIND buffers accoding to sqltype and setup the XSQLVAR to point to them.
--2) decode the info from XSQLVAR.
--3) return a table with the info and the data buffers pinned to it.
local function XSQLVAR(x)
	--allow_null tells us if the column allows null values, and so an sqlind buffer is needed
	--to receive the null flag. thing is however that you can have null values on a not-null
	--column under some circumstances, so we're always allocating an sqlind buffer.
	local allow_null = x.sqltype % 2 == 1 --this flag is kept in bit 1
	local sqltype_code = x.sqltype - (allow_null and 1 or 0)
	local sqltype = assert(sqltype_names[sqltype_code])
	local subtype = sqltype == 'SQL_BLOB' and assert(sqlsubtype_names[x.sqlsubtype]) or nil
	local sqlname = x.sqlname_length > 0 and ffi.string(x.sqlname, x.sqlname_length) or nil
	local relname = x.relname_length > 0 and ffi.string(x.relname, x.relname_length) or nil
	local ownname = x.ownname_length > 0 and ffi.string(x.ownname, x.ownname_length) or nil
	local aliasname = x.aliasname_length > 0 and ffi.string(x.aliasname, x.aliasname_length) or nil
	local buflen = sqldata_buflen(sqltype, x.sqllen)
	local sqldata_buf = buflen > 0 and ffi.new('uint8_t[?]', buflen) or nil
	local sqlind_buf = ffi.new('int16_t[1]', -1)
	x.sqldata = sqldata_buf
	x.sqlind = sqlind_buf
	--set the allow_null bit, otherwise the server won't touch the sqlind buffer on columns that have the bit clear.
	x.sqltype = sqltype_code + 1
	local xs = {
		sqltype = sqltype,         --how is SQLDATA encoded
		sqlscale = x.sqlscale,     --for number types
		sqllen = x.sqllen,         --max. size of the *contents* of the SQLDATA buffer
		buflen = buflen,           --size of the SQLDATA buffer
		subtype = subtype,         --blob encoding
		allow_null = allow_null,   --should we allow nulls?
		sqldata_buf = sqldata_buf, --pinned SQLDATA buffer
		sqlind_buf = sqlind_buf,   --pinned SQLIND buffer
		col_name = sqlname,        --underlying column name
		table = relname,           --table name
		owner = ownname,           --table owner's name
		name = aliasname,          --alias name
	}
	return xs
end

local function alloc_xsqlvars(x) --alloc data buffers for each column, based on XSQLVAR descriptions
	local alloc, used = x.sqln, x.sqld
	assert(alloc >= used)
	local t = {}
	for i=1,used do
		local xs = XSQLVAR(x.sqlvar[i-1])
		xs.index = i
		t[i] = xs
		if xs.name then
			t[xs.name] = xs
		end
	end
	return t
end

local function XSQLDA(xsqlvar_count) --alloc a new xsqlda object
	local x = ffi.new('XSQLDA', xsqlvar_count)
	ffi.fill(x, ffi.sizeof(x)) --ffi doesn't clear the trailing VLA part of a VLS
	x.version = 1
	x.sqln = xsqlvar_count
	return x
end

local stmt = {} --statement methods
local stmt_meta = {__index = stmt}

function tran:prepare(sql, conn)
	conn = check_conn(self, conn)

	--grab a handle from the statement handle pool of the connection, or make a new one.
	local sth = next(conn.spool)
	if sth then
		conn.spool[sth] = nil
	else
		sth = ffi.new'isc_stmt_handle[1]'
		--using isc_dsql_alloc_statement2 deallocates the statement automatically when connection closes.
		self.call('isc_dsql_alloc_statement2', conn.dbh, sth)
	end

	--alloc the XSQLDA for getting fields.
	local xfields = XSQLDA(20) --one xsqlvar is 152 bytes

	--prepare statement, which gets us the number of output columns.
	self.call('isc_dsql_prepare', self.trh, sth, #sql, sql, 3, xfields)

	--see if xfields is long enough to keep all fields, and if not, reallocate and re-describe.
	local alloc, used = xfields.sqln, xfields.sqld
	if alloc < used then
		xfields = XSQLDA(used)
		self.call('isc_dsql_describe', sth, 1, xfields)
	end

	--alloc the XSQLDA for setting params.
	local xparams = XSQLDA(6)
	self.call('isc_dsql_describe_bind', sth, 1, xparams)

	--see if xparams is long enough to keep all params, and if not, reallocate and re-describe.
	local alloc, used = xparams.sqln, xparams.sqld
	if alloc < used then
		xparams = XSQLDA(used)
		self.call('isc_dsql_describe_bind', sth, 1, xparams)
	end

	--alloc xsqlvar buffers based on XSQLDA descriptions
	local fields = alloc_xsqlvars(xfields)
	local params = alloc_xsqlvars(xparams)

	--statement object
	local st = setmetatable({}, stmt_meta)
	st.sth = sth
	st.call = self.call
	st.fields_xsqlda = xfields
	st.params_xsqlda = xparams
	st.fields = fields
	st.params = params

	--register statement to transaction and to connection objects
	conn.statements[st] = true
	self.statements[st] = true
	st.tran = self
	st.conn = conn

	--make and record the decision on how the statement should be executed and results be fetched.
	--NOTE: there's no official way to do this, I just did what made sense, it may be wrong.
	st.expect_output = #st.fields > 0
	st.expect_cursor = false
	if st.expect_output then
		local sttype = st:type()
		st.expect_cursor = sttype == 'select' or sttype == 'select for update'
	end

	return st
end

function stmt:set_cursor_name(cursor_name) --call it on a prepared statement
	self.self.call('isc_dsql_set_cursor_name', self.sth, cursor_name, 0)
end

function stmt:run()
	self:close_all_blobs()
	self:close_cursor()
	if self.expect_output and not self.expect_cursor then
		self.call('isc_dsql_execute2', self.tran.trh, self.sth, 1, self.fields_xsqlda, self.params_xsqlda)
		self.already_fetched = true
	else
		self.call('isc_dsql_execute', self.tran.trh, self.sth, 1, self.params_xsqlda)
		self.cursor_open = self.expect_cursor
	end
	return self
end

function stmt:fetch()
	self:close_all_blobs()
	local fetched = self.already_fetched or false
	if fetched then
		self.already_fetched = nil
	elseif self.cursor_open then
		local status = self.call('isc_dsql_fetch', self.sth, 1, self.fields_xsqlda)
		assert(status == 0 or status == 100, 'isc_dsql_fetch() error')
		fetched = status == 0
		if not fetched then
			self:close_cursor()
		end
	end
	return fetched
end

function stmt:close_all_blobs()
	--TODO
end

function stmt:close_cursor()
	if self.cursor_open then
		self.call('isc_dsql_free_statement', self.sth, 1) --close
		self.cursor_open = nil
	end
end

function stmt:close()
	self:close_all_blobs()
	self:close_cursor()

	--try unpreparing the statement handle instead of freeing it, and drop it into the handle pool.
	if count(self.conn.spool, self.conn.spool_limit) < self.conn.spool_limit then
		self.call('isc_dsql_free_statement', self.sth, 4) --unprepare
		self.conn.spool[self.sth] = true
	else
		self.call('isc_dsql_free_statement', self.sth, 2) --free
	end

	--unregister from tran and conn
	self.conn.statements[self] = nil
	self.tran.statements[self] = nil
end

local stmt_codes = {'select', 'insert', 'update', 'delete', 'ddl', 'get segment', 'put segment', 'execute procedure',
							'start transaction', 'commit', 'rollback', 'select for update', 'set generator', 'savepoint'}

function stmt:type()
	local isc_info_end = 1
	local isc_info_sql_stmt_type = 21
	local opts = string.char(isc_info_sql_stmt_type)
	--info_code + body_length (16bit little endian) + max. 4 body entries + isc_info_end
	local buf = ffi.new('uint8_t[?]', 8)
	self.call('isc_dsql_sql_info', self.sth, #opts, opts, ffi.sizeof(buf), buf)
	local info_code, szlo, szhi, stype = buf[0], buf[1], buf[2], buf[3]
	assert(info_code == isc_info_sql_stmt_type, 'invalid response')
	local sz = szlo + szhi * 256
	assert(sz >= 1 and sz <= 4, 'invalid response')
	assert(buf[3 + sz] == isc_info_end)
	return assert(stmt_codes[stype], 'unknown statement type')
end

function conn:close_all_statements()
	for stmt in pairs(self.statements) do
		stmt:close()
	end
end

function tran:close_all_statements()
	for stmt in pairs(self.statements) do
		stmt:close()
	end
end

--hi-level API

function stmt:setparams(...)
	for i,p in ipairs(self.params) do
		p:set(select(i,...))
	end
	return self
end

function stmt:values(...) -- name,descr = st:values('name', 'descr')
	if not ... then
		local t = {}
		for i,col in ipairs(self.fields) do
			t[i] = col:get()
		end
		return unpack(t,1,#self.fields)
	else
		local t,n = {},select('#',...)
		for i=1,n do
			t[i] = self.fields[select(i,...)]:get()
		end
		return unpack(t,1,n)
	end
end

function stmt:row()
	local t = {}
	for i,col in ipairs(self.fields) do
		local name = col.name
		glue.assert(name, 'column %d does not have a name', i)
		local val = col:get()
		t[name] = val
	end
	return t
end

local function statement_exec_iter(st, i)
	if st:fetch() then
		return i+1, st:values()
	end
end

function stmt:exec(...)
	self:setparams(...)
	self:run()
	return statement_exec_iter, self, 0
end

local function transaction_exec_iter(st)
	if st:fetch() then
		return st, st:values()
	else
		st:close()
	end
end

local function null_iter() end

function tran:exec_on(conn, sql, ...)
	local st = self:prepare(sql, conn)
	st:setparams(...)
	st:run()
	if st.expect_output then
		return transaction_exec_iter, st
	else
		st:close()
		return null_iter
	end
end

function tran:exec(sql, ...)
	return self:exec_on(next(self.connections), sql, ...)
end

local function conn_exec_iter(st)
	if st:fetch() then
		return st, st:values()
	else
		st.transaction:commit() --commit() closes all statements automatically
	end
end

--ATTN: if you break the iteration before fetching all the result rows the
--transaction, statement and fetch cursor all remain open until you close the connection!
function conn:exec(sql, ...)
	local tr = self:start_transaction()
	local st = tr:prepare(sql, self)
	st:setparams(...)
	st:run()
	if st.expect_output then
		return conn_exec_iter, st
	else
		st.transaction:commit()
	end
end

function conn:exec_immediate(sql)
	local tr = self:start_transaction()
	tr:exec_immediate(sql, self)
	tr:commit()
end

--info API

function conn:info(opts, info_buf_len)
	local info = require'fbclient_info_db'
	local opts, max_len = info.encode(opts)
	info_buf_len = math.min(MAX_SHORT, info_buf_len or max_len)
	local info_buf = alien.buffer(info_buf_len)
	self.call('isc_database_info', dbh, #opts, opts, info_buf_len, info_buf)
	return info.decode(info_buf, info_buf_len, fbapi)
end

function tran:info(opts, info_buf_len)
	local info = require 'fbclient.tr_info'
	local opts, max_len = info.encode(opts)
	info_buf_len = math.min(MAX_SHORT, info_buf_len or max_len)
	local info_buf = alien.buffer(info_buf_len)
	self.call('isc_transaction_info', trh, #opts, opts, info_buf_len, info_buf)
	return info.decode(info_buf, info_buf_len)
end

function stmt:info(opts, info_buf_len)
	local info = require'fbclient_sqlinfo'
	local opts, max_len = info.encode(opts)
	info_buf_len = math.min(MAX_SHORT, info_buf_len or max_len)
	local info_buf = alien.buffer(info_buf_len)
	self.call('isc_dsql_sql_info', sth, #opts, opts, info_buf_len, info_buf)
	return info.decode(info_buf, info_buf_len)
end




if not ... then

local fb = fbclient
local cn = fb.connect('localhost:x:/work/fbclient/lua/fbclient/gazolin.fdb', 'SYSDBA', 'masterkey')
--pp(cn:version_info())
local tr1 = cn:start_transaction('read')
--pp(tr1)
local tr2 = cn:start_transaction_sql'SET TRANSACTION'
tr1:exec('select * from rdb$database')
local st = tr2:prepare('select * from rdb$database')
--pp(st)
for i, field in ipairs(st.fields) do
	print(i, field.sqltype, field.name)
end
for st, v1, v2 in st:exec() do
	print(v1, v2)
end
st:close()
cn:close()


end


return glue.autoload(fbclient, {
	connect_service = 'fbclient_service',
})

