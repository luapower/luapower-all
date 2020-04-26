--[==[

	webb | mysql query function
	Written by Cosmin Apreutesei. Public Domain.

QUERY

	quote_sql(s) -> s                         quote string to mysql literal
	quote_sqlname(s) -> s                     quote string to mysql identifier
	quote_sqlparams(s, t) -> s                quote query with ? and :name placeholders.
	print_queries([t|f]) -> t|f               control printing of queries
	trace_queries(t|f) -> s                   start/stop tracing of SQL statements
	query(s, args...) -> res                  query and return result table
	query1(s, args...) -> t                   query and return first row
	iquery(s, args...) -> id                  query and return insert id
	changed(res) -> t|f                       check if any rows were updated
	atomic(func)                              execute func in transaction
	groupby(res, col) -> t                    group rows by a column

QUERY/DDL

	qsubst(typedef)                           create a substitution definition
	qmacro.<name> = f(args...)                create a macro definition

	dropfk(name)                              drop foreign key
	droptable([t|f]) -> t|f                   check/enable droptable()
	droptable(name)                           drop table
	fk(tbl, col, ...)                         create a foreign key

]==]

require'webb'
local mysql = require'webb_mysql'
local errors = require'errors'

--db connection --------------------------------------------------------------

local function assert_db(ret, ...)
	if ret ~= nil then return ret, ... end
	local err, errno, sqlstate = ...
	raise('db', {err = err, errno = errno, sqlstate = sqlstate},
		'db error: %s: %s %s', err, errno, sqlstate)
end

local function pconfig(ns, k, default)
	if ns then
		return config(ns..'_'..k, config(k, default))
	else
		return config(k, default)
	end
end

local dbs = {} --connected db objects

local function connect(ns)
	local db = dbs[ns]
	if not db then
		db = assert(mysql:new())
		db:set_timeout(pconfig(ns, 'db_conn_timeout', 3) * 1000)
		assert_db(db:connect{
			host     = pconfig(ns, 'db_host', '127.0.0.1'),
			port     = pconfig(ns, 'db_port', 3306),
			database = pconfig(ns, 'db_name'),
			user     = pconfig(ns, 'db_user', 'root'),
			password = pconfig(ns, 'db_pass'),
		})
		db:set_timeout(pconfig(ns, 'db_query_timeout', 30) * 1000)
		dbs[ns] = db
	end
	return db
end

--macro substitution ---------------------------------------------------------

local substs = {}

function qsubst(def) --'name type'
	local name, val = def:match'([%w_]+)%s+(.*)'
	substs[name] = val
end

qmacro = {}

local function macro_subst(name, args)
	local macro = assert(qmacro[name], 'invalid macro')
	args = args:sub(2,-2)..','
	local t = {}
	for arg in args:gmatch'([^,]+)' do
		arg = glue.trim(arg)
		t[#t+1] = arg
	end
	return macro(unpack(t))
end

local function preprocess(sql)
	sql = sql:gsub('%-%-[^\r\n]*', '') --remove comments
	sql = sql:gsub('$([%w_]+)(%b())', macro_subst)
	sql = sql:gsub('$([%w_]+)', substs)
	return sql
end

--arg substitution -----------------------------------------------------------

sql_default = {}

function quote_sql(v)
	if v == nil or v == null then
		return 'null'
	elseif v == true then
		return 1
	elseif v == false then
		return 0
	elseif v == sql_default then
		return 'default'
	elseif type(v) == 'string' then
		return ngx.quote_sql_str(v)
	elseif type(v) == 'number' then
		if v ~= v or v == 1/0 or v == -1/0 then
			return 'null' --avoid syntax error for what ends up as null anyway.
		else
			return format('%0.17g', v) --max precision, min. length.
		end
	else
		return nil, 'invalid value '.. pp.format(v)
	end
end
quote = quote_sql --TODO: remove this (conflicts with terra)

function quote_sqlname(v)
	assert(not v:find('`', 1, true))
	return '`'..v..'`'
end

local function quote_named_params(sql, t)
	local names = {}
	local sql = sql:gsub(':([%w_:]+)', function(k)
		add(names, k)
		local v, err = quote_sql(t[k])
		return assertf(v, 'param %s: %s\n%s', k, err, sql)
	end)
	return sql, names
end

local function quote_indexed_params(sql, t)
	local i = 0
	return (sql:gsub('%?', function()
		i = i + 1
		local v, err = quote_sql(t[i])
		return assertf(v, 'param %d: %s\n%s', i, err, sql)
	end))
end

function quote_sqlparams(sql, ...)
	local param_values = type((...)) ~= 'table' and {...} or ...
	local sql = quote_indexed_params(sql, param_values)
	return quote_named_params(sql, param_values)
end

--query execution ------------------------------------------------------------

function print_queries(on)
	if on ~= nil then
		ngx.ctx.print_queries = on
	else
		return ngx.ctx.print_queries or false
	end
end

local log_sql do
	local sql_log, sql_log_t0
	function trace_queries(on)
		if on == nil then
			return sql_log and true or false
		elseif on then
			sql_log = {}
			sql_log_t0 = time()
		else
			local t = sql_log
			sql_log = nil
			return t
		end
	end
	function log_sql(sql)
		local t = time()
		add(sql_log, _('%.2f %s', t - sql_log_t0, sql))
		sql_log_t0 = t
	end
end

local function outdent(s)
	local indent = s:match'^[\t%s]+'
	if not indent then return s end
	local t = {}
	for s in s:lines() do
		local indent1 = s:sub(1, #indent)
		if indent1 ~= indent then
			goto fail
		end
		table.insert(t, s:sub(#indent + 1))
	end
	do return table.concat(t, '\n') end
	::fail::
	return s
end

local function process_result(t, cols)
	if cols and #cols == 1 then --single column result: return it as array
		local t0 = t
		local name = cols[1].name
		t = {}
		for i,row in ipairs(t0) do
			t[i] = row[name]
		end
	end
	return t
end

local function run_query_on(ns, compact, sql, ...)
	local db = connect(ns or false)
	local sql = preprocess(sql)
	local sql, params = quote_sqlparams(sql, ...)
	if print_queries() then
		print(outdent(sql))
	end
	if trace_queries() then
		log_sql(outdent(sql))
	end
	assert_db(db:send_query(sql))
	local old_compact = db.compact
	db.compact = compact
	local t, err, cols = assert_db(db:read_result())
	db.compact = old_compact
	t = process_result(t, cols)
	if err == 'again' then --multi-result/multi-statement query
		t = {t}
		repeat
			local t1, err = assert_db(db:read_result())
			t1 = process_result(t1, cols)
			t[#t+1] = t1
		until not err
	end
	return t, cols, params
end

function query_on(ns, ...) --execute, iterate rows, close
	return run_query_on(ns, true, ...)
end

function query(...)
	return query_on(false, ...)
end

--query frontends ------------------------------------------------------------

function query1_on(ns, ...) --query first row (or first row/column) and close
	local t, cols, params = run_query_on(ns, false, ...)
	local row = t[1]
	if not row then return end
	if #cols == 1 then
		return row, params --row is actually the value
	end --first row/col
	return row, params --first row
end

function query1(...)
	return query1_on(false, ...)
end

function iquery_on(ns, ...) --insert query: return the value of the auto_increment field.
	local t, cols, params = run_query_on(ns, true, ...)
	local id = t.insert_id
	return id ~= 0 and id or nil, params
end

function iquery(...)
	return iquery_on(false, ...)
end

function changed(res)
	return tonumber(res.message:match'Changed: (%d+)') > 0
end

function atomic(func)
	query'start transaction'
	local ok, err = glue.pcall(func)
	query(ok and 'commit' or 'rollback')
	assert(ok, err)
end

--result structuring ---------------------------------------------------------

function groupby(items, col)
	local t = {}
	local v
	local st
	local group_func = col
	if type(col) == 'string' then
		group_func = function(e) return e[col] end
	end
	for i,e in ipairs(items) do
		local v1 = group_func(e)
		if not st or v ~= v1 then
			st = {}
			t[#t+1] = st
		end
		st[#st+1] = e
		v = v1
	end
	return ipairs(t)
end

--ddl vocabulary -------------------------------------------------------------

local function allow_drop(on)
	if on ~= nil then
		ngx.ctx.allow_drop = on
	elseif ngx.ctx.allow_drop ~= nil then
		return ngx.ctx.allow_drop
	else
		return not config('allow_drop', false)
	end
end

local function constable(name)
	return query1([[
		select c.table_name from information_schema.table_constraints c
		where c.table_schema = ? and c.constraint_name = ?
	]], config'db_name', name)
end

function dropfk(name)
	if not droptable() then return end
	local tbl = constable(name)
	if not tbl then return end
	query('alter table '..tbl..' drop foreign key '..name..';')
end

function droptable(name)
	if not name or type(name) == 'boolean' then
		return allow_drop(name)
	end
	if not droptable() then return end
	query('drop table if exists '..name..';')
end

local function fkname(tbl, col)
	return string.format('fk_%s_%s', tbl, col:gsub('%s', ''):gsub(',', '_'))
end

function qmacro.fk(tbl, col, ftbl, fcol, ondelete, onupdate)
	ondelete = ondelete or 'restrict'
	onupdate = onupdate or 'cascade'
	local a1 = ondelete ~= 'restrict' and ' on delete '..ondelete or ''
	local a2 = onupdate ~= 'restrict' and ' on update '..onupdate or ''
	return string.format(
		'constraint %s foreign key (%s) references %s (%s)%s%s',
		fkname(tbl, col), col, ftbl, fcol or col, a1, a2)
end

function qmacro.uk(tbl, col)
	return string.format(
		'constraint uk_%s_%s unique key (%s)',
		tbl, col:gsub('%s', ''):gsub(',', '_'), col)
end

function fk(tbl, col, ...)
	if constable(fkname(tbl, col)) then return end
	local sql = string.format('alter table %s add ', tbl)..
		qmacro.fk(tbl, col, ...)..';'
	query(sql)
end

