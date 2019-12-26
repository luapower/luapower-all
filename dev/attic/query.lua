
--database query function

setfenv(1, require'app')

local mysql = require'resty_mysql'

--db connection --------------------------------------------------------------

local db --global db object

function assert_db(ret, ...)
	if ret ~= nil then return ret, ... end
	local err, errno, sqlstate = ...
	error('db error: '..err..': '..(errno or '')..' '..(sqlstate or ''))
end

local function connect(select_db)
	if conn then return end
	db = assert(mysql:new())
	db:set_timeout(config('db_conn_timeout', 3) * 1000)
	assert_db(db:connect{
		host     = config('db_host', '127.0.0.1'),
		port     = 3306,
		database = select_db and config('db_name', 'luapower'),
		user     = config('db_user', 'root'),
		password = config('db_pass'),
	})
	db:set_timeout(config('db_query_timeout', 30) * 1000)
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

print_queries = false

local function run_query(sql)
	sql = preprocess(sql)
	if print_queries then
		print(sql)
	end
	assert_db(db:send_query(sql))
	local t, err, cols = assert_db(db:read_result())
	remove_nulls(t)
	if err == 'again' then --multi-result/multi-statement query
		t = {t}
		repeat
			local t1, err = assert_db(db:read_result())
			remove_nulls(t1)
			t[#t+1] = t1
		until not err
	end
	return t, cols
end

function db_query(sql, ...) --execute, iterate rows, close
	connect(false)
	sql = set_params(sql, ...)
	return run_query(sql)
end

function query(sql, ...) --execute, iterate rows, close
	connect(true)
	sql = set_params(sql, ...)
	return run_query(sql)
end

--query frontends ------------------------------------------------------------

function query1(sql, ...) --query first row (or first row/column) and close
	local t, cols = query(sql, ...)
	local row = t[1]
	if not row then return end
	if #cols == 1 then
		local _,v = next(row)
		return v
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

