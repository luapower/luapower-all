--[==[

	webb | mysql query module
	Written by Cosmin Apreutesei. Public Domain.

QUERY

	quote(s) -> s                             quote sql string
	print_queries([t|f]) -> t|f               control printing of queries
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

local mysql = require'resty.mysql'

--db connection --------------------------------------------------------------

local db --global db object

local function assert_db(ret, ...)
	if ret ~= nil then return ret, ... end
	local err, errno, sqlstate = ...
	error('db error: '..err..': '..(errno or '')..' '..(sqlstate or ''))
end

local function connect()
	if conn then return end
	db = assert(mysql:new())
	db:set_timeout(config('db_conn_timeout', 3) * 1000)
	assert_db(db:connect{
		host     = config('db_host', '127.0.0.1'),
		port     = config('db_port', 3306),
		database = config('db_name'),
		user     = config('db_user', 'root'),
		password = config('db_pass'),
	})
	db:set_timeout(config('db_query_timeout', 30) * 1000)
end

--macro substitution ---------------------------------------------------------

local substs = {}

function qsubst(def) --'name type'
	local name, val = def:match'(%w+)%s+(.*)'
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
	sql = sql:gsub('$(%w+)(%b())', macro_subst)
	sql = sql:gsub('$(%w+)', substs)
	return sql
end

--arg substitution -----------------------------------------------------------

function quote(v)
	if v == nil then
		return 'null'
	elseif v == true then
		return 1
	elseif v == false then
		return 0
	elseif type(v) == 'string' or type(v) == 'number' then
		return ngx.quote_sql_str(tostring(v))
	else
		return nil, 'invalid arg '.. require'pp'.format(v)
	end
end

local function set_params(sql, ...)
	local t = {}
	for i = 1, select('#', ...) do
		local arg = select(i, ...)
		local v, err = quote(arg)
		if err then
			error(err .. ' in query "' .. sql .. '"')
		end
		t[i] = v
	end
	local i = 0
	return sql:gsub('%?', function() i = i + 1; return t[i] end)
end

--result processing ----------------------------------------------------------

local function remove_nulls(t)
	for i,t in ipairs(t) do
		for k,v in pairs(t) do
			if v == ngx.null then
				t[k] = nil
			end
		end
	end
end

--query execution ------------------------------------------------------------

function print_queries(on)
	if on ~= nil then
		ngx.ctx.print_queries = on
	else
		return ngx.ctx.print_queries or false
	end
end

local function outdent(s)
	local indent = s:match'^[\t%s]+'
	if not indent then return s end
	local t = {}
	for s in (s..'\n'):gmatch'(.-)\r?\n' do
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
	remove_nulls(t)
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

local function run_query(sql)
	if print_queries() then
		print(outdent(sql))
	end
	assert_db(db:send_query(sql))
	local t, err, cols = assert_db(db:read_result())
	t = process_result(t, cols)
	if err == 'again' then --multi-result/multi-statement query
		t = {t}
		repeat
			local t1, err = assert_db(db:read_result())
			t1 = process_result(t1, cols)
			t[#t+1] = t1
		until not err
	end
	return t, cols
end

function query(sql, ...) --execute, iterate rows, close
	connect()
	sql = preprocess(sql)
	sql = set_params(sql, ...)
	return run_query(sql)
end

--query frontends ------------------------------------------------------------

function query1(sql, ...) --query first row (or first row/column) and close
	local t, cols = query(sql, ...)
	local row = t[1]
	if not row then return end
	if #cols == 1 then
		return row --row is actually the value
	end --first row/col
	return row --first row
end

function iquery(sql, ...) --insert query: return autoincremented id
	return query(sql, ...).insert_id
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
	ondelete = ondelete or 'cascade'
	onupdate = onupdate or 'restrict'
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

